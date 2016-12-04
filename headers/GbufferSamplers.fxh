sampler AlbedoGbufferSamp = sampler_state {
    texture = <GBuffer_albedo>;
    MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
    AddressU  = CLAMP;
	AddressV  = CLAMP;
};
sampler DepthGbufferSamp = sampler_state {
    texture = <GBuffer_linearDepth>;
    MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
    AddressU  = CLAMP;
	AddressV  = CLAMP;
};
sampler SpaGbufferSamp = sampler_state {
    texture = <GBuffer_spa>;
    MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
    AddressU  = CLAMP;
	AddressV  = CLAMP;
};
sampler NormalGbufferSamp = sampler_state {
    texture = <GBuffer_normal>;
    MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
    AddressU  = CLAMP;
	AddressV  = CLAMP;
};
///////////////////////////////////////////////
sampler Albedo_ALPHA_FRONT_GbufferSamp = sampler_state {
    texture = <GBuffer_ALPHA_FRONT_albedo>;
    MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
    AddressU  = CLAMP;
	AddressV  = CLAMP;
};
sampler Depth_ALPHA_FRONT_GbufferSamp = sampler_state {
    texture = <GBuffer_ALPHA_FRONT_linearDepth>;
    MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
    AddressU  = CLAMP;
	AddressV  = CLAMP;
};
sampler Spa_ALPHA_FRONT_GbufferSamp = sampler_state {
    texture = <GBuffer_ALPHA_FRONT_spa>;
    MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
    AddressU  = CLAMP;
	AddressV  = CLAMP;
};
sampler Normal_ALPHA_FRONT_GbufferSamp = sampler_state {
    texture = <GBuffer_ALPHA_FRONT_normal>;
    MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
    AddressU  = CLAMP;
	AddressV  = CLAMP;
};

