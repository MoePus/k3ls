

//背景色 RGBA各色0～1
const float4 BackColor
<
   string UIName = "BackColor";
   string UIWidget = "Color";
   string UIHelp = "背景色";
   bool UIVisible =  true;
> = float4( 0, 0, 0, 0 );

//MMM用発光強度
float ScreenBrightness2 <
   string UIName = "Brightness";
   string UIWidget = "Slider";
   string UIHelp = "画面の明るさ";
   bool UIVisible =  true;
   float UIMin = 0;
   float UIMax = 2;
> = 1.0;




float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "postprocess";
> = 0.8;


bool ParentEnable : CONTROLOBJECT < string name = "AutoLuminous.x"; >; 

float4x4 matWorld : CONTROLOBJECT < string name = "AutoLuminous.x"; >; 
static float pos_y = matWorld._42;
static float pos_z = matWorld._43;

static float OverLight = (pos_y + 100) / 100 * ScreenBrightness2;


float alpha1 : CONTROLOBJECT < string name = "(self)"; string item = "Tr"; >;

// スケール値取得
float scalingL0 : CONTROLOBJECT < string name = "(self)"; >;
static float scalingL = scalingL0 * 0.1;

// スクリーンサイズ
float2 ViewportSize : VIEWPORTPIXELSIZE;
static float Aspect = ViewportSize.x / ViewportSize.y;
static float2 ViewportOffset = (float2(0.5,0.5)/ViewportSize);
static float2 OnePx = (float2(1,1)/ViewportSize);


#define AL_TEXFORMAT "D3DFMT_A16B16G16R16F"

////////////////////////////////////////////////////////////////////////////////////
// 深度バッファ
texture2D DepthBuffer : RENDERDEPTHSTENCILTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    string Format = "D24S8";
>;


///////////////////////////////////////////////////////////////////////////////////////////////

// オリジナルの描画結果を記録するためのレンダーターゲット
texture2D ScnMap : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    int MipLevels = 1;
    string Format = AL_TEXFORMAT ;
    
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
shared texture2D ExternalHighLight : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    int MipLevels = 1;
    string Format = AL_TEXFORMAT ;
    
>;

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
//AL共通頂点シェーダ
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

//元スクリーンの高輝度成分の抽出
float4 PS_LightSampling( float2 Tex: TEXCOORD0 ) : COLOR0 {
    float4 OrgColor, OverLightColor;
    
    OrgColor = tex2Dlod(ScnSamp, float4(Tex, 0, 0));
    OverLightColor = OrgColor * OverLight;
    OverLightColor = max(0, OverLightColor - alpha1);
    OverLightColor = ToneCurve(OverLightColor);
    OverLightColor.a = 1;
    
    OverLightColor.rgb *= ScreenBrightness2 * scalingL;
    
    return OverLightColor;
    
}

////////////////////////////////////////////////////////////////////////////////////////////////
// バッファのコピー

float4 PS_BufCopy( float2 Tex: TEXCOORD0 , uniform sampler2D samp ) : COLOR {   
    float4 Color = tex2D( samp , Tex );
    
    Color = ParentEnable || (abs(Tex.x - 0.5) < 0.49) ? Color : float4(0,0,1,1);
    
    return Color;
}


////////////////////////////////////////////////////////////////////////////////////////////////
//テクニック

// レンダリングターゲットのクリア値

float4 ClearColor = {0,0,0,0};
float ClearDepth  = 1.0;


technique LightSampling <
    string Script = 
        "RenderColorTarget0=ScnMap;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "ClearSetColor=BackColor; ClearSetDepth=ClearDepth;"
        "Clear=Color; Clear=Depth;"
        "ScriptExternal=Color;"
        
        "RenderColorTarget0=ExternalHighLight;"
        "ClearSetDepth=ClearDepth;"
        "Clear=Depth;"
        "Pass=LightSampling;"
        
        "RenderColorTarget0=;"
        "RenderDepthStencilTarget=;"
        "ClearSetColor=BackColor; ClearSetDepth=ClearDepth;"
        "Clear=Color; Clear=Depth;"
        "Pass=BufCopy;"
    ;
    
> {
    
    pass LightSampling < string Script= "Draw=Buffer;"; > {
        AlphaTestEnable = true;
        AlphaBlendEnable = true;
        
        SRCBLEND = ONE; DESTBLEND = ONE; //加算合成
        
        VertexShader = compile vs_3_0 VS_ALDraw(0);
        PixelShader  = compile ps_3_0 PS_LightSampling();
    }
    
    pass BufCopy < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = false;
        AlphaTestEnable = false;
        VertexShader = compile vs_3_0 VS_ALDraw(0);
        PixelShader  = compile ps_3_0 PS_BufCopy(ScnSamp);
    }
    
}

////////////////////////////////////////////////////////////////////////////////////////////////




