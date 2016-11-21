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
sampler FogDepthMapSampler = sampler_state {
    texture = <FOG_DEPTH>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};
