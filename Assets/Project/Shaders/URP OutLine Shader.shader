Shader "Custom/URP OutLine Shader"
{
    Properties
    {
        _OutLineWidth("OutLineWidth", float) = 0.0
        _OutLineColor("OutLineColor", Color) = (0.0, 0.0, 0.0, 1)
        _OutLineCurve("OutLineCurve", float) = 0.0
        _OutLineCP("OutLineCP", float) = 0.0
        _ZTest("ZTest", float) = 0.0
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True"}
        LOD 100

        Pass
        {
            Stencil
            {
                Ref 1
                Comp Always
                Pass Replace
            }

            Name "OutLine"
            Tags { "LightMode" = "UniversalForward" }

            ZWrite On
            ZTest [_ZTest]
            Cull front

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" // URP 코어 코드

            struct vertexdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            CBUFFER_START(UnityPerMaterial)
            float _OutLineWidth;
            float4 _OutLineColor;
            float _OutLineCurve;
            float _OutLineCP;
            CBUFFER_END

            //float4x4 _ScaleMat = 
            //{
            //    1.0f, 0.0f, 0.0f, 0.0f,
            //    0.0f, 1.0f, 0.0f, 0.0f,
            //    0.0f, 0.0f, 1.0f, 0.0f,
            //    0.0f, 0.0f, 0.0f, 1.0f,
            //};

            Varyings vert(vertexdata v)
            {
                Varyings o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                //_ScaleMat[0][0] += _OutLineWidth;
                //_ScaleMat[1][1] += _OutLineWidth;
                //_ScaleMat[2][2] += _OutLineWidth;
                //_ScaleMat[3][3] += _OutLineWidth;

                float3 posWS = TransformObjectToWorld(v.vertex.xyz);//TransformObjectToWorld(mul(_ScaleMat, v.vertex.xyz));
                o.positionCS = TransformWorldToHClip(posWS);
                //float3 posPJ = mul((float3x3)UNITY_MATRIX_VP, v.vertex.xyz);

                float3 normalVS = mul((float3x3)UNITY_MATRIX_MVP, v.normal).xyz;//TransformObjectToWorldNormal(v.normal);//mul((float3x3)UNITY_MATRIX_MVP, v.normal).xyz;
                float2 offset = normalVS.xy / _ZBufferParams.y * _OutLineWidth * (1.0f + (_OutLineCurve * cos(abs((v.vertex.x + v.vertex.z) * _OutLineCP)))) * o.positionCS.w;
                o.positionCS.xy += offset;

                return o;
            }

            half4 frag(Varyings i) : SV_Target
            { 
                UNITY_SETUP_INSTANCE_ID(i);
                return _OutLineColor;
            }

            ENDHLSL
        }
    }
}
