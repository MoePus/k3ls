/////////////////////////////////////////
///////Got this From Ray-mmd shader//////
/////////////////////////////////////////

texture IBLDiffuseTexture <
    string ResourceName = "skybox\\skydiff.png"; 
>;

sampler IBLDiffuseSampler = sampler_state {
    texture = <IBLDiffuseTexture>;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
	MIPFILTER = NONE;
    ADDRESSU  = CLAMP;  
    ADDRESSV  = CLAMP;
};

texture IBLSpecularTexture <
    string ResourceName = "skybox\\skyspec.png"; 
	int MipLevels = 7;
>;
sampler IBLSpecularSampler = sampler_state {
    texture = <IBLSpecularTexture>;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
    MIPFILTER = LINEAR;
    ADDRESSU  = CLAMP;
    ADDRESSV  = CLAMP;
};

float3x3 makeRotate(float eulerX, float eulerY, float eulerZ)
{
    float sj, cj, si, ci, sh, ch;

    sincos(eulerX, si, ci);
    sincos(eulerY, sj, cj);
    sincos(eulerZ, sh, ch);

    float cc = ci * ch;
    float cs = ci * sh;
    float sc = si * ch;
    float ss = si * sh;

    float a1 = cj * ch;
    float a2 = sj * sc - cs;
    float a3 = sj * cc + ss;

    float b1 = cj * sh;
    float b2 = sj * ss + cc;
    float b3 = sj * cs - sc;

    float c1 = -sj;
    float c2 = cj * si;
    float c3 = cj * ci;
    
    float3x3 rotate;
    rotate[0] = float3(a1, a2, a3);
    rotate[1] = float3(b1, b2, b3);
    rotate[2] = float3(c1, c2, c3);
    
    return rotate;
}
static float3x3 rotate = makeRotate(0, 0, 0);

float2 computeSphereCoord(float3 normal)
{
    float2 coord = float2(atan2(normal.x,normal.z)*invPi*0.5+0.5,acos(normal.y)*invPi);//a lie down sphere map?
    return coord;
}

float HorizonOcclusion(float3 N, float3 R)
{
    float factor = clamp(1.0 + 1.3 * dot(R, N), 0.1, 1.0);
    return factor * factor;
}

float3 DecodeHDR(float4 hdr)
{
	return hdr.rgb;
}

void IBL(float3 view, float3 normal,float roughness, out float3 diffuse, out float3 specular)
{
    float3 worldReflect = reflect(-view, normal);
    
    float mipLayer = 7*roughness;

    float3 R = mul(rotate, worldReflect);
    float3 N = mul(rotate, normal);

    float3 prefilteredDiffuse = DecodeHDR(tex2D(IBLDiffuseSampler, computeSphereCoord(N)));
    float3 prefilteredSpeculr = DecodeHDR(tex2Dlod(IBLSpecularSampler, float4(computeSphereCoord(R), 0, mipLayer)));

    prefilteredSpeculr *= HorizonOcclusion(normal, view);

    diffuse = prefilteredDiffuse.rgb;
    specular = prefilteredSpeculr.rgb;
}