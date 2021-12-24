
//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

float rand(float _Seed1, float _Seed2)
{
	return frac(sin(dot(float2(_Seed1, _Seed2), float2(12.9898, 78.233))) * 43758.5453) * 1;
}

float3 CalulatePosition(float3 _Position)
{
	float d = dot(float3(0.33f, 0.33f, _Position.x % 20), _Position);
	return _Position + float3(sin(d), 0.0f, cos(d));
	//float d = dot(float3(_Position.x, -0.87f, -1), float3(_Position.z, 0.81f, 0.57f));
	//return float3(_Position.x + cos(_Position.z + d) * 0.2f, 0, _Position.z + atan(_Position.x) * 0.52f);
}