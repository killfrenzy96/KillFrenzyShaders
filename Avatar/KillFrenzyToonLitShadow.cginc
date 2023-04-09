
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
	fixed _AlphaToMaskSharpen;
	float4 _MainTex_TexelSize;
#endif

#ifdef KF_OUTLINE
	sampler2D _OutlineMask;
	fixed _OutlineWidth;
#endif

v2f vert (appdata v)
{
	v2f o;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

	#ifdef KF_CUTOUT
		o.color = v.color;
	#endif

	#if defined(KF_CUTOUT) || defined(KF_OUTLINE)
		o.uv = TRANSFORM_TEX(v.uv, _MainTex);
	#endif

	#ifdef KF_OUTLINE
		float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
		half outlineWidthMask = tex2Dlod(_OutlineMask, float4(o.uv, 0, 0)).r;
		half cameraDistance = distance(worldPos, _WorldSpaceCameraPos);
		half outlineWidth = outlineWidthMask * _OutlineWidth;

		half fov = atan(1.0f / unity_CameraProjection._m11) * (360.0 / UNITY_PI);
		half outlineVisibility = (outlineWidth / cameraDistance) - (((1080.0 * 0.1) / _ScreenParams.y) * (fov / 60.0));
		outlineWidth *= min(cameraDistance * 3, 1) * .01;
		if (outlineVisibility < 0.005) outlineWidth = 0;

		v.vertex.xyz += normalize(v.normal) * outlineWidth;
	#endif

	TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);

	return o;
}

fixed4 frag (v2f i) : SV_Target
{
	#ifdef KF_CUTOUT
		// Main alpha
		fixed alpha = tex2D(_MainTex, i.uv).a;

		// Vertex alpha
		alpha *= lerp(1, i.color.a, _VertexColorAlbedo);

		// Cutout
		alpha = lerp(alpha, (alpha - _Cutoff) / max(fwidth(alpha), 0.0001) + 0.5, _AlphaToMaskSharpen);
		alpha *= (1.0 - _AlphaNoise * 0.5) + frac(frac(_Time.a * dot(i.uv, float2(12.9898, 78.233))) * 43758.5453123) * _AlphaNoise;
		clip(alpha * (1 + _Cutoff) - _Cutoff);
	#endif
	SHADOW_CASTER_FRAGMENT(i);
}
