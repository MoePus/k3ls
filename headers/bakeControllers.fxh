#include "..\\headers\\environment.fxh"
shared texture2D baked_controllers0: RENDERCOLORTARGET;
shared texture2D baked_controllers1: RENDERCOLORTARGET;
shared texture2D baked_controllers_depth : RENDERDEPTHSTENCILTARGET;

float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "sceneorobject";
    string ScriptOrder = "postprocess";
> = 0.8;


#define getCon(_id) \
float reflectance		: CONTROLOBJECT < string name = "K3LS_A_con_"#_id".pmx"; string item = "reflectance"; >; \
float varnishAlpha		: CONTROLOBJECT < string name = "K3LS_A_con_"#_id".pmx"; string item = "varnishAlpha"; >; \
float varnishRough		: CONTROLOBJECT < string name = "K3LS_A_con_"#_id".pmx"; string item = "varnishRough"; >; \
float SSS				: CONTROLOBJECT < string name = "K3LS_A_con_"#_id".pmx"; string item = "SSS"; >; \
float translucency		: CONTROLOBJECT < string name = "K3LS_A_con_"#_id".pmx"; string item = "translucency"; >; \
float selfLighting		: CONTROLOBJECT < string name = "K3LS_A_con_"#_id".pmx"; string item = "selfLighting"; >; \
float islinear			: CONTROLOBJECT < string name = "K3LS_A_con_"#_id".pmx"; string item = "linear"; >;

getCon(_id)

void VS_ScreenTex( inout float4 Pos : POSITION,inout float4 Tex : TEXCOORD0)
{
    return;
}

void PS_bakeController(float Tex : TEXCOORD0,out float4 color0:COLOR0,out float4 color1:COLOR1)
{
	float2 pos = float2((_id - 1) * 1.0 / materialAmount,_id* 1.0 / materialAmount);
	clip(Tex - pos.x);
	clip(pos.y - Tex);
	color0 = float4(reflectance,varnishAlpha,varnishRough,SSS);
	color1 = float4(translucency,selfLighting,islinear,1.0);
}


technique ScreenTexTech <
    string Script = 
	"ScriptExternal=Color;"
        "RenderColorTarget0=baked_controllers0;"
        "RenderColorTarget1=baked_controllers1;"
	    "RenderDepthStencilTarget=baked_controllers_depth;"
	"Pass=ScreenTexPass;"
    ;
> {
    pass ScreenTexPass < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
        VertexShader = compile vs_3_0 VS_ScreenTex();
        PixelShader  = compile ps_3_0 PS_bakeController();
    }
}