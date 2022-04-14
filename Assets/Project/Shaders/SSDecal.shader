Shader "Custom/SSDecal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalTex("NormalTex", 2D) = "white" {}
        _Normal("Normal", vector) = (0,0,0,0)
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

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" // URP �ھ� �ڵ�
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl" // URP �ھ� �ڵ�
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct verdata
            {
                float4 vertex   : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 screenPos    : TEXCOORD0;
                float4 viewPosOS    : TEXCOORD1;
                float3 cameraPosOS  : TEXCOORD2;
                float3 normal : TEXCOORD3;
                float4 tangent : TEXCOORD4;
                float3 positionWS : TEXCOORD5;
                float4 positionCS   : SV_POSITION;
            };

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalTex); SAMPLER(sampler_NormalTex);
            CBUFFER_START(UnityPerMaterial)
            half4 _MainTex_ST;
            half4 _NormalTex_ST;
            half4 _Normal;
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

                o.normal = TransformObjectToWorldNormal(_Normal);
                o.tangent = v.tangent;
                o.positionWS = vertexPositionInput.positionWS;

                return o;
            }

            float3x3 cotangent_frame(float3 normal, float3 position, float2 uv)
            {
                // get edge vectors of the pixel triangle
                float3 dp1 = ddx(position);
                float3 dp2 = ddy(position) * _ProjectionParams.x;
                float2 duv1 = ddx(uv);
                float2 duv2 = ddy(uv) * _ProjectionParams.x;
                // solve the linear system
                float3 dp2perp = cross(dp2, normal);
                float3 dp1perp = cross(normal, dp1);
                float3 T = dp2perp * duv1.x + dp1perp * duv2.x;
                float3 B = dp2perp * duv1.y + dp1perp * duv2.y;
                // construct a scale-invariant frame
                float invmax = rsqrt(max(dot(T, T), dot(B, B)));
                // matrix is transposed, use mul(VECTOR, MATRIX) order
                return float3x3(T * invmax, B * invmax, normal);
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

                float3 sn = i.normal;//_Normal.xyz;
                float3 decalNormal = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, uv));

                float3x3 decalTangentToWorld = cotangent_frame(sn, decalSpaceScenePos, uv);

                float3 worldNormal = normalize(mul(decalNormal, decalTangentToWorld));

                Light light = GetMainLight();
                float d = dot(light.direction, worldNormal);

                return half4(d,d,d, 1);
            }
            ENDHLSL
        }
    }
}
