texture FogWorkBuff : RENDERCOLORTARGET <
	float2 ViewportRatio = {0.8, 0.8};
	string Format = "R16F";
	int MipLevels = 1;
>;
sampler FogWorkBuffSampler = sampler_state {
    texture = <FogWorkBuff>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

float depth2scatterFactor(float linearDepth)
{
	float scatterFactor = 1/FOG_S - exp(-FOG_S*linearDepth*0.0125)/FOG_S;
	return scatterFactor;
}

float LV2phaseFactor(float LV)
{
	float phaseFactor = 1/(4*PI) * (1 - FOG_G*FOG_G)/ pow(abs(1 + FOG_G*FOG_G -2 * FOG_G * LV), 1.5);//\bwronski_volumetric_fog_siggraph2014/
	return phaseFactor;
}

float ShadowFactor(float3 xpos)
{
	float4 wpos = float4(xpos,1);
	float4 LVPos = mul(wpos, matLightView);
	float2 texCoord = CalcDualShadowCoord(LVPos.xy);
	float lightDepth = tex2Dlod(PSSMsamp,float4(texCoord,0,1)).x * LightZMax;
	return  lightDepth < LVPos.z ? 0 : 1;
}

float4 FOG_PS(float2 Tex: TEXCOORD0) : COLOR
{
	float depth = tex2D(sumDepthSamp,Tex).x;
	
	float3 VPos = coord2WorldViewPos(Tex,depth);
	float4 WPos = mul(float4(VPos,1),ViewInverse);

	float3 view = WPos - CameraPosition;
	float3 lightNormal = normalize(-LightDirection);
	float3 LightPosition = lightNormal * LightDistance;
	
	float viewLength = length(view) + Epsilon;
	float3 viewNormal = view / viewLength;
	float Depthstep = min(700,viewLength) / VOLUMETRIC_FOG_SAMPLE;
	float3 step = Depthstep * viewNormal;
	
	float3 ray = CameraPosition + step * (0.2+hash12(Tex*ftime)*0.8);
	
    float haze = 0;
	[loop]
    for (int i = 0; i < VOLUMETRIC_FOG_SAMPLE; i++)
    {
        float3 L = ray - LightPosition;
        float atten = 5000000/dot(L,L);
        atten *= LV2phaseFactor(dot(-view, normalize(L)));

        atten *= ShadowFactor(ray);
		atten *= FOG_A;
		
        ray += step;
        haze += atten;
    }
	haze = haze / VOLUMETRIC_FOG_SAMPLE * 6;
    haze *= depth2scatterFactor(viewLength);
    float fog = haze * 0.25 * invPi;
	
    return float4(fog.xxx, 1);
}

#define FOG_RAYMARCH \
		"RenderColorTarget0=FogWorkBuff;" \
    	"RenderDepthStencilTarget=mrt_Depth;" \
		"ClearSetDepth=ClearDepth;Clear=Depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
    	"Pass=FOGRayMarch;"

#define FOGPASS \
	pass FOGRayMarch < string Script= "Draw=Buffer;"; >  \
	{ \
		AlphaBlendEnable = FALSE; \
		ZFUNC=ALWAYS; \
		ALPHAFUNC=ALWAYS; \
        VertexShader = compile vs_3_0 POST_VS(); \
        PixelShader  = compile ps_3_0 FOG_PS(); \
    }