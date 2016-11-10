texture2D lumTexture : RENDERCOLORTARGET <
	float2 ViewportRatio = {1.0, 1.0};
	string Format = "R16F";
>;
sampler2D lumSamp = sampler_state {
    texture = <lumTexture>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

#define halfPixel 32
texture2D lumHalfTexture : RENDERCOLORTARGET <
	int Width = halfPixel;
	int Height = halfPixel;
	int MipLevel = 1;
	string Format = "R16F";
>;
sampler2D lumHalfSamp = sampler_state {
    texture = <lumHalfTexture>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};
texture2D lumHalfDepth : RENDERDEPTHSTENCILTARGET <
	int Width = halfPixel;
	int Height = halfPixel;
    string Format = "D24S8";
>;

texture2D adapted_lum: RENDERCOLORTARGET <//K3LS_GBuffer_04_roughness&reflectance&effect&posw
    int Width = 1;
	int Height = 1;
	float4 ClearColor = { 0, 0, 0, 0 };
	string Format = "D3DFMT_R32F";
>;

texture2D adapted_lum_Depth : RENDERDEPTHSTENCILTARGET <
    int Width = 1;
	int Height = 1;
    string Format = "D24S8";
>;

float4 adaptedLum[1][1] : TEXTUREVALUE <
    string TextureName = "adapted_lum";
>;


float elapsed_time : ELAPSEDTIME;

float CalcAdaptedLum(float adapted_lum, float current_lum)
{
	return adapted_lum + (current_lum - adapted_lum) * (1 - pow(0.98f, 60 * elapsed_time));
}

float4 LUM_PS(float2 Tex: TEXCOORD0) : COLOR
{
	const float step = 2.0 / halfPixel;
	float lum = tex2Dlod(lumHalfSamp,float4(ViewportOffset,0,1)).x;
	lum += tex2Dlod(lumHalfSamp,float4(ViewportOffset+float2(step,step),0,1)).x;
	lum += tex2Dlod(lumHalfSamp,float4(ViewportOffset+float2(step,step)*2,0,1)).x;
	lum += tex2Dlod(lumHalfSamp,float4(ViewportOffset+float2(step,step)*3,0,1)).x;
	lum += tex2Dlod(lumHalfSamp,float4(ViewportOffset+float2(step,step)*4,0,1)).x;
	lum += tex2Dlod(lumHalfSamp,float4(ViewportOffset+float2(step*3,step),0,1)).x;
	lum += tex2Dlod(lumHalfSamp,float4(ViewportOffset+float2(step,step*3),0,1)).x;
	lum/=4;
	lum = exp(lum);
	lum = CalcAdaptedLum(adaptedLum[0][0].r,lum);
	return float4(lum.xxx,1);
}

#undef halfPixel

float EyeAdaption(float lum)
{
	return lerp(0.04f, 0.302f, lum);
}

inline float3 AF(float3 x)
{
	const float A = 2.62;//2.51f;
	const float B = 0.03f;
	const float C = 2.31;//2.43f;
	const float D = 0.59f;
	const float E = 0.16;//0.14f;
	return (x * (A * x + B)) / (x * (C * x + D) + E);
}

float4 ToneMapping_PS(float2 Tex: TEXCOORD0) : COLOR
{
	float3 blurredDiffuse = tex2D(diffuseSamp,Tex);
	float3 specular = tex2D(specularSamp,Tex);
	float3 ocolor = blurredDiffuse+specular;
	
	const float3 BLUE_SHIFT = float3(0.4f, 0.4f, 0.7f);
	float adapted_lum = adaptedLum[0][0].r;

	float lum = dot(ocolor, RGB2LUM);
	float3 color = lerp(lum * BLUE_SHIFT, ocolor, saturate(16.0f * lum));
	
	float adapted_lum_dest = 2. / (max(0.1f, 1 + 10 * EyeAdaption(adapted_lum)));
	
	color = AF(color * adapted_lum_dest);
	
	float3 outColor = HDRSTRENGTH*color+(1-HDRSTRENGTH)*ocolor;
	
	return float4(linear_to_srgb(outColor),1);
}
