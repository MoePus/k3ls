

////////////////////////////////////////////////////////////////////////////////////////////////

#include "ExcellentShadowCommonSystem.fx"

////////////////////////////////////////////////////////////////////////////////////////////////

// ぼかし範囲(大きくしすぎると縞が出ます)
float Extent
<
   string UIName = "Extent";
   string UIWidget = "Slider";
   bool UIVisible =  true;
   float UIMin = 0.00;
   float UIMax = 4.0;
> = float( 1.4 );


//背景色
const float4 BackColor <
   string UIName = "BackColor";
   string UIWidget = "Color";
   string UIHelp = "背景色";
   bool UIVisible =  true;
> = float4( 0, 0, 0, 0 );

//ぼかしのサンプリング数
#define SAMP_NUM_FULL  7


////////////////////////////////////////////////////////////////////////////////////////////////


//クオリティ調整

#if EXSHADOW_QUALITY==0
    #define SAMP_NUM  (SAMP_NUM_FULL - 2)
    #define SCREENSHADOWTEXFMT "D3DFMT_A16B16G16R16F"
    #define WORKTEXFMT   "D3DFMT_R16F"
    #define OUTPUTTEXFMT "D3DFMT_R16F"
#elif EXSHADOW_QUALITY==1
    #define SAMP_NUM  (SAMP_NUM_FULL - 1)
    #define SCREENSHADOWTEXFMT "D3DFMT_A16B16G16R16F"
    #define WORKTEXFMT   "D3DFMT_R16F"
    #define OUTPUTTEXFMT "D3DFMT_R16F"
#elif EXSHADOW_QUALITY==2
    #define SAMP_NUM  SAMP_NUM_FULL
    #define SCREENSHADOWTEXFMT "D3DFMT_A16B16G16R16F"
    #define WORKTEXFMT   "D3DFMT_R16F"
    #define OUTPUTTEXFMT "D3DFMT_R16F"
#elif EXSHADOW_QUALITY==3
    #define SAMP_NUM  SAMP_NUM_FULL
    #define SCREENSHADOWTEXFMT "D3DFMT_A16B16G16R16F"
    #define WORKTEXFMT   "D3DFMT_R16F"
    #define OUTPUTTEXFMT "D3DFMT_R16F"
#elif EXSHADOW_QUALITY==4
    #define SAMP_NUM  SAMP_NUM_FULL
    #define SCREENSHADOWTEXFMT "D3DFMT_A32B32G32R32F"
    #define WORKTEXFMT   "D3DFMT_R32F"
    #define OUTPUTTEXFMT "D3DFMT_R16F"
#else
    #define SAMP_NUM  (SAMP_NUM_FULL + 2)
    #define SCREENSHADOWTEXFMT "D3DFMT_A32B32G32R32F"
    #define WORKTEXFMT   "D3DFMT_R32F"
    #define OUTPUTTEXFMT "D3DFMT_R16F"
#endif



////////////////////////////////////////////////////////////////////////////////////////////////

shared texture ScreenShadowMap: OFFSCREENRENDERTARGET <
    string Description = "ScreenShadowRenderTarget for ExcellentShadow";
    string Format = SCREENSHADOWTEXFMT;
    float2 ViewPortRatio = {1.0,1.0};
    float4 ClearColor = { 1, 0, 0, 1 };
    float ClearDepth = 1.0;
    int Miplevels = 1;
    bool AntiAlias = true;
    string DefaultEffect = 
        "self = hide;"
        "*Controller.x = hide;"
        "SoftLight*.fx = hide;"
        "* = ExcellentShadowObject.fxsub;" 
    ;
>;

sampler ScreenShadowMapSampler = sampler_state {
    texture = <ScreenShadowMap>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};


////////////////////////////////////////////////////////////////////////////////////////////////

shared texture ExcellentShadowZMap: OFFSCREENRENDERTARGET <
    string Description = "ZRenderTarget for ExcellentShadow";
    string Format = "D3DFMT_R32F";
    int Width = SHADOWBUFSIZE;
    int Height = SHADOWBUFSIZE;
    float4 ClearColor = { 1, 1, 1, 1 };
    float ClearDepth = 1.0;
    int Miplevels = 1;
    bool AntiAlias = false;
    string DefaultEffect = 
        "self = hide;"
        "*Controller.x = hide;"
        "SoftLight*.fx = hide;"
        "* = ExcellentShadowZBufDraw.fxsub;" 
    ;
>;

shared texture ExcellentShadowZMapFar: OFFSCREENRENDERTARGET <
    string Description = "ZRenderTarget Far for ExcellentShadow";
    string Format = "D3DFMT_R32F";
    int Width = SHADOWBUFSIZE;
    int Height = SHADOWBUFSIZE;
    float4 ClearColor = { 1, 1, 1, 1 };
    float ClearDepth = 1.0;
    int Miplevels = 1;
    bool AntiAlias = false;
    string DefaultEffect = 
        "self = hide;"
        "*Controller.x = hide;"
        "SoftLight*.fx = hide;"
        "* = ExcellentShadowZBufDrawFar.fxsub;" 
    ;
>;

////////////////////////////////////////////////////////////////////////////////////////////////


texture2D DepthBuffer : RENDERDEPTHSTENCILTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    string Format = "D24S8";
>;


texture2D ScnMap : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    int MipLevels = 1;
    string Format = "A8R8G8B8" ;
    
>;
sampler2D ScnSamp = sampler_state {
    texture = <ScnMap>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

// 作業バッファ
texture2D WorkBuf1 : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    int MipLevels = 1;
    string Format = WORKTEXFMT;
>;
sampler2D WorkBuf1Samp = sampler_state {
    texture = <WorkBuf1>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

// 作業バッファ
texture2D WorkBuf2 : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    int MipLevels = 1;
    string Format = WORKTEXFMT;
>;
sampler2D WorkBuf2Samp = sampler_state {
    texture = <WorkBuf2>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

// 作業バッファ
texture2D ShadowBlurMap : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    int MipLevels = 1;
    string Format = WORKTEXFMT;
>;
sampler2D ShadowBlurMapSamp = sampler_state {
    texture = <ShadowBlurMap>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};


////////////////////////////////////////////////////////////////////////////////////////////////

// 出力バッファ
shared texture2D ScreenShadowMapProcessed : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    int MipLevels = 1;
    string Format = OUTPUTTEXFMT;
>;
sampler2D ScreenShadowMapProcessedSamp = sampler_state {
    texture = <ScreenShadowMapProcessed>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};


////////////////////////////////////////////////////////////////////////////////////////////////

// MMD本来のsamplerを上書きしないための記述です。削除不可。
#ifndef MIKUMIKUMOVING
sampler MMDSamp0 : register(s0);
sampler MMDSamp1 : register(s1);
sampler MMDSamp2 : register(s2);
#endif

////////////////////////////////////////////////////////////////////////////////////////////////


float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "preprocess";
> = 0.8;

#define PI 3.14159

float rot_x : CONTROLOBJECT < string name = "(self)"; string item = "Rx"; >;
static float rot_scale = max(0, 1 + rot_x / PI * 1.8);

// スクリーンサイズ
float2 ViewportSize : VIEWPORTPIXELSIZE;
static float2 ViewportOffset = (float2(0.5,0.5)/ViewportSize);
static float2 OnePx = (float2(1,1)/ViewportSize);


static float2 SampStep = (float2(Extent,Extent)/ViewportSize*ViewportSize.y);
static float2 SampStepScaled = SampStep * max(1, size1) / SAMP_NUM * rot_scale * (1 + (EXSHADOW_QUALITY <= 1));

// レンダリングターゲットのクリア値
//float4 ClearColor = {0,0,0,0};
float ClearDepth  = 1.0;


////////////////////////////////////////////////////////////////////////////////////////////////
//共通頂点シェーダ
struct VS_OUTPUT {
    float4 Pos            : POSITION;
    float2 Tex            : TEXCOORD0;
};

VS_OUTPUT VS_passDraw( float4 Pos : POSITION, float2 Tex : TEXCOORD0 ) {
    VS_OUTPUT Out = (VS_OUTPUT)0; 
    
    Out.Pos = Pos;
    Out.Tex = Tex + ViewportOffset;
    
    return Out;
}

////////////////////////////////////////////////////////////////////////////////////////////////
// ピクセルシェーダ

float4 PS_copy( float2 Tex: TEXCOORD0 ) : COLOR {
    //float4 color = tex2D( ScreenShadowMapSampler, Tex );
    //float4 color = tex2D( ScreenShadowMapProcessedSamp, Tex ); color.rgb = color.r;
    //float4 color = tex2D( ExcellentShadowZMapSampler, Tex ) * 0.1; color.rgb = color.r;
    
    float4 color = tex2D( ScnSamp, Tex );
    
    //color = float4(1,0,0,1);
    //color.rgb *= lightcolor_in * power_in;
    
    return color;
    
}


////////////////////////////////////////////////////////////////////////////////////////////////

float4 PS_CopyShadowBlurPower( float2 Tex: TEXCOORD0 ) : COLOR { 
    
    float4 Color = float4(0,0,0,1);
    
    Color.r = tex2Dlod(ScreenShadowMapSampler, float4(Tex, 0, 0)).b;
    
    return Color;
    
}

////////////////////////////////////////////////////////////////////////////////////////////////

float ES_GetDepthMap(float2 Tex){
    float d;
    
    d = tex2Dlod(ScreenShadowMapSampler, float4(Tex, 0, 0)).g;
    
    return d;
}

float ES_GetShadowRate(float2 Tex){
    float d;
    
    d = tex2Dlod(ScreenShadowMapSampler, float4(Tex, 0, 0)).r;
    
    return d;
}


////////////////////////////////////////////////////////////////////////////////////////////////

static float sizerate = 1;//pow(size1, 0.2);
float depthpow = 1;//0.75;
float blroffset = 0.0006;

float DepthComp(float depth1, float depth2){
    depth1 = pow(depth1, depthpow);
    depth2 = pow(depth2, depthpow);
    
    return saturate(1 - abs(depth1 - depth2) * 0.6 / size1);
    
}

////////////////////////////////////////////////////////////////////////////////////////////////

float4 PS_passBlurGaussian( float2 Tex: TEXCOORD0, uniform bool Horizontal , uniform sampler2D samp ) : COLOR {   
    float e, n = 0;
    float2 stex;
    float Color, sum = 0;
    
    float depth, centerdepth = ES_GetDepthMap(Tex);
    float step = (Horizontal ? SampStepScaled.x : SampStepScaled.y) * (1.0 / centerdepth * 2.2 + blroffset);
    
    [unroll] //ループ展開
    for(int i = -SAMP_NUM; i <= SAMP_NUM; i++){
        e = exp(-pow((float)i / (SAMP_NUM / 2.0), 2) / 2); //正規分布
        stex = Tex + float2(Horizontal, !Horizontal) * (step * (float)i);
        
        //奥行きに応じたサンプリング強度
        depth = ES_GetDepthMap(stex);
        e *= DepthComp(centerdepth, depth);
        
        sum += tex2Dlod(samp, float4(stex, 0, 0)).r * e;
        n += e;
    }
    
    Color = sum / n;
    
    return float4(Color, 0, 0, 1);
    
}


////////////////////////////////////////////////////////////////////////////////////////////////

float4 PS_passShadowGaussian( float2 Tex: TEXCOORD0, uniform bool Horizontal , uniform sampler2D samp ) : COLOR {   
    float e, n = 0;
    float2 stex;
    float Color, sum = 0;
    
    float blurstr = tex2Dlod(ShadowBlurMapSamp, float4(Tex, 0, 0)).r;
    
    float depth, centerdepth = ES_GetDepthMap(Tex);// - 0.0001;
    float step = (Horizontal ? SampStepScaled.x : SampStepScaled.y) * (min(1, (sqrt(blurstr * 2) + 0.0) / pow(centerdepth, depthpow) * sizerate) + blroffset);
    
    [unroll] //ループ展開
    for(int i = -SAMP_NUM; i <= SAMP_NUM; i++){
        e = exp(-pow((float)i / (SAMP_NUM / 2.0), 2) / 2); //正規分布
        stex = Tex + float2(Horizontal, !Horizontal) * (step * (float)i);
        
        //奥行きに応じたサンプリング強度
        depth = ES_GetDepthMap(stex);
        e *= DepthComp(centerdepth, depth);
        
        sum += tex2Dlod(samp, float4(stex, 0, 0)).r * e;
        n += e;
    }
    
    Color = sum / n;
    
    return float4(Color, 0, 0, 1);
    
}


////////////////////////////////////////////////////////////////////////////////////////////////

float4 PS_passFinishBlur( float2 Tex: TEXCOORD0, uniform bool Horizontal , uniform sampler2D samp ) : COLOR { 
    
    float Color, sum = 0, scolor, n = 0;
    float2 step = OnePx * float2(Horizontal, !Horizontal) * 0.7;
    
    //sum += tex2Dlod(samp, float4(Tex, 0, 0)).r;
    //sum += tex2Dlod(samp, float4(Tex + step, 0, 0)).r * 0.5;
    //sum += tex2Dlod(samp, float4(Tex - step, 0, 0)).r * 0.5;
    
    //Color = sum / 2.0;
    
    Color = tex2Dlod(samp, float4(Tex, 0, 0)).r;
    Color = min(Color, tex2Dlod(samp, float4(Tex + step, 0, 0)).r * 1.25);
    Color = min(Color, tex2Dlod(samp, float4(Tex - step, 0, 0)).r * 1.25);
    
    return Color;
}

////////////////////////////////////////////////////////////////////////////////////////////////

technique ExcellentShadow <
    string Script = 
        
        
        
        "RenderColorTarget0=ShadowBlurMap;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "Pass=CopyShadowBlurPower;"
        
        "RenderColorTarget0=WorkBuf1;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "Pass=SBGaussian_X;"
        #if EXSHADOW_QUALITY>1
        "RenderColorTarget0=WorkBuf2;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "Pass=SBGaussian_Y;"
        "RenderColorTarget0=WorkBuf1;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "Pass=SBGaussian_X2;"
        #endif
        "RenderColorTarget0=ShadowBlurMap;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "Pass=SBGaussian_Y2;"
        
        
        "RenderColorTarget0=WorkBuf1;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "Pass=Gaussian_X;"
        #if EXSHADOW_QUALITY>1
        "RenderColorTarget0=WorkBuf2;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "Pass=Gaussian_Y;"
        "RenderColorTarget0=WorkBuf1;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "Pass=Gaussian_X2;"
        #endif
        "RenderColorTarget0=ScreenShadowMapProcessed;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "Pass=Gaussian_Y2;"
        
        /*#if EXSHADOW_QUALITY>1
        "RenderColorTarget0=WorkBuf1;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "Pass=FinishBlur_X;"
        "RenderColorTarget0=ScreenShadowMapProcessed;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "Pass=FinishBlur_Y;"
        #endif*/
        
        "RenderColorTarget0=ScnMap;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "ClearSetColor=BackColor; ClearSetDepth=ClearDepth;"
        "Clear=Color; Clear=Depth;"
        "ScriptExternal=Color;"
        
        
        /*"RenderColorTarget0=;"
        "RenderDepthStencilTarget=;"
        "ClearSetColor=BackColor;"
        "ClearSetDepth=ClearDepth;"
        "Clear=Color;"
        "Clear=Depth;"
        "Pass=CopyPass;"
        //"Pass=AddMix;"*/
        
        
    ;
    
> {
    
    pass CopyPass < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = false;
        AlphaTestEnable = false;
        ZEnable = false;
        VertexShader = compile vs_3_0 VS_passDraw();
        PixelShader  = compile ps_3_0 PS_copy();
    }
    
    pass AddMix < string Script= "Draw=Buffer;"; > {
        SRCBLEND = ONE;
        DESTBLEND = ONE;
        VertexShader = compile vs_3_0 VS_passDraw();
        PixelShader  = compile ps_3_0 PS_copy();
    }
    
    
    /////////////////////////////////////////////////////////////////
    //影ぼかし強度
    
    pass CopyShadowBlurPower < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 VS_passDraw();
        PixelShader  = compile ps_3_0 PS_CopyShadowBlurPower();
    }
    
    pass SBGaussian_X < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 VS_passDraw();
        PixelShader  = compile ps_3_0 PS_passBlurGaussian(true, ShadowBlurMapSamp);
    }
    pass SBGaussian_Y < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 VS_passDraw();
        PixelShader  = compile ps_3_0 PS_passBlurGaussian(false, WorkBuf1Samp);
    }
    pass SBGaussian_X2 < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 VS_passDraw();
        PixelShader  = compile ps_3_0 PS_passBlurGaussian(true, WorkBuf2Samp);
    }
    pass SBGaussian_Y2 < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 VS_passDraw();
        PixelShader  = compile ps_3_0 PS_passBlurGaussian(false, WorkBuf1Samp);
    }
    
    /////////////////////////////////////////////////////////////////
    // 影ぼかし本体
    
    pass Gaussian_X < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 VS_passDraw();
        PixelShader  = compile ps_3_0 PS_passShadowGaussian(true, ScreenShadowMapSampler);
    }
    pass Gaussian_Y < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 VS_passDraw();
        PixelShader  = compile ps_3_0 PS_passShadowGaussian(false, WorkBuf1Samp);
    }
    pass Gaussian_X2 < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 VS_passDraw();
        PixelShader  = compile ps_3_0 PS_passShadowGaussian(true, WorkBuf2Samp);
    }
    pass Gaussian_Y2 < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 VS_passDraw();
        PixelShader  = compile ps_3_0 PS_passShadowGaussian(false, WorkBuf1Samp);
    }
    
    /////////////////////////////////////////////////////////////////
    // 最終ぼかし
    pass FinishBlur_X < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 VS_passDraw();
        PixelShader  = compile ps_3_0 PS_passFinishBlur(true, ScreenShadowMapProcessedSamp);
    }
    pass FinishBlur_Y < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 VS_passDraw();
        PixelShader  = compile ps_3_0 PS_passFinishBlur(false, WorkBuf1Samp);
    }
    
}
////////////////////////////////////////////////////////////////////////////////////////////////
