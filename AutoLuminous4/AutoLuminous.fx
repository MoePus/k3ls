////////////////////////////////////////////////////////////////////////////////////////////////
//
//  AutoLuminous Ver.4.1
//  作成: そぼろ
//
////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////
// ユーザーパラメータ

#ifdef MIKUMIKUMOVING

int Glare <
   string UIName = "Glare";
   string UIWidget = "Slider";
   string UIHelp = "光芒の数を指定します。";
   bool UIVisible =  true;
   int UIMin = 0;
   int UIMax = 6;
> = 0;

#endif

//MMM用グレア角度
float GlareAngle2 <
   string UIName = "GlareAngle";
   string UIWidget = "Slider";
   string UIHelp = "光芒角度";
   bool UIVisible =  true;
   float UIMin = 0;
   float UIMax = 180;
> = 0.0;

//MMM用グレア長さ
float GlareLength <
   string UIName = "GlareLength";
   string UIWidget = "Slider";
   string UIHelp = "光芒長さ";
   bool UIVisible =  true;
   float UIMin = 0;
   float UIMax = 2.0;
> = 1.0;


//MMM用発光強度
float Power2 <
   string UIName = "LightPower";
   string UIWidget = "Slider";
   string UIHelp = "発光強度";
   bool UIVisible =  true;
   float UIMin = 0;
   float UIMax = 20;
> = 1.0;

// ぼかし範囲
float AL_Extent <
   string UIName = "AL_Extent";
   string UIWidget = "Slider";
   string UIHelp = "発光ぼかし範囲";
   bool UIVisible =  true;
   float UIMin = 0;
   float UIMax = 0.2;
> = 0.07;


//グレア強度　1.0前後
float GlarePower <
   string UIName = "GlarePower";
   string UIWidget = "Slider";
   string UIHelp = "グレア強度";
   bool UIVisible =  true;
   float UIMin = 0;
   float UIMax = 3;
> = 1.2;

//白飛び係数　0～1
float OverExposureRatio <
   string UIName = "OverExposure";
   string UIWidget = "Slider";
   string UIHelp = "白飛び係数";
   bool UIVisible =  true;
   float UIMin = 0;
   float UIMax = 3;
> = 0.85;

//弱光減衰　0～1
float Modest <
   string UIName = "Modest";
   string UIWidget = "Slider";
   string UIHelp = "弱い光があまり拡散しなくなります";
   bool UIVisible =  true;
   float UIMin = 0;
   float UIMax = 2.0;
> = 1.0;

#ifdef MIKUMIKUMOVING

float ScreenToneCurve <
   string UIName = "ToneCurve";
   string UIWidget = "Slider";
   string UIHelp = "トーンカーブ変更";
   bool UIVisible =  true;
   float UIMin = 0;
   float UIMax = 1;
> = 0;

#endif


//背景色
const float4 BackColor <
   string UIName = "BackColor";
   string UIWidget = "Color";
   string UIHelp = "背景色";
   bool UIVisible =  true;
> = float4( 0, 0, 0, 0 );


//残像強度　0～50程度　0で無効
#define AFTERGLOW  8

//一方向のサンプリング数
#define AL_SAMP_NUM   12

//グレアの一方向のサンプリング数
#define AL_SAMP_NUM2  32



///////////////////////////////////////////////////////////////////////////////////////////////
//キーカラー

//キーカラー認識閾値
float KeyThreshold = 0.38;

//キーカラー数・0でキーカラー無効
#define KEYCOLOR_NUM  0 //2

#if KEYCOLOR_NUM!=0
    float3 KeyColors [KEYCOLOR_NUM][3] = {
        //{{キー色},{コア色},{発光色}}, のように並べます
        //必ず KEYCOLOR_NUM で指定した数だけ並べます(0を除く)
        {{1, 0, 1}, {0.2, 0.2, 0.1}, {0.8, 0.5, 0.3}},
        {{0, 0, 1}, {1.0, 0.8, 1.0}, {0.2, 0.4, 1.0}},
        
    };
#endif

///////////////////////////////////////////////////////////////////////////////////////////////
//オプションスイッチ

//編集中の点滅をフレーム数に同期させる
//trueだとフレーム数に応じて光の強さが変化
//falseだと編集中も点滅し続けます
#define SYNC false

//発光除外マスクを使用する
//MMEタブに AL_MaskRT が現れます。
//詳しい使い方はReadme上級編にて。
#define MASK_ENABLE  0

//トーンカーブの適用を強制
//0がオフ、1がオンです
//ToneCurve.xを読み込むのが面倒であればオンにします
#define SCREEN_TONECURVE  0

//グレアを１方向だけ強調します
//0がオフ、1がオンです
//グレアのサンプリング数もそれに応じて増やすことを推奨
#define GLARE_LONGONE  1


//厳密アルファ出力モード
//MMD上での表示はおかしくなりますが、動画や画像出力としては
//厳密に正しいアルファ付きデータが得られます
//0がオフ、1がオンです
#define ALPHA_OUT  0

//MMD上の描画をHDR情報として扱います
//明るさが1を超えた部分が光って見えるようになります
//0がオフ、1がオンです
#define HDR_RENDER  1

//作業用バッファのサイズを半分にして軽くします
//画質は落ちます
//0がオフ、1がオンです
#define HALF_DRAW  0


//テクスチャフォーマット
#define AL_TEXFORMAT "D3DFMT_A16B16G16R16F"


////////////////////////////////////////////////////////////////////////////////////

#if HALF_DRAW==0
    #define TEXSIZE1  1
    #define TEXSIZE2  0.5
    #define TEXSIZE3  0.25
    #define TEXSIZE4  0.125
    #define TEXSIZE5  0.0625
    
#else
    #define TEXSIZE1  0.5
    #define TEXSIZE2  0.25
    #define TEXSIZE3  0.125
    #define TEXSIZE4  0.0625
    #define TEXSIZE5  0.03125
    
#endif

///////////////////////////////////////////////////////////////////////////////////////////////
// 光放射オブジェクト描画先

texture AL_EmitterRT: OFFSCREENRENDERTARGET <
    string Description = "EmitterDrawRenderTarget for AutoLuminous.fx";
    float2 ViewPortRatio = {TEXSIZE1,TEXSIZE1};
    float4 ClearColor = { 0, 0, 0, 1 };
    float ClearDepth = 1.0;
    bool AntiAlias = true;
    int MipLevels = 0;
    string Format = AL_TEXFORMAT;
    string DefaultEffect = 
        "self = hide;"
        "*Luminous.x = hide;"
        "ToneCurve.x = hide;"
        
        //------------------------------------
        //セレクタエフェクトはここで指定します
        
        
        
        //------------------------------------
        
        //"* = hide;" 
        "* = AL_Object.fxsub;" 
    ;
>;


///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
//これ以降はエフェクトの知識のある人以外は触れないこと

sampler EmitterView = sampler_state {
    texture = <AL_EmitterRT>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Point;
    AddressU  = Clamp;
    AddressV = Clamp;
};

////////////////////////////////////////////////////////////////////////////////////////////////
// マスク描画先

#if MASK_ENABLE!=0
    
    texture AL_MaskRT: OFFSCREENRENDERTARGET <
        string Description = "MaskDrawRenderTarget for AutoLuminous.fx";
        float2 ViewPortRatio = {1.0,1.0};
        float4 ClearColor = { 0, 0, 0, 0 };
        float ClearDepth = 1.0;
        bool AntiAlias = true;
        int MipLevels = 1;
        string Format = "D3DFMT_A8";
        string DefaultEffect = 
            "self = hide;"
            "* = hide;" 
        ;
    >;

    sampler MaskView = sampler_state {
        texture = <AL_MaskRT>;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = None;
        AddressU  = Clamp;
        AddressV = Clamp;
    };

#endif

////////////////////////////////////////////////////////////////////////////////////////////////

int AL_LoopIndex = 0;


#define PI 3.14159

float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "postprocess";
> = 0.8;



float hash12(float2 p)
{
	float3 p3  = frac(float3(p.xyx) * float3(.1031,.11369,.13787));
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.x + p3.y) * p3.z);
}

// アルファ取得
float alpha1 : CONTROLOBJECT < string name = "(self)"; string item = "Tr"; >;

float4x4 matWorld : CONTROLOBJECT < string name = "(self)"; >; 
static float pos_y = matWorld._42;
static float pos_z = matWorld._43;

static float OverLight = (pos_y + 100) / 100;


// スケール値取得
float scaling0 : CONTROLOBJECT < string name = "(self)"; >;
static float scaling = scaling0 * 0.1 * (1.0 + pos_z / 100) * Power2;

// X回転
float3 rot : CONTROLOBJECT < string name = "(self)"; string item = "Rxyz"; >;

static float Power3 = scaling * (1.0 + pos_z / 100) * Power2;

//光芒の数

#ifndef MIKUMIKUMOVING

float Glare : CONTROLOBJECT < string name = "(self)"; string item = "X"; >;


#endif

//光芒の長さ
static float _GlareAspect = (rot.y * 180 / PI + 100) / 100.0 * GlareLength;

//光芒角度
static float GlareAngle = rot.x + GlareAngle2 * PI / 180.0;


#ifndef MIKUMIKUMOVING
    #if SCREEN_TONECURVE==0
        bool ScreenToneCurve : CONTROLOBJECT < string name = "ToneCurve.x"; >;
    #else
        bool ScreenToneCurve = true;
    #endif
#endif


//時間
float ftime : TIME <bool SyncInEditMode = SYNC;>;

static float xtime = ftime - fmod(ftime,0.14);
//static float timerate = (rot.z > 0) ? ((1 + cos(ftime * 2 * PI / (rot.z / PI * 180))) * 0.4 + 0.2)
//                     : ((rot.z < 0) ? (frac(ftime / (-rot.z / PI * 180)) < 0.5) : 1.0);

static float timerate = (rot.z > 0) ? ((1 + cos(ftime * 2 * PI / (rot.z / PI * 180))) * 0.4 + 0.2)
                     : ((rot.z < 0) ? (1 + -frac(-rot.z* 180 / PI) + lerp(0,1,frac(-rot.z* 180 / PI) * hash12(float2(xtime,rot.z)))) : 1.0);

static float GlareAspect = (rot.z >= 0) ? _GlareAspect : (_GlareAspect + 0.05 * (-rot.z* 180 / PI - frac(-rot.z* 180 / PI))* hash12(float2(xtime,rot.z)));;
					 
// スクリーンサイズ
float2 ViewportSize : VIEWPORTPIXELSIZE;
static float ViewportAspect = ViewportSize.x / ViewportSize.y;
static float2 ViewportOffset = (float2(0.5,0.5)/ViewportSize);
static float2 OnePx = (float2(1,1)/ViewportSize);

//static float2 AL_SampStep = (float2(AL_Extent,AL_Extent) / ViewportSize * ViewportSize.y);
static float2 AL_SampStep = (AL_Extent * float2(1/ViewportAspect, 1));
static float2 AL_SampStepScaled = AL_SampStep * alpha1 / (float)AL_SAMP_NUM * 1.103;

static float AL_SampStep2 = AL_Extent * alpha1 / (float)AL_SAMP_NUM2 * GlareAspect;



bool ExternLightSampling : CONTROLOBJECT < string name = "LightSampling.x"; >;


bool TestMode : CONTROLOBJECT < string name = "AL_Test.x"; >;
float TestValue : CONTROLOBJECT < string name = "AL_Test.x"; >;



////////////////////////////////////////////////////////////////////////////////////
// 深度バッファ
texture2D DepthBuffer : RENDERDEPTHSTENCILTARGET <
    float2 ViewPortRatio = {TEXSIZE1,TEXSIZE1};
    string Format = "D24S8";
>;
texture2D DepthBuffer2 : RENDERDEPTHSTENCILTARGET <
    float2 ViewPortRatio = {TEXSIZE2,TEXSIZE2};
    string Format = "D24S8";
>;
texture2D DepthBuffer3 : RENDERDEPTHSTENCILTARGET <
    float2 ViewPortRatio = {TEXSIZE3,TEXSIZE3};
    string Format = "D24S8";
>;
texture2D DepthBuffer4 : RENDERDEPTHSTENCILTARGET <
    float2 ViewPortRatio = {TEXSIZE4,TEXSIZE4};
    string Format = "D24S8";
>;
texture2D DepthBuffer5 : RENDERDEPTHSTENCILTARGET <
    float2 ViewPortRatio = {TEXSIZE5,TEXSIZE5};
    string Format = "D24S8";
>;

///////////////////////////////////////////////////////////////////////////////////////////////

// オリジナルの描画結果を記録するためのレンダーターゲット
texture2D ScnMap : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    int MipLevels = 1;
    #if HDR_RENDER==0
        string Format = "A8R8G8B8" ;
    #else
        string Format = AL_TEXFORMAT ;
    #endif
>;
sampler2D ScnSamp = sampler_state {
    texture = <ScnMap>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

// 高輝度部分を記録するためのレンダーターゲット
texture2D HighLight : RENDERCOLORTARGET <
    float2 ViewPortRatio = {TEXSIZE1,TEXSIZE1};
    int MipLevels = 0;
    string Format = AL_TEXFORMAT ;
    
>;
sampler2D HighLightView = sampler_state {
    texture = <HighLight>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Point;
    AddressU  = Border;
    AddressV = Border;
};

// 外部から高輝度部分を取得するためのレンダーターゲット
shared texture2D ExternalHighLight : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    int MipLevels = 1;
    string Format = AL_TEXFORMAT ;
    
>;
sampler2D ExternalHighLightView = sampler_state {
    texture = <ExternalHighLight>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = NONE;
    AddressU  = Border;
    AddressV = Border;
};

// X方向のぼかし結果を記録するためのレンダーターゲット
texture2D ScnMapX : RENDERCOLORTARGET <
    float2 ViewPortRatio = {TEXSIZE1,TEXSIZE1};
    int MipLevels = 1;
    string Format = AL_TEXFORMAT ;
>;
sampler2D ScnSampX = sampler_state {
    texture = <ScnMapX>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Point;
    AddressU  = Clamp;
    AddressV = Clamp;
};

// 出力結果を記録するためのレンダーターゲット
texture2D ScnMapOut : RENDERCOLORTARGET <
    float2 ViewPortRatio = {TEXSIZE1,TEXSIZE1};
    int MipLevels = 1;
    string Format = AL_TEXFORMAT ;
>;
sampler2D ScnSampOut = sampler_state {
    texture = <ScnMapOut>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Point;
    AddressU  = Clamp;
    AddressV = Clamp;
};

// X方向のぼかし結果を記録するためのレンダーターゲット
texture2D ScnMapX2 : RENDERCOLORTARGET <
    float2 ViewPortRatio = {TEXSIZE2,TEXSIZE2};
    int MipLevels = 1;
    string Format = AL_TEXFORMAT ;
>;
sampler2D ScnSampX2 = sampler_state {
    texture = <ScnMapX2>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Point;
    AddressU  = Clamp;
    AddressV = Clamp;
};

// 出力結果を記録するためのレンダーターゲット
texture2D ScnMapOut2 : RENDERCOLORTARGET <
    float2 ViewPortRatio = {TEXSIZE2,TEXSIZE2};
    int MipLevels = 1;
    string Format = AL_TEXFORMAT ;
>;
sampler2D ScnSampOut2 = sampler_state {
    texture = <ScnMapOut2>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Point;
    AddressU  = Clamp;
    AddressV = Clamp;
};

// X方向のぼかし結果を記録するためのレンダーターゲット
texture2D ScnMapX3 : RENDERCOLORTARGET <
    float2 ViewPortRatio = {TEXSIZE3,TEXSIZE3};
    int MipLevels = 1;
    string Format = AL_TEXFORMAT ;
>;
sampler2D ScnSampX3 = sampler_state {
    texture = <ScnMapX3>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Point;
    AddressU  = Clamp;
    AddressV = Clamp;
};

// 出力結果を記録するためのレンダーターゲット
texture2D ScnMapOut3 : RENDERCOLORTARGET <
    float2 ViewPortRatio = {TEXSIZE3,TEXSIZE3};
    int MipLevels = 1;
    string Format = AL_TEXFORMAT ;
>;
sampler2D ScnSampOut3 = sampler_state {
    texture = <ScnMapOut3>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Point;
    AddressU  = Clamp;
    AddressV = Clamp;
};

// X方向のぼかし結果を記録するためのレンダーターゲット
texture2D ScnMapX4 : RENDERCOLORTARGET <
    float2 ViewPortRatio = {TEXSIZE4,TEXSIZE4};
    int MipLevels = 1;
    string Format = AL_TEXFORMAT ;
>;
sampler2D ScnSampX4 = sampler_state {
    texture = <ScnMapX4>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Point;
    AddressU  = Clamp;
    AddressV = Clamp;
};

// 出力結果を記録するためのレンダーターゲット
texture2D ScnMapOut4 : RENDERCOLORTARGET <
    float2 ViewPortRatio = {TEXSIZE4,TEXSIZE4};
    int MipLevels = 1;
    string Format = AL_TEXFORMAT ;
>;
sampler2D ScnSampOut4 = sampler_state {
    texture = <ScnMapOut4>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Point;
    AddressU  = Clamp;
    AddressV = Clamp;
};

// X方向のぼかし結果を記録するためのレンダーターゲット
texture2D ScnMapX5 : RENDERCOLORTARGET <
    float2 ViewPortRatio = {TEXSIZE5,TEXSIZE5};
    int MipLevels = 1;
    string Format = AL_TEXFORMAT ;
>;
sampler2D ScnSampX5 = sampler_state {
    texture = <ScnMapX5>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Point;
    AddressU  = Clamp;
    AddressV = Clamp;
};

// 出力結果を記録するためのレンダーターゲット
texture2D ScnMapOut5 : RENDERCOLORTARGET <
    float2 ViewPortRatio = {TEXSIZE5,TEXSIZE5};
    int MipLevels = 1;
    string Format = AL_TEXFORMAT ;
>;
sampler2D ScnSampOut5 = sampler_state {
    texture = <ScnMapOut5>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Point;
    AddressU  = Clamp;
    AddressV = Clamp;
};

// グレアを記録するためのレンダーターゲット
texture2D ScnMapGlare : RENDERCOLORTARGET <
    float2 ViewPortRatio = {TEXSIZE2,TEXSIZE2};
    int MipLevels = 1;
    string Format = AL_TEXFORMAT ;
>;
sampler2D ScnSampGlare = sampler_state {
    texture = <ScnMapGlare>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Point;
    AddressU  = Clamp;
    AddressV = Clamp;
};


#if AFTERGLOW!=0
    
    // 残光を記録するためのレンダーターゲット
    texture2D AfterGlowMap : RENDERCOLORTARGET <
        float2 ViewPortRatio = {TEXSIZE2,TEXSIZE2};
        int MipLevels = 1;
        string Format = AL_TEXFORMAT ;
    >;
    sampler2D AfterGlowSamp = sampler_state {
        texture = <AfterGlowMap>;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Point;
        AddressU  = Clamp;
        AddressV = Clamp;
    };
    
#endif

////////////////////////////////////////////////////////////////////////////////////////////////
// 白とび表現関数
float4 OverExposure(float4 color){
    float4 newcolor = color;
    
    //ある色が1を超えると、他の色にあふれる
    newcolor.gb += max(color.r - 1, 0) * OverExposureRatio * float2(0.65, 0.6);
    newcolor.rb += max(color.g - 1, 0) * OverExposureRatio * float2(0.5, 0.6);
    newcolor.rg += max(color.b - 1, 0) * OverExposureRatio * float2(0.5, 0.6);
    
    return newcolor;
}


////////////////////////////////////////////////////////////////////////////////////////////////
//キーカラー比較

float ColorMuch(float4 color1, float3 key){
    float3 s = color1.rgb - key;
    float val = length(s) / KeyThreshold;
    val = saturate((1 - val) * 4);
    return val;
}

////////////////////////////////////////////////////////////////////////////////////////////////
//トーンカーブの調整
//自分でも何がどうなっているかよくわからない関数になってしまったが、
//何となくうまく動いているので怖くていじれない

float4 ToneCurve(float4 Color){
    float3 newcolor;
    const float th = 0.65;
    newcolor = normalize(Color.rgb) * (th + sqrt(max(0, (length(Color.rgb) - th) / 2)));
    newcolor.r = (Color.r > 0) ? newcolor.r : Color.r;
    newcolor.g = (Color.g > 0) ? newcolor.g : Color.g;
    newcolor.b = (Color.b > 0) ? newcolor.b : Color.b;
    
    Color.rgb = min(Color.rgb, newcolor);
    
    return Color;
}

////////////////////////////////////////////////////////////////////////////////////////////////
//共通頂点シェーダ
struct VS_OUTPUT {
    float4 Pos            : POSITION;
    float2 Tex            : TEXCOORD0;
};

VS_OUTPUT VS_ALDraw( float4 Pos : POSITION, float2 Tex : TEXCOORD0 , uniform int miplevel) {
    VS_OUTPUT Out = (VS_OUTPUT)0; 
    
    
    #ifdef MIKUMIKUMOVING
    float ofsetsize = 1;
    #else
    float ofsetsize = pow(2, miplevel);
    #endif
    
    
    Out.Pos = Pos;
    Out.Tex = Tex + float2(ViewportOffset.x, ViewportOffset.y) * ofsetsize;
    
    return Out;
}


////////////////////////////////////////////////////////////////////////////////////////////////
//高輝度成分の抽出

struct DoubleColor{
    float4 Color0  : COLOR0;
    float4 Color1  : COLOR1;
};

DoubleColor PS_DrawHighLight( float2 Tex: TEXCOORD0 ) {
    DoubleColor Out = (DoubleColor)0;
    float4 Color, OrgColor, OverLightColor, ExtColor;
    
    Color = tex2Dlod(EmitterView, float4(Tex, 0, 0));
    //Color.a = 0;
    
    //元スクリーンの高輝度成分の抽出
    OrgColor = tex2Dlod(ScnSamp, float4(Tex, 0, 0));
	OrgColor = pow(OrgColor,1/2.4);
    OverLightColor = OrgColor * OverLight;
    OverLightColor = max(0, OverLightColor - 0.936);
    OverLightColor = ToneCurve(OverLightColor);
    
    #if KEYCOLOR_NUM!=0
        [unroll] //ループ展開
        for(int i = 0; i < KEYCOLOR_NUM; i++){
            float cm = ColorMuch(OrgColor, KeyColors[i][0]);
            Color.rgb += cm * KeyColors[i][2];
            Out.Color1 = lerp(Out.Color1, float4(KeyColors[i][1], 1), cm);
        }
    #endif
    
    Color *= timerate;
    
    ExtColor = tex2Dlod(ExternalHighLightView, float4(Tex, 0, 0));
    Color.rgb += (OverLightColor.rgb * !ExternLightSampling + ExtColor.rgb);
    
    Color *= scaling * 2;
    
    Color.a = 1;
    
    Out.Color0 = Color;
    
    return Out;
}

////////////////////////////////////////////////////////////////////////////////////////////////

#define HLSampler HighLightView

////////////////////////////////////////////////////////////////////////////////////////////////
// MipMap利用ぼかし

float4 PS_AL_Gaussian( float2 Tex: TEXCOORD0, 
           uniform bool Horizontal, uniform sampler2D Samp, 
           uniform int miplevel, uniform int scalelevel
           ) : COLOR {
    
    float e, n = 0;
    float2 stex;
    float4 Color, sum = 0;
    float scalepow = pow(2, scalelevel);
    float step = (Horizontal ? AL_SampStepScaled.x : AL_SampStepScaled.y) * scalepow;
    const float2 dir = float2(Horizontal, !Horizontal);
    float4 scolor;
    
    [unroll] //ループ展開
    for(int i = -AL_SAMP_NUM; i <= AL_SAMP_NUM; i++){
        e = exp(-pow((float)i / (AL_SAMP_NUM / 2.0), 2) / 2); //正規分布
        stex = Tex + dir * (step * (float)i);
        scolor = tex2Dlod( Samp, float4(stex, 0, miplevel));
        sum += scolor * e;
        n += e;
    }
    
    Color = sum / n;
    
    //低輝度領域の光の広がりを制限
    //if(!Horizontal) Color = max(0, abs(Color) - scalepow * (2 - alpha1) * 0.002) * sign(Color);
    //Color = max(0, abs(Color) - scalepow * 0.0007) * sign(Color);
    if(!Horizontal) Color = min(abs(Color), pow(abs(Color), 1 + scalelevel * 0.1 * (2 - alpha1) * Modest)) * sign(Color);
    
    return Color;
}


////////////////////////////////////////////////////////////////////////////////////////////////
//方向性ぼかし

float4 PS_AL_DirectionalBlur( float2 Tex: TEXCOORD0 , uniform sampler2D Samp, uniform bool isfirst) : COLOR {   
    float e, n = 0;
    float2 stex1, stex2, stex3, stex4;
    float4 Color, sum = 0;
    float4 sum1 = 0, sum2 = 0, sum3 = 0, sum4 = 0;
    
    float step = AL_SampStep2 * (1.0 + cos(AL_LoopIndex * 5.1 + rot.x * 10) * 0.3);
    
    float ang = (AL_LoopIndex * 180.0 / (int)Glare) * PI / 180 + GlareAngle;
    float2 dir = float2(cos(ang) / ViewportAspect, sin(ang)) * step;
    float p = 1;
    
    #if GLARE_LONGONE!=0
        p = (1 + (AL_LoopIndex == 0)) * 0.7;
        dir *= p;
    #endif
    
    [unroll] //ループ展開
    for(int i = -AL_SAMP_NUM2; i <= AL_SAMP_NUM2; i++){
        e = exp(-pow((float)i / (AL_SAMP_NUM2 / 2.0), 2) / 2); //正規分布
        if(isfirst){
            stex1 = Tex + dir * ((float)i * 1.0);
            stex2 = Tex + dir * ((float)i * 1.8);
            stex3 = Tex + dir * ((float)i * 3.9);
            //stex4 = Tex + dir * ((float)i * 7.7);
        }else{
            stex1 = Tex + dir * ((float)i * 0.75);
        }
        if(isfirst){
            sum1 += max(0, tex2Dlod( Samp, float4(stex1, 0, 1) )) * e;
            sum2 += max(0, tex2Dlod( Samp, float4(stex2, 0, 2) )) * e;
            sum3 += max(0, tex2Dlod( Samp, float4(stex3, 0, 3) )) * e;
            //sum4 += max(0, tex2Dlod( Samp, float4(stex4, 0, 4) )) * e;
        }else{
            sum1 += max(0, tex2Dlod( Samp, float4(stex1, 0, 0) )) * e;
        }
        
        n += e;
    }
    
    sum1 /= n;
    sum2 /= n;
    sum3 /= n;
    //sum4 /= n;
    
    sum1 = max(0, sum1 - 0.006); sum2 = max(0, sum2 - 0.015); sum3 = max(0, sum3 - 0.029); //sum4 = max(0, sum4 - 0.032);
    
    Color = sum1 + sum2 + sum3 + sum4;
    
    if(isfirst){
        Color *= GlareAspect;
        Color *= p;
        Color /= sqrt(0.2 + (float)((int)Glare));
        Color = ToneCurve(Color * GlarePower);
    }
    
    return Color;
}

////////////////////////////////////////////////////////////////////////////////////////////////

float4 PS_DrawCoreColor( float2 Tex: TEXCOORD0 ) : COLOR {
    float4 Color;
    
    Color = tex2D(ScnSampOut, Tex);
    
    Color = max(Color, 0.8 * tex2D( ScnSampOut, Tex+float2(0,OnePx.y)));
    Color = max(Color, 0.8 * tex2D( ScnSampOut, Tex+float2(0,-OnePx.y)));
    Color = max(Color, 0.8 * tex2D( ScnSampOut, Tex+float2(OnePx.x,0)));
    Color = max(Color, 0.8 * tex2D( ScnSampOut, Tex+float2(-OnePx.x,0)));
    
    Color = max(Color, 0.5 * tex2D( ScnSampOut, Tex+float2(OnePx.x,OnePx.y)));
    Color = max(Color, 0.5 * tex2D( ScnSampOut, Tex+float2(OnePx.x,-OnePx.y)));
    Color = max(Color, 0.5 * tex2D( ScnSampOut, Tex+float2(-OnePx.x,OnePx.y)));
    Color = max(Color, 0.5 * tex2D( ScnSampOut, Tex+float2(-OnePx.x,-OnePx.y)));
    
    return Color;
}

////////////////////////////////////////////////////////////////////////////////////////////////

#if AFTERGLOW!=0
    float4 PS_AfterGlowCopy( float2 Tex: TEXCOORD0 ) : COLOR {
        float4 Color = tex2D(AfterGlowSamp, Tex);
        float2 step = AL_SampStep * 0.1;
        
        Color += tex2D(AfterGlowSamp, Tex + float2(step.x, 0));
        Color += tex2D(AfterGlowSamp, Tex - float2(step.x, 0));
        Color += tex2D(AfterGlowSamp, Tex + float2(0, step.y));
        Color += tex2D(AfterGlowSamp, Tex - float2(0, step.y));
        Color /= 5;
        
        
        Color *= (1.0 - 1.0 / AFTERGLOW);
        //Color -= 0.1;
        //Color = max(Color, 0);
        
        return Color;
    }
#endif

////////////////////////////////////////////////////////////////////////////////////////////////
//合成

float4 PS_AL_Mix( float2 Tex: TEXCOORD0 , uniform bool FullOut) : COLOR {
    
    float4 Color;
    
    float crate1 = 1, crate2 = 1, crate3 = 1, crate4 = 0.8;
    
    Color = tex2D(ScnSampOut, Tex);
    Color += tex2D(ScnSampOut2, Tex) * crate1;
    Color += tex2D(ScnSampOut3, Tex) * crate2;
    Color += tex2D(ScnSampOut4, Tex) * crate3;
    Color += tex2D(ScnSampOut5, Tex) * crate4;
    
    Color *= (1 - 0.3 * (Glare >= 1));
    
    Color += tex2D(ScnSampGlare, Tex);
    
    if(!ScreenToneCurve) Color = ToneCurve(Color); //トーンカーブの調整
    
    //マスクの適用
    #if MASK_ENABLE!=0
        Color *= 1 - tex2D(MaskView, Tex).a;
    #endif
    
    #if AFTERGLOW!=0
        Color = max(Color, tex2D(ScnSampX2, Tex));
    #endif
    
    if(!FullOut){
        Color.a = saturate(Color.a);
        return Color;
    }
    
    
    float4 basecolor = tex2D(ScnSamp, Tex);
    basecolor.rgb *= OverLight;
    basecolor.rgb = saturate(basecolor.rgb);
    Color = Color + basecolor;
    
    //白とび表現
    //Color = OverExposure(Color);
    
    if(ScreenToneCurve) Color = ToneCurve(Color); //トーンカーブの調整
    
    Color.a = basecolor.a + length(Color.rgb);
    Color.a = saturate(Color.a);
    Color.rgb /= Color.a;
    
    return Color;
}

////////////////////////////////////////////////////////////////////////////////////////////////

float4 PS_Test( float2 Tex: TEXCOORD0 ) : COLOR {
    return float4(tex2D(HighLightView, Tex).rgb * TestValue * 0.1, 1);
    //return float4(tex2D(EmitterView, Tex).rgb, 1);
    
}

////////////////////////////////////////////////////////////////////////////////////////////////
//テクニック

// レンダリングターゲットのクリア値

float4 ClearColor = {0,0,0,0};
float ClearDepth  = 1.0;


technique AutoLuminous <
    string Script = 
        
        "RenderColorTarget0=ExternalHighLight;"
        "ClearSetColor=ClearColor;"
        "Clear=Color;"
        
        "RenderColorTarget0=ScnMap;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "ClearSetColor=BackColor; ClearSetDepth=ClearDepth;"
        "Clear=Color; Clear=Depth;"
        "ScriptExternal=Color;"
        
        "RenderColorTarget0=HighLight;"
        "RenderColorTarget1=ScnMapOut;"
        "ClearSetColor=ClearColor; ClearSetDepth=ClearDepth;"
        "Clear=Color; Clear=Depth;"
        "Pass=DrawHighLight;"
        
        #if KEYCOLOR_NUM!=0
            "RenderColorTarget0=ScnMap;"
            "RenderColorTarget1=;"
            "RenderDepthStencilTarget=DepthBuffer;"
            "Pass=DrawCoreColor;"
        #endif
        
        
        
        "RenderColorTarget0=ScnMapGlare;"
        "RenderColorTarget1=;"
        "RenderDepthStencilTarget=DepthBuffer2;"
        "Clear=Color; Clear=Depth;"
        
        "LoopByCount=Glare;"
        "LoopGetIndex=AL_LoopIndex;"
            
            "RenderColorTarget0=ScnMapX2;"
            "Clear=Color; Clear=Depth;"
            "Pass=AL_DirectionalBlur1;"
            
            "RenderColorTarget0=ScnMapGlare;"
            "Clear=Depth;"
            "Pass=AL_DirectionalBlur2;"
            
        "LoopEnd=;"
        
        
        "RenderColorTarget0=ScnMapX;"
        "RenderColorTarget1=;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "ClearSetColor=ClearColor; ClearSetDepth=ClearDepth;"
        "Clear=Color; Clear=Depth;"
        "Pass=AL_Gaussian_X;"
        
        "RenderColorTarget0=ScnMapOut;"
        "Clear=Color; Clear=Depth;"
        "Pass=AL_Gaussian_Y;"
        
        "RenderColorTarget0=ScnMapX2;"
        "RenderDepthStencilTarget=DepthBuffer2;"
        "Clear=Color; Clear=Depth;"
        "Pass=AL_Gaussian_X2;"
        
        "RenderColorTarget0=ScnMapOut2;"
        "Clear=Color; Clear=Depth;"
        "Pass=AL_Gaussian_Y2;"
        
        "RenderColorTarget0=ScnMapX3;"
        "RenderDepthStencilTarget=DepthBuffer3;"
        "Clear=Color; Clear=Depth;"
        "Pass=AL_Gaussian_X3;"
        
        "RenderColorTarget0=ScnMapOut3;"
        "Clear=Color; Clear=Depth;"
        "Pass=AL_Gaussian_Y3;"
        
        "RenderColorTarget0=ScnMapX4;"
        "RenderDepthStencilTarget=DepthBuffer4;"
        "Clear=Color; Clear=Depth;"
        "Pass=AL_Gaussian_X4;"
        
        "RenderColorTarget0=ScnMapOut4;"
        "Clear=Color; Clear=Depth;"
        "Pass=AL_Gaussian_Y4;"
        
        
        "RenderColorTarget0=ScnMapX5;"
        "RenderDepthStencilTarget=DepthBuffer5;"
        "Clear=Color; Clear=Depth;"
        "Pass=AL_Gaussian_X5;"
        
        "RenderColorTarget0=ScnMapOut5;"
        "Clear=Color; Clear=Depth;"
        "Pass=AL_Gaussian_Y5;"
        
        
        #if AFTERGLOW!=0
            "RenderColorTarget0=ScnMapX2;"
            "RenderDepthStencilTarget=DepthBuffer2;"
            "ClearSetColor=ClearColor; ClearSetDepth=ClearDepth;"
            "Clear=Color; Clear=Depth;"
            "Pass=AfterGlowCopy;"
            
            "RenderColorTarget0=AfterGlowMap;"
            "RenderDepthStencilTarget=DepthBuffer2;"
            "ClearSetDepth=ClearDepth;"
            "Clear=Depth;"
            "Pass=AfterGlow;"
        #endif
        
        "RenderColorTarget0=;"
        "RenderDepthStencilTarget=;"
        "ClearSetColor=ClearColor; ClearSetDepth=ClearDepth;"
        "Clear=Depth;"
        "Clear=Color;"
        "Pass=AL_Mix;"
        
        "LoopByCount=TestMode;"
        "LoopGetIndex=AL_LoopIndex;"
            
            "Pass=AL_Test;"
            
        "LoopEnd=;"
    ;
    
> {
    
    pass AL_Gaussian_X < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = false;
        AlphaTestEnable = false;
        VertexShader = compile vs_3_0 VS_ALDraw(0);
        PixelShader  = compile ps_3_0 PS_AL_Gaussian(true, HLSampler, 0, 0);
    }
    pass AL_Gaussian_Y < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = false;
        AlphaTestEnable = false;
        VertexShader = compile vs_3_0 VS_ALDraw(0);
        PixelShader  = compile ps_3_0 PS_AL_Gaussian(false, ScnSampX, 0, 0);
    }
    
    pass AL_Gaussian_X2 < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = false;
        AlphaTestEnable = false;
        VertexShader = compile vs_3_0 VS_ALDraw(1);
        PixelShader  = compile ps_3_0 PS_AL_Gaussian(true, HLSampler, 2, 2);
    }
    pass AL_Gaussian_Y2 < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = false;
        AlphaTestEnable = false;
        VertexShader = compile vs_3_0 VS_ALDraw(1);
        PixelShader  = compile ps_3_0 PS_AL_Gaussian(false, ScnSampX2, 0, 2);
    }
    
    pass AL_Gaussian_X3 < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = false;
        AlphaTestEnable = false;
        VertexShader = compile vs_3_0 VS_ALDraw(2);
        PixelShader  = compile ps_3_0 PS_AL_Gaussian(true, HLSampler, 4, 4);
    }
    pass AL_Gaussian_Y3 < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = false;
        AlphaTestEnable = false;
        VertexShader = compile vs_3_0 VS_ALDraw(2);
        PixelShader  = compile ps_3_0 PS_AL_Gaussian(false, ScnSampX3, 0, 4);
    }
    
    pass AL_Gaussian_X4 < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = false;
        AlphaTestEnable = false;
        VertexShader = compile vs_3_0 VS_ALDraw(3);
        PixelShader  = compile ps_3_0 PS_AL_Gaussian(true, HLSampler, 5, 5);
    }
    pass AL_Gaussian_Y4 < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = false;
        AlphaTestEnable = false;
        VertexShader = compile vs_3_0 VS_ALDraw(3);
        PixelShader  = compile ps_3_0 PS_AL_Gaussian(false, ScnSampX4, 0, 5);
    }
    
    pass AL_Gaussian_X5 < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = false;
        AlphaTestEnable = false;
        VertexShader = compile vs_3_0 VS_ALDraw(4);
        PixelShader  = compile ps_3_0 PS_AL_Gaussian(true, HLSampler, 7, 7);
    }
    pass AL_Gaussian_Y5 < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = false;
        AlphaTestEnable = false;
        VertexShader = compile vs_3_0 VS_ALDraw(4);
        PixelShader  = compile ps_3_0 PS_AL_Gaussian(false, ScnSampX5, 0, 7);
    }
    
    
    
    pass AL_DirectionalBlur1 < string Script= "Draw=Buffer;"; > {
        SRCBLEND = ONE;
        DESTBLEND = ONE;
        AlphaTestEnable = false;
        VertexShader = compile vs_3_0 VS_ALDraw(1);
        PixelShader  = compile ps_3_0 PS_AL_DirectionalBlur(HLSampler, true);
    }
    
    pass AL_DirectionalBlur2 < string Script= "Draw=Buffer;"; > {
        SRCBLEND = ONE;
        DESTBLEND = ONE;
        AlphaTestEnable = false;
        VertexShader = compile vs_3_0 VS_ALDraw(1);
        PixelShader  = compile ps_3_0 PS_AL_DirectionalBlur(ScnSampX2, false);
    }
    pass AL_DirectionalBlur3 < string Script= "Draw=Buffer;"; > {
        SRCBLEND = ONE;
        DESTBLEND = ONE;
        AlphaTestEnable = false;
        VertexShader = compile vs_3_0 VS_ALDraw(1);
        PixelShader  = compile ps_3_0 PS_AL_DirectionalBlur(ScnSampOut2, false);
    }
    
    
    
    pass DrawHighLight < string Script= "Draw=Buffer;"; > {
        AlphaTestEnable = false;
        AlphaBlendEnable = false;
        VertexShader = compile vs_3_0 VS_ALDraw(0);
        PixelShader  = compile ps_3_0 PS_DrawHighLight();
    }
    
    pass DrawCoreColor < string Script= "Draw=Buffer;"; > {
        AlphaTestEnable = true;
        AlphaBlendEnable = true;
        VertexShader = compile vs_3_0 VS_ALDraw(0);
        PixelShader  = compile ps_3_0 PS_DrawCoreColor();
    }
    
    #if AFTERGLOW!=0
        pass AfterGlowCopy < string Script= "Draw=Buffer;"; > {
            AlphaTestEnable = false;
            VertexShader = compile vs_3_0 VS_ALDraw(1);
            PixelShader  = compile ps_3_0 PS_AfterGlowCopy();
        }
        
        pass AfterGlow < string Script= "Draw=Buffer;"; > {
            
            #if ALPHA_OUT!=0
                AlphaBlendEnable = false;
                AlphaTestEnable = false;
            #endif
            
            VertexShader = compile vs_3_0 VS_ALDraw(1);
            PixelShader  = compile ps_3_0 PS_AL_Mix(false);
        }
    
    #endif
    
    pass AL_Mix < string Script= "Draw=Buffer;"; > {
        
        #if ALPHA_OUT!=0
            AlphaBlendEnable = false;
            AlphaTestEnable = false;
        #endif
        
        VertexShader = compile vs_3_0 VS_ALDraw(0);
        PixelShader  = compile ps_3_0 PS_AL_Mix(true);
    }
    
    pass AL_Test < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = false;
        AlphaTestEnable = false;
        VertexShader = compile vs_3_0 VS_ALDraw(0);
        PixelShader  = compile ps_3_0 PS_Test();
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////




