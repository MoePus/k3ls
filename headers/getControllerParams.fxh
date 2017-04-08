struct ConParam
{
	float reflectance;
	float varnishAlpha;
	float varnishRough;
	float SSS;
	float translucency;
	float selfLighting;
	float islinear;
};

inline void getConParams(float id,out ConParam params)
{
float2 Tex = float2(id/materialAmount + 0.5/materialAmount,0.5);
float4 rvvs = tex2D(Controller0Samp,Tex);
float4 tsin = tex2D(Controller1Samp,Tex);

params.reflectance = rvvs.x;
params.varnishAlpha = rvvs.y;
params.varnishRough = rvvs.z;
params.SSS = rvvs.w;

params.translucency = tsin.x;
params.selfLighting = tsin.y;
params.islinear = tsin.z;
}