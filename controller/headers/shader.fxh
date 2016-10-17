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
	translucency *= 1.5;
	if (useTexture) 
	{
        float4 TexColor = tex2D(ObjTexSampler, IN.Tex); 
        DiffuseColor = TexColor;
    }
	
	float2 scaledTex = IN.Tex*(1+spaScale*8.5f);
	float4 normalAOmap = tex2D(NorTexSampler, scaledTex);
	float3 t = normalAOmap.xyz;
	float  AOmap = normalAOmap.w;
	float3 normal,spa;
    
	float3x3 tangentFrame = compute_tangent_frame(IN.Normal, IN.Eye, scaledTex);
	if(useNormalMap) 
	{
		if (spaornormal>=0.5) //Use for Normal
		{
			normal = 2.0f * t - 1;
			normal.rg *= ((spaornormal-0.5)*30);
			normal = normalize(normal);
			spa = (1-specularStrength).xxx;
		}
		else //Use for Spa
		{
			normal = float3(0,0,1);
			spa = t*2*(0.5-spaornormal)*(1-specularStrength);
		}
    }else
	{
	    normal = float3(0,0,1);
		spa = (1-specularStrength).xxx;
	}
	
	normal = normalize(mul(normal, tangentFrame));
	
	
	float3 color = DiffuseColor.xyz;
	float3 lightNormal = normalize(-LightDirection);
	float3 viewNormal = normalize(IN.Eye);
	float NL = saturate(dot(lightNormal,normal));
		
	IN.Pos2.xyz /= IN.Pos2.w;
	float2 TransScreenTex;
    TransScreenTex.x = (1 + IN.Pos2.x) * 0.5f;
    TransScreenTex.y = (1 - IN.Pos2.y) * 0.5f;
    TransScreenTex += ViewportOffset;

	float2 shadowMap = tex2D(ScreenShadowMapProcessedSamp, TransScreenTex).xy;
	float ShadowMapVal = saturate(shadowMap.x);
	float ao = tex2D( SSAOSamp, TransScreenTex ).r;
	
	float3 aoColor = ao * AOmap;
	float irradiance = max(0.3 + dot(-normal, lightNormal), 0.0);
	float3 trans = translucency*CalcTranslucency(shadowMap.y)*irradiance*color;

	 
	float3 diffuse = (color+trans)*NL*invPi*Diffuse(roughness,normal,lightNormal,viewNormal)*LightAmbient*(1-metalness);
	
	float3 cSpec = lerp(0.04,reflectance * spa,metalness);
	//return float4(spa,1);
	float3 specular = cSpec * BRDF(roughness,color,normal,lightNormal,viewNormal)*NL*LightAmbient*DiffuseColor.a;
	
	float SdN = dot(SKYDIR,normal)*0.5f+0.5f;
    float3 Hemisphere = lerp(GROUNDCOLOR, SKYCOLOR, SdN*SdN);
	
	float3 IBLD,IBLS;
	IBL(viewNormal,normal,roughness,IBLD,IBLS);
	float NoV = saturate(dot(normal,viewNormal));
	float3 ambient =  Hemisphere + AmbientColor * ((DiffuseColor + trans) * IBLD * lerp(0.3679,0,metalness) + IBLS * AmbientBRDF_UE4(spa*color,sqrt(roughness),NoV)) * lerp(0.63212,1,metalness); //TBD
	ambient *= aoColor;
	
	float3 selfLight = (exp(3.68888f * selfLighting) - 1) * color;
	
	IBL(viewNormal,normal,varnishRough,IBLD,IBLS);
	float3 surfaceSpecular = 0.2f * varnishAlpha * (0.32 * length(IBLS) * AmbientBRDF_UE4(1.0.xxx,varnishRough,NoV) + BRDF(varnishRough,1,normal,lightNormal,viewNormal)*NL*LightAmbient);
	
	
	float3 outColor = (diffuse + specular)*ShadowMapVal + ambient + selfLight + surfaceSpecular;
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
