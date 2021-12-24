Shader "Custom/ShadowMaskDebugShader"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _ShadowMaskTexture("ShadowMask", 2D) = "white" {}
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

            struct vertexData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 posCS : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex); half4 _MainTex_ST;
            TEXTURE2D(_ShadowMaskTexture); SAMPLER(sampler_ShadowMaskTexture); half4 _ShadowMaskTexture_ST;
            CBUFFER_END

            v2f vert (vertexData v)
            {
                v2f o;
                o.posCS = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                half mask = SAMPLE_TEXTURE2D(_ShadowMaskTexture, sampler_ShadowMaskTexture, i.uv).r;

                color.r += mask;

                return color;
            }
            ENDHLSL
        }
    }
}
