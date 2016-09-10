// NCHLShader2+C用に改変してあります　ぐるみぃ
//
// 針金Pがフルスクリーン表示バグの修正を行ったver0.0.2をベースにしています
// nilさんが行ったNCHLShader2用のプリエフェクト化も再現してあります
// 加えて下っ腹Pが提唱された高品位パラメーターを採用してあります



////////////////////////////////////////////////////////////////////////////////////////////////
//
//  HgSAO.fx ver0.0.2  SAO(Scalable Ambient Obscurance)エフェクト
//  作成: 針金P
//
////////////////////////////////////////////////////////////////////////////////////////////////
/*
  Open Source under the "BSD" license: http://www.opensource.org/licenses/bsd-license.php

  Copyright (c) 2011-2012, NVIDIA
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice,
     this list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright notice,
     this list of conditions and the following disclaimer in the documentation
     and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
////////////////////////////////////////////////////////////////////////////////////////////////
// ここのパラメータを変更してください

#define UseHDR  0   // HDRレンダリングの有無
// 0 : 通常の256階調で処理
// 1 : 高照度情報をそのまま処理

// SAOを行う際のパラメータ
float ProjScale <
   string UIName = "SS Scale";
   string UIWidget = "Slider";
   string UIHelp = "AOでサンプリングを行う際のScreenSpaceのスケール比";
   bool UIVisible =  true;
   float UIMin = 1.0;
   float UIMax = 1000.0;
> = float( 66.6 );
// > = float( 100.0 );　●変更前＝100

float Radius <
   string UIName = "AO Disk半径";
   string UIWidget = "Slider";
   string UIHelp = "AOでサンプリングを行う範囲のDisk半径";
   bool UIVisible =  true;
   float UIMin = 0.0;
   float UIMax = 10.0;
> = float( 5.0 );
// > = float( 3.0 );　●変更前＝3.0

float Intensity <
   string UIName = "AO 明度";
   string UIWidget = "Slider";
   bool UIVisible =  true;
   float UIMin = 0.01;
   float UIMax = 2.0;
> = float( 0.5 );

float Bias <
   string UIName = "AOバイアス";
   string UIWidget = "Slider";
   bool UIVisible =  true;
   float UIMin = 0.001;
   float UIMax = 0.1;
> = float( 0.03 );
// > = float( 0.01 );　●変更前＝0.01

int SampCount <
   string UIName = "サンプル数";
   string UIHelp = "AOでサンプリングを行う際の数";
   string UIWidget = "Numeric";
   bool UIVisible =  true;
   int UIMin = 1;
   int UIMax = 30;
> = int( 17 );
// > = int( 11 );　●変更前＝11

// ブラーをかける際のパラメータ
float BlurPower <
   string UIName = "ブラー強度";
   string UIHelp = "ブラーをかける際のサンプリング間隔";
   string UIWidget = "Slider";
   bool UIVisible =  true;
   float UIMin = 0.0;
   float UIMax = 5.0;
> = float( 0.9 );
// > = float( 1.0 );　●変更前＝1.0

float OutlineDepth <
   string UIName = "輪郭判定深度";
   string UIHelp = "ぼかし処理時に輪郭の内外を判定する深度";
   string UIWidget = "Slider";
   bool UIVisible =  true;
   float UIMin = 0.0;
   float UIMax = 1.0;
> = float( 0.13 );
// > = float( 0.1 );　●変更前＝0.1

float OutlineNormal <
   string UIName = "輪郭判定法線";
   string UIHelp = "ぼかし処理時に輪郭の内外を判定する法線(内積)";
   string UIWidget = "Slider";
   bool UIVisible =  true;
   float UIMin = 0.0;
   float UIMax = 1.0;
> = float( 0.25 );
// > = float( 0.2 );　●変更前＝0.2

bool FlagVisibleAO <
   string UIName = "AO表\示";
   bool UIVisible =  true;
> = false;
//> = true;



// 解らない人はここから下はいじらないでね

////////////////////////////////////////////////////////////////////////////////////////////////

float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "preprocess";
> = 0.8;

// コントロールパラメータ
float AcsTr : CONTROLOBJECT < string name = "(self)"; string item = "Tr"; >;
float AcsSi : CONTROLOBJECT < string name = "(self)"; string item = "Si"; >;
#ifndef MIKUMIKUMOVING
float3 AcsXYZ  : CONTROLOBJECT < string name = "(self)"; string item = "XYZ"; >;
float3 AcsRxyz : CONTROLOBJECT < string name = "(self)"; string item = "Rxyz"; >;
static float ssScale = max(ProjScale + AcsXYZ.x, 1.0f);
static float Radius1 = max(Radius + AcsXYZ.y, 0.0f);
static float bias = clamp(Bias + AcsXYZ.z, 0.001f, 1.0f);
static float intensity = max(Intensity + degrees(AcsRxyz.x), 0.0f);
static float blurPower = max(BlurPower + degrees(AcsRxyz.z), 0.0f);
#else
static float ssScale = ProjScale;
static float Radius1 = Radius;
static float bias = Bias;
static float intensity = Intensity;
static float blurPower = BlurPower;
#endif

// スクリーン内描画範囲の倍率(画面縁SSAO処理のため広範囲を描画)
#define ScrSizeRatio  1.1

// スクリーンサイズ
float2 ViewportSize : VIEWPORTPIXELSIZE;
static float2 ViewportOffset = (float2(0.5,0.5)/ViewportSize);
static float2 SampStep = (float2(blurPower,blurPower)/ViewportSize);

// 作業用スクリーンサイズ
static float2 WorkViewportSize = float2( floor(ViewportSize*ScrSizeRatio) );
static float2 TrueScnScale = WorkViewportSize / ViewportSize;
static float2 WorkViewportOffset = float2(0.5,0.5) / WorkViewportSize;

// 座標変換行列
float4x4 ProjMatrix0 : PROJECTION;
static float4x4 ProjMatrix = float4x4( ProjMatrix0[0] / TrueScnScale.x,
                                       ProjMatrix0[1] / TrueScnScale.y,
                                       ProjMatrix0[2],
                                       ProjMatrix0[3] );

// オフスクリーン法線マップ
texture HgSAO_NmlRT: OFFSCREENRENDERTARGET <
    string Description = "HgSAO.fxの法線マップ";
    float2 ViewPortRatio = {ScrSizeRatio, ScrSizeRatio};
    float4 ClearColor = {0.5, 0.5 ,0, 1};
    float ClearDepth = 1.0;
    string Format = "D3DFMT_A8R8G8B8" ;
    bool AntiAlias = true;
    string DefaultEffect = 
        "self = hide;"
"SoftLight*.x = hide;"
"*Controller.x = hide;"
        //"MMM_DummyModel = HgSAO_Cancel.fxsub;"
        "* = HgSAO_Normal.fxsub;";
>;
sampler NormalMapSmp = sampler_state {
    texture = <HgSAO_NmlRT>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

// オフスクリーン深度マップ
texture HgSAO_DepRT: OFFSCREENRENDERTARGET <
    string Description = "HgSAO.fxの深度マップ";
    float2 ViewPortRatio = {ScrSizeRatio, ScrSizeRatio};
    float4 ClearColor = { 1, 1, 1, 1 };
    float ClearDepth = 1.0f;
    string Format = "D3DFMT_R32F";
    int MipLevels = 0;
    bool AntiAlias = false;
    string DefaultEffect = 
        "self = hide;"
        "MMM_DummyModel = HgSAO_Cancel.fxsub;"
        "*Controller.x = hide;"
        "* = HgSAO_Depth.fxsub;"
    ;
>;
sampler DepthMapSmp = sampler_state {
    texture = <HgSAO_DepRT>;
    //Filter = NONE;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};


// レンダリングターゲットのクリア値
float4 ClearColor = {1,1,1,0};
float ClearDepth  = 1.0;

#if UseHDR==0
    #define TEX_FORMAT "D3DFMT_A8R8G8B8"
#else
    #define TEX_FORMAT "D3DFMT_A16B16G16R16F"
    //#define TEX_FORMAT "D3DFMT_A32B32G32R32F"
#endif

// オリジナルの描画結果を記録するためのレンダーターゲット
/*texture2D ScnMap : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0, 1.0};
    int MipLevels = 1;
    string Format = TEX_FORMAT;
>;
sampler2D ScnSamp = sampler_state {
    texture = <ScnMap>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU = CLAMP;
    AddressV = CLAMP;
};
texture2D ScnMapDepthBuffer : RENDERDEPTHSTENCILTARGET <
    float2 ViewPortRatio = {1.0, 1.0};
    string Format = "D3DFMT_D24S8";
>;*/


// SSAO項の結果を記録するためのレンダーターゲット
texture2D SSAO_Tex : RENDERCOLORTARGET <
    float2 ViewPortRatio = {ScrSizeRatio, ScrSizeRatio};
    float4 ClearColor = {1,1,1,0};
    float ClearDepth = 1;
    int MipLevels = 1;
    string Format = "D3DFMT_R16F";
>;
sampler2D SSAOSamp = sampler_state {
    texture = <SSAO_Tex>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

// Y方向のぼかし結果を記録するためのレンダーターゲット
texture2D SSAO_Tex2 : RENDERCOLORTARGET <
    float2 ViewPortRatio = {ScrSizeRatio, ScrSizeRatio};
    int MipLevels = 1;
    string Format = "D3DFMT_R16F";
>;
sampler2D SSAOSamp2 = sampler_state {
    texture = <SSAO_Tex2>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

texture2D DepthBuffer : RENDERDEPTHSTENCILTARGET <
    float2 ViewPortRatio = {ScrSizeRatio, ScrSizeRatio};
    string Format = "D3DFMT_D24S8";
>;


shared texture2D SSAO_Tex3 : RENDERCOLORTARGET <
float2 ViewPortRatio = {1.0, 1.0};
int MipLevels = 1;
string Format = "D3DFMT_R16F";
>;
sampler2D SSAOSamp3 = sampler_state {
texture = <SSAO_Tex3>;
MinFilter = LINEAR;
MagFilter = LINEAR;
MipFilter = NONE;
AddressU = CLAMP;
AddressV = CLAMP;
};
texture2D DepthBuffer2 : RENDERDEPTHSTENCILTARGET <
float2 ViewPortRatio = {1.0, 1.0};
string Format = "D3DFMT_D24S8";
>;


////////////////////////////////////////////////////////////////////////////////////////////////
// 共通の頂点シェーダ

struct VS_OUTPUT {
    float4 Pos : POSITION;
    float2 Tex : TEXCOORD0;
};

VS_OUTPUT VS_Common( float4 Pos : POSITION, float2 Tex : TEXCOORD0 )
{
    VS_OUTPUT Out = (VS_OUTPUT)0; 
    Out.Pos = Pos;
    Out.Tex = Tex + WorkViewportOffset;
    return Out;
}


////////////////////////////////////////////////////////////////////////////////////////////////
// SSAO項

#define DEPTH_FAR  5000.0f  // 深度最遠値

#define NUM_SPIRAL_TURNS 7  // サンプリング回転角のパラメータ
#define LOG_MAX_OFFSET 3    // ミップ使用閾値
#define MAX_MIP_LEVEL 5     // ミップレベル最大値

//半径の二乗
static float Radius2 = Radius1 * Radius1;

// マップから法線と深度を取得
void GetNormalDepth(float2 Tex, out float3 Normal, out float Depth)
{
    // 法線
    float4 ColorN = tex2D( NormalMapSmp, Tex );
    Normal = normalize( ColorN.xyz*2.0f - 1.0f );

    // 深度
    Depth = tex2Dlod( DepthMapSmp, float4(Tex,0,0) ).r * DEPTH_FAR;
}


// マップから法線とビュー座標を取得
void GetNormalVPos(float2 Tex, out float3 Normal, out float3 VPos)
{
    // 法線,深度
    float Depth;
    GetNormalDepth(Tex, Normal, Depth);

    // ビュー座標に戻す
    float2 PPos = float2(2.0f*Tex.x-1.0f, 1.0f-2.0f*Tex.y);
    VPos = float3(PPos.x / ProjMatrix._11, PPos.y / ProjMatrix._22, 1.0f) * Depth;
}


// サンプル位置のAO項を取得する
//  ssPos:Screen座標(Pixel)  tapIndex:サンプルIndex  VPos:対象座標  Normal:対象座標の法線
//  ssDiskRadius:ディスク半径  randAng:ランダム回転角度
float sampleAO(int2 ssPos, int sampIndex, float3 VPos, float3 Normal, float ssDiskRadius, float randAng)
{
    // サンプリング位置
    float alpha = float(sampIndex + 0.5f) / SampCount;
    float angle = alpha * (NUM_SPIRAL_TURNS * 6.28) + randAng;
    float ssR = alpha * ssDiskRadius;
    float2 unitOffset = float2(cos(angle), sin(angle)) * ssR;
    float2 texCoord = (float2(ssPos) + unitOffset) / WorkViewportSize;

    // ミップレベル
    int mipLevel = clamp((int)floor(log2(ssR)) - LOG_MAX_OFFSET, 0, MAX_MIP_LEVEL);

    // オフセット位置のビュー座標
    float Depth = tex2Dlod(DepthMapSmp, float4(texCoord, 0, mipLevel)).x * DEPTH_FAR;
    float2 PPos = float2(2.0f*texCoord.x-1.0f, 1.0f-2.0f*texCoord.y);
    float3 offsetVPos = float3(PPos.x / ProjMatrix._11, PPos.y / ProjMatrix._22, 1.0f) * Depth;

    // サンプリング位置ベクトル(camera space)
    float3 vec = offsetVPos - VPos;

    float vv = dot(vec, vec);
    float vn = dot(vec, Normal);

    // AO項を求める
    const float epsilon = 0.01f;
    float f = max(Radius2 - vv, 0.0f);
    float ao = f * f * f * max((vn - bias) / (epsilon + vv), 0.0f);

    return ao;
}


// SSAOマップ作成
float4 PS_SSAO( float2 Tex: TEXCOORD0 ) : COLOR
{
    // ScreenSpaceの座標(Pixel)
    int2 ssPos = int2(Tex * WorkViewportSize);

    // HPG12 AlchemyAO論文で使用されたハッシュ関数(XORが使えないので改変)
    float randAng = (5 * ssPos.x % ssPos.y + ssPos.x * ssPos.y) * 7.0f;

    // 法線,ビュー座標
    float3 Normal, VPos;
    GetNormalVPos( Tex, Normal, VPos);

    // ScreenSpaceでのサンプルディスク半径
    float ssDiskRadius = -ssScale * Radius1 / VPos.z;

    // AO項を計算
    float sum = 0.0f;
    for (int i = 0; i < SampCount; i++) {
         sum += sampleAO(ssPos, i, VPos, Normal, ssDiskRadius, randAng);
    }

    float temp = Radius2 * Radius1;
    sum /= temp * temp;
    float ao = max(0.0f, 1.0f - sum * intensity * (5.0f / SampCount));

    // Bilateral box-filter over a quad for free, respecting depth edges
    // (the difference that this makes is subtle)
    if (abs(ddx(VPos.z)) < 0.02f) {
        ao -= ddx(ao) * ((ssPos.x % 2) - 0.5f);
    }
    if (abs(ddy(VPos.z)) < 0.02f) {
        ao -= ddy(ao) * ((ssPos.y % 2) - 0.5f);
    }

    return float4(1.0f-ao, 0, 0, 1);
}


////////////////////////////////////////////////////////////////////////////////////////////////
// SSAOマップのぼかし

// ぼかし処理の重み係数：
//    ガウス関数 exp( -x^2/(2*d^2) ) を d=5, x=0～7 について計算したのち、
//    (WT_7 + WT_6 + … + WT_1 + WT_0 + WT_1 + … + WT_7) が 1 になるように正規化したもの
float WT_COEF[8] = { 0.0920246,
                     0.0902024,
                     0.0849494,
                     0.0768654,
                     0.0668236,
                     0.0558158,
                     0.0447932,
                     0.0345379 };

// サンプリングするミップマップレベル
static float MipLv = log2( max(ViewportSize.x*SampStep.x, 1.0f) );

// ぼかしサンプリング範囲の境界判定
bool IsSameArea(float Depth0, float Depth, float3 Normal0, float3 Normal)
{
    float edgeDepthThreshold = min(OutlineDepth + 0.05f * max(Depth0-20.0f, 0.0f), 7.0f);
    return (abs(Depth0 - Depth) < edgeDepthThreshold && abs(Normal0 - Normal) < OutlineNormal);
}

// ガウスフィルターによるぼかし
float SSAOGaussianXY(float2 Tex, sampler2D Samp, float2 smpVec, bool isMipMap)
{
    float mipLv = isMipMap ? MipLv : 0.0f;
    float3 Normal0, Normal;
    float Depth0, Depth;
    GetNormalDepth(Tex, Normal0, Depth0);

    float ssao = tex2Dlod( Samp, float4(Tex,0,mipLv) ).r;
    float sumSSAO = WT_COEF[0] * ssao;
    float sumRate = WT_COEF[0];

    // 境界の反対側にある色はサンプリングしない
    [unroll]
    for(int i=1; i<8; i++){
        float2 Tex1 = Tex - smpVec * SampStep * i;
        GetNormalDepth(Tex1, Normal, Depth);
        if( IsSameArea(Depth0, Depth, Normal0, Normal) ){
            ssao = tex2Dlod( Samp, float4(Tex1,0,mipLv) ).r;
            sumSSAO += WT_COEF[i] * ssao;
            sumRate += WT_COEF[i];
        }

        Tex1 = Tex + smpVec * SampStep * i;
        GetNormalDepth(Tex1, Normal, Depth);
        if( IsSameArea(Depth0, Depth, Normal0, Normal) ){
            ssao = tex2Dlod( Samp, float4(Tex1,0,mipLv) ).r;
            sumSSAO += WT_COEF[i] * ssao;
            sumRate += WT_COEF[i];
        }
    }

    return (sumSSAO / sumRate);
}

// Y方向
float4 PS_SSAOGaussianY( float2 Tex: TEXCOORD0 ) : COLOR
{
    float ssao = SSAOGaussianXY( Tex, SSAOSamp, float2(0,1), true );
    return float4(ssao, 0, 0, 1);
}

// X方向
float4 PS_SSAOGaussianX( float2 Tex: TEXCOORD0 ) : COLOR
{
    float ssao = SSAOGaussianXY( Tex, SSAOSamp2, float2(1,0), false );
    return float4(ssao, 0, 0, 1);
}


////////////////////////////////////////////////////////////////////////////////////////////////

// RGBからYCbCrへの変換
/*void RGBtoYCbCr(float3 rgbColor, out float Y, out float Cb, out float Cr)
{
    Y  =  0.298912f * rgbColor.r + 0.586611f * rgbColor.g + 0.114478f * rgbColor.b;
    Cb = -0.168736f * rgbColor.r - 0.331264f * rgbColor.g + 0.5f      * rgbColor.b;
    Cr =  0.5f      * rgbColor.r - 0.418688f * rgbColor.g - 0.081312f * rgbColor.b;
}*/


// YCbCrからRGBへの変換
/*float3 YCbCrtoRGB(float Y, float Cb, float Cr)
{
    float R = Y - 0.000982f * Cb + 1.401845f * Cr;
    float G = Y - 0.345117f * Cb - 0.714291f * Cr;
    float B = Y + 1.771019f * Cb - 0.000154f * Cr;
    return float3( R, G, B );
}*/


////////////////////////////////////////////////////////////////////////////////////////////////
// スクリーンバッファの合成

VS_OUTPUT VS_MixScreen( float4 Pos : POSITION, float2 Tex : TEXCOORD0 )
{
    VS_OUTPUT Out = (VS_OUTPUT)0; 
    Out.Pos = Pos;
    Out.Tex = Tex + ViewportOffset;
    return Out;
}

float4 PS_MixScreen( float2 Tex: TEXCOORD0 ) : COLOR
{
    // SSAOのマップ座標に修正
    float2 offset = float2(1.0f - 1.0f/TrueScnScale.x, 1.0f - 1.0f/TrueScnScale.y) * 0.5f;
    float2 Tex0 = Tex / TrueScnScale + offset;

    float ssao = tex2D( SSAOSamp, Tex0 ).r;

    // 輪郭部のジャギーをなじませる
    float2 SmpStep = float2(1,1)/WorkViewportSize;
    ssao += ssao;
    ssao += tex2D( SSAOSamp, Tex0+SmpStep*float2( 0,-1) ).r;
    ssao += tex2D( SSAOSamp, Tex0+SmpStep*float2( 0, 1) ).r;
    ssao += tex2D( SSAOSamp, Tex0+SmpStep*float2(-1, 0) ).r;
    ssao += tex2D( SSAOSamp, Tex0+SmpStep*float2( 1, 0) ).r;
    ssao += tex2D( SSAOSamp, Tex0+SmpStep*float2(-1,-1) ).r;
    ssao += tex2D( SSAOSamp, Tex0+SmpStep*float2( 1,-1) ).r;
    ssao += tex2D( SSAOSamp, Tex0+SmpStep*float2(-1, 1) ).r;
    ssao += tex2D( SSAOSamp, Tex0+SmpStep*float2( 1, 1) ).r;
    ssao *= 0.1f;

    // 元画像の色
    float4 Color = (1,1,1,1);// = tex2D( ScnSamp, Tex );

    // RGBからYCbCrへの変換
    // float Y, Cb, Cr;
    // RGBtoYCbCr( Color.rgb, Y, Cb, Cr);

    // 合成
    float a = clamp(1.0f - 0.05f * AcsSi * ssao, 0.1f, 1.0f);
    // float density = 1.0f / a;
    // float3 color = lerp(Color.rgb*a, Color.rgb, pow(Color.rgb, density));
    // Color.rgb = lerp( YCbCrtoRGB( Y*a, Cb, Cr), color, AcsTr);

    // if( FlagVisibleAO ) {
        // AO表示
        Color.rgb = a.rrr;//float4(1-ssao, 1-ssao, 1-ssao, 1);
    // }

    return Color;
}


////////////////////////////////////////////////////////////////////////////////////////////////
// テクニック

technique MainTech <
    string Script = 
        // オリジナルの描画
        /*"RenderColorTarget0=ScnMap;"
            "RenderDepthStencilTarget=ScnMapDepthBuffer;"
            "ClearSetColor=ClearColor;"
            "ClearSetDepth=ClearDepth;"
            "Clear=Color;"
            "Clear=Depth;"
            "ScriptExternal=Color;"*/
        // SSAO処理
        "RenderColorTarget0=SSAO_Tex;"
            "RenderDepthStencilTarget=DepthBuffer;"
            "ClearSetColor=ClearColor;"
            "ClearSetDepth=ClearDepth;"
            "Clear=Color;"
            "Clear=Depth;"
            "Pass=SSAODraw;"

        // SSAOマップのぼかしY方向
        "RenderColorTarget0=SSAO_Tex2;"
            "RenderDepthStencilTarget=DepthBuffer;"
            "ClearSetColor=ClearColor;"
            "ClearSetDepth=ClearDepth;"
            "Clear=Color;"
            "Clear=Depth;"
            "Pass=SSAOGaussianY;"
        // SSAOマップのぼかしX方向
        "RenderColorTarget0=SSAO_Tex;"
            "RenderDepthStencilTarget=DepthBuffer;"
            "ClearSetColor=ClearColor;"
            "ClearSetDepth=ClearDepth;"
            "Clear=Color;"
            "Clear=Depth;"
            "Pass=SSAOGaussianX;"

        // 描画結果書き出し
            "RenderColorTarget0=SSAO_Tex3;"
            "RenderDepthStencilTarget=DepthBuffer2;"
            "ClearSetColor=ClearColor;"
            "ClearSetDepth=ClearDepth;"
            "Clear=Color;"
            "Clear=Depth;"
            "Pass=MixPass;"
    ;
> {
    pass SSAODraw < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 VS_Common();
        PixelShader  = compile ps_3_0 PS_SSAO();
    }
    pass SSAOGaussianY < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 VS_Common();
        PixelShader  = compile ps_3_0 PS_SSAOGaussianY();
    }
    pass SSAOGaussianX < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 VS_Common();
        PixelShader  = compile ps_3_0 PS_SSAOGaussianX();
    }
    pass MixPass < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 VS_MixScreen();
        PixelShader  = compile ps_3_0 PS_MixScreen();
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////
