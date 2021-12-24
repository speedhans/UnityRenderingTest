
#include "GrassPositionCal.hlsl"

float3 CalulateRightWeight(float3 _RightVector, float _PosX, float _PosZ)
{
	return _RightVector * smoothstep(-4.0f, 4.0f, sin(_PosX * 85.4f + _PosZ * 142.7f));
}

inline float3 CalulateEdgePosition(float _VertexY, float _PosX, float _PosZ, float _Offset, float _HeightFactor, float3 _SourceVector, float _GrassHeight)
{
	float3 v = _VertexY * float3(0, 1, 0) * _Offset;
	float d = dot(v, float3(1, 1, -1));
	return v * d * (_HeightFactor * 5) * _GrassHeight;
	//return clamp(_VertexY * (float3(0, 1, 0) * _Offset + CalulateRightWeight(_SourceVector, _PosX, _PosZ) * _Offset), 0, 1.0f) * (_HeightFactor * 5 ) * _GrassHeight;
}

float CalulateHeightOffset(float _PosX, float _PosZ)
{
	return 0.7f + cos(tan(_PosX * _PosZ)) * 0.3f;
}

inline float CalHeight(float _HeightFactor)
{
	return (_HeightFactor * 5);
}

half3 CalulateCollisionWeight(float3 _Position, int _CollisionCount, float4 _Buffer[8], float _Pow)
{
	half3 weight;
	// Collision Weight Cal
	for (int i = 0; i < _CollisionCount; ++i)
	{
		float3 dir = _Position - _Buffer[i].xyz;
		float leng = length(dir);
		float str = 1 - saturate(leng * 2.0f); //1 - saturate(log(1 + leng));
		weight += normalize(dir) * str * _Pow;
	}
	//weight.y = (abs(weight.y) * -1);
	weight *= 0.5f;
	return weight;
}