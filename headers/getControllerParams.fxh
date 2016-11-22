#define GENController(_id) \
float roughness##_id		: CONTROLOBJECT < string name = "K3LS_A_con_"#_id".pmx"; string item = "roughness"; >; \
float reflectance##_id		: CONTROLOBJECT < string name = "K3LS_A_con_"#_id".pmx"; string item = "reflectance"; >; \
float metalness##_id		: CONTROLOBJECT < string name = "K3LS_A_con_"#_id".pmx"; string item = "metalness"; >; \
float varnishAlpha##_id		: CONTROLOBJECT < string name = "K3LS_A_con_"#_id".pmx"; string item = "varnishAlpha"; >; \
float varnishRough##_id		: CONTROLOBJECT < string name = "K3LS_A_con_"#_id".pmx"; string item = "varnishRough"; >; \
float SSS##_id				: CONTROLOBJECT < string name = "K3LS_A_con_"#_id".pmx"; string item = "SSS"; >; \
float translucency##_id		: CONTROLOBJECT < string name = "K3LS_A_con_"#_id".pmx"; string item = "translucency"; >; \
float selfLighting##_id		: CONTROLOBJECT < string name = "K3LS_A_con_"#_id".pmx"; string item = "selfLighting"; >;


GENController(0)
GENController(1)
GENController(2)
GENController(3)
GENController(4)
GENController(5)
GENController(6)
GENController(7)
GENController(8)

/*
#define GENCon1DVector(_id) \
static float Con1D##_id[7] = { roughness##_id , metalness##_id , varnishAlpha##_id , varnishRough##_id , SSS##_id , translucency##_id , selfLighting##_id };

GENCon1DVector(0)
GENCon1DVector(1)
GENCon1DVector(2)
GENCon1DVector(3)
GENCon1DVector(4)
GENCon1DVector(5)
GENCon1DVector(6)
GENCon1DVector(7)
GENCon1DVector(8)

static const float Con2D[7][9] = GENCon2DVector;
*/

struct ConParam
{
    float roughness;
	float reflectance;
    float metalness;
	float varnishAlpha;
	float varnishRough;
	float SSS;
	float translucency;
	float selfLighting;
};

void getConParams(float id,out ConParam params)
{
#define fetchParams(_cid) \
{ \
params.roughness = roughness##_cid ; \
params.reflectance = reflectance##_cid ; \
params.metalness = metalness##_cid ; \
params.varnishAlpha = varnishAlpha##_cid ; \
params.varnishRough = varnishRough##_cid ; \
params.SSS = SSS##_cid ; \
params.translucency = translucency##_cid ; \
params.selfLighting = selfLighting##_cid ; \
return; \
}

if(id<0.5) fetchParams(0)
else if(id<1.5) fetchParams(1)
else if(id<2.5) fetchParams(2)
else if(id<3.5) fetchParams(3)
else if(id<4.5) fetchParams(4)
else if(id<5.5) fetchParams(5)
else if(id<6.5) fetchParams(6)
else if(id<7.5) fetchParams(7)
else fetchParams(8)

}

