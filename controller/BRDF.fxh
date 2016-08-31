inline float3 D_Blinn_Phong(float roughness,float3 normal,float3 halfVector)
{
	return pow(saturate(dot(normal,halfVector)),2./roughness/roughness - 2.)/(PI*roughness*roughness);
}


inline float3 D_GGX(float roughness,float3 normal,float3 halfVector)
{
	return roughness*roughness/(PI*pow(pow(saturate(dot(normal,halfVector)),2)*(roughness*roughness-1)+1,2));
}


inline float3 F_UE4(float reflectance,float3 viewNormal,float3 halfVector)
{
	float e_n = dot(viewNormal, halfVector);
	return  reflectance + (1 - reflectance) * exp2(-(5.55473f * e_n + 6.98316f) * e_n);
}

inline float3 F_UE4(float3 f0,float3 viewNormal,float3 halfVector)
{
	float e_n = dot(viewNormal, halfVector);
	return  f0 + (1 - f0) * exp2(-(5.55473f * e_n + 6.98316f) * e_n);
}


inline float3 G1_Schlick(float3 n,float3 v,float roughness)
{
	float k = roughness / 2.;
	float NV = max(0,dot(n, v));
	return NV/(NV*(1-k)+k);
}


inline float3 G_Simth(float roughness,float3 lightNormal,float3 viewNormal,float3 normal)
{
	return G1_Schlick(normal,lightNormal,roughness)*G1_Schlick(normal,viewNormal,roughness);
}


inline float3 BRDF(float roughness,float3 reflectance,float3 normal,float3 lightNormal,float3 viewNormal)
{
	float NV = dot(normal,viewNormal);
	float NL = dot(lightNormal,normal);
	
	float3 halfVector = normalize( viewNormal + lightNormal );
    float3 D = D_GGX(roughness,normal,halfVector);
	float3 F = F_UE4(reflectance,viewNormal,lightNormal);
	float3 G = G_Simth(roughness,lightNormal,viewNormal,normal);
	
	return D*F*G/(4.*NL*NV);
}