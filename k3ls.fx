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
float HDRSTRENGTH : CONTROLOBJECT < string name = "(self)"; string item = "Tr"; >;
float sss_correction : CONTROLOBJECT < string name = "(self)"; string item = "Si"; >;
float2 ViewportSize : VIEWPORTPIXELSIZE;
static float2 ViewportOffset = (float2(0.5,0.5)/ViewportSize);
float3   CameraPosition    : POSITION  < string Object = "Camera"; >;
float3   LightDirection    : DIRECTION < string Object = "Light"; >;
float3	_LightAmbient		: AMBIENT   < string Object = "Light"; >;
static float3 LightAmbient = _LightAmbient * 2;

float  AmbLightPower       : CONTROLOBJECT < string name = "Ambient.x"; string item="Si"; >;
float3 AmbColorXYZ         : CONTROLOBJECT < string name = "Ambient.x"; string item="XYZ"; >;
float3 AmbColorRxyz        : CONTROLOBJECT < string name = "Ambient.x"; string item="Rxyz"; >;
static float3 AmbientColor  = AmbLightPower*0.06;
static float3 AmbLightColor0 = AmbLightPower*saturate(AmbColorXYZ*0.01); 
static float3 AmbLightColor1 = AmbLightPower*saturate(AmbColorRxyz*1.8/3.141592); 

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
#include "pssm\\pssm.fxh"
///////////////////////////////////////////////////////////////////////////////////////////////
#include "headers\\math.fxh"
#include "headers\\BRDF.fxh"
#include "headers\\IBL.fxh"

#include "headers\\getControllerParams.fxh"
#include "headers\\GbufferTextures.fxh"
#include "headers\\GbufferSamplers.fxh"
#include "headers\\GbufferClear.fxh"

#include "headers\\SSSSS.fxh"
#include "headers\\ACESToneMapping.fxh"
///////////////////////////////////////////////////////////////////////////////////////////////
texture2D lumTexture : RENDERCOLORTARGET <
	float2 ViewportRatio = {1.0, 1.0};
	string Format = "R16F";
>;
sampler2D lumSamp = sampler_state {
    texture = <lumTexture>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};
///////////////////////////////////////////////////////////////////////////////////////////////

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
	float4 color = tex2Dlod(Samp,float4(Tex,0,0));
	return color;
}

void PBR_PS(float2 Tex: TEXCOORD0,out float4 odiff : COLOR0,out float4 ospec : COLOR1,out float4 lum : COLOR2)
{
	float4 sky = tex2D(MRTSamp,Tex);

	float4 albedo = tex2D(AlbedoGbufferSamp,Tex);
	float3 spa = tex2D(SpaGbufferSamp,Tex).xyz;
	float2 linearDepthXid = tex2D(DepthGbufferSamp,Tex).xy;
	float linearDepth = linearDepthXid.x;
	float id = linearDepthXid.y;
	float3 pos = coord2WorldViewPos(Tex,linearDepth);
	float3 normal = tex2D(NormalGbufferSamp,Tex).xyz;
	float2 shadowMap = tex2D(ScreenShadowMapProcessedSamp, Tex).xy;
	float ShadowMapVal = saturate(shadowMap.x);
	
	float3 viewNormal = normalize(CameraPosition - mul(pos,(float3x3)ViewInverse));
	float3 lightNormal = normalize(-LightDirection);
	
	float NL = saturate(dot(lightNormal,normal));
		
	ConParam cp;
	getConParams(id,cp);
	
	float3 cSpec = lerp(0.04,max(0.04,spa),cp.metalness);
	
	float3 diffuse = albedo.xyz*invPi*DiffuseBRDF(cp.roughness,normal,lightNormal,viewNormal)*LightAmbient*(1-cp.metalness);
	float3 specular = cSpec*BRDF(cp.roughness,albedo.xyz,normal,lightNormal,viewNormal)*LightAmbient*albedo.a;
	
	#define SKYDIR float3(0.0,1.0,0.0)
	float SdN = dot(SKYDIR,normal)*0.5f+0.5f;
	float3 Hemisphere = lerp(AmbLightColor0.xyz, AmbLightColor1.xyz, SdN*SdN);
	float3 IBLD,IBLS;
	IBL(viewNormal,normal,cp.roughness,IBLD,IBLS);
	float NoV = saturate(dot(normal,viewNormal));
	float3 ambientDiffuse =  albedo.xyz * Hemisphere + AmbientColor * albedo.xyz * IBLD * lerp(0.63212,0,cp.metalness);
	float3 ambientSpecular = AmbientColor * IBLS * AmbientBRDF_UE4(spa,sqrt(cp.roughness),NoV) * lerp(0.3679,1,cp.metalness); //TBD
	
	
	odiff = float4(albedo.a*(ShadowMapVal*diffuse+ambientDiffuse) + (1-albedo.a)*sky,albedo.a);
	ospec = float4(albedo.a*(ShadowMapVal*specular+ambientSpecular),cp.SSS);
	float3 outColor = odiff.xyz+ospec.xyz;
	lum = float4(log(dot(RGB2LUM,outColor)+0.001),0,0,1);
	return;
}




float4 ClearColor = {0,0,0,0};
float ClearDepth  = 1.0;

technique K3LS_COMP<

string Script = 		
        "RenderColorTarget0=mrt;"
    	"RenderDepthStencilTarget=mrt_Depth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
		
        "ScriptExternal=Color;"

		GENPSSM
		
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
		PixelShader  = compile ps_3_0 COPY_PS(lumHalfSamp);
	}
	pass PBRPRECOMP < string Script= "Draw=Buffer;"; > 
	{
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
        VertexShader = compile vs_3_0 POST_VS();
        PixelShader  = compile ps_3_0 PBR_PS();
		//PixelShader  = compile ps_3_0 COPY_PS(TransObjSamp);
    }
	pass DOHALFLUM < string Script= "Draw=Buffer;"; > 
	{		
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
		VertexShader = compile vs_3_0 POST_VS();
		PixelShader  = compile ps_3_0 COPY_PS(lumSamp);
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
	pass PSSMBilateralBlurX < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
        VertexShader = compile vs_3_0 POST_VS();
        PixelShader  = compile ps_3_0 ShadowMapBlurPS(ScreenShadowMapSampler,float2(2*ViewportOffset.x, 0.0f));
    }
	
	pass PSSMBilateralBlurY < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
        VertexShader = compile vs_3_0 POST_VS();
        PixelShader  = compile ps_3_0 ShadowMapBlurPS(ScreenShadowWorkBuffSampler,float2(0.0f, 2*ViewportOffset.y));
    }
}
