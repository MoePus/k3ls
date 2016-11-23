#K3LS#
又一个mikumikudance用基于物理的渲染包

    版本 -.-.-
    
##使用方法:
###启用渲染
* 载入Gbuffer_init.pmx,并确保这是`第一个`渲染的pmx文件
* 载入ambient.x
* 载入K3LS.x
* 打开MME控制面板，为模型分配controllers文件夹下的fx文件，并通过对应的pmx文件控制渲染效果

###模型改造
* 删除模型中所有sphere贴图，或将其设置为`無效`
* 可选）在原本放置sphere贴图的位置修改为高光贴图或法线贴图
* 在pmx控制器中的`spa<=>noraml`表情中控制渲染使用的贴图类型，及其强度

##其他
* K3LS - DR 暂不支持半透明模型的正确渲染
* K3LS 尚不支持完整的HDR效果，缺少泛光，镜头光晕等，强烈建议在K3LS.X后载入AutoLuminous.x并不要载入LightSampling.x

##Reference:
* http://graphicrants.blogspot.jp/2013/08/specular-brdf-reference.html
* http://blog.selfshadow.com/publications/s2012-shading-course/burley/s2012_pbs_disney_brdf_notes_v3.pdf
* http://renderwonk.com/publications/s2010-shading-course/gotanda/course_note_practical_implementation_at_triace.pdf
* http://advances.realtimerendering.com/s2014/wronski/bwronski_volumetric_fog_siggraph2014.pdf
* http://www.iryoku.com/sssss/
* http://iryoku.com/translucency/
* https://zhuanlan.zhihu.com/p/20119162?refer=graphics
* KlayGE(https://github.com/gongminmin/KlayGE)
* Ray(https://github.com/ray-cast/ray-mmd)

##Inspired by:
* NCHLShader2
* N2+CShader
* MikuMikuEffect Reference

##TODO:
* 支持alpha
* 改进Gbuffer
* FULL HDR
* 屏幕空间阴影
* 多光源