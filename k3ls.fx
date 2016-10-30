float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "postprocess";
> = 0.8;

float2 ViewportSize : VIEWPORTPIXELSIZE;
static float2 ViewportOffset = (float2(0.5,0.5)/ViewportSize);
float HDRSTRENGTH : CONTROLOBJECT < string name = "(self)"; string item = "Tr"; >;
float sss_correction : CONTROLOBJECT < string name = "(self)"; string item = "Si"; >;
#define downscalePX 48
#define RGB2LUM float3(0.2125, 0.7154, 0.0721)
texture2D mrt : RENDERCOLORTARGET <
	float2 ViewportRatio = {1.0, 1.0};
	string Format = "D3DFMT_A32B32G32R32F";
	int MipLevel = 4;
>;
texture2D mrt_Depth : RENDERDEPTHSTENCILTARGET <
    float2 ViewportRatio = {1.0, 1.0};
    string Format = "D24S8";
>;
sampler2D MRTSamp = sampler_state {
    texture = <mrt>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = POINT;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};


///////////////////////HDR////////////////////////////
texture2D mrtQuarter : RENDERCOLORTARGET <
	int Width = downscalePX;
	int Height = downscalePX;
	string Format = "D3DFMT_A16B16G16R16F";
>;
texture2D mrtQuarter_depth : RENDERDEPTHSTENCILTARGET <
	int Width = downscalePX;
	int Height = downscalePX;
    string Format = "D24S8";
>;
sampler2D MRTQuarterSamp = sampler_state {
    texture = <mrtQuarter>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};
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
///////////////////////HDR////////////////////////////

///////////////////////SSS////////////////////////////
texture2D SSSSS_DepthMap : OFFSCREENRENDERTARGET <
	string Description = "SSSSS depth map";
	float2 ViewportRatio = {1.0, 1.0};
	float4 ClearColor = { 0, 0, 0, 0 };
	string Format = "D3DFMT_R32F";
	float ClearDepth = 1.0;
	bool AntiAlias = true;
	string DefaultEffect = 
		"self = hide;"
		"*=SSSSS_depth.fxsub;";
>;
sampler2D SSSDepthMapSamp = sampler_state {
    texture = <SSSSS_DepthMap>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};
texture2D SSS_2X : RENDERCOLORTARGET<
	float2 ViewportRatio = {1.0, 1.0};
	string Format = "D3DFMT_A16B16G16R16F";
>;
texture2D SSS_2Y : RENDERCOLORTARGET<
	float2 ViewportRatio = {1.0, 1.0};
	string Format = "D3DFMT_A16B16G16R16F";
>;
texture2D SSS_2B : RENDERCOLORTARGET<
	float2 ViewportRatio = {1.0, 1.0};
	string Format = "D3DFMT_A16B16G16R16F";
>;
shared texture2D K3LS_GBuffer_01: RENDERCOLORTARGET;
shared texture2D K3LS_GBuffer_01_Depth : RENDERDEPTHSTENCILTARGET;
sampler2D SSS_2XSamp = sampler_state {
    texture = <SSS_2X>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};
sampler2D SSS_2YSamp = sampler_state {
    texture = <SSS_2Y>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};
sampler2D SSS_2BSamp = sampler_state {
    texture = <SSS_2B>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};
sampler2D KG01SAMP = sampler_state {
    texture = <K3LS_GBuffer_01>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};
int blurCount = 3;
int BlurIndex = 0;
float3 blendYFactor[3] = {
	float3(0.3251,0.45,0.3583),float3(0.34,0.1864,0),float3(0.46,0,0.0402)
};

///////////////////////SSS////////////////////////////
struct POST_OUTPUT {
    float4 Pos      : POSITION;   
	float2 Tex	    : TEXCOORD0;	
};

POST_OUTPUT POST_VS(float4 Pos : POSITION, float2 Tex : TEXCOORD0)
{
    POST_OUTPUT Out = (POST_OUTPUT)0;

	Out.Pos = Pos;
    Out.Tex = Tex + ViewportOffset;
    return Out;
}


float4 COPY_PS(float2 Tex: TEXCOORD0 ,uniform sampler2D Samp) : COLOR
{
	float4 color = tex2D(Samp,Tex);
	return color;
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

float EyeAdaption(float lum)
{
	return lerp(0.04f, 0.302f, lum);
}

float4 ACESToneMapping(float2 Tex: TEXCOORD0) : COLOR
{
	const float3 BLUE_SHIFT = float3(0.4f, 0.4f, 0.7f);
	float adapted_lum = adaptedLum[0][0].r;
	float3 ocolor = tex2D(MRTSamp,Tex);

	float lum = dot(ocolor, RGB2LUM);
	float3 color = lerp(lum * BLUE_SHIFT, ocolor, saturate(16.0f * lum));
	
	float adapted_lum_dest = 2. / (max(0.1f, 1 + 10 * EyeAdaption(adapted_lum)));
	
	color = AF(color * adapted_lum_dest);
	
	float3 outColor = HDRSTRENGTH*color+(1-HDRSTRENGTH)*ocolor;
	outColor = pow(outColor,1.0f/2.2f);
	
	return float4(outColor,1);
}

float elapsed_time : ELAPSEDTIME;

float CalcAdaptedLum(float adapted_lum, float current_lum)
{
	return adapted_lum + (current_lum - adapted_lum) * (1 - pow(0.98f, 60 * elapsed_time));
}

float4 LUM_PS(float2 Tex: TEXCOORD0) : COLOR
{
	float lum=0;
	for(float x = 0;x<downscalePX;x++)
		for(float y = 0;y<downscalePX;y++)
		{
			float2 t = float2(x/downscalePX,y/downscalePX)+(0.5).xx/downscalePX;
			float3 fc = tex2Dlod(MRTQuarterSamp,float4(t,0.0f.xx)).xyz;
			float y = dot(RGB2LUM,fc)+0.001;
			lum += log(y);
			
		}
	lum/=float(downscalePX*downscalePX);
	lum = exp(lum);
	lum = CalcAdaptedLum(adaptedLum[0][0].r,lum);
	return float4(lum.xxx,1);
	
}

#define GENBlurPS(PS_name,SAMP_name,step_mod) \
float4 PS_name(float2 Tex: TEXCOORD0) : COLOR { \
    const float w[6] = { 0.006,   0.061,   0.242,  0.242,  0.061, 0.006 }; \
    const float o[6] = {  -1.0, -0.6667, -0.3333, 0.3333, 0.6667,   1.0 }; \
	float SSS_strength = tex2D(KG01SAMP,Tex).r * 3.5f; \
	float2 step = float2(0.0,0.0); \
	step_mod = (1 + BlurIndex)*SSS_strength; \
	float4 colorM = tex2D(SAMP_name,Tex); \
    float depthM = tex2D(SSSDepthMapSamp,Tex).r; \
    float4 colorBlurred = colorM; \
    colorBlurred.rgb *= 0.382; \
	float correction = 100*(1-sss_correction/10); \
    float2 finalStep = colorM.a * step / depthM; \
	[unroll] \
    for (int i = 0; i < 6; i++) { \
        float2 offset = Tex + o[i] * finalStep / ViewportSize; \
        float3 color = tex2D(SAMP_name,offset).rgb; \
        float depth = tex2D(SSSDepthMapSamp,offset).r; \
        float s = min(0.0125 * correction * abs(depthM - depth), 1.0); \
        color = lerp(color, colorM.rgb, s); \
        colorBlurred.rgb += w[i] * color; } \
    return colorBlurred; }

GENBlurPS(Blur_PSX,SSS_2XSamp,step.x)
GENBlurPS(Blur_PSY,SSS_2YSamp,step.y)

float4 Blend_PS(float2 Tex: TEXCOORD0 ) : COLOR
{
	float3 factor = blendYFactor[BlurIndex];
		
	float3 srcColor = tex2D(SSS_2XSamp,Tex).xyz;
	float3 dstColor = tex2D(SSS_2BSamp,Tex).xyz;
	float3 invFactor = 1.0f.xxx - factor;
	return float4(srcColor.xyz*factor + dstColor.xyz*invFactor,1);
}

float4 ClearColor = {1,1,1,1};
float4 GClearColor = {0,0,0,0};
float ClearDepth  = 1.0;

shared texture ScreenShadowMap: OFFSCREENRENDERTARGET;

sampler ScreenShadowMapSampler = sampler_state {
    texture = <ScreenShadowMap>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

technique K3LS_finalize<

string Script = 		
		"RenderColorTarget0=mrt;"
    	"RenderDepthStencilTarget=mrt_Depth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
        "ScriptExternal=Color;"
		
		"RenderColorTarget0=mrtQuarter;"
    	"RenderDepthStencilTarget=mrtQuarter_depth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
		"Pass=DrawQuarter;"
		
		"RenderColorTarget0=adapted_lum;"
    	"RenderDepthStencilTarget=adapted_lum_Depth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=calcAL;"
		
		"RenderColorTarget0=SSS_2X;"
		"RenderDepthStencilTarget=mrt_Depth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=TONEMAPPING;"
		
	"LoopByCount=blurCount;"
	"LoopGetIndex=BlurIndex;"	
		
		"RenderColorTarget0=SSS_2Y;"
		"RenderDepthStencilTarget=mrt_Depth;"
    	"Pass=BLURX;"
		
		"RenderColorTarget0=SSS_2B;"
		"RenderDepthStencilTarget=mrt_Depth;"
    	"Pass=BLURY;"
		
		"RenderColorTarget0=SSS_2X;"
		"RenderDepthStencilTarget=mrt_Depth;"
    	"Pass=Blend;"
		
	"LoopEnd=;"
		
		"RenderColorTarget0=;"
		"RenderDepthStencilTarget=;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=COPY;"

		"RenderColorTarget0=K3LS_GBuffer_01;"
		"RenderDepthStencilTarget=K3LS_GBuffer_01_Depth;"
		"ClearSetColor=GClearColor;Clear=Color;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		;
>{
	pass calcAL < string Script= "Draw=Buffer;"; > 
	{
		AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 POST_VS();
		PixelShader  = compile ps_3_0 LUM_PS();
    }
	pass DrawQuarter < string Script= "Draw=Buffer;"; > 
	{
		AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 POST_VS();
		PixelShader  = compile ps_3_0 COPY_PS(MRTSamp);
    }
	pass TONEMAPPING < string Script= "Draw=Buffer;"; > 
	{
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
        VertexShader = compile vs_3_0 POST_VS();
		PixelShader  = compile ps_3_0 ACESToneMapping();
    }
	pass COPY < string Script= "Draw=Buffer;"; > 
	{
		AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 POST_VS();
		PixelShader  = compile ps_3_0 COPY_PS(SSS_2XSamp);
    }
	pass BLURX < string Script= "Draw=Buffer;"; > 
	{
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
        VertexShader = compile vs_3_0 POST_VS();
		PixelShader  = compile ps_3_0 Blur_PSX();
    }
	pass BLURY < string Script= "Draw=Buffer;"; > 
	{
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
        VertexShader = compile vs_3_0 POST_VS();
		PixelShader  = compile ps_3_0 Blur_PSY();
    }
	pass Blend < string Script= "Draw=Buffer;"; > 
	{
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
        VertexShader = compile vs_3_0 POST_VS();
        PixelShader  = compile ps_3_0 Blend_PS();
    }
}
