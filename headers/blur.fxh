#define BLUR_COUNT 6

float BilateralWeight(float r, float depth, float center_d, float sharpness)
{
    const float blurSigma = 6 * depth;
    const float blurFalloff = 1.0f / (2.0f * blurSigma * blurSigma);

    float ddiff = (depth - center_d) * sharpness;
    return exp2(-r * r * blurFalloff - ddiff * ddiff);
}//Bilateral?

inline float getBaseSharpness(float depth)
{
	return max(0.4,3 - 0.01*depth);
}
inline float getExtraSharpness(float id1,float id2)
{
	return 6*min(1,abs(floor(id1)-floor(id2)));
}
float4 ShadowMapBlurAxBxToTxy_PS(float2 coord : TEXCOORD0, uniform sampler2D source1, uniform sampler2D source2, uniform float2 offset) : COLOR
{
    float center1 = tex2D(source1, coord).x;
    float center2 = tex2D(source2, coord).x;
	
	float2 centerDepth = tex2D(sumDepthSamp,coord).xy;

    float3 sum = float3(center1, center2, 1);

    float2 offset1 = coord + offset;
    float2 offset2 = coord - offset;
	float sharpness = getBaseSharpness(centerDepth.x);
    [unroll]
    for(int i = 1; i < BLUR_COUNT; i++)
    {        
        float l1 = tex2D(source1, offset1).x;
		float r1 = tex2D(source1, offset2).x;
		float l2 = tex2D(source2, offset1).x;
		float r2 = tex2D(source2, offset2).x;
		float2 s1Depth = tex2D(sumDepthSamp, offset1).xy;
        float2 s2Depth = tex2D(sumDepthSamp, offset2).xy;
		
        float bilateralWeight1 = BilateralWeight(i, s1Depth.x, centerDepth.x, sharpness + getExtraSharpness(s1Depth.y,centerDepth.y));
        float bilateralWeight2 = BilateralWeight(i, s2Depth.x, centerDepth.x, sharpness + getExtraSharpness(s2Depth.y,centerDepth.y));
        
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

	float2 centerDepth = tex2D(sumDepthSamp,coord).xy;

    float3 sum = float3(center, 1);

    float2 offset1 = coord + offset;
    float2 offset2 = coord - offset;
	float sharpness = getBaseSharpness(centerDepth.x);
    [unroll]
    for(int i = 1; i < BLUR_COUNT; i++)
    {        
        float2 l = tex2D(source, offset1).xy;
		float2 r = tex2D(source, offset2).xy;

		float2 s1Depth = tex2D(sumDepthSamp, offset1).xy;
        float2 s2Depth = tex2D(sumDepthSamp, offset2).xy;
		
        float bilateralWeight1 = BilateralWeight(i, s1Depth.x, centerDepth.x, sharpness + getExtraSharpness(s1Depth.y,centerDepth.y));
        float bilateralWeight2 = BilateralWeight(i, s2Depth.x, centerDepth.x, sharpness + getExtraSharpness(s2Depth.y,centerDepth.y));
        
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