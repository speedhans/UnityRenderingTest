Shader "Custom/CloudsShader"
{
    Properties
    {
        _TextureLURD ("TextureLURD", 2D) = "white" {}
        _TextureFBDA ("TextureFBDA", 2D) = "white" {}
        _LightingPow ("LightingPow", Range(-0.5,2)) = 0.0
        _Density ("Density", float) = 1.0
        _AmbientIntensity("AmbientIntensity", float) = 1.0
        _Tint ("Tint", Color) = (1,1,1,1)
        _Thickness("Thickness", float ) = 1.0
        _HightFogOffset("HightFogOffset", float) = 1.0
        _HightFogDistance("HightFogDistance", float) = 1.0
        _StartEndDepthFade("Start/End Depth Fade", Vector) = (0,1,0,0)
        [Toggle]_SoftParticles("SoftParticles", float) = 0.0
        [Toggle]_BlueNoise("BlueNoise", float) = 0.0

        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("SrcBlend Mode", Float) = 5 // SrcAlpha
        [Enum(UnityEngine.Rendering.BlendMode)]_DstBlend("DstBlend Mode", Float) = 1 // One

    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True"}
        LOD 100

        Pass
        {
            Name "Clouds"
            Tags { "LightMode" = "UniversalForward" }

            ZWrite On
            ZTest On
            Cull front
            Blend [_SrcBlend] [_DstBlend]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            //#include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : NORMAL;
                float3 tangentWS : TANGENT;
                float3 bitangentWS : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
                float3 positionOS : TEXCOORD4;
                float4 positionCS : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
            float4x4 _BA_SkyboxMatrix;
            float _BA_SkyboxRatio;
            float4 _FogColor;
            float _FogDensity;
            float4 _BA_CloudData;
            CBUFFER_END

            TEXTURE2D(_TextureLURD); SAMPLER(sampler_TextureLURD); half4 _TextureLURD_ST;
            TEXTURE2D(_TextureFBDA); SAMPLER(sampler_TextureFBDA); half4 _TextureFBDA_ST;
            float _LightingPow;
            float _Density;
            float _AmbientIntensity;
            float4 _Tint;
            float _Thickness;
            float _HightFogOffset;
            float _HightFogDistance;
            float2 _StartEndDepthFade;
            float _SoftParticles;
            float _BlueNoise;

            v2f vert (appdata v)
            {
                v2f o;

                o.positionWS = TransformObjectToWorld(v.vertex.xyz);
                o.positionCS = TransformObjectToHClip(v.vertex.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normal);
                o.tangentWS = mul((float3x3)UNITY_MATRIX_MV, v.tangent);
                o.bitangentWS = cross(o.tangentWS, o.normalWS);
                o.viewDir = GetWorldSpaceViewDir(o.positionWS);
                o.positionOS = v.vertex.zyz;
                o.uv = v.uv;

                return o;
            }

            inline float Remap(float source, float2 InMinMax, float2 OutMinMax)
            {
                return OutMinMax.x + (source - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
            }

            float ComputeLightMap(float3 lightDir, float left, float right, float up, float down, float front, float back)
            {
                float frontsource = pow((left + right + up + down) * 0.25, 1);

                float frontRec = 1 - frontsource;
                float backRec = frontsource;
                
                float horizontal = lightDir.x > 0 ? right : left;
                float vertical = lightDir.y > 0 ? up : down;
                float axial = lightDir.z > 0 ? backRec : frontRec;

                float3 combine = (lightDir * lightDir) * float3(horizontal, vertical, axial);

                float final = combine.x + combine.y + combine.z;
                return final;
            }

            float3 SampleSH(float3 normalWS)
            {
                // LPPV is not supported in Ligthweight Pipeline
                real4 SHCoefficients[7];
                SHCoefficients[0] = unity_SHAr;
                SHCoefficients[1] = unity_SHAg;
                SHCoefficients[2] = unity_SHAb;
                SHCoefficients[3] = unity_SHBr;
                SHCoefficients[4] = unity_SHBg;
                SHCoefficients[5] = unity_SHBb;
                SHCoefficients[6] = unity_SHC;

                return max(float3(0, 0, 0), SampleSH9(SHCoefficients, normalWS));
            }

            float3 CustomMixFog(float3 color, float3 posWS)
            {
                float a = posWS.y - _WorldSpaceCameraPos.y * (1 - _BA_SkyboxRatio);
                float b = _HightFogOffset * _BA_SkyboxRatio;
                float c = max(_HightFogDistance * _BA_SkyboxRatio, 0) / 1;

                float heightFog = saturate((a - b) * c);

                float d = (_FogDensity / _BA_SkyboxRatio);
                float expFog = exp2(1 - (d * d));

                float e = 1.0 - (1.0 - heightFog) * (1.0 - expFog);
                float density = lerp(expFog, e, 1);

                return lerp(_FogColor.rgb, color, saturate(density));
            }

            float RandomRange(float2 Seed, float Min, float Max)
            {
                float randomno = frac(sin(dot(Seed, float2(12.9898, 78.233))) * 43758.5453);
                return lerp(Min, Max, randomno);
            }

            void SceenSpaceBlueNoise(float2 dimenstions, float animated, float seed, float4 screenPos)
            {
                float s = seed * 0.321;
                float2 timeParam = float2(_Time.x, _Time.x);

                float2 b = (timeParam * s) * float2(0.018, 0.32) + s;
                float2 fraction = frac(b);

                float random1 = RandomRange(fraction.x, 0, _ScreenParams.x);
                float random2 = RandomRange(fraction.y, 0, _ScreenParams.y);

                float2 uv = screenPos.xy / screenPos.w;

                float2 fixuv = frac((float2(random1, random2) + (uv * screenPos.xy)) / dimenstions);

                //  텍스쳐가 없다...
            }

            float ComputeSoftParticle(float4 screenPos, float offset)
            {
                float depth = Linear01Depth(screenPos.xy / screenPos.w, _ZBufferParams) * _ProjectionParams.z;
                return saturate(Remap(depth - (screenPos.w + offset), _StartEndDepthFade.xy, float2(0, 1)));
            }

            half4 frag(v2f i) : SV_Target
            {
                Light mainLight = GetMainLight();

                float3x3 cloudMat = float3x3(i.tangentWS, i.bitangentWS, i.normalWS);
                float3 tangentLight = mul(cloudMat, mainLight.direction);

                // sample the texture
                half4 LURD = SAMPLE_TEXTURE2D(_TextureLURD, sampler_TextureLURD, i.uv);
                half4 FBDA = SAMPLE_TEXTURE2D(_TextureFBDA, sampler_TextureFBDA, i.uv);

                clip(FBDA.w - 0.05);

                //------- Color Field ------------
                float lightmap = ComputeLightMap(tangentLight, LURD.x, LURD.z, LURD.y, LURD.w, FBDA.x, FBDA.y);
                float RimLight = Remap(pow(saturate(dot(SafeNormalize(i.viewDir), mainLight.direction * -1)), 150), float2(0, 1), float2(1, 2));

                float directLighting = pow(lightmap, max(Remap(_LightingPow, float2(0, 1), float2(0.5, 1)) * _Density, 0));

                float3 ambient = SampleSH(SafeNormalize(float3(1, lightmap, 1))) * _AmbientIntensity;

                float3 finalColor = mainLight.color * (RimLight * directLighting) + ambient * _Tint.xyz;
                finalColor = CustomMixFog(finalColor, i.positionWS);
                //---------------------------------

                float depth = FBDA.z;

                //------ Alpha Field --------------
                float alpha = 1 - pow((1 - FBDA.w), _Density);

                float a_a = 1 - _BA_CloudData.a;

                float alphaFade = min(alpha, smoothstep(a_a, a_a + 0.1, depth));
               
                //---------------------------------

                float offset = (1 - depth) * _Thickness;
                float softpaticle = ComputeSoftParticle(ComputeScreenPos(float4(i.positionCS)), offset);

                return half4(finalColor * alphaFade, softpaticle);
            }
            ENDHLSL
        }
    }
}
