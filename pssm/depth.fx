#include "..\\headers\\environment.fxh"

uniform float4   MaterialDiffuse   : DIFFUSE  < string Object = "Geometry"; >;
uniform float3   MaterialAmbient   : AMBIENT  < string Object = "Geometry"; >;
uniform float3   MaterialEmmisive  : EMISSIVE < string Object = "Geometry"; >;
uniform float3   MaterialSpecular  : SPECULAR < string Object = "Geometry"; >;
uniform float    SpecularPower     : SPECULARPOWER < string Object = "Geometry"; >;
uniform float4   MaterialToon      : TOONCOLOR;
static	float4	DiffuseColor  = float4(MaterialDiffuse.rgb, saturate(MaterialDiffuse.a+0.01f));

sampler MMDSamp0 : register(s0);
sampler MMDSamp1 : register(s1);
sampler MMDSamp2 : register(s2);

texture DiffuseMap: MATERIALTEXTURE;
sampler DiffuseMapSamp = sampler_state {
	texture = <DiffuseMap>;
	MinFilter = POINT;	MagFilter = POINT;	MipFilter = POINT;
	ADDRESSU  = WRAP;	ADDRESSV  = WRAP;
};


void CascadeShadowMapVS(
    in float4 Position : POSITION,
    in float3 Normal : NORMAL,
    in float2 Texcoord : TEXCOORD0,
    out float4 oTexcoord0 : TEXCOORD0,
    out float4 oTexcoord1 : TEXCOORD1,
    out float4 oPosition : POSITION,
    uniform int3 offset)
{
    float cosAngle = 1 - saturate(dot(Normal, -LightDirection));
    
    oPosition = mul(Position + float4(Normal * cosAngle * 0.02, 0), matLightViewProject);
    oPosition.xy = oPosition.xy * lightParam[offset.z].xy + lightParam[offset.z].zw;
    oPosition.xy = oPosition.xy * 0.5 + (offset.xy * 0.5f);
   
    oTexcoord1 = oPosition;
    oTexcoord0 = float4(Texcoord, offset.xy);
}

float4 CascadeShadowMapPS(float4 coord0 : TEXCOORD0, float4 position : TEXCOORD1, uniform bool useTexture) : COLOR
{
    float2 clipUV = (position.xy - SHADOW_MAP_OFFSET) * coord0.zw;
    clip(clipUV.x);
    clip(clipUV.y);
    clip(!opadd - 0.001f);


    float alpha = MaterialDiffuse.a;
    if ( useTexture ) alpha *= tex2D(DiffuseMapSamp, coord0.xy).a;
    //clip(alpha - CasterAlphaThreshold);

    return float4(position.z,0,0,alpha);
}

#define alphaCliper \
AlphaFunc = GREATER; \
AlphaRef = CasterAlphaThreshold; \
AlphaBlendEnable = false; 

#define PSSM_TEC(name, mmdpass, tex) \
    technique name < string MMDPass = mmdpass; bool UseTexture = tex; \
    > { \
        pass CascadeShadowMap0 { \
			alphaCliper \
            AlphaBlendEnable = false; AlphaTestEnable = false; \
            VertexShader = compile vs_3_0 CascadeShadowMapVS(int3(-1, 1, 0)); \
            PixelShader  = compile ps_3_0 CascadeShadowMapPS(tex); \
        } \
        pass CascadeShadowMap1 { \
			alphaCliper \
            AlphaBlendEnable = false; AlphaTestEnable = false; \
            VertexShader = compile vs_3_0 CascadeShadowMapVS(int3( 1, 1, 1)); \
            PixelShader  = compile ps_3_0 CascadeShadowMapPS(tex); \
        } \
        pass CascadeShadowMap2 { \
			alphaCliper \
            AlphaBlendEnable = false; AlphaTestEnable = false; \
            VertexShader = compile vs_3_0 CascadeShadowMapVS(int3(-1,-1, 2)); \
            PixelShader  = compile ps_3_0 CascadeShadowMapPS(tex); \
        } \
        pass CascadeShadowMap3 { \
			alphaCliper \
            AlphaBlendEnable = false; AlphaTestEnable = false; \
            VertexShader = compile vs_3_0 CascadeShadowMapVS(int3( 1,-1, 3)); \
            PixelShader  = compile ps_3_0 CascadeShadowMapPS(tex); \
        } \
    }

PSSM_TEC(DepthTecBS2, "object_ss", false)
PSSM_TEC(DepthTecBS3, "object_ss", true)

technique DepthTec0 < string MMDPass = "object"; >{}
technique EdgeTec < string MMDPass = "edge"; > {}
technique ShadowTec < string MMDPass = "shadow"; > {}
technique ZplotTec < string MMDPass = "zplot"; > {}