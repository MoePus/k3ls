sampler MMDSamp0 : register(s0);
sampler MMDSamp1 : register(s1);
sampler MMDSamp2 : register(s2);

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
	string Format = "G32R32F";
>;

shared texture2D GBuffer_spa: RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
	float4 ClearColor = { 0, 0, 0, 0 };
	string Format = "A16B16G16R16F";
>;

shared texture2D GBuffer_normal: RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
	float4 ClearColor = { 0, 0, 0, 0 };
	string Format = "D3DFMT_G32R32F";
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
	string Format = "G32R32F";
>;

shared texture2D GBuffer_ALPHA_FRONT_spa: RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
	float4 ClearColor = { 0, 0, 0, 0 };
	string Format = "A16B16G16R16F";
>;

shared texture2D GBuffer_ALPHA_FRONT_normal: RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
	float4 ClearColor = { 0, 0, 0, 0 };
	string Format = "D3DFMT_A32B32G32R32F";
>;
/////////////////////ALPHA FRAG////////////////////////


shared texture2D FOG_depth : RENDERDEPTHSTENCILTARGET <
    float2 ViewPortRatio = {1.8,1.8};
    string Format = "D24S8";
>;

shared texture2D FOG_DEPTH: RENDERCOLORTARGET<
    float2 ViewPortRatio = {1.8,1.8};
	float4 ClearColor = { 0, 0, 0, 0 };
	bool AntiAlias = false;
	string Format = "R32F";
>;


#include "headers\\GbufferClear.fxh"

float4 ClearColor = {0,0,0,0};
float ClearDepth  = 1.0;
technique buffer_init <
string Script = 		
		ClearGbuffer
		;
>{
}

