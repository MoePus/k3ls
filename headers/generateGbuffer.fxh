#include "..\\headers\\environment.fxh"

uniform	float4	MaterialDiffuse   : DIFFUSE  < string Object = "Geometry"; >;
static	float4	DiffuseColor  = float4(MaterialDiffuse.rgb, saturate(MaterialDiffuse.a+0.01f));

texture ObjectTexture: MATERIALTEXTURE;
sampler ObjTexSampler = sampler_state {
    texture = <ObjectTexture>;
    MINFILTER = ANISOTROPIC;
    MAGFILTER = ANISOTROPIC;
    MIPFILTER = LINEAR;
    MAXANISOTROPY = 16;
};
texture2D NormalTexure: MATERIALSPHEREMAP;
sampler NorSampler = sampler_state {
    texture = <NormalTexure>;
    MINFILTER = ANISOTROPIC;
    MAGFILTER = ANISOTROPIC;
    MIPFILTER = ANISOTROPIC;
    MAXANISOTROPY = 16;
    ADDRESSU = WRAP;
    ADDRESSV = WRAP;
};
texture ObjectToonTexture : MATERIALTOONTEXTURE;
sampler ObjToonSampler = sampler_state{
    texture = <ObjectToonTexture>;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
    MIPFILTER = NONE;
    ADDRESSU  = CLAMP;
    ADDRESSV  = CLAMP;
};

sampler MMDSamp0 : register(s0);
sampler MMDSamp1 : register(s1);
sampler MMDSamp2 : register(s2);
technique EdgeTec < string MMDPass = "edge"; > {}
technique ShadowTec < string MMDPass = "shadow"; > {}

///////////////////////////////////////////////////////////////////////////////////////////////
#define getCon(_id) \
float normalScale : CONTROLOBJECT < string name = "K3LS_A_con_"#_id".pmx"; string item = "normalScale"; >; \
float normalStrength : CONTROLOBJECT < string name = "K3LS_A_con_"#_id".pmx"; string item = "normalStrength"; >; \
float specularStrength : CONTROLOBJECT < string name = "K3LS_A_con_"#_id".pmx"; string item = "specularStrength"; >;

getCon(_id)
///////////////////////////////////////////////////////////////////////////////////////////////

struct GbufferParam
{
    float4 albedo	:	COLOR0;
    float4 depth	:	COLOR1;
	float4 spa		:	COLOR2;
	float4 Normal	:	COLOR3;
};

struct VS_OUTPUT {
    float4 Pos			: POSITION;
    float2 Tex			: TEXCOORD1;
    float4 oPos			: TEXCOORD2;
	float3 Normal		: TEXCOORD3;
	float3 Eye			: TEXCOORD4;
};

VS_OUTPUT Basic_VS(float4 Pos : POSITION, float3 Normal : NORMAL, float2 Tex : TEXCOORD0)
{
    VS_OUTPUT Out = (VS_OUTPUT)0;
    Out.oPos = Out.Pos = mul( Pos, ViewProjectMatrix );

	Out.Normal = normalize( Normal);
    Out.Tex = Tex;
	Out.Eye = CameraPosition - Pos.xyz;
	
    return Out;
}


inline float3x3 compute_tangent_frame(float3 Normal, float3 View, float2 UV)
{
    float3 dp1 = ddx(View);
    float3 dp2 = ddy(View);
    float2 duv1 = ddx(UV);
    float2 duv2 = ddy(UV);

    float3x3 M = float3x3(dp1, dp2, cross(dp1, dp2));
    float2x3 inverseM = float2x3(cross(M[1], M[2]), cross(M[2], M[0]));
    float3 Tangent = mul(float2(duv1.x, duv2.x), inverseM);
    float3 Binormal = mul(float2(duv1.y, duv2.y), inverseM);

    return float3x3(normalize(Tangent), normalize(Binormal), Normal);
}

void Basic_PS(VS_OUTPUT IN,uniform const bool useTexture,uniform const bool useNormalMap,uniform const bool usespa,out GbufferParam gbuffer)
{
	if (useTexture) 
	{
        float4 TexColor = tex2D(ObjTexSampler, IN.Tex); 
        DiffuseColor.xyz *= TexColor.xyz;
		DiffuseColor.a = TexColor.a;
    }
	
	float3 normal,spa;
	float roughnessFactor = 0;
	
	if(useNormalMap) 
	{
		float2 scaledTex = IN.Tex*(1+normalScale*10.0f);
		float3 t = tex2D(NorSampler, scaledTex).xyz;
		float3x3 tangentFrame = compute_tangent_frame(IN.Normal, IN.Eye, scaledTex);
		normal = 2.0f * t - 1;
		normal.rg *= ((0.5-normalStrength)*30);
		if(normal.b<0)//If the user wrongly used a spa map as a normal map.Correct it.
			normal = float3(0,0,1);
		normal = mul(normalize(normal), tangentFrame);
    }else
	{
		normal = IN.Normal;
	}
	normal = normalize(normal);
	
	if(usespa)
	{
		float4 t = tex2D(ObjToonSampler, IN.Tex);
		spa = t.xyz * (1-specularStrength);
		roughnessFactor = (1-t.w)/10.0;
	}
	else
	{
		spa = 1-specularStrength;
	}

	float alpha = DiffuseColor.a;
	clip(alpha>=1-Epsilon?1:-1);
	
	float spaShineness = dot(spa, RGB2LUM);
	gbuffer.albedo = DiffuseColor;
	gbuffer.depth = float4(IN.oPos.w/SCENE_ZFAR,_id+roughnessFactor,0,0);
	gbuffer.spa = float4(spaShineness,normal.z,0,0);
	gbuffer.Normal = float4(normal.xy,0,0);
	return;
}

void ALPHA_OBJECT_PS(VS_OUTPUT IN,uniform const bool useTexture,uniform const bool useNormalMap,uniform const bool usespa,out GbufferParam gbuffer)
{
	if (useTexture) 
	{
        float4 TexColor = tex2D(ObjTexSampler, IN.Tex); 
        DiffuseColor = TexColor;
    }

	float3 normal,spa;
	float roughnessFactor = 0;
	
	if(useNormalMap) 
	{
		float2 scaledTex = IN.Tex*(1+normalScale*10.0f);
		float3 t = tex2D(NorSampler, scaledTex).xyz;
		float3x3 tangentFrame = compute_tangent_frame(IN.Normal, IN.Eye, scaledTex);
		normal = 2.0f * t - 1;
		normal.rg *= ((0.5-normalStrength)*30);
		if(normal.b<0)
			normal = float3(0,0,1);
		normal = mul(normalize(normal), tangentFrame);
    }else
	{
		normal = IN.Normal;
	}
	normal = normalize(normal);
	
	if(usespa)
	{
		float4 t = tex2D(ObjToonSampler, IN.Tex);
		spa = t.xyz * (1-specularStrength);
		roughnessFactor = (1-t.w)/10.0;
	}
	else
	{
		spa = 1-specularStrength;
	}
	
	float alpha = DiffuseColor.a;
	clip(alpha>=1-Epsilon || alpha<Epsilon?-1:1);
	
	float spaShineness = dot(spa, RGB2LUM);
	gbuffer.albedo = DiffuseColor;
	gbuffer.depth = float4(IN.oPos.w/SCENE_ZFAR,_id+roughnessFactor,0,1);
	gbuffer.spa = float4(spaShineness,normal.z,0,1);
	gbuffer.Normal = float4(normal.xy,0,1);
	return;
}

#define GENTec(tecname, _mmdpass, _useTexture, _usespheremap, _usetoonmap) \
technique tecname < string MMDPass = #_mmdpass; bool UseTexture = _useTexture; bool UseSphereMap = _usespheremap; bool UseToon = _usetoonmap;\
 string Script = \
        "RenderColorTarget0=GBuffer_albedo;" \
        "RenderColorTarget1=GBuffer_linearDepth;" \
        "RenderColorTarget2=GBuffer_spa;" \
        "RenderColorTarget3=GBuffer_normal;" \
		"RenderDepthStencilTarget=GBuffer_depth;" \
        "Pass=DrawObject;" \
		\
		"RenderColorTarget0=GBuffer_ALPHA_FRONT_albedo;" \
        "RenderColorTarget1=GBuffer_ALPHA_FRONT_linearDepth;" \
        "RenderColorTarget2=GBuffer_ALPHA_FRONT_spa;" \
        "RenderColorTarget3=GBuffer_ALPHA_FRONT_normal;" \
		"RenderDepthStencilTarget=GBuffer_depth;" \
        "Pass=Draw_ALPHA_FRONT_Object;" \
    ; \
> { \
    pass DrawObject {  \
	AlphaBlendEnable = false; \
	VertexShader = compile vs_3_0 Basic_VS(); \
    PixelShader  = compile ps_3_0 Basic_PS(_useTexture,_usespheremap,_usetoonmap); } \
	\
	pass Draw_ALPHA_FRONT_Object {  \
	VertexShader = compile vs_3_0 Basic_VS(); \
    PixelShader  = compile ps_3_0 ALPHA_OBJECT_PS(_useTexture,_usespheremap,_usetoonmap); }}


GENTec(MainTec0,object,false,false,false)
GENTec(MainTec1,object,true,false,false)
GENTec(MainTec2,object,false,true,false)
GENTec(MainTec3,object,true,true,false)
GENTec(MainTec4,object,false,false,true)
GENTec(MainTec5,object,true,false,true)
GENTec(MainTec6,object,false,true,true)
GENTec(MainTec7,object,true,true,true)

GENTec(MainTecBS0,object_ss,false,false,false)
GENTec(MainTecBS1,object_ss,true,false,false)
GENTec(MainTecBS2,object_ss,false,true,false)
GENTec(MainTecBS3,object_ss,true,true,false)
GENTec(MainTecBS4,object_ss,false,false,true)
GENTec(MainTecBS5,object_ss,true,false,true)
GENTec(MainTecBS6,object_ss,false,true,true)
GENTec(MainTecBS7,object_ss,true,true,true)