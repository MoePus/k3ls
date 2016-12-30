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

//float HDRSTRENGTH : CONTROLOBJECT < string name = "(self)"; string item = "Tr"; >;
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
#include "headers\\SSSSS.fxh"
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
	float4 color = tex2Dlod(Samp,float4(Tex,0,0));
	
	float Depth1 = tex2D(DepthGbufferSamp,Tex).x * SCENE_ZFAR;
	float Depth2 = tex2D(Depth_ALPHA_FRONT_GbufferSamp,Tex).x * SCENE_ZFAR;
	color = abs(Depth1 - Depth2);
	return float4(color.xxx,1);
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
	albedo.xyz = easysrgb2linear(albedo.xyz);
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
	float3 ambientDiffuse =  albedo.xyz * Hemisphere + AmbientColor * albedo.xyz * IBLD * lerp(0.63212, 0, cp.metalness)*(1 - diffAmbientMinus);
	float3 ambientSpecular = AmbientColor * IBLS * AmbientBRDF_UE4(spa * albedo.xyz, cp.roughness, NoV) * lerp(0.3679, 1, cp.metalness)*(1 - specAmbientMinus); //TBD
		
	IBL(viewNormal,normal,cp.varnishRough,IBLD,IBLS);
	float3 surfaceSpecular = cp.varnishAlpha * (lerp(dot(IBLS,RGB2LUM),IBLS*albedo.xyz,0.68) * AmbientBRDF_UE4(0.32.xxx,cp.varnishRough,NoV) + NL*BRDF(cp.varnishRough,lerp(1.0,albedo.xyz,0.68),normal,lightNormal,viewNormal)*LightAmbient);	

	float RF = lerp(1,lerp(1,min(1,pow(saturate(1.468-NoV),5)+0.23),square(cp.roughness)),cp.reflectance);
	
	float3 selfLight = (exp(3.68888f * cp.selfLighting) - 1) * albedo.xyz * 0.25;
		
	odiff = float4((albedo.a>Epsilon)*((ShadowMapVal*diffuse + ao*ambientDiffuse)*RF + selfLight + trans),albedo.a);
	ospec = float4((albedo.a>Epsilon)*(ShadowMapVal*specular+ao*ambientSpecular+surfaceSpecular),cp.SSS);
}
						
void PBR_NONEALPHA_PS(float2 Tex: TEXCOORD0,out float4 odiff : COLOR0,out float4 ospec : COLOR1,out float4 lum : COLOR2)
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
	lum = float4(log(dot(RGB2LUM,outColor) + Epsilon),0,0,1);
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
		
		"RenderColorTarget0=AOWorkMap;"
    	"RenderDepthStencilTarget=mrt_Depth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=AOPass;"
		
		BLUR_PSSM_AO
		
		"RenderColorTarget0=Blur4WorkBuff1;"
		"RenderDepthStencilTarget=mrt_Depth;"
		"Pass=PBRALPHAFRONTPRECOMP;"
		
		"RenderColorTarget0=diffuseTexture;"
		"RenderColorTarget1=specularTexture;"
		"RenderColorTarget2=lumTexture;"
    	"RenderDepthStencilTarget=mrt_Depth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=PBRPRECOMP;"
		"RenderColorTarget1=;"
		"RenderColorTarget2=;" //mono:Do not forget to free it.
								
		SSSSS		
		
		#if SSDO_COLOR_BLEEDING > 0
		BLUR_COLOR_BLEEDING
		#endif
		
		DownSacleLumAdapt
		
		#if VOLUMETRIC_FOG_SAMPLE > 0
		FOG_RAYMARCH
		#endif
		
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
		PixelShader  = compile ps_3_0 COPY_PS(Depth_ALPHA_FRONT_GbufferSamp);
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
	
	AdaptLumPass
	
	pass ToneMapping < string Script= "Draw=Buffer;"; > 
	{
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
        VertexShader = compile vs_3_0 POST_VS();
		PixelShader  = compile ps_3_0 ToneMapping_PS();
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
	#if VOLUMETRIC_FOG_SAMPLE > 0
	FOGPASS
	#endif
}
