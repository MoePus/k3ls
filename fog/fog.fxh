texture FogDepthMap : OFFSCREENRENDERTARGET <
    string Description = "FOG";
    float2 ViewPortRatio = {1.8, 1.8};
    string Format = "R32F";
    float4 ClearColor = { 1, 0, 0, 0 };
    float ClearDepth = 1.0;
    int MipLevels = 1;
    string DefaultEffect =
        "self = hide;"
        "skybox*.* = hide;"
        "*.pmx=fog\\fogDepth.fxsub;"
        "*.pmd=fog\\fogDepth.fxsub;"
        "*.x=hide;";
>;
sampler FogDepthMapSampler = sampler_state {
    texture = <FogDepthMap>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

texture FogWorkBuff : RENDERCOLORTARGET <
	float2 ViewportRatio = {1.0, 1.0};
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

float ftime : TIME <bool SyncInEditMode = false;>;
float depth2scatterFactor(float linearDepth)
{
	float scatterFactor = 1/FOG_S - exp(-FOG_S*linearDepth*0.0000125)/FOG_S;
	return scatterFactor;
}

float2 LV2phaseFactor(float LV)
{
	float phaseFactor = 1/(4*PI) * (1 - FOG_G*FOG_G)/ pow(abs(1 + FOG_G*FOG_G -2 * FOG_G * LV), 1.5);//\bwronski_volumetric_fog_siggraph2014/
	return phaseFactor;
}

float4 FOG_PS(float2 Tex: TEXCOORD0) : COLOR
{
	Tex = Tex - float2(0.5,0.5);
	Tex /= 3;
	Tex = Tex + float2(0.5,0.5);
#define FOG_BLUR_SAMPLES 55
	float depth = tex2Dlod(FogDepthMapSampler,float4(Tex,0,0)).x;
	depth = depth<1+Epsilon?6666666:depth;
	float3 pos = coord2WorldViewPos(Tex,depth);
	float3 wpos = mul(pos,(float3x3)ViewInverse);
	
	float3 view = CameraPosition - wpos;
	float3 viewNormal = normalize(view);
	float3 lightNormal = normalize(-LightDirection);
	float LV = dot(lightNormal,viewNormal);	
	
	float phaseFactor = LV2phaseFactor(LV);
	
	float4 LightPosition = float4(lightNormal * LightDistance,1);
	float4 lightPosProj = mul(LightPosition,ViewProjectMatrix);
	lightPosProj.xy/lightPosProj.w;
	lightPosProj.y *= -1;
    float decay=0.96815;
    float exposure=0.21;
    float density=0.926;
    float weight=0.58767;

    float2 tc = Tex;
    float2 deltaTexCoord = -lightPosProj.xy*0.00003;
    deltaTexCoord *= 1.0 / float(FOG_BLUR_SAMPLES)  * density;
    
    float illuminationDecay = 1.0;
    float color = phaseFactor * FOG_A * depth2scatterFactor(length(view))*0.305104;
    
    tc += deltaTexCoord * frac( sin(dot(Tex.xy+frac(ftime), 
                                         float2(12.9898, 78.233)))* 43758.5453 );
    
    for(int i=0; i < FOG_BLUR_SAMPLES; i++)
    {
        tc -= deltaTexCoord;
        float sampledepth = tex2Dlod(FogDepthMapSampler,float4(tc,0,0)).x;
		sampledepth = sampledepth<1+Epsilon?6666666:sampledepth;
		float3 samplepos = coord2WorldViewPos(tc,sampledepth);
		float3 samplewpos = mul(samplepos,(float3x3)ViewInverse);
		
		float3 sampleview = CameraPosition - samplewpos;
		float3 sampleviewNormal = normalize(sampleview);
		float sampleLV = dot(lightNormal,sampleviewNormal);	
		
		float samplephaseFactor = LV2phaseFactor(sampleLV);
		float samplescatterFactor = depth2scatterFactor(length(sampleview));
		
		float sample = samplephaseFactor * FOG_A * samplescatterFactor*0.305104;

		sample *= illuminationDecay * weight;
        color += sample;
        illuminationDecay *= decay;
    }
#undef FOG_BLUR_SAMPLES
	color *= color*exposure;
	return float4(color.xxx,1);
}
