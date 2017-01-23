
texture QuterBloomTexture : RENDERCOLORTARGET <
    float2 ViewportRatio = {0.5, 0.5};
    string Format = YOR16F;
>;
sampler QuterBloomSamp = sampler_state {
    texture = <QuterBloomTexture>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = POINT;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};
texture2D QuterBloomDepth : RENDERDEPTHSTENCILTARGET <
	float2 ViewportRatio = {0.5, 0.5};
    string Format = "D24S8";
>;

float4 HLDownSamp4X_PS(float2 Tex: TEXCOORD0, uniform sampler samp) : COLOR0
{
	float4 color = tex2Dlod(samp, float4(Tex, 0, 0));
	color += tex2Dlod(samp, float4(Tex + float2(ViewportOffset2.x,0), 0, 0));
	color += tex2Dlod(samp, float4(Tex + float2(0,ViewportOffset2.y), 0, 0));
	color += tex2Dlod(samp, float4(Tex + ViewportOffset2, 0, 0));
	
	return color/4;
}

float4 BloomDownSamp2X_PS(float2 Tex: TEXCOORD0, uniform sampler samp) : COLOR0
{
	Tex += ViewportOffset2*2;
	float4 color = tex2Dlod(samp, float4(Tex, 0, 0));
	return color;
}
	
#define DownSampHL4X1st \
		"RenderColorTarget0=QuterBloomTexture;" \
		"RenderDepthStencilTarget=QuterBloomDepth;" \
		"ClearSetDepth=ClearDepth;Clear=Depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
    	"Pass=DOQuaterHL1st;"
		
#define DownSampHL4X1stPass \
	pass DOQuaterHL1st < string Script= "Draw=Buffer;"; >   \
	{	\
		AlphaBlendEnable = FALSE;  \
		ZFUNC=ALWAYS;  \
		ALPHAFUNC=ALWAYS;  \
		VertexShader = compile vs_3_0 POST_VS();  \
		PixelShader  = compile ps_3_0 HLDownSamp4X_PS(Blur4WorkBuff0Sampler);  \
	}
		
#define DownSampBloom4X1st \
		"RenderColorTarget0=BloomTexture2nd;" \
    	"Pass=DOHalfBloom1st;"
		
#define DownSampBloom4X1stPass \
	pass DOHalfBloom1st < string Script= "Draw=Buffer;"; >   \
	{	\
		AlphaBlendEnable = FALSE;  \
		ZFUNC=ALWAYS;  \
		ALPHAFUNC=ALWAYS;  \
		VertexShader = compile vs_3_0 POST_VS();  \
		PixelShader  = compile ps_3_0 BloomDownSamp2X_PS(QuterBloomSamp);  \
	}
	
#define DownSampBloom4X2nd \
		"RenderColorTarget0=BloomTexture3rd;" \
    	"Pass=DOHalfBloom2nd;"
		
#define DownSampBloom4X2ndPass \
	pass DOHalfBloom2nd < string Script= "Draw=Buffer;"; >   \
	{	\
		AlphaBlendEnable = FALSE;  \
		ZFUNC=ALWAYS;  \
		ALPHAFUNC=ALWAYS;  \
		VertexShader = compile vs_3_0 POST_VS();  \
		PixelShader  = compile ps_3_0 BloomDownSamp2X_PS(BloomTexture2ndSamp);  \
	}
	
static const float2 bloomOffset = ViewportOffset2*0.4;
static const float2 bloomOffset2 = bloomOffset * 1.5;
static const float2 bloomOffset3 = bloomOffset * 16;
static const float2 bloomOffset4 = bloomOffset * 34;

texture BloomTexture1st2Y : RENDERCOLORTARGET <
    float2 ViewportRatio = {0.5, 0.5};
    string Format = YOR16F;
>;
sampler BloomTexture1st2YSamp = sampler_state {
    texture = <BloomTexture1st2Y>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = POINT;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

texture BloomTexture1st : RENDERCOLORTARGET <
    float2 ViewportRatio = {0.5, 0.5};
    string Format = YOR16F;
>;
sampler BloomTexture1stSamp = sampler_state {
    texture = <BloomTexture1st>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = POINT;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

texture BloomTexture2nd2Y : RENDERCOLORTARGET <
    float2 ViewportRatio = {0.25, 0.25};
    string Format = YOR16F;
>;
sampler BloomTexture2nd2YSamp = sampler_state {
    texture = <BloomTexture2nd2Y>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = POINT;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

texture BloomTexture2nd : RENDERCOLORTARGET <
    float2 ViewportRatio = {0.25, 0.25};
    string Format = YOR16F;
>;
sampler BloomTexture2ndSamp = sampler_state {
    texture = <BloomTexture2nd>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = POINT;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

texture BloomTexture3rd2Y : RENDERCOLORTARGET <
    float2 ViewportRatio = {0.25, 0.25};
    string Format = YOR16F;
>;
sampler BloomTexture3rd2YSamp = sampler_state {
    texture = <BloomTexture3rd2Y>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = POINT;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

texture BloomTexture3rd : RENDERCOLORTARGET <
    float2 ViewportRatio = {0.25, 0.25};
    string Format = YOR16F;
>;
sampler BloomTexture3rdSamp = sampler_state {
    texture = <BloomTexture3rd>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = POINT;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

texture BloomTexture4th : RENDERCOLORTARGET <
    float2 ViewportRatio = {0.25, 0.25};
    string Format = YOR16F;
>;
sampler BloomTexture4thSamp = sampler_state {
    texture = <BloomTexture4th>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = POINT;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

float4 HDRBloomGaussianPS(float2 Tex: TEXCOORD0, uniform sampler samp, uniform float2 offset) : COLOR0
{
	/*float3 sum = 0;
	float n = 0;
	float3 ocolor = 0;
	[unroll] //ループ展開
	#define AL_SAMP_NUM 14
	offset = offset/AL_SAMP_NUM*4;
    for(int i = -AL_SAMP_NUM; i <= AL_SAMP_NUM; i++){
        float e = exp(-pow((float)i / (AL_SAMP_NUM / 2.0), 2) / 2); //正規分布
        float2 stex = Tex + (offset * (float)i);
        float3 scolor = tex2D(samp, stex).rgb;
        sum += scolor * e;
        n += e;
    }
	ocolor = sum/n;*/
	//https://github.com/CRYTEK-CRYENGINE/CRYENGINE/blob/main/Engine/Shaders/HWScripts/CryFX/HDRPostProcess.cfx
	const float weights[15] = { 153, 816, 3060, 8568, 18564, 31824, 43758, 48620, 43758, 31824, 18564, 8568, 3060, 816, 153 };
	const float weightSum = 262106.0;

	float2 coords = Tex - offset * 7.0;
	float3 ocolor = 0;
	[unroll]
	for (int i = 0; i < 15; ++i)
	{
		ocolor += tex2D(samp, coords).rgb * (weights[i] / weightSum);
		coords += offset.xy;
	}
	
	return float4(ocolor,1);
}

#define HDRBloomX1st \
		"RenderColorTarget0=BloomTexture1st2Y;" \
    	"Pass=DOHDRBloomX1st;"
		
#define HDRBloomX1stPass \
	pass DOHDRBloomX1st < string Script= "Draw=Buffer;"; >   \
	{	\
		AlphaBlendEnable = FALSE;  \
		ZFUNC=ALWAYS;  \
		ALPHAFUNC=ALWAYS;  \
		VertexShader = compile vs_3_0 POST_VS();  \
		PixelShader  = compile ps_3_0 HDRBloomGaussianPS(QuterBloomSamp,float2(bloomOffset.x,0));  \
	}
	
#define HDRBloomY1st \
		"RenderColorTarget0=BloomTexture1st;" \
    	"Pass=DOHDRBloomY1st;"
		
#define HDRBloomY1stPass \
	pass DOHDRBloomY1st < string Script= "Draw=Buffer;"; >   \
	{	\
		AlphaBlendEnable = FALSE;  \
		ZFUNC=ALWAYS;  \
		ALPHAFUNC=ALWAYS;  \
		VertexShader = compile vs_3_0 POST_VS();  \
		PixelShader  = compile ps_3_0 HDRBloomGaussianPS(BloomTexture1st2YSamp,float2(0,bloomOffset.y));  \
	}
	
	
#define HDRBloomX2nd \
		"RenderColorTarget0=BloomTexture2nd2Y;" \
    	"Pass=DOHDRBloomX2nd;"
		
#define HDRBloomX2ndPass \
	pass DOHDRBloomX2nd < string Script= "Draw=Buffer;"; >   \
	{	\
		AlphaBlendEnable = FALSE;  \
		ZFUNC=ALWAYS;  \
		ALPHAFUNC=ALWAYS;  \
		VertexShader = compile vs_3_0 POST_VS();  \
		PixelShader  = compile ps_3_0 HDRBloomGaussianPS(BloomTexture2ndSamp,float2(bloomOffset2.x,0));  \
	}
	
#define HDRBloomY2nd \
		"RenderColorTarget0=BloomTexture2nd;" \
    	"Pass=DOHDRBloomY2nd;"
		
#define HDRBloomY2ndPass \
	pass DOHDRBloomY2nd < string Script= "Draw=Buffer;"; >   \
	{	\
		AlphaBlendEnable = FALSE;  \
		ZFUNC=ALWAYS;  \
		ALPHAFUNC=ALWAYS;  \
		VertexShader = compile vs_3_0 POST_VS();  \
		PixelShader  = compile ps_3_0 HDRBloomGaussianPS(BloomTexture2nd2YSamp,float2(0,bloomOffset2.y));  \
	}
	
#define HDRBloomX3rd \
		"RenderColorTarget0=BloomTexture3rd2Y;" \
    	"Pass=DOHDRBloomX3rd;"
		
#define HDRBloomX3rdPass \
	pass DOHDRBloomX3rd < string Script= "Draw=Buffer;"; >   \
	{	\
		AlphaBlendEnable = FALSE;  \
		ZFUNC=ALWAYS;  \
		ALPHAFUNC=ALWAYS;  \
		VertexShader = compile vs_3_0 POST_VS();  \
		PixelShader  = compile ps_3_0 HDRBloomGaussianPS(BloomTexture3rdSamp,float2(bloomOffset3.x,0));  \
	}
	
#define HDRBloomY3rd \
		"RenderColorTarget0=BloomTexture3rd;" \
    	"Pass=DOHDRBloomY3rd;"
		
#define HDRBloomY3rdPass \
	pass DOHDRBloomY3rd < string Script= "Draw=Buffer;"; >   \
	{	\
		AlphaBlendEnable = FALSE;  \
		ZFUNC=ALWAYS;  \
		ALPHAFUNC=ALWAYS;  \
		VertexShader = compile vs_3_0 POST_VS();  \
		PixelShader  = compile ps_3_0 HDRBloomGaussianPS(BloomTexture3rd2YSamp,float2(0,bloomOffset3.y));  \
	}
	

#define HDRBloomX4th \
		"RenderColorTarget0=BloomTexture3rd2Y;" \
    	"Pass=DOHDRBloomX4th;"
		
#define HDRBloomX4thPass \
	pass DOHDRBloomX4th < string Script= "Draw=Buffer;"; >   \
	{	\
		AlphaBlendEnable = FALSE;  \
		ZFUNC=ALWAYS;  \
		ALPHAFUNC=ALWAYS;  \
		VertexShader = compile vs_3_0 POST_VS();  \
		PixelShader  = compile ps_3_0 HDRBloomGaussianPS(BloomTexture3rdSamp,float2(bloomOffset4.x,0));  \
	}
	
#define HDRBloomY4th \
		"RenderColorTarget0=BloomTexture4th;" \
    	"Pass=DOHDRBloomY4th;"
		
#define HDRBloomY4thPass \
	pass DOHDRBloomY4th < string Script= "Draw=Buffer;"; >   \
	{	\
		AlphaBlendEnable = FALSE;  \
		ZFUNC=ALWAYS;  \
		ALPHAFUNC=ALWAYS;  \
		VertexShader = compile vs_3_0 POST_VS();  \
		PixelShader  = compile ps_3_0 HDRBloomGaussianPS(BloomTexture3rd2YSamp,float2(0,bloomOffset4.y));  \
	}
	
	
	
#define HDRBLOOM \
	HDRBloomX1st \
	DownSampBloom4X1st \
	HDRBloomY1st \
	HDRBloomX2nd \
	DownSampBloom4X2nd \
	HDRBloomY2nd \
	HDRBloomX3rd \
	HDRBloomY3rd \
	HDRBloomX4th \
	HDRBloomY4th
	
#define HDRBLOOMPASS \
	HDRBloomX1stPass \
	HDRBloomY1stPass \
	DownSampBloom4X1stPass \
	HDRBloomX2ndPass \
	HDRBloomY2ndPass \
	DownSampBloom4X2ndPass \
	HDRBloomX3rdPass \
	HDRBloomY3rdPass \
	HDRBloomX4thPass \
	HDRBloomY4thPass

	
float3 OverExposure(float3 color){
	//AutoLuminous4
    float OverExposureRatio = 0.85;
	float3 newcolor = color;
    
    newcolor.gb += max(color.r - 0.95, 0) * OverExposureRatio * float2(0.65, 0.6);
    newcolor.rb += max(color.g - 0.95, 0) * OverExposureRatio * float2(0.5, 0.6);
    newcolor.rg += max(color.b - 0.8, 0) * OverExposureRatio * float2(0.5, 0.6);
    
    return newcolor;
}


void HDRBLOOMCOMP_PS(float2 Tex: TEXCOORD0,out float4 ocolor : COLOR0)
{
	ocolor = float4(0,0,0,1);
	float3 bloom0 = tex2D(BloomTexture1stSamp,Tex).xyz;
	float3 bloom1 = tex2D(BloomTexture2ndSamp,Tex).xyz;
	float3 bloom2 = tex2D(BloomTexture3rdSamp,Tex).xyz;
	float3 bloom3 = tex2D(BloomTexture4thSamp,Tex).xyz;
	
	ocolor.xyz = OverExposure(bloom0 + bloom1*0.8)*0.2 + bloom2*0.4 + bloom3*0.4;
	return;
}

#define HDRBLOOMCOMP\
		"RenderColorTarget0=Blur4WorkBuff0;" \
    	"RenderDepthStencilTarget=mrt_Depth;" \
		"ClearSetDepth=ClearDepth;Clear=Depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
    	"Pass=DOHDRBLOOMCOMP;"
		
#define HDRBLOOMCOMPPASS \
	pass DOHDRBLOOMCOMP < string Script= "Draw=Buffer;"; >   \
	{	\
		AlphaBlendEnable = FALSE;  \
		ZFUNC=ALWAYS;  \
		ALPHAFUNC=ALWAYS;  \
		VertexShader = compile vs_3_0 POST_VS();  \
		PixelShader  = compile ps_3_0 HDRBLOOMCOMP_PS();  \
	}