/////////////////////////////////////////
///////Got this From ikPolishShader//////
/////////////////////////////////////////
float4 Antialias_PS( float2 Tex: TEXCOORD0) : COLOR
{
	float4 center = tex2D(MRTSamp, Tex);

	// 深度の差が大きいところ
	// Where depth gets lots of difference
	float DC = tex2D( DepthGbufferSamp, Tex).x;
	float DL = tex2D( DepthGbufferSamp, Tex + float2(-1, 0) * ViewportOffset2).x;
	float DR = tex2D( DepthGbufferSamp, Tex + float2( 1, 0) * ViewportOffset2).x;
	float DU = tex2D( DepthGbufferSamp, Tex + float2( 0,-1) * ViewportOffset2).x;
	float DD = tex2D( DepthGbufferSamp, Tex + float2( 0, 1) * ViewportOffset2).x;
	float4 grad = abs(DC - float4(DL,DR,DU,DD)) * 10.0 / DC;

	// 色の差が大きいところ
	// Where color gets lots of difference
	float lumaC =dot(RGB2LUM,center.rgb);
	float3 rgbL = tex2D( MRTSamp, Tex + float2(-1, 0) * ViewportOffset2).rgb;
	float3 rgbR = tex2D( MRTSamp, Tex + float2( 1, 0) * ViewportOffset2).rgb;
	float3 rgbU = tex2D( MRTSamp, Tex + float2( 0,-1) * ViewportOffset2).rgb;
	float3 rgbD = tex2D( MRTSamp, Tex + float2( 0, 1) * ViewportOffset2).rgb;
	float lumaL = dot(RGB2LUM,rgbL);
	float lumaR = dot(RGB2LUM,rgbR);
	float lumaU = dot(RGB2LUM,rgbU);
	float lumaD = dot(RGB2LUM,rgbD);
	float4 gradCol = abs(lumaC - float4(lumaL,lumaR,lumaU,lumaD));

	// 勾配を求める
	// Mix the difference
	grad = max(length(grad), length(gradCol));
	float w = saturate(dot(grad, 1.4));

	float4 rcpGrad = 1.0 / clamp(grad, 1.0, 4.0);

	float gradX = clamp(grad.x - grad.y, -1, 1);
	float gradY = clamp(grad.z - grad.w, -1, 1);
	float2 vl = float2(-1, gradY) * rcpGrad.x;
	float2 vr = float2( 1, gradY) * rcpGrad.y;
	float2 vu = float2(gradX, -1) * rcpGrad.z;
	float2 vd = float2(gradX,  1) * rcpGrad.w;

	float3 cl = tex2D(MRTSamp, Tex + vl * ViewportOffset2).rgb;
	float3 cr = tex2D(MRTSamp, Tex + vr * ViewportOffset2).rgb;
	float3 cu = tex2D(MRTSamp, Tex + vu * ViewportOffset2).rgb;
	float3 cd = tex2D(MRTSamp, Tex + vd * ViewportOffset2).rgb;
	float3 col = (center.rgb + cl + cr + cu + cd) * (1.0 / 5.0);

	return float4(lerp(center.rgb, col, w), 1);
}
