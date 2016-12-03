texture2D lumTexture : RENDERCOLORTARGET <
	float2 ViewportRatio = {1.0, 1.0};
	int MipLevel = 1;
	string Format = "R16F";
>;
sampler2D lumSamp = sampler_state {
    texture = <lumTexture>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

#define halfPixel 32
#define quaterPixel 16
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
    MipFilter = POINT;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};
texture2D lumHalfDepth : RENDERDEPTHSTENCILTARGET <
	int Width = halfPixel;
	int Height = halfPixel;
    string Format = "D24S8";
>;


texture2D lumQuaterTexture : RENDERCOLORTARGET <
	int Width = quaterPixel;
	int Height = quaterPixel;
	int MipLevel = 1;
	string Format = "R16F";
>;
sampler2D lumQuaterSamp = sampler_state {
    texture = <lumQuaterTexture>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = POINT;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};
texture2D lumQuaterDepth : RENDERDEPTHSTENCILTARGET <
	int Width = quaterPixel;
	int Height = quaterPixel;
    string Format = "D24S8";
>;


texture2D lum4x4Texture : RENDERCOLORTARGET <
	int Width = 4;
	int Height = 4;
	int MipLevel = 1;
	string Format = "R16F";
>;
sampler2D lum4x4Samp = sampler_state {
    texture = <lum4x4Texture>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};
texture2D lum4x4Depth : RENDERDEPTHSTENCILTARGET <
	int Width = 4;
	int Height = 4;
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
	float2 Offset = 0.25;
	const float step = 0.4;
	float4 lumS = float4(
	tex2Dlod(lum4x4Samp,float4(Offset,0,1)).x,
	tex2Dlod(lum4x4Samp,float4(Offset+float2(0,step),0,1)).x,
	tex2Dlod(lum4x4Samp,float4(Offset+float2(step,0),0,1)).x,
	tex2Dlod(lum4x4Samp,float4(Offset+float2(step,step),0,1)).x
	);
	
	float maxLum = lumS.x;
	maxLum = max(maxLum,lumS.y);
	maxLum = max(maxLum,lumS.z);
	maxLum = max(maxLum,lumS.w);
	float avgLum = (lumS.x + lumS.y + lumS.z + lumS.w)/4;
	
	float lum = 0.4*maxLum + 0.6*avgLum;
	lum = exp(maxLum);
	lum = CalcAdaptedLum(adaptedLum[0][0].r,lum);
	return float4(lum.xxx,1);
}

#undef halfPixel
#undef quaterPixel

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
	float4 blurredDiffuse = tex2D(diffuseSamp,Tex);
	float3 specular = tex2D(specularSamp,Tex).xyz;
	
	float3 fog = tex2D(FogWorkBuffSampler,Tex).x * LightAmbient * float3(0.7,0.72,0.79);
	float3 lightNormal = normalize(-LightDirection);
	float4 LightPosition = float4(lightNormal * LightDistance,1);
	float4 lightPosProj = mul(LightPosition,ViewProjectMatrix);
	if(blurredDiffuse.a > Epsilon)
		fog *= saturate(dot(CameraDirection,normalize(lightPosProj.xyz)));
	
	#if SSDO_COLOR_BLEEDING > 0
	float3 GI = tex2D(AOWorkMapSampler,Tex).xyz;
	float3 ocolor = (blurredDiffuse.xyz + specular)*(1+SSDO_COLOR_BLEEDING*GI) + fog;
	#else
	float3 ocolor = blurredDiffuse.xyz + specular + fog;
	#endif
	
	const float3 BLUE_SHIFT = float3(0.4f, 0.4f, 0.7f);
	float adapted_lum = adaptedLum[0][0].r;

	float lum = dot(ocolor, RGB2LUM);
	float3 color = lerp(lum * BLUE_SHIFT, ocolor, saturate(16.0f * lum));
	
	float adapted_lum_dest = 2. / (max(0.1f, 1 + 10 * EyeAdaption(adapted_lum)));
	
	color = AF(color * adapted_lum_dest);
	
	float3 outColor = HDRSTRENGTH*color+(1-HDRSTRENGTH)*ocolor;
	
	return float4(outColor,1);
}

float4 DownScale_PS(float2 Tex: TEXCOORD0 ,uniform sampler2D Samp) : COLOR
{
	return tex2Dlod(Samp,float4(Tex,0,1));
}