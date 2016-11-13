float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "postprocess";
> = 0.8;

float4x4 ProjectionInverse			: PROJECTIONINVERSE;
float4x4 ProjectionMatrix			: PROJECTION;
float4x4 ViewProjectionInverse		: VIEWPROJECTIONINVERSE;
float4x4 ViewMatrix					: VIEW;
float4x4 ViewInverse				: VIEWINVERSE;
float4x4 ViewProjMatrix				: VIEWPROJECTION;
float4x4 WorldViewProjMatrix		: WORLDVIEWPROJECTION;
float HDRSTRENGTH : CONTROLOBJECT < string name = "(self)"; string item = "Tr"; >;
float sss_correction : CONTROLOBJECT < string name = "(self)"; string item = "Si"; >;
float3 FOGXYZ         : CONTROLOBJECT < string name = "(self)"; string item="XYZ"; >;
static float FOG_G = max(0,FOGXYZ.x);
static float FOG_S = max(1.5,10.0 + FOGXYZ.y);
static float FOG_S2inv = 1/(FOG_S*FOG_S);
static float FOG_A = saturate(1.0 - FOGXYZ.z);

float2 ViewportSize : VIEWPORTPIXELSIZE;
static float2 ViewportOffset = (float2(0.5,0.5)/ViewportSize);
static float2 ViewportOffset2 = ViewportOffset * 2;
float3   CameraPosition    : POSITION  < string Object = "Camera"; >;
float3   LightDirection    : DIRECTION < string Object = "Light"; >;
float3	_LightAmbient		: AMBIENT   < string Object = "Light"; >;
static float3 LightAmbient = _LightAmbient * 2;

float  AmbLightPower       : CONTROLOBJECT < string name = "Ambient.x"; string item="Si"; >;
float3 AmbColorXYZ         : CONTROLOBJECT < string name = "Ambient.x"; string item="XYZ"; >;
float3 AmbColorRxyz        : CONTROLOBJECT < string name = "Ambient.x"; string item="Rxyz"; >;
static float3 AmbientColor  = AmbLightPower*0.06;
static float3 AmbLightColor0 = AmbLightPower*AmbColorXYZ*0.01; 
static float3 AmbLightColor1 = AmbLightPower*AmbColorRxyz*1.8/3.141592; 

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
#include "headers\\ACESToneMapping.fxh"
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
	return color;
}

void PBR_PS(float2 Tex: TEXCOORD0,out float4 odiff : COLOR0,out float4 ospec : COLOR1,out float4 lum : COLOR2)
{
	float4 sky = tex2D(MRTSamp,Tex);

	float4 albedo = tex2D(AlbedoGbufferSamp,Tex);
	float3 spa = tex2D(SpaGbufferSamp,Tex).xyz;
	float2 linearDepthXid = tex2D(DepthGbufferSamp,Tex).xy;
	float linearDepth = albedo.a<0.0001? 6666666:linearDepthXid.x;
	float id = linearDepthXid.y;
	float3 pos = coord2WorldViewPos(Tex,linearDepth);
	float3 normal = tex2D(NormalGbufferSamp,Tex).xyz;
	
	float2 shadowMap = tex2D(ScreenShadowMapProcessedSamp, Tex).xy;
	float ShadowMapVal = saturate(shadowMap.x);
	float ao = saturate(shadowMap.y);
	
	float3 view = CameraPosition - mul(pos,(float3x3)ViewInverse);
	float3 viewNormal = normalize(view);
	float3 lightNormal = normalize(-LightDirection);
	
	float NL = saturate(dot(lightNormal,normal));
	float LV = saturate(dot(lightNormal,viewNormal));
	
	ConParam cp;
	getConParams(id,cp);
	
	float3 cSpec = lerp(0.04,max(0.04,spa),cp.metalness);
	
	float3 diffuse = NL*albedo.xyz*invPi*DiffuseBRDF(cp.roughness,normal,lightNormal,viewNormal)*LightAmbient*(1-cp.metalness);
	float3 specular = NL*cSpec*BRDF(cp.roughness,albedo.xyz,normal,lightNormal,viewNormal)*LightAmbient*albedo.a;
	
	#define SKYDIR float3(0.0,1.0,0.0)
	float SdN = dot(SKYDIR,normal)*0.5f+0.5f;
	float3 Hemisphere = lerp(AmbLightColor1.xyz, AmbLightColor0.xyz, SdN*SdN);
	float3 IBLD,IBLS;
	IBL(viewNormal,normal,cp.roughness,IBLD,IBLS);
	
	float NoV = saturate(dot(normal,viewNormal));
	float3 ambientDiffuse =  albedo.xyz * Hemisphere + AmbientColor * albedo.xyz * IBLD * lerp(0.63212, 0, cp.metalness);
	float3 ambientSpecular = AmbientColor * IBLS * AmbientBRDF_UE4(spa * albedo.xyz, cp.roughness, NoV) * lerp(0.3679, 1, cp.metalness); //TBD
		
	IBL(viewNormal,normal,cp.varnishRough,IBLD,IBLS);
	float3 surfaceSpecular = cp.varnishAlpha * (dot(IBLS,RGB2LUM) * AmbientBRDF_UE4(1.0.xxx,cp.varnishRough,NoV) + NL*BRDF(cp.varnishRough,1.0.xxx,normal,lightNormal,viewNormal)*LightAmbient);	
	
	float3 selfLight = (exp(3.68888f * cp.selfLighting) - 1) * albedo.xyz * 0.25;
	
	
	float phaseFactor = 1/(4*PI) * (1 - FOG_G*FOG_G)/ pow(1 + FOG_G*FOG_G -2 * FOG_G * LV, 1.5);
	//\bwronski_volumetric_fog_siggraph2014/
	float viewDistance = length(view);
	float scatterFactor = -exp(-FOG_S*viewDistance*0.0000125)/FOG_S+1/FOG_S;
	float3 fog = LightAmbient * scatterFactor * phaseFactor * FOG_A;	
	
	
	odiff = float4(albedo.a*(ShadowMapVal*diffuse + ao*ambientDiffuse + selfLight) + (1-albedo.a)*sky.xyz,albedo.a);
	ospec = float4(albedo.a*(ShadowMapVal*specular+ao*ambientSpecular) + (albedo.a>0)*surfaceSpecular ,cp.SSS);
	odiff.xyz *= 1-FOG_S2inv;
	ospec.xyz *= 1-FOG_S2inv;
	
	//fog*=;
	
	ospec.xyz += fog;
	

	
	float3 outColor = odiff.xyz+ospec.xyz;
	lum = float4(log(dot(RGB2LUM,outColor)+0.001),0,0,1);
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
		"RenderColorTarget2=;" //NEED to free after malloc?
				
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
		

		"RenderColorTarget0=;"
    	"RenderDepthStencilTarget=;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=ToneMapping;"
			
		ClearGbuffer
		;
>{
	pass TEST < string Script= "Draw=Buffer;"; > 
	{		
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
		VertexShader = compile vs_3_0 POST_VS();
		PixelShader  = compile ps_3_0 DownScale_PS(DepthGbufferSamp);
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

}
