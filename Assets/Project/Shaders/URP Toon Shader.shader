Shader "Custom/URP Toon Shader"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _MainColor("MainColor", Color) = (1,1,1,1)
        _CutOff("Alpha CutOff", Range(0.0, 1.0)) = 0.5

        _RampTex("RampTex", 2D) = "white" {}
        _SpecularPower("SpecularPower", float) = 0.0
        [HDR] _SpecularColor("SpecularColor", Color) = (1,1,1,1)
        _SpecularIntensity("SpecularIntensity", float) = 0.0
        _FresnelPower("FresnelPower", float) = 0.0
        _FresnelAngle("FresnelAngle", Range(-30, 0)) = -1
        _FresnelIntensity("FresnelIntensity", float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0

        _Cull("Cull", float) = 0.0
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }
        LOD 100

        Pass
        {
            Name "URP Toon"
            Tags { "LightMode" = "UniversalForward" }

            Cull [_Cull]

            HLSLPROGRAM
            #pragma target 4.5

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON

            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" // URP 코어 코드
            #include "Assets/Project/Shaders/Lighting/Lighting_c.hlsl" // URP 빛 관련 코드
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl" // SurfaceData 등 UPR의 기본 데이터를 받아올때 사용되는 듯?
            #include "Assets/Project/Shaders/CustomFuntion.hlsl"

            struct vertexdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };


            struct Varyings
            {
                float2 uv                       : TEXCOORD0;
                float4 positionWSAndFogFactor   : TEXCOORD2; // xyz: positionWS, w: vertex fog factor
                half3  normalWS                 : TEXCOORD3;
        //#ifdef _MAIN_LIGHT_SHADOWS
                float4 shadowCoord              : TEXCOORD6; // compute shadow coord per-vertex for the main light
        //#endif
                float4 positionCS               : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            CBUFFER_START(UnityPerMaterial)
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex); half4 _MainTex_ST;
            TEXTURE2D(_RampTex); SAMPLER(sampler_RampTex); half4 _RampTex_ST;
            half4 _MainColor;
            float _CutOff;
            half _SpecularPower;
            half4 _SpecularColor;
            half _SpecularIntensity;
            half _FresnelPower;
            half _FresnelAngle;
            half _FresnelIntensity;
            CBUFFER_END


            Varyings vert(vertexdata v)
            {
                Varyings o;

                float3 posWS = TransformObjectToWorld(v.vertex.xyz);
                o.positionCS = TransformWorldToHClip(posWS);
                float fogFactor = ComputeFogFactor(o.positionCS.z);
                o.normalWS = TransformObjectToWorldNormal(v.normal);
                o.positionWSAndFogFactor = float4(posWS, fogFactor);
//#ifdef _MAIN_LIGHT_SHADOWS
                o.shadowCoord = TransformWorldToShadowCoord(posWS);
//#endif
                o.uv = v.uv;

                return o;
            }

            half4 CalSpecular(half3 normal, half3 viewDir, half3 lightDir)
            {
                half NdotH = dot(normal, normalize(viewDir + lightDir));
                NdotH = Remap(NdotH, float2(-1, 1), float2(0, 1));
                return step(0.1f, pow(abs(NdotH), _SpecularPower)) * _SpecularIntensity * _SpecularColor; //smoothstep(0.1f,0.99f, pow(abs(NdotH), _SpecularPower)) * _SpecularColor;
            }

            half4 frag(Varyings v) : SV_Target
            {
//#ifdef _MAIN_LIGHT_SHADOWS 
                Light mainLight = GetMainLight(v.shadowCoord);
//#else
//                Light mainLight = GetMainLight();
//#endif

                half3 positionWS = v.positionWSAndFogFactor.xyz;
                half fogfactor = v.positionWSAndFogFactor.w;
                half3 viewDir = SafeNormalize(GetCameraPositionWS() - positionWS);

                // 기본 컬러
                half4 diffuse = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, v.uv) * _MainColor;

                // 기본 Cel Shadow 계산
                half4 ramp = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(Minimum(mainLight.shadowAttenuation * mainLight.distanceAttenuation, Remap(dot(mainLight.direction, v.normalWS), float2(-1, 1), float2(0.01f, 0.99f))), 0.5f));

                // 그림자를 받고 있는지 여부
                //half shadowAttenuation = mainLight.shadowAttenuation;

                // 역광 프레넬 효과
                half fresnel = FresnelEffect(v.normalWS, viewDir, _FresnelPower);
                fresnel *= Remap(dot(mainLight.direction, normalize(-(v.normalWS) + viewDir)), float2(-1,1), float2(1, _FresnelAngle));
                fresnel = step(0.1f, fresnel) * _FresnelIntensity * mainLight.shadowAttenuation;

#ifdef _ADDITIONAL_LIGHTS // 추가 광원 계산
                int additionalLightsCount = GetAdditionalLightsCount();
                half3 additionalColor = half3(0,0,0);
                half4 additionalRamp = half4(0, 0, 0, 0);
                if (additionalLightsCount > 0)
                {
                    for (int j = 0; j < additionalLightsCount; ++j)
                    {
                        Light light = GetAdditionalLight(j, positionWS);
                        additionalColor = Maximum(additionalColor, light.color * dot(v.normalWS, light.direction) * light.shadowAttenuation * light.distanceAttenuation);
                        additionalRamp = Maximum(additionalRamp, SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(Remap(dot(light.direction, v.normalWS), float2(-1, 1), float2(0.01f, 0.99f)), 0.5f)));// light.shadowAttenuation* light.distanceAttenuation)));
                        //shadowAttenuation = Maximum(shadowAttenuation, light.shadowAttenuation);
                    }
                }

                diffuse.xyz = Maximum(diffuse.xyz, additionalColor);// *mainLight.shadowAttenuation;// *mainLight.distanceAttenuation;
                ramp = Maximum(ramp, additionalRamp);

#endif
                // 스펙큘러 계산
                half4 spec = CalSpecular(v.normalWS, viewDir, mainLight.direction);

                // 최종 색 결정
                half4 finalcolor;
                half4 Intensity = Maximum(fresnel, ramp);
                Intensity = Maximum(Intensity, spec);
                finalcolor = float4(diffuse.xyz * mainLight.color * Intensity.xyz, diffuse.a);
                //return float4(mainLight.shadowAttenuation, mainLight.distanceAttenuation, 0, 1);
                return finalcolor;
//#ifdef _MAIN_LIGHT_SHADOWS 
//                return half4(0, 1, 0, 1);
//#else
//                return half4(0, 0, 1, 1);
//#endif
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            Cull[_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/Project/Shaders/CustomSurfaceInput.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 texcoord     : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 positionCS   : SV_POSITION;
            };

            float3 _LightDirection;

            CBUFFER_START(UnityPerMaterial)
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex); half4 _MainTex_ST;
            TEXTURE2D(_RampTex); SAMPLER(sampler_RampTex); half4 _RampTex_ST;
            half4 _MainColor;
            float _CutOff;
            half _SpecularPower;
            half4 _SpecularColor;
            half _SpecularIntensity;
            half _FresnelPower;
            half _FresnelAngle;
            half _FresnelIntensity;
            CBUFFER_END

            float4 _ShadowBias;

            float3 ApplyShadowBias(float3 positionWS, float3 normalWS, float3 lightDirection)
            {
                float invNdotL = 1.0 - saturate(dot(lightDirection, normalWS));
                float scale = invNdotL * _ShadowBias.y;

                // normal bias is negative since we want to apply an inset normal offset
                positionWS = lightDirection * _ShadowBias.xxx + positionWS;
                positionWS = normalWS * scale.xxx + positionWS;
                return positionWS;
            }

            float4 GetShadowPositionHClip(Attributes input)
            {
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

#if UNITY_REVERSED_Z
                positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#else
                positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#endif

                return positionCS;
            }

            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);

                output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
                output.positionCS = GetShadowPositionHClip(input);
                return output;
            }
            
            half4 ShadowPassFragment(Varyings input) : SV_TARGET
            {
                Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_MainTex, sampler_MainTex)).a, _MainColor, _CutOff);
                return 0;
            }

            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/Project/Shaders/CustomSurfaceInput.hlsl"

            struct Attributes
            {
                float4 position     : POSITION;
                float2 texcoord     : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 positionCS   : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            CBUFFER_START(UnityPerMaterial)
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex); half4 _MainTex_ST;
            TEXTURE2D(_RampTex); SAMPLER(sampler_RampTex); half4 _RampTex_ST;
            half4 _MainColor;
            float _CutOff;
            half _SpecularPower;
            half4 _SpecularColor;
            half _SpecularIntensity;
            half _FresnelPower;
            half _FresnelAngle;
            half _FresnelIntensity;
            CBUFFER_END

            Varyings DepthOnlyVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
                output.positionCS = TransformObjectToHClip(input.position.xyz);
                return output;
            }

            half4 DepthOnlyFragment(Varyings input) : SV_TARGET
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_MainTex, sampler_MainTex)).a, _MainColor, _CutOff);
                return 0;
            }
            ENDHLSL
        }

        // This pass it not used during regular rendering, only for lightmap baking.
//        Pass
//        {
//            Name "Meta"
//            Tags{"LightMode" = "Meta"}
//
//            Cull Off
//
//            HLSLPROGRAM
//            // Required to compile gles 2.0 with standard srp library
//            #pragma prefer_hlslcc gles
//            #pragma exclude_renderers d3d11_9x
//
//            #pragma vertex UniversalVertexMeta
//            #pragma fragment UniversalFragmentMeta
//
//            #pragma shader_feature _SPECULAR_SETUP
//            #pragma shader_feature _EMISSION
//            #pragma shader_feature _METALLICSPECGLOSSMAP
//            #pragma shader_feature _ALPHATEST_ON
//            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
//
//            #pragma shader_feature _SPECGLOSSMAP
//
//            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
//            #include "Assets/Project/Shader/CustomSurfaceInput.hlsl"
//
//            struct Attributes
//            {
//                float4 positionOS   : POSITION;
//                float3 normalOS     : NORMAL;
//                float2 uv0          : TEXCOORD0;
//                float2 uv1          : TEXCOORD1;
//                float2 uv2          : TEXCOORD2;
//            #ifdef _TANGENT_TO_WORLD
//                float4 tangentOS     : TANGENT;
//            #endif
//            };
//
//            struct Varyings
//            {
//                float4 positionCS   : SV_POSITION;
//                float2 uv           : TEXCOORD0;
//            };
//
//            CBUFFER_START(UnityPerMaterial)
//            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex); float4 _MainTex_ST;
//            half4 _MainColor;
//            half4 _EmissionColor;
//            float _CutOff;
//            CBUFFER_END
//
//            Varyings UniversalVertexMeta(Attributes input)
//            {
//                Varyings output;
//                output.positionCS = MetaVertexPosition(input.positionOS, input.uv1, input.uv2,
//                    unity_LightmapST, unity_DynamicLightmapST);
//                output.uv = TRANSFORM_TEX(input.uv0, _MainTex);
//                return output;
//            }
//
//            half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha)
//            {
//                half4 specGloss;
//
//#ifdef _METALLICSPECGLOSSMAP
//                specGloss = SAMPLE_METALLICSPECULAR(uv);
//#ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
//                specGloss.a = albedoAlpha * _Smoothness;
//#else
//                specGloss.a *= _Smoothness;
//#endif
//#else // _METALLICSPECGLOSSMAP
//#if _SPECULAR_SETUP
//                specGloss.rgb = _SpecColor.rgb;
//#else
//                specGloss.rgb = _Metallic.rrr;
//#endif
//
//#ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
//                specGloss.a = albedoAlpha * _Smoothness;
//#else
//                specGloss.a = _Smoothness;
//#endif
//#endif
//
//                return specGloss;
//            }
//
//            inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
//            {
//                half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_MainTex, sampler_MainTex));
//                outSurfaceData.alpha = Alpha(albedoAlpha.a, _MainColor, _CutOff);
//
//                half4 specGloss = SampleMetallicSpecGloss(uv, albedoAlpha.a);
//                outSurfaceData.albedo = albedoAlpha.rgb * _MainColor.rgb;
//
//#if _SPECULAR_SETUP
//                outSurfaceData.metallic = 1.0h;
//                outSurfaceData.specular = specGloss.rgb;
//#else
//                outSurfaceData.metallic = specGloss.r;
//                outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);
//#endif
//
//                outSurfaceData.smoothness = specGloss.a;
//                outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
//                outSurfaceData.occlusion = SampleOcclusion(uv);
//                outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
//            }
//
//            half4 UniversalFragmentMeta(Varyings input) : SV_Target
//            {
//                SurfaceData surfaceData;
//                InitializeStandardLitSurfaceData(input.uv, surfaceData);
//
//                BRDFData brdfData;
//                InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);
//
//                MetaInput metaInput;
//                metaInput.Albedo = brdfData.diffuse + brdfData.specular * brdfData.roughness * 0.5;
//                metaInput.SpecularColor = surfaceData.specular;
//                metaInput.Emission = surfaceData.emission;
//
//                return MetaFragment(metaInput);
//            }
//
//
//            //LWRP -> Universal Backwards Compatibility
//            Varyings LightweightVertexMeta(Attributes input)
//            {
//                return UniversalVertexMeta(input);
//            }
//
//            half4 LightweightFragmentMeta(Varyings input) : SV_Target
//            {
//                return UniversalFragmentMeta(input);
//            }
//
//            ENDHLSL
//        }
    }
}
