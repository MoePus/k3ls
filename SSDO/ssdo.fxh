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
#define	SSAORayCount	24
static float2 SSAORadiusB = (64.0 / 1024.0) / SSAORayCount * float2(1, ViewportSize.x/ViewportSize.y);

inline float GetOccRate(float2 Tex, float3 WPos, float3 N)
{
	float Depth = tex2D(sumDepthSamp,Tex).x;
	float3 RayPos = mul(coord2WorldViewPos(Tex,Depth),(float3x3)ViewInverse);
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

float4 PS_AO( float2 Tex: TEXCOORD0 ) : COLOR
{
	float Depth = tex2D(sumDepthSamp,Tex).x;
	float Depth2 = tex2D(Depth_ALPHA_FRONT_GbufferSamp,Tex).x;
	float3 N = float3(tex2D(NormalGbufferSamp,Tex).xy,tex2D(SpaGbufferSamp,Tex).y);
	float3 N2 = float3(tex2D(Normal_ALPHA_FRONT_GbufferSamp,Tex).xy,tex2D(Spa_ALPHA_FRONT_GbufferSamp,Tex).y);
	if(length(N2)>0.6  && Depth2<=Depth)
	{
		N = N2;
	}
	float3 WPos = mul(coord2WorldViewPos(Tex,Depth),(float3x3)ViewInverse);

	float radMul = 1.0 / SSAORayCount * (3.14 * 2.0 * 7.0);
	float radAdd = hash12(Tex*Depth*ftime) * (PI * 2.0);

	float sum = 0.0;
	float4 col = 0;

	// MEMO: unrollするとレジスタを使い過ぎてコンパイルが通らない
	[unroll]
	for(int j = 0; j < SSAORayCount; j++)
	{
		float2 sc;
		sincos(j * radMul + radAdd, sc.x, sc.y);
		float2 r = j * SSAORadiusB;
		float2 uv = sc * r + Tex;

		float ao = GetOccRate(uv, WPos, N);
		sum += ao;
	}

	// 元のSAOのソースでは、ddx/ddyでクアッド単位の
	// 補正を行っていた。

	float s = saturate(1.0 - sum * (1.0 / SSAORayCount));
	return float4(s.xxx,1);
}
#undef	SSAORayCount