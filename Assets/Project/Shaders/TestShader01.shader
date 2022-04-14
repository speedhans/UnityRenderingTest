Shader "Custom/TestShader01"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalTex("NormalTex", 2D) = "white" {}
        _StencilRef("_StencilRef", float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp("_StencilComp", float) = 0
        [Enum(UnityEngine.Rendering.CullMode)]_Cull("_Cull", float) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)]_ZTest("_ZTest", float) = 0
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "Queue" = "Geometry+501" "RenderPipeline" = "UniversalRenderPipeline" }
        LOD 100

        Pass
        {
            //Stencil
            //{
            //    Ref[_StencilRef]
            //    Comp[_StencilComp]
            //    //Pass Replace
            //}

            Cull [_Cull]
            ZTest [_ZTest]
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM

            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" // URP 코어 코드
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl" // URP 코어 코드
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct verdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 T : TEXCOORD1;
                float3 B : TEXCOORD2;
                float3 N : TEXCOORD3;
                float4 positionCS   : SV_POSITION;
            };

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalTex); SAMPLER(sampler_NormalTex);
            CBUFFER_START(UnityPerMaterial)
            half4 _MainTex_ST;
            half4 _NormalTex_ST;
            CBUFFER_END


            void Fuc_LocalNormal2TBN(half3 localnormal, float4 tangent, inout half3 T, inout half3  B, inout half3 N)
            {
                half fTangentSign = tangent.w * unity_WorldTransformParams.w;
                N = normalize(TransformObjectToWorldNormal(localnormal));
                T = normalize(TransformObjectToWorldDir(tangent.xyz));
                B = normalize(cross(N, T) * fTangentSign);
            }

            half3 Fuc_TangentNormal2WorldNormal(half3 fTangnetNormal, half3 T, half3  B, half3 N)
            {
                float3x3 TBN = float3x3(T, B, N);
                TBN = transpose(TBN);
                return mul(TBN, fTangnetNormal);
            }


            v2f vert (verdata v)
            {
                v2f o;

                VertexPositionInputs vertexPositionInput = GetVertexPositionInputs(v.vertex);

                o.positionCS = vertexPositionInput.positionCS;
                //o.normal = TransformObjectToWorldNormal(v.normal);
                o.uv = v.uv;

                Fuc_LocalNormal2TBN(v.normal, v.tangent, o.T, o.B, o.N);

                return o;
            }



            half4 frag(v2f i) : SV_Target
            {
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                half3 fTangnetNormal = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv));
                fTangnetNormal.xy *= 1.5f; // 노말강도 조절
                float3 worldNormal = Fuc_TangentNormal2WorldNormal(fTangnetNormal, i.T, i.B, i.N);

                Light light = GetMainLight();

                float d = dot(light.direction, worldNormal);
                col *= dot(light.direction, worldNormal);

                return float4(d,d,d, 1);
            }
            ENDHLSL
        }
    }
}
