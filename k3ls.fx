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
static float3 AmbientColor  = AmbLightPower*0.25;
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
	string Format = "G32R32F";
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
#include "headers\\pssm.fxh"
#include "headers\\ssdo.fxh"
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
	float4 depthmap = float4(
	tex2D(DepthGbufferSamp,Tex).xy,
	tex2D(Depth_ALPHA_FRONT_GbufferSamp,Tex).xy
	);

	float3 N1 = tex2D(NormalGbufferSamp,Tex).xyz;
	float3 N2 = tex2D(Normal_ALPHA_FRONT_GbufferSamp,Tex).xyz;

	if(depthmap.z<=depthmap.x)
	{
		Depth = float4(depthmap.z * SCENE_ZFAR,depthmap.w,0,1);
		N = float4(N2,1);
	}else
	{
		Depth = float4(depthmap.x * SCENE_ZFAR,depthmap.y,0,1);
		N = float4(N1,1);
	}
	return;
}
float4 COPY_PS(float2 Tex: TEXCOORD0 ,uniform sampler2D Samp) : COLOR
{

	float4 c = tex2D(Samp,Tex);
	return float4(c.rgb,1);
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

inline void PBR_shade(float id,float roughness,float metalness,float2 Tex,float3 view,float3 wpos,float4 albedo,float spa,float3 normal,
out float4 odiff,
out float4 ospec
)
{
	albedo.xyz = srgb2linear(albedo.xyz);
	albedo.xyz = max(albedo.xyz,0.002.xxx);//note: there is no pure black in the world.
	
	float2 shadowMap = tex2D(ScreenShadowMapProcessedSamp, Tex).xy;
	float ShadowMapVal = saturate(shadowMap.x);
	float ao = saturate(shadowMap.y);
	
	float3 viewNormal = normalize(view);
	float3 lightNormal = normalize(-LightDirection);

	float NL = saturate(dot(lightNormal,normal));
	float LV = dot(lightNormal,viewNormal);

	ConParam cp;
	getConParams(id,cp);
	
	float3 f0 = lerp(0.04,max(0.04,spa)*(albedo.xyz*0.68169+0.31831),metalness);

	float en = lerp(DiffuseBRDF(roughness,normal,lightNormal,viewNormal),DiffuseBSDF(roughness,normal,lightNormal,viewNormal),min(1,Epsilon+cp.SSS*0.85));
	float3 diffuse = NL*albedo.xyz*invPi*en*LightAmbient*(1-metalness);
	float3 specular = NL*BRDF(roughness,f0,normal,lightNormal,viewNormal)*LightAmbient;
	
	float irradiance = max(0.3 + dot(-normal, lightNormal), 0.0);
	float3 trans = CalcTranslucency((1-ShadowMapVal)/cp.translucency)*irradiance*albedo.xyz * 0.532 *step(Epsilon,cp.translucency);//Wrong but beautiful.
	
	#define SKYDIR float3(0.0,1.0,0.0)
	float SdN = dot(SKYDIR,normal)*0.5f+0.5f;
	float3 Hemisphere = lerp(AmbLightColor1.xyz, AmbLightColor0.xyz, SdN*SdN);
	float3 IBLD,IBLS;
	IBL(viewNormal,normal,roughness,IBLD,IBLS);
	
	float NoV = saturate(dot(normal,viewNormal));
	float3 ambientDiffuse =  albedo.xyz * Hemisphere + AmbientColor * albedo.xyz * IBLD * lerp(0.85, 0, metalness)*(1 - diffAmbientMinus);
	float3 ambientSpecular = AmbientColor * IBLS * AmbientBRDF_UE4(spa * albedo.xyz, roughness, NoV) * lerp(0.15, 1, metalness)*(1 - specAmbientMinus); //TBD
		
	IBL(viewNormal,normal,cp.varnishRough,IBLD,IBLS);
	float3 surfaceSpecular = cp.varnishAlpha * (lerp(dot(IBLS,RGB2LUM),IBLS*albedo.xyz,0.68) * AmbientBRDF_UE4(0.32.xxx,cp.varnishRough,NoV) + NL*BRDF(cp.varnishRough,lerp(1.0,albedo.xyz,0.68),normal,lightNormal,viewNormal)*LightAmbient);	

	float RF = lerp(1,lerp(1,min(1,pow(saturate(1.468-NoV),5)+0.23),square(roughness)),cp.reflectance);
	
	float3 selfLight = (exp(3.68888f * cp.selfLighting) - 1) * albedo.xyz * 0.25;
		
	odiff = float4((albedo.a>Epsilon)*((ShadowMapVal*diffuse + ao*ambientDiffuse)*RF + selfLight + trans),albedo.a);
	ospec = float4((albedo.a>Epsilon)*(ShadowMapVal*specular+ao*ambientSpecular+surfaceSpecular),cp.SSS);
}

void PBR_NONEALPHA_PS(float2 Tex: TEXCOORD0,out float4 odiff : COLOR0,out float4 ospec : COLOR1)
{
	float4 sky = tex2D(MRTSamp,Tex);

	float4 albedo = tex2D(AlbedoGbufferSamp,Tex);
	float4 spaMap = tex2D(SpaGbufferSamp,Tex);
	float3 normal = tex2D(NormalGbufferSamp,Tex).xyz;
	float spa = spaMap.x;
	float roughness = spaMap.y;
	float metalness = spaMap.z;
	float2 linearDepthXid = tex2D(DepthGbufferSamp,Tex).xy;
	float linearDepth = linearDepthXid.x * SCENE_ZFAR;
	float id = linearDepthXid.y;
	float3 vpos = coord2WorldViewPos(Tex - ViewportOffset,linearDepth);
	float3 wpos = mul(vpos,(float3x3)ViewInverse);
	float3 view = CameraPosition - wpos;
	
	PBR_shade(id,roughness,metalness,Tex,view,wpos,albedo,spa,normal,odiff,ospec);
	
	float4 alphaLight = tex2D(Blur4WorkBuff1Sampler,Tex);
	odiff.xyz += (1-albedo.a)*sky.xyz;
	
	float Depth1 = tex2D(DepthGbufferSamp,Tex).x * SCENE_ZFAR;
	float Depth2 = tex2D(Depth_ALPHA_FRONT_GbufferSamp,Tex).x * SCENE_ZFAR;
	if(Depth2<=Depth1)
	{
		odiff.xyz*=(1-alphaLight.a);
		ospec = float4(ospec.xyz*(1-alphaLight.a)+alphaLight.xyz*alphaLight.a,
		0);
	}
	return;
}

void PBR_ALPHAFRONT_PS(float2 Tex: TEXCOORD0,out float4 ocolor : COLOR0)
{
	float4 albedo = tex2D(Albedo_ALPHA_FRONT_GbufferSamp,Tex);

	float4 spaMap = tex2D(Spa_ALPHA_FRONT_GbufferSamp,Tex);
	float3 normal = tex2D(Normal_ALPHA_FRONT_GbufferSamp,Tex).xyz;
	float spa = spaMap.x;
	float roughness = spaMap.y;
	float metalness = spaMap.z;
	float2 linearDepthXid = tex2D(Depth_ALPHA_FRONT_GbufferSamp,Tex).xy;
	float linearDepth = linearDepthXid.x * SCENE_ZFAR;
	float id = linearDepthXid.y;
	float3 vpos = coord2WorldViewPos(Tex - ViewportOffset,linearDepth);
	float3 wpos = mul(vpos,(float3x3)ViewInverse);
	float3 view = CameraPosition - wpos;
	
	float4 odiff,ospec;
	PBR_shade(id,roughness,metalness,Tex,view,wpos,albedo,spa,normal,odiff,ospec);

	ocolor = float4(odiff.xyz+ospec.xyz,albedo.a);
	return;
}

texture AL_EmitterRT: OFFSCREENRENDERTARGET <
    string Description = "EmitterDrawRenderTarget for AutoLuminous.fx";
    float2 ViewPortRatio = {1.0,1.0};
    float4 ClearColor = { 0, 0, 0, 1 };
    float ClearDepth = 1.0;
    bool AntiAlias = false;
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
	highLight.xyz += max(0,ocolor.xyz*1.1-11.5+10*HDRSTRENGTH)/max(0.95,l*0.032);
	highLight.xyz *= 1.2;
	highLight.a = 1;
	return;
}
		

// texture2D HalfResSSR: RENDERCOLORTARGET <
    // float2 ViewPortRatio = {0.9,0.9};
	// string Format = YOR16F;
// >;	
// sampler HalfResSSRSamp = sampler_state {
    // texture = <HalfResSSR>;
    // MinFilter = POINT;
	// MagFilter = POINT;
	// MipFilter = NONE;
    // AddressU  = CLAMP;
	// AddressV  = CLAMP;
// };	
// float3 SSRRayTraceHitPosPercent(float2 startSSPos,float3 normal,float linearDepth)
// {
	// float3 vpos = coord2WorldViewPos(startSSPos,linearDepth);
	// float3 wpos = mul(vpos,(float3x3)ViewInverse);
	// float3 view = CameraPosition - wpos;
	// float3 viewNormal = -normalize(view);
	// float3 worldReflect = normalize(reflect(viewNormal, normal));

	// float3 startpos = wpos;
	// float3 delta = linearDepth*1.5*worldReflect;
	// float3 endpos = startpos + delta;
	
	// const static float2 oneEighthRes = ViewportSize * 0.15;
	// float3 startsspos = worldPos2coord(startpos);
	// float3 endsspos = worldPos2coord(endpos);
	// float3 mstep = (endsspos - startsspos) / oneEighthRes.x;
	// float3 currentpos = startsspos + mstep * 1;
	
	// float interval = linearDepth * 1.7 / oneEighthRes.x;
	// float hit = 0;
	// float i = 1.0;
	// for(;i<oneEighthRes.x*0.5;i+=1.0)
	// {
		// float dz = tex2Dlod(sumDepthSamp,float4(currentpos.xy,0,0));
		// if(dz-currentpos.z<Epsilon)
		// float dif = abs(dz-currentpos.z);
		// if(dif<interval)
		// {
			// hit = 1;
			// break;
		// }
		// currentpos += mstep;
	// }
	
	// hit *= step(Epsilon,dot(viewNormal,worldReflect));
	// hit *= min(0.1,dot(currentpos.x,1.0))*10.0;
	// hit *= min(0.1,dot(currentpos.y,1.0))*10.0;
	// hit *= min(0.1,dot(currentpos.x,0.0))*10.0;
	// hit *= min(0.1,dot(currentpos.y,0.0))*10.0;
	// if(dot(viewNormal,worldReflect)<=0|| min(currentpos.x,currentpos.y)<0 || max(currentpos.x,currentpos.y)>1)
	// {
		// hit = 0;
	// }
	// return float3(currentpos.xy,hit);
// }

// float4 SSRRayTracing_PS(float2 Tex: TEXCOORD0) :COLOR
// {
	// float3 normal = tex2D(sumNormalSamp,Tex).xyz;
	// float linearDepth = tex2D(sumDepthSamp,Tex).x;
	
	// float3 hit = SSRRayTraceHitPosPercent(Tex - ViewportOffset,normal,linearDepth);
	
	// float4 c = tex2D(MRTSamp,hit.xy);
	// return c*hit.zzzz;
// }

// #define SSR_RAYTRACING_PASS\
	// pass SSR_RAYTRACING < string Script= "Draw=Buffer;"; >   \
	// {	\
		// AlphaBlendEnable = FALSE;  \
		// ZFUNC=ALWAYS;  \
		// ALPHAFUNC=ALWAYS;  \
		// VertexShader = compile vs_3_0 POST_VS();  \
		// PixelShader  = compile ps_3_0 SSRRayTracing_PS();  \
	// }
	
// #define SSR_HT \
		// "RenderColorTarget0=HalfResSSR;" \
    	// "RenderDepthStencilTarget=mrt_Depth;" \
		// "ClearSetDepth=ClearDepth;Clear=Depth;" \
		// "ClearSetColor=ClearColor;Clear=Color;" \
    	// "Pass=SSR_RAYTRACING;" \

///////////////////////////////////////////////////////////////////////////////////////////////
#include "headers\\bloom.fxh"
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

		/*SSR_HT*/
		
		// "RenderColorTarget0=;"
    	// "RenderDepthStencilTarget=;"
		// "ClearSetDepth=ClearDepth;Clear=Depth;"
		// "ClearSetColor=ClearColor;Clear=Color;"
    	// "Pass=TEST;"
		
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
		PixelShader  = compile ps_3_0 COPY_PS(AlbedoGbufferSamp);
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
	// SSR_RAYTRACING_PASS
}	