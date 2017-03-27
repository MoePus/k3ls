
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
    AddressU  = Border;
    AddressV = Border;
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
    AddressU  = Border;
    AddressV = Border;
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
    AddressU  = Border;
    AddressV = Border;
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
    AddressU  = Border;
    AddressV = Border;
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
    AddressU  = Border;
    AddressV = Border;
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
    AddressU  = Border;
    AddressV = Border;
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
    AddressU  = Border;
    AddressV = Border;
};

float4 HDRBloomGaussianPS(float2 Tex: TEXCOORD0, uniform sampler samp, uniform float2 offset) : COLOR0
{
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
		"RenderColorTarget0=Blur4WorkBuff2;" \
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
	
	
#if GLARE_SAMPLE > 0
float3 colorOffset(float3 c)
{
	c.rgb = rgb2hsv(c.rgb);
	c.r = c.r + 0.5;
	c.rgb = hsv2rgb(c.rgb);
	
	return c;
}

float4 PS_AL_DirectionalBlur1( float2 Tex: TEXCOORD0 , uniform sampler2D Samp) : COLOR 
{   
    float n = Epsilon;
    float2 stex1, stex2, stex3;
    float4 Color = 0;
    float4 sum1 = 0, sum2 = 0, sum3 = 0;
    
    float2 dir = float2(1.0/1000.0,0);
    
    [unroll]
    for(int i = -GLARE_SAMPLE; i <= GLARE_SAMPLE; i++){
        float e = exp(-pow((float)i / (GLARE_SAMPLE / 2.0), 2) / 2); 

        stex1 = Tex + dir * ((float)i * 1.0);
        stex2 = Tex + dir * ((float)i * 1.8);
        stex3 = Tex + dir * ((float)i * 3.9);
        
		float3 color1,color2,color3;
		color1 = max(0,tex2Dlod( Samp, float4(stex1, 0, 1) ));
		color2 = max(0,tex2Dlod( Samp, float4(stex2, 0, 1) ));
		color3 = max(0,tex2Dlod( Samp, float4(stex3, 0, 1) ));
		
		sum1.rgb += color1 * e;
		sum2.rgb += color2 * e;
		sum3.rgb += color3 * e;

        n += e;
    }
    
    sum1 /= n;
    sum2 /= n;
    sum3 /= n;
    
    sum1 = max(0, sum1 - 0.006); sum2 = max(0, sum2 - 0.015); sum3 = max(0, sum3 - 0.029);
    
    Color = sum1 + sum2 + sum3;
    
	Color /= 1.08;
    
	
	float2 linearDepthXid = tex2D(sumDepthSamp,Tex).xy;
	float linearDepth = linearDepthXid.x * SCENE_ZFAR;
	float3 vpos = coord2WorldViewPos(Tex - ViewportOffset,linearDepth);
	float3 wpos = mul(vpos,(float3x3)ViewInverse);
	float3 view = normalize(CameraPosition - wpos);
	
	dir = float2(view.x*0.43,0);
	float3 ghost = tex2Dlod( Samp, float4(Tex+dir, 0, 1) );
	
	Color.rgb += colorOffset(ghost)*0.5*max(0,0.18-abs(dir.x));
	
    return Color;
}


float4 PS_AL_DirectionalBlur2( float2 Tex: TEXCOORD0 , uniform sampler2D Samp) : COLOR 
{   

    float n = Epsilon;
    float2 stex;
    float4 sum = 0;
    
    float step = 1.0/1680.0;
    
    float2 dir = float2(1,0) * step;
    float p = 1;
    
    [unroll]
    for(int i = -GLARE_SAMPLE; i <= GLARE_SAMPLE; i++){
		float fact = 2.0 * (float)i / GLARE_SAMPLE;
        float e = exp(-pow(fact, 2) / 2);

        stex = Tex + dir * (float)i;
        
		float4 color = tex2Dlod( Samp, float4(stex, 0, 0) );
		sum += color * e;

        n += e;
    }

    sum /= n;

    return sum;
}

float4 PS_Unconvolution( float2 Tex: TEXCOORD0 , uniform sampler2D Samp) : COLOR 
{   
	float4 color = tex2Dlod( Samp, float4(Tex, 0, 0) );
	float4 colorU = tex2Dlod( Samp, float4(Tex+float2(0,ViewportOffset2.y), 0, 0) );
	float4 colorD = tex2Dlod( Samp, float4(Tex-float2(0,ViewportOffset2.y), 0, 0) );
	return max(0,color*3-colorU-colorD);
	// return color;
}
#define HDRGLARE\
		"RenderColorTarget0=BloomTexture1st2Y;" \
    	"RenderDepthStencilTarget=mrt_Depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
    	"Pass=DOHDRGLARE1;" \
		\
		"RenderColorTarget0=BloomTexture1st;" \
    	"RenderDepthStencilTarget=mrt_Depth;" \
    	"Pass=DOHDRGLARE2;" \
		\
		"RenderColorTarget0=Blur4WorkBuff0;" \
    	"RenderDepthStencilTarget=mrt_Depth;" \
    	"Pass=UNCONVOLUTION;" \
		
#define HDRGLAREPASS \
	pass DOHDRGLARE1 < string Script= "Draw=Buffer;"; >   \
	{	\
		AlphaBlendEnable = FALSE;  \
		ZFUNC=ALWAYS;  \
		ALPHAFUNC=ALWAYS;  \
		VertexShader = compile vs_3_0 POST_VS();  \
		PixelShader  = compile ps_3_0 PS_AL_DirectionalBlur1(Blur4WorkBuff0SamplerB);  \
	} \
	pass DOHDRGLARE2 < string Script= "Draw=Buffer;"; >   \
	{	\
		AlphaBlendEnable = FALSE;  \
		ZFUNC=ALWAYS;  \
		ALPHAFUNC=ALWAYS;  \
		VertexShader = compile vs_3_0 POST_VS();  \
		PixelShader  = compile ps_3_0 PS_AL_DirectionalBlur2(BloomTexture1st2YSamp);  \
	} \
	pass UNCONVOLUTION < string Script= "Draw=Buffer;"; >   \
	{	\
		AlphaBlendEnable = FALSE;  \
		ZFUNC=ALWAYS;  \
		ALPHAFUNC=ALWAYS;  \
		VertexShader = compile vs_3_0 POST_VS();  \
		PixelShader  = compile ps_3_0 PS_Unconvolution(BloomTexture1stSamp);  \
	}

#endif


//Len Ghost from Ray-mmd
void VS_LenGhost(
	inout float4 Position : POSITION,
	in float2 Texcoord : TEXCOORD,
	out float4 oTexcoord0 : TEXCOORD0,
	out float4 oTexcoord1 : TEXCOORD1,
	uniform float4 scalar)
{
	oTexcoord0.xy = (Texcoord - 0.5) * scalar[0] + 0.5;
	oTexcoord0.zw = (Texcoord - 0.5) * scalar[1] + 0.5;
	oTexcoord1.xy = (Texcoord - 0.5) * scalar[2] + 0.5;
	oTexcoord1.zw = (Texcoord - 0.5) * scalar[3] + 0.5;
}

float coord2sphereFac(float2 tex)
{
	tex -= 0.5;
	float factor = length(tex);
	return min(1,exp(-9*factor)*5);
}

float4 PS_LenGhost(
	in float4 coord0 : TEXCOORD0,
	in float4 coord1 : TEXCOORD1,
	uniform sampler source1,
	uniform sampler source2,
	uniform sampler source3,
	uniform float4 colorCoeff[4], uniform float threshold) : COLOR
{
	float ghostThreshold = threshold / (1 - threshold + Epsilon) * 10.0;
	float4 color1 = saturate(tex2Dlod(source1, float4(coord0.xy, 0, 0)) - ghostThreshold) * colorCoeff[0];
	float4 color2 = saturate(tex2Dlod(source1, float4(coord0.zw, 0, 0)) - ghostThreshold) * colorCoeff[1];
	float4 color3 = saturate(tex2Dlod(source2, float4(coord1.xy, 0, 0)) - ghostThreshold) * colorCoeff[2];
	float4 color4 = saturate(tex2Dlod(source3, float4(coord1.zw, 0, 0)) - ghostThreshold) * colorCoeff[3];
	
	color1 *= coord2sphereFac(coord0.xy);
	color2 *= coord2sphereFac(coord0.zw);
	color3 *= coord2sphereFac(coord1.xy);
	color4 *= coord2sphereFac(coord1.zw);
	
	return color1 + color2 + color3 + color4;
}


static float4 ghost_scalar1st = float4(-4.0, 3.0, -2.0, 0.3);
static float4 ghost_scalar2nd = float4(3.6, 2.0, 0.9, -0.77);

static const float4 ghost_modulation1st[4] = {float4(0.1, 0.10, 1.00, 1.0), float4(0.2, 0.30, 1.0, 1.0), float4(0.10, 0.20, 0.60, 1.0), float4(0.60, 0.30, 1.00, 1.0)};
static const float4 ghost_modulation2nd[4] = {float4(0.6, 0.20, 0.20, 1.0), float4(0.2, 0.06, 0.6, 1.0), float4(0.15, 0.00, 0.10, 1.0), float4(0.06, 0.00, 0.55, 1.0)};

#define LenGhost \
		"RenderColorTarget0=BloomTexture1st;" \
    	"RenderDepthStencilTarget=mrt_Depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
    	"Pass=Ghost1st;" \
		\
		"RenderColorTarget0=BloomTexture1st2Y;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
    	"Pass=Ghost2nd;" 


#define LenGhostPass \
	pass Ghost1st < string Script= "Draw=Buffer;"; >   \
	{	\
		AlphaBlendEnable = FALSE;  \
		ZFUNC=ALWAYS;  \
		ALPHAFUNC=ALWAYS;  \
		VertexShader = compile vs_3_0 VS_LenGhost(ghost_scalar1st);  \
		PixelShader  = compile ps_3_0 PS_LenGhost(BloomTexture4thSamp,BloomTexture3rdSamp,BloomTexture2ndSamp,ghost_modulation1st,0.05); \
	} \
	pass Ghost2nd < string Script= "Draw=Buffer;"; >   \
	{	\
		AlphaBlendEnable = FALSE;  \
		ZFUNC=ALWAYS;  \
		ALPHAFUNC=ALWAYS;  \
		VertexShader = compile vs_3_0 VS_LenGhost(ghost_scalar2nd);  \
		PixelShader  = compile ps_3_0 PS_LenGhost(BloomTexture1stSamp,BloomTexture1stSamp,BloomTexture3rdSamp,ghost_modulation2nd,0.0);  \
	}