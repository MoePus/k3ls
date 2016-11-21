#define ClearGbuffer \
		"RenderColorTarget0=GBuffer_albedo;" \
		"RenderColorTarget1=GBuffer_linearDepth;" \
		"RenderColorTarget2=GBuffer_spa;" \
		"RenderColorTarget3=GBuffer_normal;" \
		"RenderDepthStencilTarget=GBuffer_depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
		"ClearSetDepth=ClearDepth;Clear=Depth;" \
		"RenderColorTarget0=FOG_DEPTH;" \
		"RenderColorTarget1=;" \
		"RenderColorTarget2=;" \
		"RenderColorTarget3=;" \
		"RenderDepthStencilTarget=FOG_depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
		"ClearSetDepth=ClearDepth;Clear=Depth;" 