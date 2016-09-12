beta版本，无法保证与最终版本渲染风格相同。
任何BUG请回报

ExcellentShadow.x 必须 阴影
HgSao.x  必须  环境遮蔽
Ambient.x 必须 环境光 xyz指定天空颜色 rxyz指定地面颜色 Si 环境光强度
k3ls.x HDR效果与SSS效果，想要使用SSS效果必须载入Gbuffer_init.pmx并设置为第一个渲染的pmx  Si调整SSS_corrention Tr调整HDR强度

模型改造相关。
可以替换spa为法线贴图。

加入了遮蔽贴图，可以烘焙出AO map后放置于法线贴图alpha通道内使用。

模型载入controller中的fx开始渲染。
所有fx初始效果相同，可以通过同名的pmx文件表情控制效果。
表情 	左上：spa贴图与法线贴图相关
	右上：物理参数相关
	左下：特殊效果相关
	右下：暂时无效


K3LS beta v0.25 MoePus 2016.9.11

Reference:
https://github.com/gongminmin/KlayGE
http://graphicrants.blogspot.jp/2013/08/specular-brdf-reference.html
http://blog.selfshadow.com/publications/s2012-shading-course/burley/s2012_pbs_disney_brdf_notes_v3.pdf
http://www.iryoku.com/sssss/
http://iryoku.com/translucency/
NCHLShader2
N2+CShader
MikuMikuEffect Reference