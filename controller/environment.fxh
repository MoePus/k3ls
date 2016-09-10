// パラメータ宣言
float2 ViewportSize : VIEWPORTPIXELSIZE;
static float2 ViewportOffset = (float2(0.5,0.5)/ViewportSize);
float3   CameraPosition    : POSITION  < string Object = "Camera"; >;
float3   LightDirection    : DIRECTION < string Object = "Light"; >;
float3   LightAmbient      : AMBIENT   < string Object = "Light"; >;
const float PI = 3.14159265359f;
const float invPi = 0.31830988618;

sampler MMDSamp0 : register(s0);
sampler MMDSamp1 : register(s1);
sampler MMDSamp2 : register(s2);

uniform float4   MaterialDiffuse   : DIFFUSE  < string Object = "Geometry"; >;
uniform float3   MaterialAmbient   : AMBIENT  < string Object = "Geometry"; >;
uniform float3   MaterialEmmisive  : EMISSIVE < string Object = "Geometry"; >;
uniform float3   MaterialSpecular  : SPECULAR < string Object = "Geometry"; >;
uniform float    SpecularPower     : SPECULARPOWER < string Object = "Geometry"; >;
uniform float4   MaterialToon      : TOONCOLOR;
static	float4	DiffuseColor  = float4(MaterialDiffuse.rgb, saturate(MaterialDiffuse.a+0.01f));

float  AmbLightPower       : CONTROLOBJECT < string name = "Ambient.x"; string item="Si"; >;
float3 AmbColorXYZ         : CONTROLOBJECT < string name = "Ambient.x"; string item="XYZ"; >;
float3 AmbColorRxyz        : CONTROLOBJECT < string name = "Ambient.x"; string item="Rxyz"; >;

static float3 AmbientColor  = MaterialToon*MaterialEmmisive*AmbLightPower*5;
static float3 AmbLightColor0 = saturate(AmbColorXYZ*0.01); 
static float3 AmbLightColor1 = saturate(AmbColorRxyz*1.8/3.141592); 

#define SKYCOLOR AmbLightColor0.xyz
#define GROUNDCOLOR AmbLightColor1.xyz
// 空の向き
#define SKYDIR float3(0.0,1.0,0.0)

#include "BRDF.fxh"


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

shared texture2D ScreenShadowMapProcessed : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1,1};
    int MipLevels = 1;
    string Format = "D3DFMT_R16F";
>;
sampler2D ScreenShadowMapProcessedSamp = sampler_state {
    texture = <ScreenShadowMapProcessed>;
    MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = NONE;
    AddressU  = CLAMP; AddressV = CLAMP;
};

shared texture ScreenShadowMap: OFFSCREENRENDERTARGET;

sampler ScreenShadowMapSampler = sampler_state {
    texture = <ScreenShadowMap>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

shared texture2D SSAO_Tex3 : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0, 1.0};
    int MipLevels = 0;
    string Format = "D3DFMT_R16F";
>;
sampler2D SSAOSamp = sampler_state {
    texture = <SSAO_Tex3>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

float size0 : CONTROLOBJECT < string name = "ExcellentShadow.x"; string item = "Si"; >;
static float size1 = size0 * 0.1;

shared texture ExcellentShadowZMapFar : OFFSCREENRENDERTARGET;

sampler ExcellentShadowZMapFarSampler = sampler_state {
    texture = <ExcellentShadowZMapFar>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};



/*
shared texture2D K3LS_Translucency : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1,1};
    int MipLevels = 1;
    string Format = "D3DFMT_R16F";
>;
sampler2D TranslucencyLengthSamp = sampler_state {
    texture = <K3LS_Translucency>;
    MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = NONE;
    AddressU  = CLAMP; AddressV = CLAMP;
};*/


// 座法変換行列
float4x4 WorldViewProjMatrix      : WORLDVIEWPROJECTION;
float4x4 WorldMatrix              : WORLD;
float4x4 WorldMatrixInverse       : WORLDINVERSE;
float4x4 ViewMatrix               : VIEW;
//float4x4 LightWorldViewProjMatrix : WORLDVIEWPROJECTION < string Object = "Light"; >;
//float4x4 LightWorldViewMatrix     : WORLDVIEW < string Object = "Light"; >;


// 輪郭描画用テクニック
technique EdgeTec < string MMDPass = "edge"; > {}

// 影描画用テクニック
technique ShadowTec < string MMDPass = "shadow"; > {}