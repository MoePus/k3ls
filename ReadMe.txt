beta版本，无法保证与最终版本渲染风格相同。
任何BUG请回报


准备工作：
改造模型，将模型材质的sphere贴图换成高光贴图或法线贴图。
使用作为高光贴图时  spa<=>normal 项需要保持在0.5以下，作为法线贴图使用时，需要保持在>=0.5。


使用方法：
在MME中为模型分配controller中的fx，同时使用controller的pmx文件的表情调整效果。

PSSM.x 必须 阴影
HgSao.x  必须  环境遮蔽
Ambient.x 必须 环境光 xyz指定天空颜色 rxyz指定地面颜色 Si 环境光强度 Si推荐1-2，不要太高
k3ls.x HDR效果与SSS效果，想要使用SSS效果必须载入Gbuffer_init.pmx并设置为第一个渲染的pmx  Si调整SSS_corrention Tr调整HDR强度
Skybox.pmx 天空盒，自行替换hdr贴图，可不要


模型改造相关。
可以替换模型的spa贴图为法线贴图+遮蔽贴图:
RGB：法线XYZ，A：遮蔽贴图Y

模型载入controller中的fx开始渲染。
所有fx初始效果相同，可以通过同名的pmx文件表情控制效果。
表情 	左上：spa贴图与法线贴图相关
	右上：物理参数相关
	左下：特殊效果相关
	右下：自发光，表面清漆相关


已移除ExcellentShadow。

K3LS beta v0.9.0 MoePus 2016.10.30



Reference:
http://graphicrants.blogspot.jp/2013/08/specular-brdf-reference.html
http://blog.selfshadow.com/publications/s2012-shading-course/burley/s2012_pbs_disney_brdf_notes_v3.pdf
http://renderwonk.com/publications/s2010-shading-course/gotanda/course_note_practical_implementation_at_triace.pdf
https://github.com/gongminmin/KlayGE
http://www.iryoku.com/sssss/
http://iryoku.com/translucency/
Ray(https://github.com/ray-cast/ray-mmd)
https://zhuanlan.zhihu.com/p/20119162?refer=graphics
NCHLShader2
N2+CShader
MikuMikuEffect Reference


TODO:
提高HDR性能
SSDO ×
PSSM √
Forward -> Deferred