/*/////////////////////////////////////
* NONONO
* THIS IS TO SLOW
* I WOULD NEVER USE THIS
*////////////////////////////////////*/

texture Blur4WorkBuffHALF0 : RENDERCOLORTARGET <
    float2 ViewportRatio = {0.6, 0.6};
    string Format = YOR16F;
>;
sampler Blur4WorkBuffHALF0Sampler = sampler_state {
    texture = <Blur4WorkBuffHALF0>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

void GI_PS(float2 Tex: TEXCOORD0,out float4 GI : COLOR0)
{
	float4 albedoNA = tex2D(AlbedoGbufferSamp,Tex);
	float4 albedoA = tex2D(Albedo_ALPHA_FRONT_GbufferSamp,Tex);
	float4 albedo = float4(albedoNA.xyz*(1-albedoA.a)+albedoA.xyz,max(albedoNA.a,albedoA.a));
	if(albedo.a<Epsilon)
	{
		GI = float4(0,0,0,1);
		return;
	}	
	float3 normal = tex2D(sumNormalSamp,Tex).xyz;
	float linearDepth = tex2D(sumDepthSamp,Tex).x;
	float3 pos = coord2WorldViewPos(Tex,linearDepth);
	float3 wpos = mul(pos,(float3x3)ViewInverse);
	float hash = hash12(Tex*ftime);
	float mlDepth =  linearDepth/86;
	
	#define GI_SAMPLE 32.0
	for(float x = 0; x < GI_SAMPLE; x+=1.0)
    for(float y = 0; y < GI_SAMPLE; y+=1.0)
    {

		float2 p = Tex + float2(x-GI_SAMPLE/2+hash,y-GI_SAMPLE/2+hash) / (ViewportSize/32.0) / mlDepth;

        float4 EAN = tex2Dlod(diffuseSamp,float4(p,0,0));
	
        if( EAN.a < Epsilon )
                continue;

		float3 Enormal = tex2Dlod(sumNormalSamp,float4(p,0,0)).xyz;
		float ElinearDepth = tex2Dlod(sumDepthSamp,float4(p,0,0)).x;
		float3 Epos = coord2WorldViewPos(p,ElinearDepth);
		float3 wEpos = mul(Epos,(float3x3)ViewInverse);
			
        float3 di = wEpos.xyz - wpos.xyz;
        float ld = length(di) + Epsilon;
        di /= ld;//normalize it.

        float cosE = max(0,dot( -di, Enormal.xyz ));
        float cosR = max(0,dot( di, normal.xyz ));

		float3 specular = tex2Dlod(specularSamp,float4(p,0,0)).xyz;
	
		GI.xyz += min(cosE*cosR*192/GI_SAMPLE/PI/ld/ld * (EAN.xyz + specular.xyz),0.07);
    }
		GI.xyz *= albedo.xyz * LightAmbient;
		GI.a = 1;
		return;
}


///////////////////////////////////////////////////////////////////////////////////////////////
	
	pass PBGI  < string Script= "Draw=Buffer;"; > {
		AlphaBlendEnable = FALSE;
		ZFUNC=ALWAYS;
		ALPHAFUNC=ALWAYS;
		VertexShader = compile vs_3_0 POST_VS();
		PixelShader  = compile ps_3_0 GI_PS();
	}
	
		"RenderColorTarget0=Blur4WorkBuffHALF0;"
    	"RenderDepthStencilTarget=mrt_Depth;"
		"ClearSetDepth=ClearDepth;Clear=Depth;"
		"ClearSetColor=ClearColor;Clear=Color;"
    	"Pass=PBGI;"