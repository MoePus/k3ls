texture BlurWorkBuff : RENDERCOLORTARGET <
    float2 ViewportRatio = {1.0, 1.0};
    string Format = "G16R16F";
>;
sampler BlurWorkBuffSampler = sampler_state {
    texture = <BlurWorkBuff>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

#define BLUR_COUNT 6

float BilateralWeight(float r, float depth, float center_d, float sharpness)
{
    const float blurSigma = 6 * depth;
    const float blurFalloff = 1.0f / (2.0f * blurSigma * blurSigma);

    float ddiff = (depth - center_d) * sharpness;
    return exp2(-r * r * blurFalloff - ddiff * ddiff);
}//Bilateral?


float4 ShadowMapBlurAxBxToTxy_PS(float2 coord : TEXCOORD0, uniform sampler2D source1, uniform sampler2D source2, uniform float2 offset) : COLOR
{
    float center1 = tex2D(source1, coord).x;
    float center2 = tex2D(source2, coord).x;
	
	float centerDepth = tex2D(DepthGbufferSamp,coord).x;

    float3 sum = float3(center1, center2, 1);

    float2 offset1 = coord + offset;
    float2 offset2 = coord - offset;
	float sharpness = 7 - 0.05*centerDepth;
    [unroll]
    for(int i = 1; i < BLUR_COUNT; i++)
    {        
        float l1 = tex2D(source1, offset1).x;
		float r1 = tex2D(source1, offset2).x;
		float l2 = tex2D(source2, offset1).x;
		float r2 = tex2D(source2, offset2).x;
		float s1Depth = tex2D(DepthGbufferSamp, offset1).x;
        float s2Depth = tex2D(DepthGbufferSamp, offset2).x;
		
        float bilateralWeight1 = BilateralWeight(i, s1Depth, centerDepth, sharpness);
        float bilateralWeight2 = BilateralWeight(i, s2Depth, centerDepth, sharpness);
        
        sum.xy += float2(l1,l2) * bilateralWeight1;
        sum.xy += float2(r1,r2) * bilateralWeight2;

        sum.z += bilateralWeight1;
        sum.z += bilateralWeight2;
        
        offset1 += offset;
        offset2 -= offset;
    }

    return float4(sum.xy / sum.z,0,1);
}


float4 ShadowMapBlurAxyToTxy_PS(float2 coord : TEXCOORD0, uniform sampler2D source, uniform float2 offset) : COLOR
{
    float2 center = tex2D(source, coord).xy;

	float centerDepth = tex2D(DepthGbufferSamp,coord).x;

    float3 sum = float3(center, 1);

    float2 offset1 = coord + offset;
    float2 offset2 = coord - offset;
	float sharpness = 5.2 - 0.022*centerDepth;
    [unroll]
    for(int i = 1; i < BLUR_COUNT; i++)
    {        
        float2 l = tex2D(source, offset1).xy;
		float2 r = tex2D(source, offset2).xy;

		float s1Depth = tex2D(DepthGbufferSamp, offset1).x;
        float s2Depth = tex2D(DepthGbufferSamp, offset2).x;
		
        float bilateralWeight1 = BilateralWeight(i, s1Depth, centerDepth, sharpness);
        float bilateralWeight2 = BilateralWeight(i, s2Depth, centerDepth, sharpness);
        
        sum.xy += l * bilateralWeight1;
        sum.xy += r * bilateralWeight2;

        sum.z += bilateralWeight1;
        sum.z += bilateralWeight2;
        
        offset1 += offset;
        offset2 -= offset;
    }

    return float4(sum.xy / sum.z,0,1);
}

#undef BLUR_COUNT