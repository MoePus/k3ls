#define ClearGbuffer \
		"RenderColorTarget0=GBuffer_albedo;" \
		"RenderColorTarget1=GBuffer_spa;" \
		"RenderColorTarget2=GBuffer_normal;" \
		"RenderDepthStencilTarget=GBuffer_depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
		"ClearSetDepth=ClearDepth;Clear=Depth;" \
		\
		"RenderColorTarget0=GBuffer_ALPHA_FRONT_albedo;" \
		"RenderColorTarget1=GBuffer_ALPHA_FRONT_spa;" \
		"RenderColorTarget2=GBuffer_ALPHA_FRONT_normal;" \
		"RenderDepthStencilTarget=GBuffer_depth;" \
		"ClearSetColor=ClearColor;Clear=Color;" \
		"ClearSetDepth=ClearDepth;Clear=Depth;" \
		\
		"RenderColorTarget0=GBuffer_linearDepth;" \
		"RenderColorTarget1=GBuffer_ALPHA_FRONT_linearDepth;" \
		"RenderColorTarget2=;" \
		"RenderDepthStencilTarget=GBuffer_depth;" \
		"ClearSetColor=ClearDepthColor;Clear=Color;" \
		"ClearSetDepth=ClearDepth;Clear=Depth;" 