float3 coord2WorldViewPos(float2 texcoord, float depth)
{
	float2 SPos = float2(2.0f*texcoord.x-1.0f, -2.0f*texcoord.y+1.0f);
	float3 VPos = float3(SPos.x * invCotheta * Aspect, SPos.y * invCotheta, 1.0f) * depth;
	return VPos;
}

float3 worldPos2coord(float3 worldpos)
{
	float4 proj = mul(float4(worldpos,0),ViewProjectMatrix);
	proj.xy /= proj.w;
	proj.xy = 0.5 + float2(0.5,-0.5)*proj.xy;
	return proj.xyw;
}

float3 easysrgb2linear(float3 rgb)
{
    return pow(rgb, 2.2f);
}

float3 srgb2linear(float3 rgb)
{
	const float ALPHA = 0.055f;
    return rgb < 0.0404482f ? rgb / 12.92f : pow((rgb + ALPHA) / (1 + ALPHA), 2.4f);
}

float3 linear2srgb(float3 rgb)
{
	const float ALPHA = 0.055f;
	return rgb < 0.0031308f ? 12.92f * rgb : (1 + ALPHA) * pow(rgb, 1 / 2.4f) - ALPHA;
}

float hash12(float2 p)
{
	float3 p3  = frac(float3(p.xyx) * float3(.1031,.11369,.13787));
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.x + p3.y) * p3.z);
}

float3 rgb2hsv(float3 c)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 hsv2rgb(float3 c)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}