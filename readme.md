#K3LS#
又一个mikumikudance用基于物理的渲染包

    版本 1.1.6
    
##使用方法:
###启用渲染
* 载入Gbuffer_init.pmx,并确保这是`第一个`渲染的pmx文件
* 载入ambient.x
* 载入K3LS.x
* 打开MME控制面板，为模型分配controllers文件夹下的fx文件，并通过对应的pmx文件控制渲染效果

###模型改造
* 删除模型中所有sphere贴图，或将其设置为`無效`
* 删除模型中所有toon贴图
* 可选）在原本放置sphere贴图的位置修改为法线贴图
* 可选）在原本放置sphere贴图的位置修改为高光贴图(RBG)+粗糙度贴图(A)

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
* KlayGE(https://github.com/gongminmin/KlayGE)
* Ray(https://github.com/ray-cast/ray-mmd)
* N2+CShader
* ikPolishShader

##Inspired by:
* NCHLShader2
* MikuMikuEffect Reference
* https://zhuanlan.zhihu.com/p/20119162?refer=graphics

##TODO:
* 支持alpha √
* 改进Gbuffer √
* 屏幕空间阴影 √
* 基于物理的体积雾 √
* FULL HDR
* 多光源

##TBD
* IBL的合成模式
* translucency的因子