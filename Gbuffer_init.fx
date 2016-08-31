sampler MMDSamp0 : register(s0);
sampler MMDSamp1 : register(s1);
sampler MMDSamp2 : register(s2);

shared texture2D K3LS_GBuffer_01: RENDERCOLORTARGET <//SSS
    float2 ViewPortRatio = {1.0,1.0};
	float4 ClearColor = { 0, 0, 0, 0 };
	string Format = "D3DFMT_R32F";
>;

shared texture2D K3LS_GBuffer_01_Depth : RENDERDEPTHSTENCILTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    string Format = "D24S8";
>;


float4 ClearColor = {0,0,0,0};
float ClearDepth  = 1.0;
technique buffer_init <
string Script = 		
		"RenderColorTarget0=K3LS_GBuffer_01;"
		"RenderDepthStencilTarget=K3LS_GBuffer_01_Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		;
>{

}

