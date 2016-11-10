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

float4 PS_AO( float2 texCoord: TEXCOORD0 ) : COLOR
{
	const float JitterOffsets[16] = {
	 6/16.0, 1/16.0,12/16.0,11/16.0,
	 9/16.0,14/16.0, 5/16.0, 2/16.0,
	 0/16.0, 7/16.0,10/16.0,13/16.0,
	15/16.0, 8/16.0, 3/16.0, 4/16.0,
	};
	float Depth = tex2D(DepthGbufferSamp,texCoord).x;
	float3 WPos = mul(coord2WorldViewPos(texCoord,Depth),(float3x3)ViewInverse);
	float3 N = tex2D(NormalGbufferSamp,texCoord).xyz;
	
	int2 rndTexOffset = int2(texCoord * ViewportSize);
	int index = (rndTexOffset.x % 4) * 4 + (rndTexOffset.y % 4);

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