Shader "Unlit/BlitTestShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Pow("Power", float) = 10000
        _Density("Density", float) = 0.002
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
            float _Pow;
            float _Density;
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
                half2 uv = i.uv;

                half4 mainColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                half4 sample1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, half2(uv.x + sin((uv.x * _Pow) % 2 + _Time.w) * _Density, uv.y));
                half4 sample2 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, half2(uv.x + cos((uv.x * _Pow) % 2 + _Time.w) * _Density, uv.y));

                half4 finalColor = (mainColor + sample1 + sample2) / 3;

                return finalColor;
            }
            ENDHLSL
        }
    }
}
