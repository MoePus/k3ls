sampler MMDSamp0 : register(s0);
sampler MMDSamp1 : register(s1);
sampler MMDSamp2 : register(s2);

#include "headers\\environment.fxh"

shared texture2D GBuffer_depth : RENDERDEPTHSTENCILTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    string Format = "D24S8";
>;

//////////////////////NO ALPHA/////////////////////////
shared texture2D GBuffer_albedo: RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
	float4 ClearColor = { 0, 0, 0, 0 };
	string Format = "A8R8G8B8";
>;

shared texture2D GBuffer_linearDepth: RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
	float4 ClearColor = { 0, 0, 0, 0 };
	string Format = NIR32F;
>;

shared texture2D GBuffer_spa: RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
	float4 ClearColor = { 0, 0, 0, 0 };
	string Format = NIR16F;
>;

shared texture2D GBuffer_normal: RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
	float4 ClearColor = { 0, 0, 0, 0 };
	string Format = NIR32F;
>;
//////////////////////NO ALPHA/////////////////////////

/////////////////////ALPHA FRAG////////////////////////
shared texture2D GBuffer_ALPHA_FRONT_albedo: RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
	float4 ClearColor = { 0, 0, 0, 0 };
	string Format = "A8R8G8B8";
>;

shared texture2D GBuffer_ALPHA_FRONT_linearDepth: RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
	float4 ClearColor = { 0, 0, 0, 0 };
	string Format = NIR32F;
>;

shared texture2D GBuffer_ALPHA_FRONT_spa: RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
	float4 ClearColor = { 0, 0, 0, 0 };
	string Format = NIR16F;
>;

shared texture2D GBuffer_ALPHA_FRONT_normal: RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
	float4 ClearColor = { 0, 0, 0, 0 };
	string Format = NIR32F;
>;
/////////////////////ALPHA FRAG////////////////////////


#include "headers\\GbufferClear.fxh"

float4 ClearColor = {0,0,0,0};
float4 ClearDepthColor = {1,1,1,0};
float ClearDepth  = 1.0;
technique buffer_init <
string Script = 		
		ClearGbuffer
		;
>{
}

