float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "postprocess";
> = 0.8;
///////////////////////////////////////////////////////////////////////////////////////////////
#include "headers\\environment.fxh"
///////////////////////////////////////////////////////////////////////////////////////////////
#define RGB2LUM float3(0.2125, 0.7154, 0.0721)
#define PI  3.14159265359f
#define invPi 0.31830988618
///////////////////////////////////////////////////////////////////////////////////////////////
float3 FOGXYZ         : CONTROLOBJECT < string name = "(self)"; string item="XYZ"; >;
static float FOG_G = max(0,FOGXYZ.x);
static float FOG_S = max(1.5,10.0 + FOGXYZ.y);
static float FOG_S2inv = 1/(FOG_S*FOG_S);
static float FOG_A = max(0,1+FOGXYZ.z);

float HDRSTRENGTH : CONTROLOBJECT < string name = "(self)"; string item = "Tr"; >;
float sss_correction : CONTROLOBJECT < string name = "(self)"; string item = "Si"; >;

float  AmbLightPower       : CONTROLOBJECT < string name = "Ambient.x"; string item="Si"; >;
float3 AmbColorXYZ         : CONTROLOBJECT < string name = "Ambient.x"; string item="XYZ"; >;
float3 AmbColorRxyz        : CONTROLOBJECT < string name = "Ambient.x"; string item="Rxyz"; >;
static float3 AmbientColor  = AmbLightPower*0.06;
static float3 AmbLightColor0 = AmbColorXYZ*0.01; 
static float3 AmbLightColor1 = AmbColorRxyz*1.8/3.141592; 
///////////////////////////////////////////////////////////////////////////////////////////////
texture2D mrt : RENDERCOLORTARGET <
	float2 ViewportRatio = {1.0, 1.0};
	string Format = "D3DFMT_A16B16G16R16F";
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
	string Format = "A16B16G16R16F";
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
	string Format = "A16B16G16R16F";
>;
sampler2D specularSamp = sampler_state {
    texture = <specularTexture>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV = CLAMP;
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
#include "headers\\SSSSS.fxh"
#include "headers\\fog.fxh"
#include "headers\\ACESToneMapping.fxh"
#include "headers\\AA.fxh"
///////////////////////////////////////////////////////////////////////////////////////////////
#include "pssm\\pssm.fxh"
#include "ssdo\\ssdo.fxh"
#include "headers\\blur.fxh"
///////////////////////////////////////////////////////////////////////////////////////////////
POST_OUTPUT POST_VS(float4 Pos : POSITION, float2 Tex : TEXCOORD0)
{
    POST_OUTPUT Out = (POST_OUTPUT)0;

	Out.Pos = Pos;
    Out.Tex = Tex + ViewportOffset;
    return Out;
}

float4 COPY_PS(float2 Tex: TEXCOORD0 ,uniform sampler2D Samp) : COLOR
{
	float4 color = tex2Dlod(Samp,float4(Tex,0,0));
	return color.xxxw;
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

void PBR_PS(float2 Tex: TEXCOORD0,out float4 odiff : COLOR0,out float4 ospec : COLOR1,out float4 lum : COLOR2)
{
	float4 sky = tex2D(MRTSamp,Tex);

	float4 albedo = tex2D(AlbedoGbufferSamp,Tex);
	float3 spa = tex2D(SpaGbufferSamp,Tex).xyz;
	float2 linearDepthXid = tex2D(DepthGbufferSamp,Tex).xy;
	float linearDepth = albedo.a < Epsilon ? 6666666:linearDepthXid.x;
	float id = linearDepthXid.y;
	float3 pos = coord2WorldViewPos(Tex,linearDepth);
	float3 wpos = mul(pos,(float3x3)ViewInverse);
	float3 normal = tex2D(NormalGbufferSamp,Tex).xyz;
	
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
	float3 ambientDiffuse =  albedo.xyz * Hemisphere + AmbientColor * albedo.xyz * IBLD * lerp(0.63212, 0, cp.metalness);
	float3 ambientSpecular = AmbientColor * IBLS * AmbientBRDF_UE4(spa * albedo.xyz, cp.roughness, NoV) * lerp(0.3679, 1, cp.metalness); //TBD
		
	IBL(viewNormal,normal,cp.varnishRough,IBLD,IBLS);
	float3 surfaceSpecular = cp.varnishAlpha * (lerp(dot(IBLS,RGB2LUM),IBLS*albedo.xyz,0.68) * AmbientBRDF_UE4(0.32.xxx,cp.varnishRough,NoV) + NL*BRDF(cp.varnishRough,lerp(1.0,albedo.xyz,0.68),normal,lightNormal,viewNormal)*LightAmbient);	
	
	float3 selfLight = (exp(3.68888f * cp.selfLighting) - 1) * albedo.xyz * 0.25;
		
	odiff = float4(albedo.a*(ShadowMapVal*diffuse + ao*ambientDiffuse + selfLight + trans) + (1-albedo.a)*sky.xyz,albedo.a);
	ospec = float4(albedo.a*(ShadowMapVal*specular+ao*ambientSpecular) + (albedo.a>0)*surfaceSpecular,cp.SSS);
	odiff.xyz *= 1-FOG_S2inv;
	ospec.xyz *= 1-FOG_S2inv;

	float3 outColor = odiff.xyz+ospec.xyz;
	lum = float4(log(dot(RGB2LUM,outColor) + Epsilon),0,0,1);
	return;
}
///////////////////////////////////////////////////////////////////////////////////////////////
#define BLUR_PSSM_AO \
		"RenderColorTarget0=BlurWorkBuff;" \
    	"RenderDepthStencilTarget=mrt_Depth;" \
		"ClearSetDepth=ClearDepth;Clear=Depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
    	"Pass=PSSMBilateralBlurX;" \
		\
		"RenderColorTarget0=ScreenShadowMapProcessed;" \
    	"RenderDepthStencilTarget=mrt_Depth;" \
		"ClearSetDepth=ClearDepth;Clear=Depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
    	"Pass=PSSMBilateralBlurY;"
///////////////////////////////////////////////////////////////////////////////////////////////

float4 ClearColor = {0,0,0,0};
float ClearDepth  = 1.0;

technique K3LS_COMP<

string Script = 		
        "RenderColorTarget0=mrt;"
    	"RenderDepthStencilTarget=mrt_Depth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
		
        "ScriptExternal=Color;"

		
		"RenderColorTarget0=AOWorkMap;"
    	"RenderDepthStencilTarget=mrt_Depth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=AOPass;"
		
		BLUR_PSSM_AO
		
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
		
		"RenderColorTarget0=lumHalfTexture;"
		"RenderDepthStencilTarget=lumHalfDepth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=DOHALFLUM;"
		
		"RenderColorTarget0=lumQuaterTexture;"
		"RenderDepthStencilTarget=lumQuaterDepth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=DOQuaterLUM;"
		
		"RenderColorTarget0=lum4x4Texture;"
		"RenderDepthStencilTarget=lum4x4Depth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=DO4x4LUM;"
		
		"RenderColorTarget0=adapted_lum;"
    	"RenderDepthStencilTarget=adapted_lum_Depth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=calcAL;"
		
		"RenderColorTarget0=FogWorkBuff;"
    	"RenderDepthStencilTarget=mrt_Depth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=FOGBLUR;"
		
		"RenderColorTarget0=mrt;"
    	"RenderDepthStencilTarget=mrt_Depth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=ToneMapping;"
		
		"RenderColorTarget0=;"
    	"RenderDepthStencilTarget=;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=AA;"
			
		ClearGbuffer
		;
>{
	pass TEST < string Script= "Draw=Buffer;"; > 
	{		
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
		VertexShader = compile vs_3_0 POST_VS();
		PixelShader  = compile ps_3_0 COPY_PS(FogDepthMapSampler);
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
        PixelShader  = compile ps_3_0 ShadowMapBlurAxyToTxy_PS(BlurWorkBuffSampler,float2(0.0f, ViewportOffset2.y));
    }

	
	pass PBRPRECOMP < string Script= "Draw=Buffer;"; > 
	{
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
        VertexShader = compile vs_3_0 POST_VS();
        PixelShader  = compile ps_3_0 PBR_PS();
    }
	
	
	pass DOHALFLUM < string Script= "Draw=Buffer;"; > 
	{		
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
		VertexShader = compile vs_3_0 POST_VS();
		PixelShader  = compile ps_3_0 DownScale_PS(lumSamp);
	}
	pass DOQuaterLUM < string Script= "Draw=Buffer;"; > 
	{		
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
		VertexShader = compile vs_3_0 POST_VS();
		PixelShader  = compile ps_3_0 DownScale_PS(lumHalfSamp);
	}
	pass DO4x4LUM < string Script= "Draw=Buffer;"; > 
	{		
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
		VertexShader = compile vs_3_0 POST_VS();
		PixelShader  = compile ps_3_0 DownScale_PS(lumQuaterSamp);
	}
	pass calcAL < string Script= "Draw=Buffer;"; > 
	{
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
        VertexShader = compile vs_3_0 POST_VS();
		PixelShader  = compile ps_3_0 LUM_PS();
    }
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
	
	pass AA < string Script= "Draw=Buffer;"; > 
	{
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
        VertexShader = compile vs_3_0 POST_VS();
        PixelShader  = compile ps_3_0 Antialias_PS();
    }

	pass FOGBLUR < string Script= "Draw=Buffer;"; > 
	{
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
        VertexShader = compile vs_3_0 POST_VS();
        PixelShader  = compile ps_3_0 FOG_PS();
    }
}
