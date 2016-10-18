#include "headers\\environment.fxh"

float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "preprocess";
> = 0.8;


texture2D mrt_Depth : RENDERDEPTHSTENCILTARGET <
    float2 ViewportRatio = {1.0, 1.0};
    string Format = "D24S8";
>;

shared texture2D ScreenShadowMapProcessed : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    int MipLevels = 1;
    string Format = "G32R32F";
>;

texture ScreenShadowWorkBuff : RENDERCOLORTARGET <
    float2 ViewportRatio = {1.0, 1.0};
    string Format = "R32F";
>;
sampler ScreenShadowWorkBuffSampler = sampler_state {
    texture = <ScreenShadowWorkBuff>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

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
        "*.pmx=headers\\object.fx;"
        "*.pmd=headers\\object.fx;"
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
        "*.pmx=headers\\depth.fx;"
        "*.pmd=headers\\depth.fx;"
        "*.x=hide;";
>;



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

float4 PS_COPY(float2 Tex: TEXCOORD0) : COLOR
{
	float3 color = tex2Dlod(ScreenShadowMapSampler,float4(Tex,0,0)).xxx;
	return float4(color,1);

}


float hash12(float2 p)
{
	float3 p3  = frac(p.xyx * float3(.1031,.11369,.13787));
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.x + p3.y) * p3.z);
}

float BilateralWeight(float r, float depth, float center_d, float sharpness)
{
    const float blurSigma = 6 * depth;
    const float blurFalloff = 1.0f / (2.0f * blurSigma * blurSigma);

    float ddiff = (depth - center_d) * sharpness;
    return exp2(-r * r * blurFalloff - ddiff * ddiff);
}

#define SHADOW_BLUR_COUNT 5

float4 ShadowMapBlurPS(float2 coord : TEXCOORD0, uniform sampler2D source, uniform float2 offset) : COLOR
{
    float4 center = tex2D(source, coord);
    center.y = abs(center.y);

    float2 sum = float2(center.x, 1);

    float2 offset1 = coord + offset;
    float2 offset2 = coord - offset;

    [unroll]
    for(int r = 1; r < SHADOW_BLUR_COUNT; r++)
    {        
        float2 shadow1 = tex2D(source, offset1).xy;
        float2 shadow2 = tex2D(source, offset2).xy;
        
        float bilateralWeight1 = BilateralWeight(r, abs(shadow1.y), center.y, 3);
        float bilateralWeight2 = BilateralWeight(r, abs(shadow2.y), center.y, 3);
        
        sum.x += shadow1.x * bilateralWeight1;
        sum.x += shadow2.x * bilateralWeight2;

        sum.y += bilateralWeight1;
        sum.y += bilateralWeight2;
        
        offset1 += offset;
        offset2 -= offset;
    }

    return float4(sum.x / sum.y,center.z,0,1);
}




float4 ClearColor = {1,1,1,1};
float ClearDepth  = 1.0;

technique MainTech <
    string Script = 
        "ScriptExternal=Color;"
		
		"RenderColorTarget0=ScreenShadowWorkBuff;"
    	"RenderDepthStencilTarget=mrt_Depth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=BilateralBlurX;"
		
		"RenderColorTarget0=ScreenShadowMapProcessed;"
    	"RenderDepthStencilTarget=mrt_Depth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=BilateralBlurY;"
    ;
> {
	pass BilateralBlurX < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 POST_VS();
        PixelShader  = compile ps_3_0 ShadowMapBlurPS(ScreenShadowMapSampler,float2(ViewportOffset2.x, 0.0f));
    }
	
	pass BilateralBlurY < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 POST_VS();
        PixelShader  = compile ps_3_0 ShadowMapBlurPS(ScreenShadowWorkBuffSampler,float2(0.0f, ViewportOffset2.y));
    }
}
