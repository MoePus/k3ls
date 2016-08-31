shared texture2D K3LS_GBuffer_01: RENDERCOLORTARGET;

shared texture2D K3LS_GBuffer_01_Depth : RENDERDEPTHSTENCILTARGET;

struct VS_OUTPUT {
    float4 Pos      : POSITION;     // 射影変換座標
    float2 Tex      : TEXCOORD0;    // テクスチャ
    float3 Normal   : TEXCOORD1;    // 法線
    float3 Eye      : TEXCOORD2;    // カメラとの相対位置
	float4 Pos2		: TEXCOORD3;
};


// 頂点シェーダ
VS_OUTPUT Basic_VS(float4 Pos : POSITION, float3 Normal : NORMAL, float2 Tex : TEXCOORD0)
{
    VS_OUTPUT Out = (VS_OUTPUT)0;
    
    // カメラ視点のワールドビュー射影変換
    Out.Pos2 = Out.Pos = mul( Pos, WorldViewProjMatrix );
	Out.Eye = CameraPosition - mul( Pos, WorldMatrix );
    Out.Normal = Normal;
	
    // テクスチャ座標
    Out.Tex = Tex;

    return Out;
}

inline float3 CalcTranslucency(float s)
{
	float dd = s*-s;
	return float3(0.233f, 0.455f, 0.649f) * exp(dd / 0.0064f)
		+ float3(0.1f, 0.336f, 0.344f) * exp(dd / 0.0484f)
		+ float3(0.118f, 0.198f, 0.0f) * exp(dd / 0.187f)
		+ float3(0.113f, 0.007f, 0.007f) * exp(dd / 0.567f)
		+ float3(0.358f, 0.004f, 0.0f) * exp(dd / 1.99f)
		+ float3(0.078f, 0.0f, 0.0f) * exp(dd / 7.41f);
}

// 接空間取得
inline float3x3 compute_tangent_frame(float3 Normal, float3 View, float2 UV)
{
    float3 dp1 = ddx(View);
    float3 dp2 = ddy(View);
    float2 duv1 = ddx(UV);
    float2 duv2 = ddy(UV);

    float3x3 M = float3x3(dp1, dp2, cross(dp1, dp2));
    float2x3 inverseM = float2x3(cross(M[1], M[2]), cross(M[2], M[0]));
    float3 Tangent = mul(float2(duv1.x, duv2.x), inverseM);
    float3 Binormal = mul(float2(duv1.y, duv2.y), inverseM);

    return float3x3(normalize(Tangent), normalize(Binormal), Normal);
}




// ピクセルシェーダ
float4 Basic_PS(VS_OUTPUT IN,uniform const bool useTexture,uniform const bool useNormalMap) : COLOR0
{
	roughness = (roughness * 2.5) + 0.05;
	if (useTexture) 
	{
        float4 TexColor = tex2D(ObjTexSampler, IN.Tex); 
        DiffuseColor = TexColor;
		AmbientColor *= TexColor;
    }
	
	float3 t = tex2D(NorTexSampler, IN.Tex*(1+spaScale*8));
	float3 normal,spa;
    if (useNormalMap && spaornormal>=0.5) 
	{
        float3x3 tangentFrame = compute_tangent_frame(IN.Normal, IN.Eye, IN.Tex*(1+spaScale*8));
        normal = 2.0f * t - 1;
		normal.rg *= ((spaornormal-0.5)*30);
		normal = normalize(normal);
		normal = normalize(mul(normal, tangentFrame));
		spa = (1-specularStrength).xxx;
    } 
	else if(useNormalMap)
	{
        normal = normalize(IN.Normal);
		spa = t*2*(0.5-spaornormal)*(1-specularStrength);
    }else
	{
	    normal = normalize(IN.Normal);
		spa = (1-specularStrength).xxx;
	}
	
	float3 color = DiffuseColor.xyz;
	float3 lightNormal = normalize(-LightDirection);
	float3 viewNormal = normalize(IN.Eye);
	float NL = dot(lightNormal,normal);
		
	IN.Pos2.xyz /= IN.Pos2.w;
	float2 TransScreenTex;
    TransScreenTex.x = (1 + IN.Pos2.x) * 0.5f;
    TransScreenTex.y = (1 - IN.Pos2.y) * 0.5f;
    TransScreenTex += ViewportOffset;

	float ShadowMapVal = saturate(tex2D(ScreenShadowMapProcessedSamp, TransScreenTex).r);
	//float dist = tex2D(ScreenShadowMapSampler, TransScreenTex).b*sqrt(size1)/300.;
	float ToonShade = smoothstep(0, 1.5, NL*0.5f+0.5f);
	float comp = lerp(ToonShade,ShadowMapVal*ToonShade,1-ShadowMapVal);
	
	float irradiance = max(0.3 + dot(-normal, lightNormal), 0.0);
	
	float3 trans;
	if(translucency>0)
	{float s = 1-ShadowMapVal;
	s = max(0,s-0.94)*5.2 +s;
	s*=10.4 - pow(32.74549*translucency,0.66);
	trans= CalcTranslucency(s)*irradiance*color;}
	else
	{trans = 0.0f.xxx;}
	 
	float3 diffuse = (color*comp*NL+trans*pow(comp,0.09)*1.79)*LightAmbient;
	
	float3 mSpec = lerp(0.04,(color+trans)*spa, reflectance);
	
	float3 specular = BRDF(roughness,mSpec,normal,lightNormal,viewNormal)*NL*LightAmbient*DiffuseColor.a*ShadowMapVal;
	
	float SdN = dot(SKYDIR,normal)*0.5f+0.5f;
    float3 Hemisphere = lerp(GROUNDCOLOR, SKYCOLOR, SdN*SdN);
	float3 ambient = Hemisphere*AmbientColor*(1.65-dot(normal,IN.Normal));
	
	float3 outColor = diffuse*(1-metalness)+specular+ambient;
	//outColor.rgb = (1-ShadowMapVal).xxx;
	return float4(outColor,DiffuseColor.a);
}

float4 G_PS(VS_OUTPUT IN) : COLOR0
{
	return float4(SSS.xxx,1);
}

//-----------------------------------------------------------------------------------------------------
// 標準エミュレート
// オブジェクト描画用テクニック（アクセサリ用）
// 不要なものは削除可
technique MainTec0 < 
	string Script = 
	        "RenderColorTarget0=;"
    	    "RenderDepthStencilTarget=;"
    	    "Pass=DrawObject;"
			"RenderColorTarget0=K3LS_GBuffer_01;"
			"RenderDepthStencilTarget=K3LS_GBuffer_01_Depth;"
			"Pass=G;";
	string MMDPass = "object"; bool UseTexture = false; bool UseSphereMap = false;> {
    pass DrawObject {  
        VertexShader = compile vs_3_0 Basic_VS();
        PixelShader  = compile ps_3_0 Basic_PS(false,false);
    }
	pass G {
	    VertexShader = compile vs_3_0 Basic_VS();
        PixelShader  = compile ps_3_0 G_PS();
	}
}

technique MainTec1 < 
	string Script = 
	        "RenderColorTarget0=;"
    	    "RenderDepthStencilTarget=;"
    	    "Pass=DrawObject;"
			"RenderColorTarget0=K3LS_GBuffer_01;"
			"RenderDepthStencilTarget=K3LS_GBuffer_01_Depth;"
			"Pass=G;";
	string MMDPass = "object"; bool UseTexture = true; bool UseSphereMap = false; > {
    pass DrawObject {      
        VertexShader = compile vs_3_0 Basic_VS();
        PixelShader  = compile ps_3_0 Basic_PS(true,false);
    }
	pass G {
	    VertexShader = compile vs_3_0 Basic_VS();
        PixelShader  = compile ps_3_0 G_PS();
	}
}

technique MainTec2 < 
	string Script = 
	        "RenderColorTarget0=;"
    	    "RenderDepthStencilTarget=;"
    	    "Pass=DrawObject;"
			"RenderColorTarget0=K3LS_GBuffer_01;"
			"RenderDepthStencilTarget=K3LS_GBuffer_01_Depth;"
			"Pass=G;";
	string MMDPass = "object"; bool UseTexture = false; bool UseSphereMap = true;> {
    pass DrawObject { 
        VertexShader = compile vs_3_0 Basic_VS();
        PixelShader  = compile ps_3_0 Basic_PS(false,true);
    }
	pass G {
	    VertexShader = compile vs_3_0 Basic_VS();
        PixelShader  = compile ps_3_0 G_PS();
	}
}

technique MainTec3 < 
	string Script = 
	        "RenderColorTarget0=;"
    	    "RenderDepthStencilTarget=;"
    	    "Pass=DrawObject;"
			"RenderColorTarget0=K3LS_GBuffer_01;"
			"RenderDepthStencilTarget=K3LS_GBuffer_01_Depth;"
			"Pass=G;";
	string MMDPass = "object"; bool UseTexture = true; bool UseSphereMap = true; > {
    pass DrawObject {
        VertexShader = compile vs_3_0 Basic_VS();
        PixelShader  = compile ps_3_0 Basic_PS(true,true);
    }
	pass G {
	    VertexShader = compile vs_3_0 Basic_VS();
        PixelShader  = compile ps_3_0 G_PS();
	}
}


//-----------------------------------------------------------------------------------------------------
// 標準エミュレート
// オブジェクト描画用テクニック（アクセサリ用）
technique MainTecBS0  < 
	string Script = 
	        "RenderColorTarget0=;"
    	    "RenderDepthStencilTarget=;"
    	    "Pass=DrawObject;"
			"RenderColorTarget0=K3LS_GBuffer_01;"
			"RenderDepthStencilTarget=K3LS_GBuffer_01_Depth;"
			"Pass=G;";
	string MMDPass = "object_ss"; bool UseTexture = false; bool UseSphereMap = false;> {
    pass DrawObject {  
        VertexShader = compile vs_3_0 Basic_VS();
        PixelShader  = compile ps_3_0 Basic_PS(false,false);
    }
	pass G {
	    VertexShader = compile vs_3_0 Basic_VS();
        PixelShader  = compile ps_3_0 G_PS();
	}
}

technique MainTecBS1  < 
	string Script = 
	        "RenderColorTarget0=;"
    	    "RenderDepthStencilTarget=;"
    	    "Pass=DrawObject;"
			"RenderColorTarget0=K3LS_GBuffer_01;"
			"RenderDepthStencilTarget=K3LS_GBuffer_01_Depth;"
			"Pass=G;";
	string MMDPass = "object_ss"; bool UseTexture = true; bool UseSphereMap = false;> {
    pass DrawObject {  
        VertexShader = compile vs_3_0 Basic_VS();
        PixelShader  = compile ps_3_0 Basic_PS(true,false);
    }
	pass G {
	    VertexShader = compile vs_3_0 Basic_VS();
        PixelShader  = compile ps_3_0 G_PS();
	}
}

technique MainTecBS2  < 
	string Script = 
	        "RenderColorTarget0=;"
    	    "RenderDepthStencilTarget=;"
    	    "Pass=DrawObject;"
			"RenderColorTarget0=K3LS_GBuffer_01;"
			"RenderDepthStencilTarget=K3LS_GBuffer_01_Depth;"
			"Pass=G;";
	string MMDPass = "object_ss"; bool UseTexture = false; bool UseSphereMap = true;> {
    pass DrawObject {       
        VertexShader = compile vs_3_0 Basic_VS();
        PixelShader  = compile ps_3_0 Basic_PS(false,true);
    }
	pass G {
	    VertexShader = compile vs_3_0 Basic_VS();
        PixelShader  = compile ps_3_0 G_PS();
	}
}

technique MainTecBS3  < 
	string Script = 
	        "RenderColorTarget0=;"
    	    "RenderDepthStencilTarget=;"
    	    "Pass=DrawObject;"
			"RenderColorTarget0=K3LS_GBuffer_01;"
			"RenderDepthStencilTarget=K3LS_GBuffer_01_Depth;"
			"Pass=G;";
	string MMDPass = "object_ss"; bool UseTexture = true; bool UseSphereMap = true;> {
    pass DrawObject {       
        VertexShader = compile vs_3_0 Basic_VS();
        PixelShader  = compile ps_3_0 Basic_PS(true,true);
    }
	pass G {
	    VertexShader = compile vs_3_0 Basic_VS();
        PixelShader  = compile ps_3_0 G_PS();
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////
