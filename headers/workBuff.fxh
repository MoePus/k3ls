texture Blur2WorkBuff0 : RENDERCOLORTARGET <
    float2 ViewportRatio = {1.0, 1.0};
    string Format = "G16R16F";
>;
sampler Blur2WorkBuff0Sampler = sampler_state {
    texture = <Blur2WorkBuff0>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

texture Blur4WorkBuff0 : RENDERCOLORTARGET <
    float2 ViewportRatio = {1.0, 1.0};
    string Format = "A16B16G16R16F";
>;
sampler Blur4WorkBuff0Sampler = sampler_state {
    texture = <Blur4WorkBuff0>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

