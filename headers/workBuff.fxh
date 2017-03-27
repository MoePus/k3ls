texture Blur2WorkBuff0 : RENDERCOLORTARGET <
    float2 ViewportRatio = {1.0, 1.0};
    string Format = NIR16F;
>;
sampler Blur2WorkBuff0Sampler = sampler_state {
    texture = <Blur2WorkBuff0>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};
sampler Blur2WorkBuff0SamplerP = sampler_state {
    texture = <Blur2WorkBuff0>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

texture Blur4WorkBuff0 : RENDERCOLORTARGET <
    float2 ViewportRatio = {1.0, 1.0};
    string Format = YOR16F;
>;
sampler Blur4WorkBuff0Sampler = sampler_state {
    texture = <Blur4WorkBuff0>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};
sampler Blur4WorkBuff0SamplerB = sampler_state {
    texture = <Blur4WorkBuff0>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = Border;
    AddressV  = Border;
};

texture2D Blur4WorkBuff1: RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
	string Format = YOR16F;
>;
sampler Blur4WorkBuff1Sampler = sampler_state {
    texture = <Blur4WorkBuff1>;
    MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
    AddressU  = CLAMP;
	AddressV  = CLAMP;
};

texture2D Blur4WorkBuff2: RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
	string Format = YOR16F;
>;
sampler Blur4WorkBuff2Sampler = sampler_state {
    texture = <Blur4WorkBuff2>;
    MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
    AddressU  = CLAMP;
	AddressV  = CLAMP;
};