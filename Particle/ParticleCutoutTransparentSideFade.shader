Shader "KillFrenzy/Particle/Cutout Transparent Side Fade"
{
	Properties
	{
		[Enum(Off,0,Front,1,Back,2)] _Culling ("Culling Mode", Int) = 0
		[HDR]_Color ("Color", Color) = (1, 1, 1, 1)
		_MainTex ("Texture", 2D) = "white" {}
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		_AlphaNoise ("Alpha Noise", Range(0,2)) = 0.05
		_AlphaRimIntensity ("Soft Side View Intensity", Range(0,5)) = 1.0
		_AlphaRimCutoff ("Soft Side View Cutoff", Range(0,1)) = 0.25
	}
	SubShader
	{
		Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest+50" "IgnoreProjector"="True" }
		LOD 100
		// AlphaToMask On
		ZWrite On
		Lighting Off
		Cull [_Culling]

		Pass
		{
			Tags { "LightMode" = "Vertex" }

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fog
			#pragma multi_compile_instancing

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				fixed4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				half3 normalWorld : TEXCOORD1;
				half3 viewDirection : TEXCOORD2;
				fixed4 color : COLOR;
				UNITY_FOG_COORDS(3)
				UNITY_VERTEX_OUTPUT_STEREO
			};

			half4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _Cutoff;
			fixed _AlphaNoise;

			half _AlphaRimIntensity;
			fixed _AlphaRimCutoff;

			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normalWorld = UnityObjectToWorldNormal(v.normal);
				o.viewDirection = WorldSpaceViewDir(v.vertex);
				o.color = v.color;
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv) * i.color * _Color;
				half NdotV = 1.0 - min(abs(dot(normalize(i.normalWorld), normalize(i.viewDirection))), 1.0);
				NdotV *= NdotV;

				half alpha = max(col.a - (NdotV + _AlphaRimCutoff) * _AlphaRimIntensity, 0.0);
				alpha *= (1.0 - _AlphaNoise * 0.5) + frac(frac(_Time.a * dot(i.uv, float2(12.9898, 78.233))) * 43758.5453123) * _AlphaNoise;

				clip(alpha - _Cutoff);
				UNITY_APPLY_FOG(i.fogCoord, col);
				return fixed4(col.rgb, alpha);
			}
			ENDCG
		}

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fog
			#pragma multi_compile_instancing

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				fixed4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				half3 normalWorld : TEXCOORD1;
				half3 viewDirection : TEXCOORD2;
				fixed4 color : COLOR;
				UNITY_FOG_COORDS(3)
				UNITY_VERTEX_OUTPUT_STEREO
			};

			half4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _Cutoff;
			fixed _AlphaNoise;

			half _AlphaRimIntensity;
			fixed _AlphaRimCutoff;

			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normalWorld = UnityObjectToWorldNormal(v.normal);
				o.viewDirection = WorldSpaceViewDir(v.vertex);
				o.color = v.color;
				UNITY_TRANSFER_FOG(o,o.pos);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv) * i.color * _Color;
				half NdotV = 1.0 - min(abs(dot(normalize(i.normalWorld), normalize(i.viewDirection))), 1.0);
				NdotV *= NdotV;

				// col.a *= max(col.a - (NdotV + _AlphaRimCutoff) * _AlphaRimIntensity, 0.0);

				half alpha = col.a;
				alpha *= max(col.a - (NdotV + _AlphaRimCutoff) * _AlphaRimIntensity, 0.0);
				col.a = alpha;
				alpha *= (1.0 - _AlphaNoise * 0.5) + frac(frac(_Time.a * dot(i.uv, float2(12.9898, 78.233))) * 43758.5453123) * _AlphaNoise;

				clip(1.0 - (alpha - _Cutoff));
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}

		Pass
		{
			Name "SHADOWCASTER"
			Tags { "LightMode" = "ShadowCaster" }

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex: POSITION;
				float2 uv: TEXCOORD0;
				half3 normal: NORMAL;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 uv: TEXCOORD0;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _Cutoff;
			fixed _AlphaNoise;

			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				half alpha = tex2D(_MainTex, i.uv).a * _Color;
				alpha *= (1.0 - _AlphaNoise * 0.5) + frac(frac(_Time.a * dot(i.uv, float2(12.9898, 78.233))) * 43758.5453123) * _AlphaNoise;

				clip(alpha - _Cutoff);
				SHADOW_CASTER_FRAGMENT(i);
			}

			ENDCG
		}
	}
	Fallback "Transparent/Cutout/Soft Edge Unlit"
}
