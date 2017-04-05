inline float square(float x)
{
    return x * x;
}

inline float3 D_GGX(float roughness,float3 normal,float3 halfVector)
{
	return square(roughness)/(PI*pow(pow(saturate(dot(normal,halfVector)),2)*(square(roughness)-1)+1,2));
}


inline float3 F_UE4(float reflectance,float3 viewNormal,float3 halfVector)
{
	float e_n = saturate(dot(viewNormal, halfVector));
	return  reflectance + (1 - reflectance) * exp2(-(5.55473f * e_n + 6.98316f) * e_n);
}

inline float3 F_UE4(float3 f0,float3 viewNormal,float3 halfVector)
{
	float e_n = saturate(dot(viewNormal, halfVector));
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
	roughness = square(roughness);
	float NV = saturate(dot(normal,viewNormal));
	float NL = saturate(dot(lightNormal,normal));
	
	float3 halfVector = normalize( viewNormal + lightNormal );
    float3 D = D_GGX(roughness,normal,halfVector);
	float3 F = F_UE4(reflectance,viewNormal,halfVector);
	float3 G = G_Simth(roughness,lightNormal,viewNormal,normal);
	
	return D*F*G/(4.*NL*NV);
}

inline float pow5(float v)
{
	return v*v*v*v*v;
}

inline float DiffuseBRDF(float roughness,float3 normal,float3 lightNormal,float3 viewNormal)
{
	float NV = abs(dot(normal,viewNormal)) + 0.00001;
	float NL = saturate(dot(lightNormal,normal));
	float3 halfVector = normalize( viewNormal + lightNormal );
	float VH = saturate(dot(viewNormal, halfVector));
	
	float FL = pow5(1-NL);
	float FV = pow5(1-NV);
	float RR = 2*roughness*VH*VH;
	float Fretro_reflection = RR*(FL+FV+FL*FV*(RR-1));
	
	float Fd = (1-0.5*FL)*(1-0.5*FV) + Fretro_reflection;

	return Fd;
}

inline float DiffuseBSDF(float roughness,float3 normal,float3 lightNormal,float3 viewNormal)
{
	//Blender/gpu/shaders/gpu_shader_material.glsl
	float3 halfVector = normalize( viewNormal + lightNormal );
	float bsdf = max(dot(lightNormal,normal), 0.0) * 2 + pow(max(dot(normal, halfVector), 0.0), 1.0 / roughness);

	return bsdf*0.5;
}

inline float3 AmbientBRDF_UE4( float3 SpecularColor, float Roughness, float NoV )
{
	// [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
	// Adaptation to fit our G term.
	const float4 c0 = { -1, -0.0275, -0.572, 0.022 };
	const float4 c1 = { 1, 0.0425, 1.04, -0.04 };
	float4 r = Roughness * c0 + c1;
	float a004 = min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
	float2 AB = float2( -1.04, 1.04 ) * a004 + r.zw;

	return SpecularColor * AB.x + AB.y;
}