#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

#ifndef KF_DEFINES
	#define KF_DEFINES
#endif

half4 _Color;
UNITY_DECLARE_TEX2D(_MainTex);
half4 _MainTex_ST;

fixed _MinBrightness;
fixed _MaxBrightness;
fixed _Contrast;
fixed _LightingSaturation;
fixed _ShadowStrength;
fixed _ShadowLit;

fixed _VertexColorAlbedo;

#ifdef KF_TRANSPARENT
	fixed _VertexColorAlpha;
#endif

#ifdef KF_TEXTUREALT
	half4 _AltColor;
	UNITY_DECLARE_TEX2D_NOSAMPLER(_AltTex);
	fixed _AltTexStrength;
#endif

#ifdef KF_CUTOUT
	fixed _Cutoff;
	fixed _AlphaNoise;
	fixed _AlphaToMaskSharpen;
	float4 _MainTex_TexelSize;
#endif

#ifdef KF_SHADOW
	sampler2D _Ramp;
	fixed _RampStrength;
	fixed _RampLit;
#endif

#ifdef KF_NORMAL
	UNITY_DECLARE_TEX2D_NOSAMPLER(_BumpMap);
	half4 _BumpMap_ST;
	fixed _BumpScale;
	UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailNormalMap);
	half4 _DetailNormalMap_ST;
	fixed _DetailNormalMapScale;
	UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailMask);
#endif

#ifdef KF_SPECULAR
	UNITY_DECLARE_TEX2D_NOSAMPLER(_SpecularMap);
	half _SpecularIntensity;
	fixed _SpecularAlbedoTint;
	fixed _SpecularArea;
	fixed _SpecularSharpness;
#endif

#ifdef KF_EMISSION
	UNITY_DECLARE_TEX2D_NOSAMPLER(_EmissionMap);
	half4 _EmissionColor;
	fixed _ScaleWithLightSensitivity;
#endif

#ifdef KF_EMISSIONALT
	UNITY_DECLARE_TEX2D_NOSAMPLER(_EmissionMapAlt);
	half4 _EmissionAltColor;
	fixed _EmissionMapAltStrength;
#endif

#ifdef KF_RIMLIGHT
	fixed4 _RimColor;
	fixed _RimAlbedoTint;
	half _RimIntensity;
	fixed _RimRange;
	fixed _RimSharpness;
#endif

#ifdef KF_RIMSHADOW
	fixed4 _ShadowRim;
	fixed _ShadowRimRange;
	fixed _ShadowRimSharpness;
#endif

#ifdef KF_OUTLINE
	sampler2D _OutlineMask;
	fixed4 _OutlineColor;
	fixed _OutlineWidth;
	fixed _OutlineFade;
#endif

#ifdef KF_CUBEMAP
	half4 _WorldReflectionTint;
	samplerCUBE _BakedCubemap;
#endif

#ifdef KF_MATCAP
	sampler2D _Matcap;
	UNITY_DECLARE_TEX2D_NOSAMPLER(_ReflectivityMask);
#endif

#if defined(KF_CUBEMAP) || defined(KF_MATCAP)
	fixed4 _MatcapTint;
	fixed _MatcapTintToDiffuse;
	fixed _MatcapArea;
	fixed _MatcapFresnel;
#endif

#ifdef KF_HSB
	UNITY_DECLARE_TEX2D_NOSAMPLER(_HSLAMask);
	// half4 _HSLAAdjust;
	half _MainHue;
	half _MainSaturation;
	half _MainBrightness;
	#ifdef KF_EMISSION
		UNITY_DECLARE_TEX2D_NOSAMPLER(_HSLAMaskEmission);
		// half4 _HSLAAdjustEmission;
		half _EmissionHue;
		half _EmissionSaturation;
		half _EmissionBrightness;
	#endif
	float _RainbowMainHueUVX;
	float _RainbowMainHueUVY;
	float _RainbowMainHueSpeed;
	float _RainbowEmissionHueUVX;
	float _RainbowEmissionHueUVY;
	float _RainbowEmissionHueSpeed;
#endif

#ifdef LIGHTMAP_ON
	// sampler2D unity_Lightmap;
	// float4 unity_LightmapST;
#endif


struct appdata
{
	float4 vertex: POSITION;
	fixed4 color: COLOR;
	half3 normal: NORMAL;
	float2 uv: TEXCOORD0;
	#ifdef LIGHTMAP_ON
		float2 uv2: TEXCOORD1;
	#endif
	UNITY_VERTEX_INPUT_INSTANCE_ID
	#ifdef KF_NORMAL
		half4 tangent: TANGENT;
	#endif
	#ifdef KF_INSERT_VERT_INPUT
		KF_INSERT_VERT_INPUT
	#endif
};

struct v2f
{
	#ifdef KF_GEOMETRY
		float4 vertex: CLIP_POS;
	#endif
	float4 pos: SV_POSITION;
	fixed4 color: COLOR;
	float2 uv: TEXCOORD0;
	SHADOW_COORDS(1)
	UNITY_FOG_COORDS(2)
	half3 normal: TEXCOORD3;
	half3 worldNormal: TEXCOORD4;
	float3 worldPos: TEXCOORD5;
	#ifdef KF_NORMAL
		float4 normalUV: TEXCOORD6;
		// float2 detailNormalUV: TEXCOORD7;
		half3 tspace0: TEXCOORD7; // tangent.x, bitangent.x, normal.x
		half3 tspace1: TEXCOORD8; // tangent.y, bitangent.y, normal.y
		half3 tspace2: TEXCOORD9; // tangent.z, bitangent.z, normal.z
	#endif
	#ifdef KF_OUTLINE
		half4 outlineColor: TEXCOORD10;
	#endif
	#ifdef KF_VERTEX
		float4 light: TEXCOORD11;
	#endif
	#ifdef LIGHTMAP_ON
		float2 lightmapUv: TEXCOORD12;
	#endif
	#ifdef KF_INSERT_FRAG_INPUT
		KF_INSERT_FRAG_INPUT
	#endif
	UNITY_VERTEX_OUTPUT_STEREO
};
