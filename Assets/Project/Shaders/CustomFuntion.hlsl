float Maximum(float Value1, float Value2)
{
    return Value1 > Value2 ? Value1 : Value2;
}


float4 Maximum(float Value1, float4 Value2)
{
    float4 r;
    r.x = Value1 > Value2.x ? Value1 : Value2.x;
    r.y = Value1 > Value2.y ? Value1 : Value2.y;
    r.z = Value1 > Value2.z ? Value1 : Value2.z;
    return r;
}

float4 Maximum(float4 Value1, float4 Value2)
{
    float4 r;
    r.x = Value1.x > Value2.x ? Value1.x : Value2.x;
    r.y = Value1.y > Value2.y ? Value1.y : Value2.y;
    r.z = Value1.z > Value2.z ? Value1.z : Value2.z;
    r.w = Value1.w > Value2.w ? Value1.w : Value2.w;
    return r;
}

float3 Maximum(float3 Value1, float3 Value2)
{
    float3 r;
    r.x = Value1.x > Value2.x ? Value1.x : Value2.x;
    r.y = Value1.y > Value2.y ? Value1.y : Value2.y;
    r.z = Value1.z > Value2.z ? Value1.z : Value2.z;
    return r;
}

float Minimum(float Value1, float Value2)
{
    return Value1 < Value2 ? Value1 : Value2;
}

float4 Minimum(float4 Value1, float4 Value2)
{
    float4 r;
    r.x = Value1.x < Value2.x ? Value1.x : Value2.x;
    r.y = Value1.y < Value2.y ? Value1.y : Value2.y;
    r.z = Value1.z < Value2.z ? Value1.z : Value2.z;
    r.w = Value1.w < Value2.w ? Value1.w : Value2.w;
    return r;
}

float3 Minimum(float3 Value1, float3 Value2)
{
    float3 r;
    r.x = Value1.x < Value2.x ? Value1.x : Value2.x;
    r.y = Value1.y < Value2.y ? Value1.y : Value2.y;
    r.z = Value1.z < Value2.z ? Value1.z : Value2.z;
    return r;
}

float FresnelEffect(float3 Normal, float3 ViewDir, float Power)
{
    return pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
}

float Remap(float In, float2 InMinMax, float2 OutMinMax)
{
    return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
}