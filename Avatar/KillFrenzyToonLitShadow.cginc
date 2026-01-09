
#include "UnityCG.cginc"

struct appdata
{
	float4 vertex: POSITION;
	float3 normal: NORMAL;
	#ifdef KF_CUTOUT
		fixed4 color: COLOR;
	#endif
	#if defined(KF_CUTOUT) || defined(KF_OUTLINE)
		float2 uv: TEXCOORD0;
	#endif
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
	V2F_SHADOW_CASTER;
	#ifdef KF_CUTOUT
		fixed4 color: COLOR;
	#endif
	#if defined(KF_CUTOUT) || defined(KF_OUTLINE)
		float2 uv: TEXCOORD0;
	#endif
	#ifdef KF_CUTOUT
		fixed4 screenPos: TEXCOORD1;
	#endif
	UNITY_VERTEX_OUTPUT_STEREO
};

#if defined(KF_CUTOUT) || defined(KF_OUTLINE)
	sampler2D _MainTex;
	float4 _MainTex_ST;
#endif

#ifdef KF_CUTOUT
	fixed _VertexColorAlbedo;

	fixed _Cutoff;
	fixed _AlphaNoise;
	fixed _AlphaDither;
	fixed _AlphaToMaskSharpen;
	float4 _MainTex_TexelSize;
#endif

#ifdef KF_OUTLINE
	sampler2D _OutlineMask;
	fixed _OutlineWidth;
	fixed _OutlineExpandWithDistance;
#endif

#ifdef KF_INSERT_DECLARE
	KF_INSERT_DECLARE
#endif

#ifdef KF_INSERT_FUNCTION
	KF_INSERT_FUNCTION
#endif

v2f vert (appdata v)
{
	v2f o;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

	#ifdef KF_INSERT_VERT_START
		KF_INSERT_VERT_START
	#endif

	#ifdef KF_CUTOUT
		o.color = v.color;

		float4 pos = UnityObjectToClipPos(v.vertex);
		o.screenPos = ComputeScreenPos(pos);
	#endif

	#if defined(KF_CUTOUT) || defined(KF_OUTLINE)
		o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
	#endif

	#ifdef KF_OUTLINE
		float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
		half outlineWidthMask = tex2Dlod(_OutlineMask, float4(o.uv.xy, 0, 0)).r;
		half cameraDistance = distance(worldPos, _WorldSpaceCameraPos);
		half outlineWidth = outlineWidthMask * _OutlineWidth;

		half fov = atan(1.0f / unity_CameraProjection._m11) * (360.0 / UNITY_PI);
		outlineWidth += outlineWidth * cameraDistance * _OutlineExpandWithDistance;
		half outlineVisibility = (outlineWidth / cameraDistance) - (((1080.0 * 0.1) / _ScreenParams.y) * (fov / 60.0));
		outlineWidth *= min(cameraDistance * 3, 1) * .01;
		if (outlineVisibility < 0.005) outlineWidth = 0;

		v.vertex.xyz += normalize(v.normal) * outlineWidth;
	#endif

	#ifdef KF_INSERT_VERT_END
		KF_INSERT_VERT_END
	#endif

	TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);

	return o;
}

inline half Dither8x8Bayer( int x, int y )
{
	const half dither[ 64 ] = {
		 1, 49, 13, 61,  4, 52, 16, 64,
		33, 17, 45, 29, 36, 20, 48, 32,
		 9, 57,  5, 53, 12, 60,  8, 56,
		41, 25, 37, 21, 44, 28, 40, 24,
		 3, 51, 15, 63,  2, 50, 14, 62,
		35, 19, 47, 31, 34, 18, 46, 30,
		11, 59,  7, 55, 10, 58,  6, 54,
		43, 27, 39, 23, 42, 26, 38, 22
	};
	int r = y * 8 + x;
	return dither[r] / 64;
}

half calcDither(half2 screenPos)
{
	half dither = Dither8x8Bayer(fmod(screenPos.x, 8), fmod(screenPos.y, 8));
	return dither;
}

fixed4 frag (v2f i) : SV_Target
{
	#ifdef KF_INSERT_FRAG_START
		KF_INSERT_FRAG_START
	#endif

	// #ifdef KF_CUTOUT
	// 	// Main alpha
	// 	fixed alpha = tex2D(_MainTex, i.uv.xy).a;

	// 	// Vertex alpha
	// 	alpha *= lerp(1, i.color.a, _VertexColorAlbedo);

	// 	// Cutout
	// 	alpha = lerp(alpha, (alpha - _Cutoff) / max(fwidth(alpha), 0.0001) + 0.5, _AlphaToMaskSharpen);
	// 	alpha *= (1.0 - _AlphaNoise * 0.5) + frac(frac(_Time.a * dot(i.uv.xy, float2(12.9898, 78.233))) * 43758.5453123) * _AlphaNoise;
	// 	clip(alpha * (1 + _Cutoff) - _Cutoff);
	// #endif

	// Cutout
	#ifdef KF_CUTOUT
		fixed alpha = tex2D(_MainTex, i.uv.xy).a;

		// Vertex alpha
		alpha *= lerp(1, i.color.a, _VertexColorAlbedo);

		// alpha *= 1 + CalcMipLevel(i.uv.xy * _MainTex_TexelSize.zw) * 0.25;
		#ifndef KF_TRANSPARENT
			alpha = lerp(alpha, (alpha - _Cutoff) / max(fwidth(alpha), 0.0001) + 0.5, _AlphaToMaskSharpen);
		#endif

		// Strength of dither/noise
		#if defined(SHADER_API_D3D11) || defined(SHADER_API_D3D12)
			uint msaaSamples = GetRenderTargetSampleCount();
		#else
			uint msaaSamples = 1;
		#endif
		half alphaStrength = step(0.005, alpha) * step(alpha, 0.995); // Disable cutout processing for low and high alpha values

		// Alpha Dither
		float2 screenUv = i.screenPos.xy / (i.screenPos.w + 0.0000000001); //0.0x1 Stops division by 0 warning in console.
		#if UNITY_SINGLE_PASS_STEREO
			screenUv *= half2(_ScreenParams.x * 2, _ScreenParams.y);
		#else
			screenUv *= _ScreenParams.xy;
		#endif
		half alphaDitherMultiplier = _AlphaDither / msaaSamples;
		half alphaDither = (calcDither(screenUv) * alphaStrength - (alphaStrength * 0.5)) * alphaDitherMultiplier;

		// Alpha Noise
		half alphaNoiseMultiplier = _AlphaNoise / msaaSamples;
		half alphaNoise = (frac(frac(_Time.a * dot(i.uv.xy, float2(12.9898, 78.233))) * 43758.5453123) * alphaStrength - (alphaStrength * 0.5)) * alphaNoiseMultiplier;

		// Merge and apply
		alpha += alphaDither + alphaNoise;
		alpha = clamp(alpha, 0, 1);
		clip(alpha * (1 + _Cutoff * _AlphaToMaskSharpen) - _Cutoff);
	#endif

	#ifdef KF_INSERT_FRAG_END
		KF_INSERT_FRAG_END
	#endif

	SHADOW_CASTER_FRAGMENT(i);
}
