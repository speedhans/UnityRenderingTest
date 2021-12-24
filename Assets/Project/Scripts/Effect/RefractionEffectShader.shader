Shader "Custom/RefractionEffectShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GrabPow("GrabPow", float) = 10000
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            struct vertexData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 posWS : TEXCOORD1;
                float4 posCS : SV_POSITION;
                float2 pixelPos : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex); half4 _MainTex_ST;
            float _GrabPow;
            CBUFFER_END
            TEXTURE2D(_CameraOpaqueTexture); SAMPLER(sampler_CameraOpaqueTexture); float4 _CameraOpaqueTexture_TexelSize;

            v2f vert (vertexData v)
            {
                v2f o;
                o.posWS = TransformObjectToWorld(v.vertex.xyz);
                o.posCS = TransformWorldToHClip(o.posWS);
                float4 screenPos = ComputeScreenPos(o.posCS);
                o.pixelPos = screenPos.xy / screenPos.w;
                o.uv = v.uv;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half2 uv = i.uv;
                half2 screenPos = i.pixelPos;

                half4 mainColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);

                float count = 1;
                for (int i = 0; i < 4; ++i)
                {
                    mainColor += SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, half2(screenPos.x + (_GrabPow * i), screenPos.y));
                    mainColor += SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, half2(screenPos.x - (_GrabPow * i), screenPos.y));
                    mainColor += SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, half2(screenPos.x, screenPos.y + (_GrabPow * i)));
                    mainColor += SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, half2(screenPos.x, screenPos.y - (_GrabPow * i)));
                    count += 4;
                }

                mainColor /= count;

                return mainColor;
            }
            ENDHLSL
        }
    }
}
