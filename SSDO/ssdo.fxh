texture2D AOWorkMap : RENDERCOLORTARGET <
	float2 ViewPortRatio = {1.0, 1.0};
	string Format = "R16F";
>;
sampler AOWorkMapSampler = sampler_state {
    texture = <AOWorkMap>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

const float DepthLength = 10.0;	
static float InvDepthLength6 = 1.0 / pow(DepthLength, 6);
#define	SSAORayCount	31
static float2 SSAORadiusB = (64.0 / 1024.0) / SSAORayCount * float2(1, ViewportSize.x/ViewportSize.y);

inline float GetOccRate(float2 texCoord, float3 WPos, float3 N)
{
	float Depth = tex2D(DepthGbufferSamp,texCoord).x;
	float3 RayPos = mul(coord2WorldViewPos(texCoord,Depth),(float3x3)ViewInverse);

	const float SSAO_BIAS = 0.01;

	float3 v = RayPos - WPos;
	float distance2 = dot(v, v);
	float dotVN = max(dot(v, N) - SSAO_BIAS, 0.0f);
	float f = max(DepthLength * DepthLength - distance2, 0.0f);
	float f3 = f * f * f;
	float ao = f3 * InvDepthLength6 * dotVN / (distance2 + 1e-3);

	return min(ao, 1.0);
}

float hash12(float2 p)
{
	float3 p3  = frac(float3(p.xyx) * float3(.1031,.11369,.13787));
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.x + p3.y) * p3.z);
}

float4 PS_AO( float2 texCoord: TEXCOORD0 ) : COLOR
{
	const float JitterOffsets[29] = {
	0.00013,0.0356718,0.0701546,0.104637,0.13912,
	0.173603,0.208086,0.242568,0.277051,0.311534,
	0.346017,0.380499,0.414982,0.449465,0.483948,
	0.51843,0.552913,0.587396,0.621879,0.6563611,
	0.690844,0.725327,0.75981,0.7942932,0.828775,
	0.863258,0.897741,0.932224,0.966706};
	float Depth = tex2D(DepthGbufferSamp,texCoord).x;
	float3 WPos = mul(coord2WorldViewPos(texCoord,Depth),(float3x3)ViewInverse);
	float3 N = tex2D(NormalGbufferSamp,texCoord).xyz;
	
	//int2 rndTexOffset = int2(texCoord * ViewportSize);
	int index = hash12(texCoord)*30%29;
	float radMul = 1.0 / SSAORayCount * (3.14 * 2.0 * 7.0);
	float radAdd = JitterOffsets[index] * (PI * 2.0);

	// 深度に応じて探索範囲を変えるとモアレが酷い。
	//float2 radiusMul = SSAORadiusA / Depth;
	//float2 radiusMul = SSAORadiusB;
	//float2 radiusMul = (SSAORadiusA / Depth + SSAORadiusB) * 0.5;
	
	float sum = 0.0;
	float4 col = 0;

	// MEMO: unrollするとレジスタを使い過ぎてコンパイルが通らない
	[unroll]
	for(int j = 0; j < SSAORayCount; j++)
	{
		float2 sc;
		sincos(j * radMul + radAdd, sc.x, sc.y);
		float2 r = j * SSAORadiusB;
		float2 uv = sc * r + texCoord;

		float ao = GetOccRate(uv, WPos, N);
		sum += ao;
	}

	// 元のSAOのソースでは、ddx/ddyでクアッド単位の
	// 補正を行っていた。

	float s = saturate(1.0 - sum * (1.0 / SSAORayCount));
	return float4(s.xxx,1);
}
#undef	SSAORayCount