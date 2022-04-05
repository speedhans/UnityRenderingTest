Shader "Custom/SSDecal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _StencilRef("_StencilRef", float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp("_StencilComp", float) = 0
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "Queue" = "Geometry+501" "RenderPipeline" = "UniversalRenderPipeline" }
        LOD 100

        Pass
        {
            Stencil
            {
                Ref[_StencilRef]
                Comp[_StencilComp]
                Pass Replace
            }
            
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM

            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" // URP �ھ� �ڵ�
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct verdata
            {
                float4 vertex   : POSITION;
            };

            struct v2f
            {
                float4 screenPos    : TEXCOORD0;
                float4 viewPosOS    : TEXCOORD1;
                float3 cameraPosOS  : TEXCOORD2;
                float4 positionCS   : SV_POSITION;
            };

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            CBUFFER_START(UnityPerMaterial)
            half4 _MainTex_ST;
            CBUFFER_END

            v2f vert (verdata v)
            {
                v2f o;

                VertexPositionInputs vertexPositionInput = GetVertexPositionInputs(v.vertex);

                o.positionCS = vertexPositionInput.positionCS;
                o.screenPos = ComputeScreenPos(o.positionCS);

                float3 viewPos = vertexPositionInput.positionVS;
                o.viewPosOS.w = viewPos.z;

                float4x4 ViewToObjectMatrix = mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V);

                o.viewPosOS.xyz = mul((float3x3)ViewToObjectMatrix, viewPos * -1);

                o.cameraPosOS = mul(ViewToObjectMatrix, float4(0, 0, 0, 1)).xyz; //< ī�޶� ��ǥ�� ������Ʈ ���� ��ǥ�� ��ȯ

                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                // �ȼ� ���̴� �ܰ迡�� ������ ������ ��Ȯ�� �������� ������ ����
                i.viewPosOS.xyz /= i.viewPosOS.w;

                float2 screenSpaceUV = i.screenPos.xy / i.screenPos.w;
                float sceneRawDepth = SAMPLE_TEXTURE2D_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, screenSpaceUV, 0).r;

                float sceneDepthVS = LinearEyeDepth(sceneRawDepth, _ZBufferParams);

                float3 decalSpaceScenePos = i.cameraPosOS + i.viewPosOS.xyz * sceneDepthVS;

                float2 decalSpaceUV = decalSpaceScenePos.xy + 0.5;

                clip(0.5 - abs(decalSpaceScenePos));

                float2 uv = decalSpaceUV.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                half4 mainColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);


                //>> ������ �ʿ��ϸ� ������ �߰�

                return mainColor;
            }
            ENDHLSL
        }
    }
}
