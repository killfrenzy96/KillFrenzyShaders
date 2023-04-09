
#include "UnityCG.cginc"

struct appdata
{
	float4 vertex: POSITION;
	float3 normal: NORMAL;
	#ifdef KF_CUTOUT
		float2 uv: TEXCOORD0;
		fixed4 color: COLOR;
	#endif
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
	V2F_SHADOW_CASTER;
	#ifdef KF_CUTOUT
		fixed alpha: COLOR;
		float2 uv: TEXCOORD0;
	#endif
	UNITY_VERTEX_OUTPUT_STEREO
};

#ifdef KF_CUTOUT
	sampler2D _MainTex;
	float4 _MainTex_ST;

	fixed _VertexColorAlbedo;

	fixed _Cutoff;
#endif

v2f vert (appdata v)
{
	v2f o;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
	TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
	#ifdef KF_CUTOUT
		o.alpha = v.color.a;
		o.uv = TRANSFORM_TEX(v.uv, _MainTex);
	#endif
	return o;
}

fixed4 frag (v2f i) : SV_Target
{
	#ifdef KF_CUTOUT
		// Main alpha
		fixed alpha = tex2D(_MainTex, i.uv).a;

		// Vertex alpha
		alpha *= lerp(1, i.alpha, _VertexColorAlbedo);

		// Cutout
		clip(alpha - _Cutoff);
	#endif
	SHADOW_CASTER_FRAGMENT(i);
}
