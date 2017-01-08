float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "postprocess";
> = 0.8;
///////////////////////////////////////////////////////////////////////////////////////////////
#include "headers\\environment.fxh"
#include "headers\\workBuff.fxh"
///////////////////////////////////////////////////////////////////////////////////////////////
#define PI  3.14159265359f
#define invPi 0.31830988618
///////////////////////////////////////////////////////////////////////////////////////////////
float3 FOGXYZ         : CONTROLOBJECT < string name = "(self)"; string item="XYZ"; >;
static float FOG_G = max(0,FOGXYZ.x);
static float FOG_S = max(1.5,10.0 + FOGXYZ.y);
static float FOG_A = max(0,1+FOGXYZ.z);

float HDRSTRENGTH : CONTROLOBJECT < string name = "(self)"; string item = "Tr"; >;
float sss_correction : CONTROLOBJECT < string name = "(self)"; string item = "Si"; >;

float  AmbLightPower		: CONTROLOBJECT < string name = "Ambient.x"; string item="Si"; >;
float3 AmbColorXYZ			: CONTROLOBJECT < string name = "Ambient.x"; string item="XYZ"; >;
float3 AmbColorRxyz			: CONTROLOBJECT < string name = "Ambient.x"; string item="Rxyz"; >;
static float3 AmbientColor  = AmbLightPower;
static float3 AmbLightColor0 = AmbColorXYZ*0.01; 
static float3 AmbLightColor1 = AmbColorRxyz*1.8/3.141592; 

float  diffAmbientMinus		: CONTROLOBJECT < string name = "Gbuffer_init.pmx"; string item="diffAmbient-"; >;
float  specAmbientMinus		: CONTROLOBJECT < string name = "Gbuffer_init.pmx"; string item="specAmbient-"; >;
float  shadowPlus			: CONTROLOBJECT < string name = "Gbuffer_init.pmx"; string item="shadow+"; >;
float  aoPlus				: CONTROLOBJECT < string name = "Gbuffer_init.pmx"; string item="ao+"; >;
float  directLightPlus		: CONTROLOBJECT < string name = "Gbuffer_init.pmx"; string item="directLight+"; >;
float  colorTemperature		: CONTROLOBJECT < string name = "Gbuffer_init.pmx"; string item="colorTemperature"; >;
static float3 LightAmbient = _LightAmbient * (2 + 4 * directLightPlus);
///////////////////////////////////////////////////////////////////////////////////////////////
texture2D mrt : RENDERCOLORTARGET <
	float2 ViewportRatio = {1.0, 1.0};
	string Format = YOR16F;
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

texture2D diffuseTexture : RENDERCOLORTARGET <
	float2 ViewportRatio = {1.0, 1.0};
	string Format = YOR16F;
>;
sampler2D diffuseSamp = sampler_state {
    texture = <diffuseTexture>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};
texture2D specularTexture : RENDERCOLORTARGET <
	float2 ViewportRatio = {1.0, 1.0};
	string Format = YOR16F;
>;
sampler2D specularSamp = sampler_state {
    texture = <specularTexture>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

texture2D sumDepth: RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
	float4 ClearColor = { 0, 0, 0, 0 };
	string Format = "R32F";
>;
sampler sumDepthSamp = sampler_state {
    texture = <sumDepth>;
    MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
    AddressU  = CLAMP;
	AddressV  = CLAMP;
};

texture2D sumNormal: RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
	float4 ClearColor = { 0, 0, 0, 0 };
	string Format = YOR32F;
>;
sampler sumNormalSamp = sampler_state {
    texture = <sumNormal>;
    MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
    AddressU  = CLAMP;
	AddressV  = CLAMP;
};
///////////////////////////////////////////////////////////////////////////////////////////////
struct POST_OUTPUT {
    float4 Pos      : POSITION;   
	float2 Tex	    : TEXCOORD0;	
};
///////////////////////////////////////////////////////////////////////////////////////////////
#include "headers\\math.fxh"
#include "headers\\BRDF.fxh"
#include "headers\\IBL.fxh"
///////////////////////////////////////////////////////////////////////////////////////////////
#include "headers\\getControllerParams.fxh"
#include "headers\\GbufferTextures.fxh"
#include "headers\\GbufferSamplers.fxh"
#include "headers\\GbufferClear.fxh"
///////////////////////////////////////////////////////////////////////////////////////////////
#include "pssm\\pssm.fxh"
#include "ssdo\\ssdo.fxh"
#include "headers\\blur.fxh"
#if ENABLE_SSS > 0
#include "headers\\SSSSS.fxh"
#endif	
#if VOLUMETRIC_FOG_SAMPLE > 0
#include "headers\\fog.fxh"
#endif	
#include "headers\\ACESToneMapping.fxh"
///////////////////////////////////////////////////////////////////////////////////////////////
#ifdef USE_SMAA
#include "SMAA\\SMAA.h"
#include "SMAA\\SMAA.ready"
#else
#include "headers\\AA.fxh"
#endif
///////////////////////////////////////////////////////////////////////////////////////////////
POST_OUTPUT POST_VS(float4 Pos : POSITION, float2 Tex : TEXCOORD0)
{
    POST_OUTPUT Out = (POST_OUTPUT)0;

	Out.Pos = Pos;
    Out.Tex = Tex + ViewportOffset;
    return Out;
}

void sumG_PS(float2 Tex: TEXCOORD0,out float4 Depth : COLOR0,out float4 N : COLOR1)
{
	float Depth1 = tex2D(DepthGbufferSamp,Tex).x * SCENE_ZFAR;
	float Depth2 = tex2D(Depth_ALPHA_FRONT_GbufferSamp,Tex).x * SCENE_ZFAR;
	
	float3 N1 = float3(tex2D(NormalGbufferSamp,Tex).xy,tex2D(SpaGbufferSamp,Tex).y);
	float3 N2 = float3(tex2D(Normal_ALPHA_FRONT_GbufferSamp,Tex).xy,tex2D(Spa_ALPHA_FRONT_GbufferSamp,Tex).y);
	
	bool T = Depth2<=Depth1;
	if(T)
	{
		Depth = float4(Depth2,0,0,1);
		N = float4(N2,1);
	}else
	{
		Depth = float4(Depth1,0,0,1);
		N = float4(N1,1);
	}

	return;
}
float4 COPY_PS(float2 Tex: TEXCOORD0 ,uniform sampler2D Samp) : COLOR
{
	float3 color = tex2D(Samp,Tex).xyz;
	
	return float4(color,1);
}

inline float3 CalcTranslucency(float s)
{
	//http://iryoku.com/translucency/
	float dd = s*-s;
	return float3(0.233f, 0.455f, 0.649f) * exp(dd / 0.0064f)
		+ float3(0.1f, 0.336f, 0.344f) * exp(dd / 0.0484f)
		+ float3(0.118f, 0.198f, 0.0f) * exp(dd / 0.187f)
		+ float3(0.113f, 0.007f, 0.007f) * exp(dd / 0.567f)
		+ float3(0.358f, 0.004f, 0.0f) * exp(dd / 1.99f)
		+ float3(0.078f, 0.0f, 0.0f) * exp(dd / 7.41f);
}

inline void PBR_shade(float id,float2 Tex,float3 wpos,float4 albedo,float spa,float3 normal,
out float4 odiff,
out float4 ospec
)
{
	albedo.xyz = srgb2linear(albedo.xyz);
	albedo.xyz = max(albedo.xyz,0.0013.xxx);//note: there is no pure black in the world.
	
	float2 shadowMap = tex2D(ScreenShadowMapProcessedSamp, Tex).xy;
	float ShadowMapVal = saturate(shadowMap.x);
	float ao = saturate(shadowMap.y);
	
	float3 view = CameraPosition - wpos;
	float3 viewNormal = normalize(view);
	float3 lightNormal = normalize(-LightDirection);

	float NL = saturate(dot(lightNormal,normal));
	float LV = dot(lightNormal,viewNormal);

	ConParam cp;
	getConParams(id,cp);
	cp.roughness *= 1-frac(id)*10;
	
	float3 f0 = lerp(0.04,max(0.04,spa)*(albedo.xyz*0.68169+0.31831),cp.metalness);
	
	float3 diffuse = NL*albedo.xyz*invPi*DiffuseBRDF(cp.roughness,normal,lightNormal,viewNormal)*LightAmbient*(1-cp.metalness);
	float3 specular = NL*BRDF(cp.roughness,f0,normal,lightNormal,viewNormal)*LightAmbient;
	
	float3 trans;
	if(cp.translucency>Epsilon)
	{
		float irradiance = max(0.3 + dot(-normal, lightNormal), 0.0);
		trans = CalcTranslucency((1-ShadowMapVal)/cp.translucency)*irradiance*albedo.xyz;//Wrong but beautiful.
	}
	else
	{
		trans = 0;
	}
	
	#define SKYDIR float3(0.0,1.0,0.0)
	float SdN = dot(SKYDIR,normal)*0.5f+0.5f;
	float3 Hemisphere = lerp(AmbLightColor1.xyz, AmbLightColor0.xyz, SdN*SdN);
	float3 IBLD,IBLS;
	IBL(viewNormal,normal,cp.roughness,IBLD,IBLS);
	
	float NoV = saturate(dot(normal,viewNormal));
	float3 ambientDiffuse =  albedo.xyz * Hemisphere + AmbientColor * albedo.xyz * IBLD * lerp(0.85, 0, cp.metalness)*(1 - diffAmbientMinus);
	float3 ambientSpecular = AmbientColor * IBLS * AmbientBRDF_UE4(spa * albedo.xyz, cp.roughness, NoV) * lerp(0.15, 1, cp.metalness)*(1 - specAmbientMinus); //TBD
		
	IBL(viewNormal,normal,cp.varnishRough,IBLD,IBLS);
	float3 surfaceSpecular = cp.varnishAlpha * (lerp(dot(IBLS,RGB2LUM),IBLS*albedo.xyz,0.68) * AmbientBRDF_UE4(0.32.xxx,cp.varnishRough,NoV) + NL*BRDF(cp.varnishRough,lerp(1.0,albedo.xyz,0.68),normal,lightNormal,viewNormal)*LightAmbient);	

	float RF = lerp(1,lerp(1,min(1,pow(saturate(1.468-NoV),5)+0.23),square(cp.roughness)),cp.reflectance);
	
	float3 selfLight = (exp(3.68888f * cp.selfLighting) - 1) * albedo.xyz * 0.25;
		
	odiff = float4((albedo.a>Epsilon)*((ShadowMapVal*diffuse + ao*ambientDiffuse)*RF + selfLight + trans),albedo.a);
	ospec = float4((albedo.a>Epsilon)*(ShadowMapVal*specular+ao*ambientSpecular+surfaceSpecular),cp.SSS);
}
						
void PBR_NONEALPHA_PS(float2 Tex: TEXCOORD0,out float4 odiff : COLOR0,out float4 ospec : COLOR1)
{
	float4 sky = tex2D(MRTSamp,Tex);

	float4 albedo = tex2D(AlbedoGbufferSamp,Tex);
	float2 spaMap = tex2D(SpaGbufferSamp,Tex).xy;
	float2 normalMap = tex2D(NormalGbufferSamp,Tex).xy;
	float spa = spaMap.x;
	float3 normal = float3(normalMap.xy,spaMap.y);
	float2 linearDepthXid = tex2D(DepthGbufferSamp,Tex).xy;
	float linearDepth = linearDepthXid.x * SCENE_ZFAR;
	float id = linearDepthXid.y;
	float3 pos = coord2WorldViewPos(Tex,linearDepth);
	float3 wpos = mul(pos,(float3x3)ViewInverse);

	PBR_shade(id,Tex,wpos,albedo,spa,normal,odiff,ospec);
	
	odiff.xyz += (1-albedo.a)*sky.xyz;
	
	float4 alphaLight = tex2D(Blur4WorkBuff1Sampler,Tex);
	
	float Depth1 = tex2D(DepthGbufferSamp,Tex).x * SCENE_ZFAR;
	float Depth2 = tex2D(Depth_ALPHA_FRONT_GbufferSamp,Tex).x * SCENE_ZFAR;
	if(Depth2<=Depth1)
	{
		odiff.xyz*=(1-alphaLight.a);
		ospec.xyz=ospec.xyz*(1-alphaLight.a)+alphaLight.xyz*alphaLight.a;
	}

	float3 outColor = odiff.xyz+ospec.xyz;
	return;
}

void PBR_ALPHAFRONT_PS(float2 Tex: TEXCOORD0,out float4 ocolor : COLOR0)
{
	float4 albedo = tex2D(Albedo_ALPHA_FRONT_GbufferSamp,Tex);
	albedo.xyz/=albedo.a;
	float2 spaMap = tex2D(Spa_ALPHA_FRONT_GbufferSamp,Tex).xy;
	float2 normalMap = tex2D(Normal_ALPHA_FRONT_GbufferSamp,Tex).xy;
	float spa = spaMap.x;
	float3 normal = float3(normalMap.xy,spaMap.y);
	float2 linearDepthXid = tex2D(Depth_ALPHA_FRONT_GbufferSamp,Tex).xy;
	float linearDepth = linearDepthXid.x * SCENE_ZFAR;
	float id = linearDepthXid.y;
	float3 pos = coord2WorldViewPos(Tex,linearDepth);
	float3 wpos = mul(pos,(float3x3)ViewInverse);

	float4 odiff,ospec;
	PBR_shade(id,Tex,wpos,albedo,spa,normal,odiff,ospec);

	ocolor = float4(odiff.xyz+ospec.xyz,albedo.a);
	return;
}


texture AL_EmitterRT: OFFSCREENRENDERTARGET <
    string Description = "EmitterDrawRenderTarget for AutoLuminous.fx";
    float2 ViewPortRatio = {1.0,1.0};
    float4 ClearColor = { 0, 0, 0, 1 };
    float ClearDepth = 1.0;
    bool AntiAlias = true;
    int MipLevels = 0;
    string Format = YOR16F;
    string DefaultEffect = 
        "self = hide;"
        "*.x=hide;"
        "* = AutoLuminous\\AL_Object.fx;" 
    ;
>;
sampler EmitterView = sampler_state {
    texture = <AL_EmitterRT>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Point;
    AddressU  = Clamp;
    AddressV = Clamp;
};

void COMP_PS(float2 Tex: TEXCOORD0,out float4 ocolor : COLOR0,out float4 lum : COLOR1,out float4 highLight : COLOR2)
{
	float4 blurredDiffuse = tex2D(diffuseSamp,Tex);
	float3 specular = tex2D(specularSamp,Tex).xyz;
	
	#if VOLUMETRIC_FOG_SAMPLE > 0
	float fogFactor = tex2D(FogWorkBuffSampler,Tex).x;
	fogFactor = clamp(fogFactor,0,0.67) * 1.7;
	fogFactor = pow(fogFactor,3.6) * 0.62;
	float3 fog = fogFactor * LightAmbient * fogColor;
	#else
	float3 fog = 0;
	#endif

	#if SSDO_COLOR_BLEEDING > 0
	float3 GI = tex2D(AOWorkMapSampler,Tex).xyz;
	ocolor.xyz = (blurredDiffuse.xyz + specular)*(1+SSDO_COLOR_BLEEDING*GI);
	#else
	ocolor.xyz = blurredDiffuse.xyz + specular;
	#endif
	
	ocolor.xyz *= (1-dot(fog, RGB2LUM)*0.5);
	ocolor.xyz += fog;
	ocolor.a = 1;
			
	float l = dot(RGB2LUM,ocolor.xyz);
	lum = float4(log(l + Epsilon),0,0,1);
	highLight = tex2Dlod(EmitterView, float4(Tex, 0, 0));
	highLight.xyz = easysrgb2linear(highLight.xyz)*11;
	highLight.xyz += max(0,ocolor.xyz*1.1-2.3+HDRSTRENGTH)/max(0.95,l*0.032);
	highLight.xyz *= 1.8;
	highLight.a = 1;
	return;
}


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
	
///////////////////////////////////////////////////////////////////////////////////////////////
#define BLUR_PSSM_AO \
		"RenderColorTarget0=Blur2WorkBuff0;" \
    	"RenderDepthStencilTarget=mrt_Depth;" \
		"ClearSetDepth=ClearDepth;Clear=Depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
    	"Pass=PSSMBilateralBlurX;" \
		\
		"RenderColorTarget0=ScreenShadowMap;" \
    	"RenderDepthStencilTarget=mrt_Depth;" \
		"ClearSetDepth=ClearDepth;Clear=Depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
    	"Pass=PSSMBilateralBlurY;"
///////////////////////////////////////////////////////////////////////////////////////////////
#if SSDO_COLOR_BLEEDING > 0
#define BLUR_COLOR_BLEEDING \
		"RenderColorTarget0=Blur4WorkBuff0;" \
    	"RenderDepthStencilTarget=mrt_Depth;" \
		"ClearSetDepth=ClearDepth;Clear=Depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
    	"Pass=ColorBleedingBilateralBlurX;" \
		\
		"RenderColorTarget0=AOWorkMap;" \
    	"RenderDepthStencilTarget=mrt_Depth;" \
		"ClearSetDepth=ClearDepth;Clear=Depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
    	"Pass=ColorBleedingBilateralBlurY;"
#endif
///////////////////////////////////////////////////////////////////////////////////////////////
float4 ClearColor = {0,0,0,0};
float4 ClearDepthColor = {1,1,1,0};
float ClearDepth  = 1.0;

technique K3LS_COMP<

string Script = 		
        "RenderColorTarget0=mrt;"
    	"RenderDepthStencilTarget=mrt_Depth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
		
        "ScriptExternal=Color;"

		"RenderColorTarget0=sumDepth;"
		"RenderColorTarget1=sumNormal;"
    	"RenderDepthStencilTarget=mrt_Depth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=SUMGDN;"
		"RenderColorTarget1=;"
		
		SSSHADOWOBJ
		
		SSDO_COLORBLEEDING
		
		BLUR_PSSM_AO
		
		"RenderColorTarget0=Blur4WorkBuff1;"
		"RenderDepthStencilTarget=mrt_Depth;"
		"Pass=PBRALPHAFRONTPRECOMP;"
		
		"RenderColorTarget0=diffuseTexture;"
		"RenderColorTarget1=specularTexture;"
    	"RenderDepthStencilTarget=mrt_Depth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=PBRPRECOMP;"
		"RenderColorTarget1=;" //mono:Do not forget to free it.
		
		#if ENABLE_SSS > 0
		SSSSS	
		#endif
		
		#if SSDO_COLOR_BLEEDING > 0
		BLUR_COLOR_BLEEDING
		#endif
		
		#if VOLUMETRIC_FOG_SAMPLE > 0
		FOG_RAYMARCH
		#endif
		
		"RenderColorTarget0=Blur4WorkBuff1;"
		"RenderColorTarget1=lumTexture;"
		"RenderColorTarget2=Blur4WorkBuff0;"
    	"RenderDepthStencilTarget=mrt_Depth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=PBRAFTERCOMP;"
		"RenderColorTarget1=;"
		"RenderColorTarget2=;"
		
		DownSacleLumAdapt
		
		DownSampHL4X1st
		
		HDRBLOOM
		
		HDRBLOOMCOMP
		
		"RenderColorTarget0=mrt;"
    	"RenderDepthStencilTarget=mrt_Depth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=ToneMapping;"
			
		#ifndef USE_SMAA
		"RenderColorTarget0=;"
    	"RenderDepthStencilTarget=;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=AA;"  
		#else
		DO_SMAA
		#endif

		/*"RenderColorTarget0=;"
    	"RenderDepthStencilTarget=;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=TEST;"*/
	
		ClearGbuffer
		;
>{
	#ifdef USE_SMAA
	SMAA_PASS_ES
	#else
	IKAA_PASS
	#endif
	
	pass TEST < string Script= "Draw=Buffer;"; > 
	{
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_3_0 POST_VS();
		PixelShader  = compile ps_3_0 COPY_PS(EmitterView);
	}
	
	pass SUMGDN < string Script= "Draw=Buffer;"; > {
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
		VertexShader = compile vs_3_0 POST_VS();
		PixelShader  = compile ps_3_0 sumG_PS();
	}
	
	pass SSShadow < string Script= "Draw=Buffer;"; > {
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
		VertexShader = compile vs_3_0 POST_VS();
		PixelShader  = compile ps_3_0 SSOBJ();
	}
	
	pass AOPass < string Script= "Draw=Buffer;"; > {
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
		VertexShader = compile vs_3_0 POST_VS();
		PixelShader  = compile ps_3_0 PS_AO();
	}
	
	
	pass PSSMBilateralBlurX < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
        VertexShader = compile vs_3_0 POST_VS();
        PixelShader  = compile ps_3_0 ShadowMapBlurAxBxToTxy_PS(ScreenShadowMapSampler,AOWorkMapSampler,float2(ViewportOffset2.x, 0.0f));
    }
	
	pass PSSMBilateralBlurY < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
        VertexShader = compile vs_3_0 POST_VS();
        PixelShader  = compile ps_3_0 ShadowMapBlurAxyToTxy_PS(Blur2WorkBuff0Sampler,float2(0.0f, ViewportOffset2.y));
    }
	#if SSDO_COLOR_BLEEDING > 0
	pass ColorBleedingBilateralBlurX < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
        VertexShader = compile vs_3_0 POST_VS();
        PixelShader  = compile ps_3_0 ShadowMapBlurAyzwToTxyz_PS(AOWorkMapSampler,float2(ViewportOffset2.x, 0.0f));
    }
	
	pass ColorBleedingBilateralBlurY < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
        VertexShader = compile vs_3_0 POST_VS();
        PixelShader  = compile ps_3_0 ShadowMapBlurAxyzToTxyz_PS(Blur4WorkBuff0Sampler,float2(0.0f, ViewportOffset2.y));
    }
	#endif
	pass PBRPRECOMP < string Script= "Draw=Buffer;"; > 
	{
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
        VertexShader = compile vs_3_0 POST_VS();
        PixelShader  = compile ps_3_0 PBR_NONEALPHA_PS();
    }
	pass PBRALPHAFRONTPRECOMP < string Script= "Draw=Buffer;"; > 
	{
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
        VertexShader = compile vs_3_0 POST_VS();
        PixelShader  = compile ps_3_0 PBR_ALPHAFRONT_PS();
    }
	
	pass PBRAFTERCOMP < string Script= "Draw=Buffer;"; > 
	{
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
        VertexShader = compile vs_3_0 POST_VS();
        PixelShader  = compile ps_3_0 COMP_PS();
    }
	
	AdaptLumPass
	
	pass ToneMapping < string Script= "Draw=Buffer;"; > 
	{
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
        VertexShader = compile vs_3_0 POST_VS();
		PixelShader  = compile ps_3_0 ToneMapping_PS();
    }

	#if ENABLE_SSS > 0
	SSSSSPASS
	#endif
	#if VOLUMETRIC_FOG_SAMPLE > 0
	FOGPASS
	#endif
	DownSampHL4X1stPass
	HDRBLOOMPASS
	HDRBLOOMCOMPPASS
}

