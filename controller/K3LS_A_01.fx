#include "..\\headers\\environment.fxh"
#include "..\\headers\\renderConf.fxh"
#include "..\\headers\\BRDF.fxh"

float roughness : CONTROLOBJECT < string name = "K3LS_A_con_01.pmx"; string item = "roughness"; >;
float spaScale : CONTROLOBJECT < string name = "K3LS_A_con_01.pmx"; string item = "spaScale"; >;
float spaornormal : CONTROLOBJECT < string name = "K3LS_A_con_01.pmx"; string item = "spa<->normal"; >;
float specularStrength : CONTROLOBJECT < string name = "K3LS_A_con_01.pmx"; string item = "specularStrength"; >;
float metalness : CONTROLOBJECT < string name = "K3LS_A_con_01.pmx"; string item = "metalness"; >;
float translucency : CONTROLOBJECT < string name = "K3LS_A_con_01.pmx"; string item = "translucency"; >;
float SSS : CONTROLOBJECT < string name = "K3LS_A_con_01.pmx"; string item = "SSS"; >;
float selfLighting : CONTROLOBJECT < string name = "K3LS_A_con_01.pmx"; string item = "selfLighting"; >;
float varnishAlpha : CONTROLOBJECT < string name = "K3LS_A_con_01.pmx"; string item = "varnishAlpha"; >;
float varnishRough : CONTROLOBJECT < string name = "K3LS_A_con_01.pmx"; string item = "varnishRough"; >;

#include "..\\headers\\shader.fxh"