/////////////////////////////////////////
///////Got this From Ray-mmd shader//////
///////		and	From ikPolishShader//////
/////////////////////////////////////////
#include "pssm\\config.fxh"

texture ScreenShadowMap : OFFSCREENRENDERTARGET <
    string Description = "PSSM";
    float2 ViewPortRatio = {1.0, 1.0};
    string Format = "A16B16G16R16F";
    float4 ClearColor = { 1, 0, 0, 0 };
    float ClearDepth = 1.0;
    int MipLevels = 1;
    string DefaultEffect =
        "self = hide;"
        "skybox*.* = hide;"
        "*.pmx=pssm\\object.fx;"
        "*.pmd=pssm\\object.fx;"
        "*.x=hide;";
>;
sampler ScreenShadowMapSampler = sampler_state {
    texture = <ScreenShadowMap>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

shared texture PSSMDepth : OFFSCREENRENDERTARGET <
    string Description = "PSSMDepth";
	int Width = SHADOW_MAP_SIZE;
    int Height = SHADOW_MAP_SIZE;
    string Format = "R32F";
    float4 ClearColor = { 0, 0, 0, 0 };
    float ClearDepth = 1.0;
    int MipLevels = 1;
    string DefaultEffect =
        "self = hide;"
        "skybox*.* = hide;"
        "*.pmx=pssm\\depth.fx;"
        "*.pmd=pssm\\depth.fx;"
        "*.x=hide;";
>;
sampler PSSMsamp = sampler_state {
	texture = <PSSMDepth>;
	MinFilter = LINEAR;	MagFilter = LINEAR;	MipFilter = NONE;
	AddressU  = CLAMP;	AddressV = CLAMP;
};


texture2D ScreenShadowMapProcessed : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    string Format = "G16R16F";
>;
sampler2D ScreenShadowMapProcessedSamp = sampler_state {
    texture = <ScreenShadowMapProcessed>;
    MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = NONE;
    AddressU  = CLAMP; AddressV = CLAMP;
};