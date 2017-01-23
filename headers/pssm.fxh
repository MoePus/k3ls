/////////////////////////////////////////
///////Got this From Ray-mmd shader//////
///////		and	From ikPolishShader//////
/////////////////////////////////////////
texture PSSMDepth : OFFSCREENRENDERTARGET <
    string Description = "PSSMDepth";
	int Width = SHADOW_MAP_SIZE;
    int Height = SHADOW_MAP_SIZE;
    string Format = "R32F";
    float4 ClearColor = { 1, 0, 0, 0 };
    float ClearDepth = 1.0;
    int MipLevels = 1;
    string DefaultEffect =
        "self = hide;"
        "skybox*.* = hide;"
        "*.pmx=headers\\pssmdepth.fx;"
        "*.pmd=headers\\pssmdepth.fx;"
        "*.x=hide;";
>;
sampler PSSMsamp = sampler_state {
	texture = <PSSMDepth>;
	MinFilter = LINEAR;	MagFilter = LINEAR;	MipFilter = NONE;
	AddressU  = CLAMP;	AddressV = CLAMP;
};

texture2D ScreenShadowMap: RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
	string Format = NIR16F;
>;
sampler ScreenShadowMapSampler = sampler_state {
    texture = <ScreenShadowMap>;
    MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = NONE;
    AddressU  = CLAMP; AddressV = CLAMP;
};
sampler2D ScreenShadowMapProcessedSamp = sampler_state {
    texture = <ScreenShadowMap>;
    MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = NONE;
    AddressU  = CLAMP; AddressV = CLAMP;
};

float transmission(float c,float r)
{
	return saturate(abs((c-r)*(LightZMax)));
}

float2 CalcDualShadowCoord(float2 PPos)
{
	const float2 scale = float2(0.25, -0.25);
	float4 lightPPos0 = CalcCascadePPos((PPos * lightParam[0].xy + lightParam[0].zw)*scale, float2(0, 0), 0);
	float4 lightPPos1 = CalcCascadePPos((PPos * lightParam[1].xy + lightParam[1].zw)*scale, float2(1, 0), 1);
	float4 lightPPos2 = CalcCascadePPos((PPos * lightParam[2].xy + lightParam[2].zw)*scale, float2(0, 1), 2);
	float4 lightPPos3 = CalcCascadePPos((PPos * lightParam[3].xy + lightParam[3].zw)*scale, float2(1, 1), 3);

	float4 texCoord = lightPPos3;
	if (lightPPos2.w > 0.0) {texCoord = lightPPos2; }
	if (lightPPos1.w > 0.0) {texCoord = lightPPos1; }
	if (lightPPos0.w > 0.0) {texCoord = lightPPos0; }
	
	return texCoord.xy;
}

float4 SSOBJ(float2 Tex: TEXCOORD0) : COLOR
{
	float alpha = min(1,tex2D(AlbedoGbufferSamp,Tex).a + tex2D(Albedo_ALPHA_FRONT_GbufferSamp,Tex).a);

	float Depth = tex2D(sumDepthSamp,Tex).x;
	float3 N = tex2D(sumNormalSamp,Tex).xyz;

	float3 VPos = coord2WorldViewPos(Tex,Depth);
	float4 WPos = mul(float4(VPos,1),ViewInverse);
	
	float4 LVPos = mul(WPos, matLightViewProject);
	
	float2 texCoord = CalcDualShadowCoord(LVPos.xy);

	float receiverDepth = LVPos.z;
	float depthSlope = max(abs( ddx( receiverDepth ) ) ,abs( ddy( receiverDepth ) ));
	float depthBias = (VPos.z / LightZMax + depthSlope) * 0.0049;
	
	receiverDepth -= depthBias;

	float s = 1.5 / SHADOW_MAP_SIZE;	
	float fCasterDepth[9] = {
	tex2D(PSSMsamp, texCoord).x,
	tex2D(PSSMsamp, texCoord + float2( s, s)).x,
	tex2D(PSSMsamp, texCoord + float2(-s, s)).x,
	tex2D(PSSMsamp, texCoord + float2( s,-s)).x,
	tex2D(PSSMsamp, texCoord + float2(-s,-s)).x,
	tex2D(PSSMsamp, texCoord + float2( s, 0)).x,
	tex2D(PSSMsamp, texCoord + float2(-s, 0)).x,
	tex2D(PSSMsamp, texCoord + float2( 0, s)).x,
	tex2D(PSSMsamp, texCoord + float2( 0,-s)).x
	};
	
	
	float sdrate = 30000.0 / 4.0 - 0.05;
	sdrate = (1+3*shadowPlus)*sdrate;
	
	float shadow = 0;
	shadow += CalcLight(fCasterDepth[0], receiverDepth, sdrate);
	shadow += CalcLight(fCasterDepth[1], receiverDepth, sdrate) * 0.5;
	shadow += CalcLight(fCasterDepth[2], receiverDepth, sdrate) * 0.5;
	shadow += CalcLight(fCasterDepth[3], receiverDepth, sdrate) * 0.5;
	shadow += CalcLight(fCasterDepth[4], receiverDepth, sdrate) * 0.5;
	shadow += CalcLight(fCasterDepth[5], receiverDepth, sdrate) * 0.95;
	shadow += CalcLight(fCasterDepth[6], receiverDepth, sdrate) * 0.95;
	shadow += CalcLight(fCasterDepth[7], receiverDepth, sdrate) * 0.95;
	shadow += CalcLight(fCasterDepth[8], receiverDepth, sdrate) * 0.95;

	shadow /= 6.8;
	
	shadow = shadow*max(0,alpha - RecieverAlphaThreshold)/(1 - RecieverAlphaThreshold);
	
	shadow = min(shadow, saturate(dot(N, -LightDirection)));
	return float4(shadow,0,0,1);
}

#define SSSHADOWOBJ \
		"RenderColorTarget0=ScreenShadowMap;" \
    	"RenderDepthStencilTarget=mrt_Depth;" \
		"ClearSetDepth=ClearDepth;Clear=Depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
    	"Pass=SSShadow;"