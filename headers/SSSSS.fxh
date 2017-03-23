/////////////////////////////////////////
///////http://www.iryoku.com/sssss///////
/////////////////////////////////////////
int blurCount = 3;
int BlurIndex = 0;

float4 SSSMakeStencil_PS(float2 Tex: TEXCOORD0): COLOR
{
	float SSS_strength = tex2D(specularSamp,Tex).w;
	if(SSS_strength<=Epsilon)
	{
		discard;
	}
	return float4(SSS_strength*3.5f,0,0,1);
}


#define GENBlurPS(PS_name,SAMP_name,step_mod) \
float4 PS_name(float2 Tex: TEXCOORD0) : COLOR { \
    const float w[6] = { 0.006,   0.061,   0.242,  0.242,  0.061, 0.006 }; \
    const float o[6] = {  -1.0, -0.6667, -0.3333, 0.3333, 0.6667,   1.0 }; \
	float SSS_strength = tex2D(Blur2WorkBuff0Sampler,Tex).x; \
	float2 step = float2(0.0,0.0); \
	step_mod = (1 + BlurIndex)*SSS_strength; \
	step *= 5000; \
	float4 colorM = tex2D(SAMP_name,Tex); \
    float depthM = tex2D(sumDepthSamp,Tex).r * SCENE_ZFAR; \
    float4 colorBlurred = colorM; \
    colorBlurred.rgb *= 0.382; \
	float correction = sss_correction*0.6667; \
    float2 finalStep = colorM.a * step / depthM; \
	[unroll] \
    for (int i = 0; i < 6; i++) { \
        float2 offset = Tex + o[i] * finalStep / ViewportSize; \
        float3 color = tex2D(SAMP_name,offset).rgb; \
        float depth = tex2D(sumDepthSamp,offset).r * SCENE_ZFAR; \
        float s = min(0.0125 * correction * abs(depthM - depth), 1.0); \
        color = lerp(color, colorM.rgb, s); \
        colorBlurred.rgb += w[i] * color; } \
    return colorBlurred; }


#define SSS_2XSamp diffuseSamp
#define SSS_2BSamp Blur4WorkBuff0Sampler
#define SSS_2YSamp MRTSamp

GENBlurPS(Blur_PSX,SSS_2XSamp,step.x)
GENBlurPS(Blur_PSY,SSS_2YSamp,step.y)

float4 Blend_PS(float2 Tex: TEXCOORD0 ) : COLOR
{
	const float3 blendYFactor[3] = {
		float3(0.3251,0.45,0.3583),float3(0.34,0.1864,0),float3(0.46,0,0.0402)
	};
	float3 factor = blendYFactor[BlurIndex];
		
	float4 srcColor = tex2D(SSS_2XSamp,Tex);
	float3 dstColor = tex2D(SSS_2BSamp,Tex).xyz;
	float3 invFactor = 1.0f.xxx - factor;
	return float4(srcColor.xyz*factor + dstColor.xyz*invFactor,srcColor.a);
}

#define SSSSS \
	"RenderColorTarget0=Blur2WorkBuff0;" \
	"RenderDepthStencilTarget=mrt_Depth;" \
	"ClearSetDepth=ClearDepth;Clear=Depth;" \
	"ClearSetColor=ClearColor;Clear=Color;" \
	"Pass=SSSMAKEStencil;" \
	\
	"LoopByCount=blurCount;" \
	"LoopGetIndex=BlurIndex;"	\
		\
		"RenderColorTarget0=mrt;" \
		"RenderDepthStencilTarget=mrt_Depth;" \
    	"Pass=BLURX;" \
		\
		"RenderColorTarget0=Blur4WorkBuff0;" \
		"RenderDepthStencilTarget=mrt_Depth;" \
    	"Pass=BLURY;" \
		\
		"RenderColorTarget0=diffuseTexture;" \
		"RenderDepthStencilTarget=mrt_Depth;" \
    	"Pass=Blend;" \
		\
	"LoopEnd=;" \
	"RenderDepthStencilTarget=mrt_Depth;" \
	"ClearSetDepth=ClearDepth;Clear=Depth;"


	
#define SSSSSPASS \
	pass SSSMAKEStencil < string Script= "Draw=Buffer;"; >  \
	{ \
		AlphaBlendEnable = FALSE; \
		ZFUNC=ALWAYS; \
		ALPHAFUNC=ALWAYS; \
        StencilEnable = true; \
        StencilPass = REPLACE; \
        StencilRef = 1; \
        VertexShader = compile vs_3_0 POST_VS(); \
		PixelShader  = compile ps_3_0 SSSMakeStencil_PS(); \
    } \
	pass BLURX < string Script= "Draw=Buffer;"; >  \
	{ \
		AlphaBlendEnable = FALSE; \
		ZFUNC=ALWAYS; \
		ALPHAFUNC=ALWAYS; \
		StencilEnable = true; \
        StencilPass = KEEP; \
        StencilFunc = EQUAL; \
        StencilRef = 1; \
        VertexShader = compile vs_3_0 POST_VS(); \
		PixelShader  = compile ps_3_0 Blur_PSX(); \
    } \
	pass BLURY < string Script= "Draw=Buffer;"; >  \
	{ \
		AlphaBlendEnable = FALSE; \
		ZFUNC=ALWAYS; \
		ALPHAFUNC=ALWAYS; \
		StencilEnable = true; \
        StencilPass = KEEP; \
        StencilFunc = EQUAL; \
        StencilRef = 1; \
        VertexShader = compile vs_3_0 POST_VS(); \
		PixelShader  = compile ps_3_0 Blur_PSY(); \
    } \
	pass Blend < string Script= "Draw=Buffer;"; >  \
	{ \
		AlphaBlendEnable = FALSE; \
		ZFUNC=ALWAYS; \
		ALPHAFUNC=ALWAYS; \
		StencilEnable = true; \
        StencilPass = KEEP; \
        StencilFunc = EQUAL; \
        StencilRef = 1; \
        VertexShader = compile vs_3_0 POST_VS(); \
        PixelShader  = compile ps_3_0 Blend_PS(); \
    }
	
#undef SSS_2XSamp
#undef SSS_2BSamp
#undef SSS_2YSamp