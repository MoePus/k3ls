static float invCotheta = 1/ProjectionMatrix._22;
static float Aspect = ViewportSize.x/ViewportSize.y;
#define RGB2LUM float3(0.2125, 0.7154, 0.0721)
#define PI  3.14159265359f
#define invPi 0.31830988618

float3 coord2WorldViewPos(float2 texcoord, float depth)
{
	float2 SPos = float2(2.0f*texcoord.x-1.0f, -2.0f*texcoord.y+1.0f);
	float3 VPos =  float3(SPos.x * invCotheta * Aspect, SPos.y * invCotheta, 1.0f) * depth;
	return VPos;
}

float3 NormalDecode(float3 N)
{
	return N * 2 - 1;
}

float3 srgb2linear(float3 rgb)
{
	const float ALPHA = 0.055f;
    return rgb < 0.0404482f ? rgb / 12.92f : pow((rgb + ALPHA) / (1 + ALPHA), 2.4f);
}

float3 linear_to_srgb(float3 rgb)
{
	const float ALPHA = 0.055f;
	return rgb < 0.0031308f ? 12.92f * rgb : (1 + ALPHA) * pow(rgb, 1 / 2.4f) - ALPHA;
}