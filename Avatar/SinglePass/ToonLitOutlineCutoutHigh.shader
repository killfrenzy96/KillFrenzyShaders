Shader "KillFrenzy/Avatar (Single Pass)/Outline Cutout/Toon Lit High"
{
	Properties
	{
		[Enum(Off,0,Front,1,Back,2)] _Culling("Culling Mode", Int) = 2
		_VertexColorAlbedo("Vertex Color Tint", Range(0,1)) = 1
		// _VertexColorAlpha("Vertex Color To Alpha", Range(0,1)) = 0


		[HDR]_Color("Color Tint", Color) = (1,1,1,1)
		_MainTex("Texture", 2D) = "white" {}


		[HDR]_AltColor("Alternate Color Tint", Color) = (1,1,1,1)
		[NoScaleOffset]_AltTex("Alternate Texture", 2D) = "white" {}
		_AltTexStrength("Alternate Texture Strength", Range(0,1)) = 0


		_MinBrightness("Minimum Brightness", Range(0,1)) = 0.01
		_MaxBrightness("Maximum Brightness", Range(0,2)) = 0.9
		_Contrast("Contrast Adjustment", Range(0,1)) = 0.25
		_LightingSaturation("Lighting Saturation", Range(0,1)) = 0.75
		_ShadowStrength("Recieved Shadow Strength", Range(0,1)) = 0.3
		_ShadowLit("Received Shadow Ambient Tint", Range(0,1)) = 0


		[Enum(Off,0,On,1)] _AlphaMask ("Alpha To Mask", Int) = 1
		_AlphaToMaskSharpen("Alpha To Mask Sharpen", Range(0,1)) = 1
		_Cutoff("Cutoff Alpha", Range(0,1)) = 0.01
		_AlphaNoise("Cutoff Noise", Range(0,2)) = 0.0


		[NoScaleOffset]_Ramp("Shadow Ramp", 2D) = "white" {}
		_RampStrength("Shadow Ramp Strength", Range(0,1)) = 1
		_RampLit("Shadow Ramp Ambient Tint", Range(0,1)) = 0


		// _BumpMap("Normal Map", 2D) = "bump" {}
		// _BumpScale("Normal Scale", Range(-2,2)) = 1
		// _DetailNormalMap("Detail Normal Map", 2D) = "bump" {}
		// [NoScaleOffset]_DetailMask("Detail Mask", 2D) = "white" {}
		// _DetailNormalMapScale("Detail Normal Scale", Range(-2,2)) = 1


		[NoScaleOffset]_SpecularMap("Specular Map", 2D) = "white" {}
		_SpecularAlbedoTint("Specular Albedo Tint", Range(0,1)) = 1
		_SpecularIntensity("Specular Intensity", Float) = 0.2
		_SpecularArea("Specular Area", Range(0,1)) = 0.1
		_SpecularSharpness("Specular Sharpness", Range(0,1)) = 0.5


		[HDR]_EmissionColor("Emission Color", Color) = (0,0,0,1)
		[NoScaleOffset]_EmissionMap("Emission Map", 2D) = "white" {}
		_ScaleWithLightSensitivity("Emission Scale with Light", Range(0,1)) = 0


		[HDR]_EmissionAltColor("Alternate Emission Color", Color) = (0,0,0,1)
		[NoScaleOffset]_EmissionMapAlt("Alternate Emission Map", 2D) = "white" {}
		_EmissionMapAltStrength("Alternate Emission Strength", Range(0,1)) = 0


		_RimColor("Rimlight Tint", Color) = (1,1,1,1)
		_RimAlbedoTint("Rimlight Albedo Tint", Range(0,1)) = 1
		_RimIntensity("Rimlight Intensity", Float) = 1
		_RimRange("Rim Range", Range(0,1)) = 0.5
		_RimSharpness("Rim Sharpness", Range(0,1)) = 0.1


		_ShadowRim("Shadow Rim Tint", Color) = (0.9,0.9,0.9,1)
		_ShadowRimRange("Shadow Rim Range", Range(0,1)) = 0.7
		_ShadowRimSharpness("Shadow Rim Sharpness", Range(0,1)) = 0.5


		[HDR]_OutlineColor("Outline Color", Color) = (0.5,0.5,0.5,1)
		[NoScaleOffset]_OutlineMask("Outline Mask", 2D) = "white" {}
		_OutlineWidth("Outline Width", Range(0, 2)) = 0.1
		_OutlineFade("Outline Fade", Range(0, 1)) = 1


		// [HDR]_WorldReflectionTint("World Reflection Tint", Color) = (0,0,0,0)
		[HDR]_MatcapTint("Reflection Tint", Color) = (1,1,1,1)
		// [NoScaleOffset]_BakedCubemap("Cubemap Reflection", CUBE) = "black" {}
		[NoScaleOffset]_Matcap("Matcap Reflection", 2D) = "black" {}
		_MatcapTintToDiffuse("Reflection Albedo Tint", Range(0,1)) = 1
		[HDR][NoScaleOffset]_ReflectivityMask("Reflection Mask" , 2D) = "white" {}
		_MatcapArea("Reflection Area", Range(0,1)) = 1
		_MatcapFrensel("Reflection Frensel", Range(0,1)) = 0


		[NoScaleOffset]_HSLAMask("HSB Mask Main", 2D) = "white" {}
		_MainHue("Main Hue", Float) = 0
		_MainSaturation("Main Saturation", Float) = 0
		_MainBrightness("Main Brightness", Float) = 0
		[NoScaleOffset]_HSLAMaskEmission("HSB Mask Emission", 2D) = "white" {}
		_EmissionHue("Emission Hue", Float) = 0
		_EmissionSaturation("Emission Saturation", Float) = 0
		_EmissionBrightness("Emission Brightness", Float) = 0
		_RainbowMainHueUVX("Rainbow Hue UV X", Float) = 0
		_RainbowMainHueUVY("Rainbow Hue UV Y", Float) = 0
		_RainbowMainHueSpeed("Rainbow Hue Speed", Float) = 0
		_RainbowEmissionHueUVX("Rainbow Emission Hue UV X", Float) = 0
		_RainbowEmissionHueUVY("Rainbow Emission Hue UV Y", Float) = 0
		_RainbowEmissionHueSpeed("Rainbow Emission Hue Speed", Float) = 0


		[IntRange]_Stencil("Stencil ID [0-255]", Range(0,255)) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp("Stencil Comparison", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)]_StencilOp("Stencil Pass Operation", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)]_StencilFail("Stencil Fail Operation", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)]_StencilZFail("Stencil ZFail Operation", Int) = 0
		_Offset("Z Offset", Float) = 0
		[Enum(False,0,True,1)]_ZClip("Z Clip", Int) = 1
	}

	SubShader
	{
		Tags { "RenderType"="TransparentCutout" "Queue"="Geometry" }
		Cull [_Culling]
		Offset [_Offset], [_Offset]
		ZClip [_ZClip]
		LOD 100

		Stencil
		{
			Ref [_Stencil]
			Comp [_StencilComp]
			Pass [_StencilOp]
			Fail [_StencilFail]
			ZFail [_StencilZFail]
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			AlphaToMask [_AlphaMask]

			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

			#pragma multi_compile _ VERTEXLIGHT_ON
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#pragma multi_compile_fwdbase

			#ifndef UNITY_PASS_FORWARDBASE
				#define UNITY_PASS_FORWARDBASE
			#endif

			#define KF_CUTOUT
			// #define KF_TRANSPARENT
			#define KF_TEXTUREALT
			#define KF_SHADOW
			// #define KF_NORMAL
			#define KF_SPECULAR
			#define KF_EMISSION
			#define KF_EMISSIONALT
			#define KF_RIMLIGHT
			#define KF_RIMSHADOW
			#define KF_OUTLINE
			// #define KF_CUBEMAP
			#define KF_MATCAP
			#define KF_HSB

			#include "../KillFrenzyToonLitMain.cginc"
			ENDCG
		}

		Pass
		{
			Name "SHADOWCASTER"
			Tags { "LightMode" = "ShadowCaster" }
			ZWrite On
			ZTest LEqual

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_instancing
			#pragma multi_compile_shadowcaster

			#ifndef UNITY_PASS_SHADOWCASTER
				#define UNITY_PASS_SHADOWCASTER
			#endif

			#define KF_OUTLINE
			#define KF_CUTOUT

			#include "../KillFrenzyToonLitShadow.cginc"
			ENDCG
		}
	}

	Fallback "Transparent/Cutout/Diffuse"
	CustomEditor "KillFrenzyToonLitEditor"
}
