
////////////////////////////////////////////////////////////////////////////////////////////////
// モデルを黒く塗りつぶすエフェクト
////////////////////////////////////////////////////////////////////////////////////////////////

// 座法変換行列
float4x4 WorldViewProjMatrix      : WORLDVIEWPROJECTION;

float4 MaterialDiffuse : DIFFUSE  < string Object = "Geometry"; >;
static float alpha1 = MaterialDiffuse.a;

bool use_texture;  //テクスチャの有無

// オブジェクトのテクスチャ
texture ObjectTexture: MATERIALTEXTURE;
sampler ObjTexSampler = sampler_state
{
    texture = <ObjectTexture>;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

// MMD本来のsamplerを上書きしないための記述です。削除不可。
sampler MMDSamp0 : register(s0);
sampler MMDSamp1 : register(s1);
sampler MMDSamp2 : register(s2);

////////////////////////////////////////////////////////////////////////////////////////////////

struct VS_OUTPUT
{
    float4 Pos        : POSITION;    // 射影変換座標
    float2 Tex        : TEXCOORD1;   // テクスチャ
};

// 頂点シェーダ
VS_OUTPUT Basic_VS(float4 Pos : POSITION, float3 Normal : NORMAL, float2 Tex : TEXCOORD0)
{
    VS_OUTPUT Out = (VS_OUTPUT)0;
    
    // カメラ視点のワールドビュー射影変換
    Out.Pos = mul( Pos, WorldViewProjMatrix );
    
    // テクスチャ座標
    Out.Tex = Tex;
    
    return Out;
}

float4 Basic_PS( VS_OUTPUT IN ) : COLOR0 {
    float alpha = alpha1;
    if ( use_texture ) alpha *= tex2D( ObjTexSampler, IN.Tex ).a;
    return float4(0.0, 0.0, 0.0, alpha);
}

//セルフシャドウなし
technique Mask < string MMDPass = "object"; > {
    pass Single_Pass { 
        VertexShader = compile vs_2_0 Basic_VS();
        PixelShader = compile ps_2_0 Basic_PS(); 
    }
}

//セルフシャドウあり
technique MaskSS < string MMDPass = "object_ss"; > {
    pass Single_Pass { 
        VertexShader = compile vs_2_0 Basic_VS();
        PixelShader = compile ps_2_0 Basic_PS(); 
    }
}

//影や輪郭は描画しない
technique EdgeTec < string MMDPass = "edge"; > { }
technique ShadowTec < string MMDPass = "shadow"; > { }
technique ZplotTec < string MMDPass = "zplot"; > { }

