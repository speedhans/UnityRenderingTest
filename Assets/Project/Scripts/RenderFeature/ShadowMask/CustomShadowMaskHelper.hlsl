

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"


RWTexture2D<float4> _ShadowMaskTexture;
float2 _ShadowMaskTextureSize;

float LinearEyeDepth_(float In)
{
    return 1.0 / (_ZBufferParams.z * In + _ZBufferParams.w);
}

real SampleShadowmap_(TEXTURE2D_SHADOW_PARAM(ShadowMap, sampler_ShadowMap), float4 shadowCoord, half4 shadowParams)
{
    real attenuation;
    real shadowStrength = shadowParams.x;

    attenuation = real(SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, shadowCoord.xyz));

    return BEYOND_SHADOW_FAR(shadowCoord) ? 1.0 : attenuation;
}


half ComputeCascadeIndex_(float3 positionWS)
{
    float3 fromCenter0 = positionWS - _CascadeShadowSplitSpheres0.xyz;
    float3 fromCenter1 = positionWS - _CascadeShadowSplitSpheres1.xyz;
    float3 fromCenter2 = positionWS - _CascadeShadowSplitSpheres2.xyz;
    float3 fromCenter3 = positionWS - _CascadeShadowSplitSpheres3.xyz;
    float4 distances2 = float4(dot(fromCenter0, fromCenter0), dot(fromCenter1, fromCenter1), dot(fromCenter2, fromCenter2), dot(fromCenter3, fromCenter3));

    half4 weights = half4(distances2 < _CascadeShadowSplitSphereRadii);
    weights.yzw = saturate(weights.yzw - weights.xyz);

    return 4 - dot(weights, half4(4, 3, 2, 1));
}

float4 TransformWorldToShadowCoord_(float3 positionWS)
{
    half cascadeIndex = ComputeCascadeIndex_(positionWS);

    float4 shadowCoord = mul(_MainLightWorldToShadow[cascadeIndex], float4(positionWS, 1.0));

    return float4(shadowCoord.xyz, 0);
}

float3 GetWorldPosition(half2 uv)
{
    float depth = SAMPLE_TEXTURE2D_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, uv, 0).r;
    return ComputeWorldSpacePosition(uv, depth, UNITY_MATRIX_I_VP);
}

half SampleShadowAttenuation(half2 uv)
{
    float3 posWS = GetWorldPosition(uv);
    float4 coords = TransformWorldToShadowCoord_(posWS);

#if defined(_MAIN_LIGHT_SHADOWS_SCREEN) && !defined(_SURFACE_TYPE_TRANSPARENT)
    return half(SAMPLE_TEXTURE2D_LOD(_ScreenSpaceShadowmapTexture, sampler_ScreenSpaceShadowmapTexture, coords.xy, 0).x);
#else
    ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
    half4 shadowParams = GetMainLightShadowParams();
    return 1 - SampleShadowmap_(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), coords, shadowParams);
#endif
}


