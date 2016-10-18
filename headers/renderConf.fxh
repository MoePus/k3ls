float  AmbLightPower       : CONTROLOBJECT < string name = "Ambient.x"; string item="Si"; >;
float3 AmbColorXYZ         : CONTROLOBJECT < string name = "Ambient.x"; string item="XYZ"; >;
float3 AmbColorRxyz        : CONTROLOBJECT < string name = "Ambient.x"; string item="Rxyz"; >;
static float3 AmbientColor  = MaterialToon*MaterialEmmisive*AmbLightPower*0.11;
static float3 AmbLightColor0 = saturate(AmbColorXYZ*0.01); 
static float3 AmbLightColor1 = saturate(AmbColorRxyz*1.8/3.141592); 

#define SKYCOLOR AmbLightColor0.xyz
#define GROUNDCOLOR AmbLightColor1.xyz
//////////// 空の向き ////////////
#define SKYDIR float3(0.0,1.0,0.0)

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

texture IBLDiffuseTexture <
    string ResourceName = "skybox\\skydiff.dds"; 
>;

sampler IBLDiffuseSampler = sampler_state {
    texture = <IBLDiffuseTexture>;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
	MIPFILTER = NONE;
    ADDRESSU  = CLAMP;  
    ADDRESSV  = CLAMP;
};

texture IBLSpecularTexture <
    string ResourceName = "skybox\\skyspec.dds"; 
	int MipLevels = 6;
>;
sampler IBLSpecularSampler = sampler_state {
    texture = <IBLSpecularTexture>;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
    MIPFILTER = LINEAR;
    ADDRESSU  = CLAMP;
    ADDRESSV  = CLAMP;
};


float2 computeSphereCoord(float3 normal)
{
    float2 coord = float2(1 - (atan2(normal.x, normal.z) * invPi * 0.5f + 0.5f), acos(normal.y) * invPi);
    return coord;
}

void IBL(float3 viewNormal, float3 normal,float roughness, out float3 diffuse, out float3 specular)
{
	float3 R = reflect(-viewNormal, normal);
	float mipLayer = lerp(0, 6, roughness);

	float2 coord = computeSphereCoord(R);
	diffuse = tex2D(IBLDiffuseSampler, coord);
    specular = tex2Dlod(IBLSpecularSampler, float4(coord, 0, mipLayer));
}



// 輪郭描画用テクニック
technique EdgeTec < string MMDPass = "edge"; > {}

// 影描画用テクニック
technique ShadowTec < string MMDPass = "shadow"; > {}