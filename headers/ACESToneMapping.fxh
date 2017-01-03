float3 ColorTemperatureToRGB(float temperatureInKelvins)
{
	if (temperatureInKelvins<=1000.0+Epsilon)
		return float3(1,1,1);
		
	//http://www.tannerhelland.com/4435/convert-temperature-rgb-algorithm-code/
	
	float3 retColor;
	
    temperatureInKelvins = clamp(temperatureInKelvins, 1000.0, 40000.0) / 100.0;
    
    if (temperatureInKelvins <= 66.0)
    {
        retColor.r = 1.0;
        retColor.g = saturate(0.39008157876901960784 * log(temperatureInKelvins) - 0.63184144378862745098);
    }
    else
    {
    	float t = temperatureInKelvins - 60.0;
        retColor.r = saturate(1.29293618606274509804 * pow(t, -0.1332047592));
        retColor.g = saturate(1.12989086089529411765 * pow(t, -0.0755148492));
    }
    
    if (temperatureInKelvins >= 66.0)
        retColor.b = 1.0;
    else if(temperatureInKelvins <= 19.0)
        retColor.b = 0.0;
    else
        retColor.b = saturate(0.54320678911019607843 * log(temperatureInKelvins - 10.0) - 1.19625408914);

    return retColor;
}

static float3 temperatureColor = ColorTemperatureToRGB(colorTemperature*10000.0 + 1000.0);

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


texture2D adapted_lum: RENDERCOLORTARGET <
    int Width = 1;
	int Height = 1;
	float4 ClearColor = { 0, 0, 0, 0 };
	string Format = "D3DFMT_R32F";
>;
texture2D baked_adapted_lum: RENDERCOLORTARGET <
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
sampler adaptedLumSamp = sampler_state {
    texture = <adapted_lum>;
    MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
    AddressU  = CLAMP;
	AddressV  = CLAMP;
};
sampler bakedAdaptedLumSamp = sampler_state {
    texture = <baked_adapted_lum>;
    MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
    AddressU  = CLAMP;
	AddressV  = CLAMP;
};
/*
float4 adaptedLum[1][1] : TEXTUREVALUE <
    string TextureName = "adapted_lum";
>;
*///note:TEXTUREVALUE slows down the shader.said ik.

float4 CopyAL_PS(float2 Tex: TEXCOORD0) : COLOR
{
	return tex2Dlod(adaptedLumSamp, float4(0.5,0.5,0,0));
}


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
	lum = CalcAdaptedLum(tex2Dlod(bakedAdaptedLumSamp, float4(0.5,0.5,0,0)).r,lum);
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
	float3 ocolor = tex2D(Blur4WorkBuff1Sampler,Tex).xyz;
	float3 bloom = tex2D(Blur4WorkBuff0Sampler,Tex).xyz;
	ocolor += bloom;
	
	const float3 BLUE_SHIFT = float3(0.4f, 0.4f, 0.7f);
	float adapted_lum = tex2Dlod(adaptedLumSamp, float4(0.5,0.5,0,0)).r;

	ocolor *= temperatureColor;
	float lum = dot(ocolor, RGB2LUM);
	float3 color = lerp(lum * BLUE_SHIFT, ocolor, saturate(16.0f * lum));
	
	float adapted_lum_dest = 2. / (max(0.1f, 1 + 10 * EyeAdaption(adapted_lum)));
	
	color = AF(color * adapted_lum_dest);
	
	return float4(color,1);
}

float4 DownScale_PS(float2 Tex: TEXCOORD0 ,uniform sampler2D Samp) : COLOR
{
	return tex2Dlod(Samp,float4(Tex,0,1));
}

#define DownSacleLumAdapt \
		"RenderColorTarget0=lumHalfTexture;" \
		"RenderDepthStencilTarget=lumHalfDepth;" \
		"ClearSetDepth=ClearDepth;Clear=Depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
    	"Pass=DOHALFLUM;" \
		 \
		"RenderColorTarget0=lumQuaterTexture;" \
		"RenderDepthStencilTarget=lumQuaterDepth;" \
		"ClearSetDepth=ClearDepth;Clear=Depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
    	"Pass=DOQuaterLUM;" \
		 \
		"RenderColorTarget0=lum4x4Texture;" \
		"RenderDepthStencilTarget=lum4x4Depth;" \
		"ClearSetDepth=ClearDepth;Clear=Depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
    	"Pass=DO4x4LUM;" \
		 \
		"RenderColorTarget0=baked_adapted_lum;" \
    	"RenderDepthStencilTarget=adapted_lum_Depth;" \
		"ClearSetDepth=ClearDepth;Clear=Depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
    	"Pass=copyAL;" \
		 \
		"RenderColorTarget0=adapted_lum;" \
    	"RenderDepthStencilTarget=adapted_lum_Depth;" \
		"ClearSetDepth=ClearDepth;Clear=Depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
    	"Pass=calcAL;"
		

#define AdaptLumPass \
	pass DOHALFLUM < string Script= "Draw=Buffer;"; >  \
	{	\
		AlphaBlendEnable = FALSE;  \
		ZFUNC=ALWAYS;  \
		ALPHAFUNC=ALWAYS;  \
		VertexShader = compile vs_3_0 POST_VS();  \
		PixelShader  = compile ps_3_0 DownScale_PS(lumSamp);  \
	}  \
	pass DOQuaterLUM < string Script= "Draw=Buffer;"; >   \
	{	\
		AlphaBlendEnable = FALSE;  \
		ZFUNC=ALWAYS;  \
		ALPHAFUNC=ALWAYS;  \
		VertexShader = compile vs_3_0 POST_VS();  \
		PixelShader  = compile ps_3_0 DownScale_PS(lumHalfSamp);  \
	}  \
	pass DO4x4LUM < string Script= "Draw=Buffer;"; >   \
	{	  \
		AlphaBlendEnable = FALSE;  \
		ZFUNC=ALWAYS;  \
		ALPHAFUNC=ALWAYS;  \
		VertexShader = compile vs_3_0 POST_VS();  \
		PixelShader  = compile ps_3_0 DownScale_PS(lumQuaterSamp);  \
	}  \
	pass copyAL < string Script= "Draw=Buffer;"; >   \
	{  \
		AlphaBlendEnable = FALSE;  \
		ZFUNC=ALWAYS;  \
		ALPHAFUNC=ALWAYS;  \
        VertexShader = compile vs_3_0 POST_VS();  \
		PixelShader  = compile ps_3_0 CopyAL_PS();  \
    }  \
	pass calcAL < string Script= "Draw=Buffer;"; >   \
	{  \
		AlphaBlendEnable = FALSE;  \
		ZFUNC=ALWAYS;  \
		ALPHAFUNC=ALWAYS;  \
        VertexShader = compile vs_3_0 POST_VS();  \
		PixelShader  = compile ps_3_0 LUM_PS();  \
    }