shared texture2D GBuffer_depth : RENDERDEPTHSTENCILTARGET;
shared texture2D GBuffer_albedo: RENDERCOLORTARGET;
shared texture2D GBuffer_linearDepth: RENDERCOLORTARGET;
shared texture2D GBuffer_spa: RENDERCOLORTARGET;
shared texture2D GBuffer_normal: RENDERCOLORTARGET;

shared texture2D GBuffer_ALPHA_FRONT_albedo: RENDERCOLORTARGET;
shared texture2D GBuffer_ALPHA_FRONT_linearDepth: RENDERCOLORTARGET;
shared texture2D GBuffer_ALPHA_FRONT_spa: RENDERCOLORTARGET;
shared texture2D GBuffer_ALPHA_FRONT_normal: RENDERCOLORTARGET;

shared texture2D FOG_depth : RENDERDEPTHSTENCILTARGET;
shared texture2D FOG_DEPTH: RENDERCOLORTARGET;