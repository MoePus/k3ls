#K3LS#
又一个mikumikudance用基于物理的渲染包

    版本 1.4.0
    
##使用方法:
###启用渲染
* 载入Gbuffer_init.pmx,并确保这是`第一个`渲染的pmx文件
* 关闭MMD自带抗锯齿
* 载入ambient.x
* 载入K3LS.x
* 打开MME控制面板，为模型分配materials文件夹下的fx文件，并通过对应的controllers文件夹下的pmx文件控制渲染效果

###模型改造
* 删除模型中所有sphere贴图，或将其设置为`無效`
* 删除模型中所有toon贴图
* 可选）在原本放置sphere贴图的位置修改为法线贴图

##其他
* K3LS - DR 暂不支持半透明模型的正确渲染

##高级选项
####在`headers\\environment.fxh`文件中，可以配置以下效果
* SHADOW_QUALITY
        范围1-5
        显存够大就往大了开
		
* SSAORayCount
        推荐范围24-32
        决定AO与COLOR—BLEEDING的质量
		
* SSDO_COLOR_BLEEDING
        推荐范围15-25，0为关闭此效果
        COLOR—BLEEDING效果的强度
		
* BLUR_COUNT
        推荐数值6
        影响AO与阴影的模糊强度
        如果不是闲得蛋疼请不要试着修改这个选项
		
* VOLUMETRIC_FOG_SAMPLE
        推荐范围80-140，0为关闭此效果
        体积雾的精确度，过低的值会造成漏光，以及噪音
		
* AA_QUALITY
        抗锯齿强度，不推荐5
        大于1为SMAA
		
* SMAA_EDGE_DETECT_MODE
        在开启SMAA的情况下此选项生效
        0为通过深度判断物体边缘
        1为通过亮度判断物体边缘
        推荐0
		
* SMAA_WEIGHT_SUBSAMPLE
        在开启SMAA的情况下此选项生效
        SMAA混合子像素数量
        控制nX-SMAA
        推荐1
		
* FILL_2_FLOAT_TO_4
		N卡建议1
		A卡建议0
		
* ENABLE_SSS
		控制SSSSS效果
		建议1


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
* 加速SSSSS √
* FULL HDR √
* bokeh
* 多光源
