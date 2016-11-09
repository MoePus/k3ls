/////////////////////////////////////////
///////Got this From Ray-mmd shader//////
/////////////////////////////////////////

texture IBLDiffuseTexture <
    string ResourceName = "skybox\\skydiff.dds"; 
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
    string ResourceName = "skybox\\skyspec.dds"; 
	int MipLevels = 6;
>;
sampler IBLSpecularSampler = sampler_state {
    texture = <IBLSpecularTexture>;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
    MIPFILTER = LINEAR;
    ADDRESSU  = CLAMP;
    ADDRESSV  = CLAMP;
};

float3 EnvironmentReflect(float3 normal, float3 view)
{
    return reflect(-view, normal);
}

float2 computeSphereCoord(float3 normal)
{
    float2 coord = float2(1 - (atan2(normal.x, normal.z) * invPi * 0.5f + 0.5f), acos(normal.y) * invPi);
    return coord;
}

float HorizonOcclusion(float3 N, float3 R)
{
    float factor = clamp(1.0 + 1.3 * dot(R, N), 0.1, 1.0);
    return factor * factor;
}

void IBL(float3 viewNormal, float3 normal,float roughness, out float3 diffuse, out float3 specular)
{
    float3 worldNormal = mul(normal, (float3x3)ViewInverse);
    float3 worldReflect = EnvironmentReflect(worldNormal, viewNormal);
    
    float mipLayer = 6*roughness;

    float3 R = worldReflect;
    float3 N = worldNormal;

    float4 prefilteredDiffuse = tex2D(IBLDiffuseSampler, computeSphereCoord(N));
    float4 prefilteredSpeculr = tex2Dlod(IBLSpecularSampler, float4(computeSphereCoord(R), 0, mipLayer));
    float4 prefilteredTransmittance = tex2D(IBLDiffuseSampler, computeSphereCoord(-N));

    prefilteredDiffuse.rgb = srgb2linear(prefilteredDiffuse.rgb);
    prefilteredSpeculr.rgb = srgb2linear(prefilteredSpeculr.rgb);
    prefilteredTransmittance.rgb = srgb2linear(prefilteredTransmittance.rgb);

    prefilteredSpeculr *= HorizonOcclusion(worldNormal, worldReflect);

    diffuse = prefilteredDiffuse.rgb;
    //diffuse += prefilteredTransmittance.rgb * material.transmittance * (1 + mEnvSSSLightP * 5 - mEnvSSSLightM);
    specular = prefilteredSpeculr.rgb;
}