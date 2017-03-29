#define SHADOW_QUALITY				4
#define	SSAORayCount				24
#define SSDO_COLOR_BLEEDING			0
#define BLUR_COUNT					8
#define VOLUMETRIC_FOG_SAMPLE		0
#define AA_QUALITY					4
#define SMAA_EDGE_DETECT_MODE		0
#define ENABLE_SSS					1
#define GLARE_SAMPLE				0
#define FILL_2_FLOAT_TO_4			0
///////////////////////////////////////////////////////////////////////////////////////////////
#define fogColor float3(0.9,0.522,0.2)
#define CasterAlphaThreshold 140
#define RecieverAlphaThreshold 0.4

#if SHADOW_QUALITY == 1
#   define SHADOW_MAP_SIZE 2048
#elif SHADOW_QUALITY == 2
#   define SHADOW_MAP_SIZE 4096
#elif SHADOW_QUALITY == 3
#   define SHADOW_MAP_SIZE 6144
#elif SHADOW_QUALITY == 4
#   define SHADOW_MAP_SIZE 8192
#else
#   define SHADOW_MAP_SIZE 10000
#endif

#if AA_QUALITY == 1
#	define IK_AA
#elif AA_QUALITY == 3
#	define USE_SMAA
#	define SMAA_PRESET_LOW
#elif AA_QUALITY == 3
#	define USE_SMAA
#	define SMAA_PRESET_MEDIUM
#elif AA_QUALITY == 4
#	define USE_SMAA
#	define SMAA_PRESET_HIGH
#else
#	define USE_SMAA
#	define SMAA_PRESET_ULTRA
#endif

#ifdef USE_SMAA
#define SMAA_WEIGHT_SUBSAMPLE 0
#define SMAA_RT_METRICS float4(ViewportOffset2, ViewportSize)
#define SMAA_HLSL_3
#endif

#if SMAA_EDGE_DETECT_MODE == 0
#define SMAA_DEPTH_THRESHOLD 0.2
#define SMAA_EDGE_DETECT_PASS "DepthEdgeDetection"
#else
#define SMAA_EDGE_DETECT_PASS "LumaEdgeDetection"
#endif

#define WARP_RANGE 8
#define SHADOW_MAP_OFFSET  (1.0 / SHADOW_MAP_SIZE)
#define SELFSHADOW_COS_MAX 0.00872653549837393496488821397358 //cos 89.5 degree

#define Epsilon 0.0001
#define RGB2LUM float3(0.2125, 0.7154, 0.0721)

#if (FILL_2_FLOAT_TO_4>0)
#define YOR32F "A32B32G32R32F"
#define NIR32F "A32B32G32R32F"
#define YOR16F "A16B16G16R16F"
#define NIR16F "A16B16G16R16F"
#else
#define YOR32F "A32B32G32R32F"
#define NIR32F "G32R32F"
#define YOR16F "A16B16G16R16F"
#define NIR16F "G16R16F"
#endif

// ¥Ñ¥é¥á©`¥¿ÐûÑÔ
float2 ViewportSize : VIEWPORTPIXELSIZE;
static float2 ViewportOffset = (float2(0.5,0.5)/ViewportSize);
static float2 ViewportOffset2 = (float2(1.0,1.0) / ViewportSize);
static float2 ViewportAspect  = float2(1, ViewportSize.x / ViewportSize.y);
uniform bool opadd;

float3	CameraPosition		: POSITION  < string Object = "Camera"; >;
float3	CameraDirection		: DIRECTION < string Object = "Camera"; >;
float3	LightDirection		: DIRECTION < string Object = "Light"; >;
float3	_LightAmbient		: AMBIENT   < string Object = "Light"; >;
float 	ftime : TIME <bool SyncInEditMode = false;>;

// ×ù·¨‰ä“QÐÐÁÐ
float4x4 WorldMatrix              : WORLD;
float4x4 WorldInverse			  : WORLDINVERSE;
float4x4 WorldViewMatrix          : WORLDVIEW;
float4x4 WorldViewProjMatrix      : WORLDVIEWPROJECTION;
float4x4 ViewMatrix               : VIEW;
float4x4 ViewInverse			  : VIEWINVERSE;
float4x4 ProjectMatrix            : PROJECTION;
float4x4 ProjectMatrixInverse     : PROJECTIONINVERSE;
float4x4 ViewProjectMatrix        : VIEWPROJECTION;
float4x4 ViewProjectMatrixInverse : VIEWPROJECTIONINVERSE;

#define SCENE_ZFAR 3200

static float invCotheta = 1/ProjectMatrix._22;
static float Aspect = ViewportSize.x/ViewportSize.y;

const float CascadeZMin = 5;
const float CascadeZMax = 2000;
const float CascadeScale = 0.5;

const float LightZMax = 4000.0;
const float LightDistance = 1000;

static float4x4 matLightProject = {
    1,  0,  0,  0,
    0,  1,  0,  0,
    0,  0,  1.0 / LightZMax,    0,
    0,  0,  0,  1
};

float4x4 GetLightViewMatrix(float3 forward)
{
	const float3 up1 = float3(0, 0, 1);
	const float3 up2 = float3(1, 0, 0);
   
	float3 LightPosition = -forward * LightDistance;
	float3 right = cross(CameraDirection.xyz, forward);

	if (any(right))
	{
		right = normalize(right);
	}
	else
	{
		right = cross(up1, forward);
		right = !any(right) ? normalize(cross(up2, forward)) : normalize(right);
	}
   
	float3 up = normalize(cross(forward, right));
	float3x3 rotation = { right.x, up.x, forward.x,
                         right.y, up.y, forward.y,
                         right.z, up.z, forward.z };

	return float4x4(rotation[0], 0,
					rotation[1], 0,
					rotation[2], 0,
					mul(-(CameraPosition+LightPosition), rotation), 1);
};

float4 CalcLightProjPos(float fov, float znear, float zfar, float4 P)
{
    float h = 1.0 / tan(fov);
    float zp = zfar * (P.z - znear) / (zfar - znear);
    return float4(h * P.x, h * P.y, zp, P.z);
}


float CalculateSplitPosition(float i)
{
    float p0 = CascadeZMin + ((CascadeZMax - CascadeZMin) / CascadeZMin) * (i / 4.0);
    float p1 = CascadeZMin * pow(abs(CascadeZMax / CascadeZMin), i / 4.0);
    return p0 * (1.0 - CascadeScale) + p1 * CascadeScale;
}

float4 CreateFrustumFromProjection()
{
    float4 r = mul(float4( 1, 0, 1, 1), ProjectMatrixInverse);
    float4 l = mul(float4(-1, 0, 1, 1), ProjectMatrixInverse);
    float4 t = mul(float4( 0, 1, 1, 1), ProjectMatrixInverse);
    float4 b = mul(float4( 0,-1, 1, 1), ProjectMatrixInverse);
    return float4(r.x / r.z, l.x / l.z, t.y / t.z, b.y / b.z);
}

float4 CreateLightProjParameter(float4x4 matLightProjectionToCameraView, float4 frustumInfo, float near, float far)
{
    float4 znear = float4(near.xxx, 1);
    float4 zfar = float4(far.xxx, 1);

    float4 rtn = float4(frustumInfo.xz, 1, 1) * znear;
    float4 rtf = float4(frustumInfo.xz, 1, 1) * zfar;
    float4 lbn = float4(frustumInfo.yw, 1, 1) * znear;
    float4 lbf = float4(frustumInfo.yw, 1, 1) * zfar;

    float4 rbn = float4(rtn.x, lbn.yzw), rbf = float4(rtf.x, lbf.yzw);
    float4 ltn = float4(lbn.x, rtn.yzw), ltf = float4(lbf.x, rtf.yzw);

    float4 orthographicBB = float4(9999, 9999, -9999,-9999);

    float2 vpos;
    #define CalcMinMax(inV) \
        vpos = mul(inV, matLightProjectionToCameraView).xy; \
        orthographicBB.xy = min(orthographicBB.xy, vpos); \
        orthographicBB.zw = max(orthographicBB.zw, vpos);
    CalcMinMax(rtn);    CalcMinMax(rtf);    CalcMinMax(lbn);    CalcMinMax(lbf);
    CalcMinMax(rbn);    CalcMinMax(rbf);    CalcMinMax(ltn);    CalcMinMax(ltf);

    const float normalizeByBufferSize = 2.0 / SHADOW_MAP_SIZE;
    const float scaleDuetoBlureAMT = (WARP_RANGE * 2.0 + 1) * normalizeByBufferSize * 0.5;

    orthographicBB += (orthographicBB.xyzw - orthographicBB.zwxy) * scaleDuetoBlureAMT;
    float4 unit = (orthographicBB.zwzw - orthographicBB.xyxy) * normalizeByBufferSize;
    orthographicBB = floor(orthographicBB / unit) * unit;

    float2 invBB = 1.0 / (orthographicBB.zw - orthographicBB.xy);
    float2 endPos = -(orthographicBB.xy + orthographicBB.zw);
    return float4(2.0, 2.0, endPos.xy) * invBB.xyxy;
}

float4x4 CreateLightProjParameters(float4x4 matLightProjectionToCameraView)
{
    float4 frustumInfo = CreateFrustumFromProjection();

    float z0 = CascadeZMin;
    float z1 = CalculateSplitPosition(1.0);
    float z2 = CalculateSplitPosition(2.0);
    float z3 = CalculateSplitPosition(3.0);
    float z4 = CascadeZMax;

    return float4x4(
        CreateLightProjParameter(matLightProjectionToCameraView, frustumInfo, z0, z1),
        CreateLightProjParameter(matLightProjectionToCameraView, frustumInfo, z1, z2),
        CreateLightProjParameter(matLightProjectionToCameraView, frustumInfo, z2, z3),
        CreateLightProjParameter(matLightProjectionToCameraView, frustumInfo, z3, z4));
}

float2 WarpDepth(float depth, float2 exponents)
{
    depth = 2.0f * depth - 1.0f;
    float pos =  exp( exponents.x * depth);
    float neg = -exp(-exponents.y * depth);
    return float2(pos, neg);
}

float CalcEdgeFalloff(float2 texCoord)
{
    const float m = (SHADOW_MAP_SIZE * 0.5 / WARP_RANGE);
    const float a = (SHADOW_MAP_OFFSET * 1.0 / WARP_RANGE);
    float2 falloff = abs(texCoord) * (-m * 4.0) + (m - a);
    return saturate(min(falloff.x, falloff.y));
}

float4 CalcCascadePPos(float2 uv, float2 offset, float index)
{
    return float4(uv + ((0.5 + offset) * 0.5 + (0.5 / SHADOW_MAP_SIZE)), index, CalcEdgeFalloff(uv));
}

static float4x4 matLightView = GetLightViewMatrix(normalize(LightDirection));
static float4x4 matLightViewProject = mul(matLightView, matLightProject);
static float4x4 matLightProjectToCameraView = mul(ViewInverse, matLightView);
static float4x4 lightParam = CreateLightProjParameters(matLightProjectToCameraView);