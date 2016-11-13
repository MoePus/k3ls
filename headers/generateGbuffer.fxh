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
sampler NorTexSampler = sampler_state {
    texture = <NormalTexure>;
    MINFILTER = ANISOTROPIC;
    MAGFILTER = ANISOTROPIC;
    MIPFILTER = ANISOTROPIC;
    MAXANISOTROPY = 16;
    ADDRESSU = WRAP;
    ADDRESSV = WRAP;
};


sampler MMDSamp0 : register(s0);
sampler MMDSamp1 : register(s1);
sampler MMDSamp2 : register(s2);
technique EdgeTec < string MMDPass = "edge"; > {}
technique ShadowTec < string MMDPass = "shadow"; > {}

///////////////////////////////////////////////////////////////////////////////////////////////
#define getCon(_id) \
float spaScale : CONTROLOBJECT < string name = "K3LS_A_con_"#_id".pmx"; string item = "spaScale"; >; \
float spaornormal : CONTROLOBJECT < string name = "K3LS_A_con_"#_id".pmx"; string item = "spa<->normal"; >; \
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

float3 NormalEncode(float3 N)
{
	return N * 0.5 + 0.5;
}

VS_OUTPUT Basic_VS(float4 Pos : POSITION, float3 Normal : NORMAL, float2 Tex : TEXCOORD0)
{
    VS_OUTPUT Out = (VS_OUTPUT)0;
    Out.oPos = Out.Pos = mul( Pos, WorldViewProjMatrix );

	Out.Normal = normalize( Normal);
    Out.Tex = Tex;
	Out.Eye = CameraPosition - mul( Pos, WorldMatrix ).xyz;
	
    return Out;
}


// 接空間取得
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

void Basic_PS(VS_OUTPUT IN,uniform const bool useTexture,uniform const bool useNormalMap,out GbufferParam gbuffer)
{
	if (useTexture) 
	{
        float4 TexColor = tex2D(ObjTexSampler, IN.Tex); 
        DiffuseColor = TexColor;
    }
	
	float2 scaledTex = IN.Tex*(1+spaScale*8.5f);
	float3 t = tex2D(NorTexSampler, scaledTex).xyz;
	float3 normal,spa;
	
	if(useNormalMap) 
	{
		if (spaornormal>=0.5) //Use for Normal
		{
			float3x3 tangentFrame = compute_tangent_frame(IN.Normal, IN.Eye, scaledTex);
			normal = 2.0f * t - 1;
			normal.rg *= ((spaornormal-0.5)*30);
			
			if(normal.b<0)
				normal.b = 1.0f;
			
			normal = normalize(normal);
			spa = (1-specularStrength).xxx;
			
			normal = normalize(mul(normal, tangentFrame));
		}
		else //Use for Spa
		{
			normal = IN.Normal;
			spa = t*2*(0.5-spaornormal)*(1-specularStrength);
		}
    }else
	{
	    normal = IN.Normal;
		spa = (1-specularStrength).xxx;
	}

	float alpha = DiffuseColor.a;
	
	gbuffer.albedo = DiffuseColor;
	gbuffer.depth = float4(IN.oPos.w,_id,0,1);
	gbuffer.spa = float4(spa,1);
	gbuffer.Normal = float4(normal,1);
	return;
}

#define GENTec(tecname,_mmdpass,_useTexture,_usespheremap) \
technique tecname < string MMDPass = _mmdpass; bool UseTexture = _useTexture; bool UseSphereMap = _usespheremap;\
 string Script = \
        "RenderColorTarget0=GBuffer_albedo;" \
        "RenderColorTarget1=GBuffer_linearDepth;" \
        "RenderColorTarget2=GBuffer_spa;" \
        "RenderColorTarget3=GBuffer_normal;" \
		"RenderDepthStencilTarget=GBuffer_depth;" \
        "Pass=DrawObject;" \
    ; \
> { \
    pass DrawObject {  VertexShader = compile vs_3_0 Basic_VS(); \
    PixelShader  = compile ps_3_0 Basic_PS(_useTexture,_usespheremap); }}

GENTec(MainTec0,"object",false,false)
GENTec(MainTec1,"object",true,false)
GENTec(MainTec2,"object",false,true)
GENTec(MainTec3,"object",true,true)

GENTec(MainTecBS0,"object_ss",false,false)
GENTec(MainTecBS1,"object_ss",true,false)
GENTec(MainTecBS2,"object_ss",false,true)
GENTec(MainTecBS3,"object_ss",true,true)