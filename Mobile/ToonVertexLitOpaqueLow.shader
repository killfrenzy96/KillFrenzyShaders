Shader "KillFrenzy/Mobile/Opaque/Toon VertexLit Low"
{
	Properties
	{
		[Enum(Off,0,Front,1,Back,2)] _Culling("Culling Mode", Int) = 2
		_VertexColorAlbedo("Vertex Color Tint", Range(0,1)) = 1
		// _VertexColorAlpha("Vertex Color To Alpha", Range(0,1)) = 0


		[HDR]_Color("Color Tint", Color) = (1,1,1,1)
		_MainTex("Texture", 2D) = "white" {}
		_MinBrightness("Minimum Brightness", Range(0,1)) = 0.01
		_MaxBrightness("Maximum Brightness", Range(0,2)) = 1.0
		_Contrast("Contrast Adjustment", Range(0,1)) = 0.0


		// _Cutoff("Cutoff Alpha", Range(0,1)) = 0.5


		_RampStrength("Shadow Ramp Strength", Range(0,1)) = 0.3
		_RampSharpness("Shadow Ramp Sharpness", Range(0,0.5)) = 0.1


		// _SpecularIntensity("Specular Intensity", Float) = 0.2
		// _SpecularArea("Specular Area", Range(0,1)) = 0.1


		// [HDR]_EmissionColor("Emission Color", Color) = (0,0,0,1)
		// [NoScaleOffset]_EmissionMap("Emission Map", 2D) = "black" {}


		// [HDR]_RimColor("Rimlight Tint", Color) = (1,1,1,1)
		// _RimIntensity("Rimlight Intensity", Float) = 1
		// _RimRange("Rim Range", Range(0,1)) = 0.5
		// _RimSharpness("Rim Sharpness", Range(0,1)) = 0.1


		// _ShadowRim("Shadow Rim Tint", Color) = (0.9,0.9,0.9,1)
		// _ShadowRimRange("Shadow Rim Range", Range(0,1)) = 0.7
		// _ShadowRimSharpness("Shadow Rim Sharpness", Range(0,1)) = 0.5


		// [HDR]_MatcapTint("Reflection Tint", Color) = (1,1,1,1)
		// [NoScaleOffset]_Matcap("Matcap Reflection", 2D) = "black" {}
		// _MatcapTintToDiffuse("Reflection Albedo Tint", Range(0,1)) = 1


		[IntRange]_Stencil("Stencil ID [0-255]", Range(0,255)) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp("Stencil Comparison", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)]_StencilOp("Stencil Operation", Int) = 0
		_Offset("Z Offset", Float) = 0
		[Enum(False,0,True,1)]_ZClip("Z Clip", Int) = 1
	}

	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Cull [_Culling]
		Offset [_Offset], [_Offset]
		ZClip [_ZClip]
		LOD 80

		Stencil
		{
			Ref [_Stencil]
			Comp [_StencilComp]
			Pass [_StencilOp]
		}

		Pass {
			Tags { "LightMode" = "Vertex" }
			Lighting On

			CGPROGRAM
			#pragma target 2.0
			#pragma vertex vert
			#pragma fragment frag

			// #define KF_CUTOUT
			// #define KF_TRANSPARENT
			#define KF_SHADOW
			// #define KF_EMISSION
			// #define KF_SPECULAR
			// #define KF_RIMLIGHT
			// #define KF_RIMSHADOW
			// #define KF_MATCAP

			#include "KillFrenzyToonVertexLitMain.cginc"

			ENDCG
		}

		// Pass to render object as a shadow caster
		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			ZWrite On
			ZTest LEqual

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#pragma multi_compile_shadowcaster

			// #define KF_CUTOUT

			#include "KillFrenzyToonVertexLitShadow.cginc"

			ENDCG
		}
	}

	Fallback "Diffuse"
	CustomEditor "KillFrenzyToonVertexLitEditor"
}