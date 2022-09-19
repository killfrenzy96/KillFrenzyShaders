Shader "KillFrenzy/Fake Light/Fake Mesh Light"
{
	Properties
	{
		[HDR]_Color("Color Tint", Color) = (1,1,1,1)
		_MainTex("Texture", 2D) = "white" {}
		[IntRange]_Stencil("Stencil ID [0;255]", Range(0,255)) = 120
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="AlphaTest+60" }
		LOD 100

		Pass
		{
			Stencil {
				Ref [_Stencil]
				Comp Always
				Pass Zero
				ZFail Replace
			}

			Tags { "LightMode" = "Vertex" }
			Cull Front
			ZWrite Off
			ZTest LEqual
			Blend Zero One

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_instancing
			#include "UnityCG.cginc"

			struct appdata{
				float4 vertex: POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f{
				float4 pos: SV_POSITION;
				UNITY_FOG_COORDS(0)
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert(appdata v){
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.pos = UnityObjectToClipPos(v.vertex);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				return 0;
			}

			ENDCG
		}

		Pass
		{
			Stencil {
				Ref [_Stencil]
				Comp Equal
			}

			Tags { "LightMode" = "Vertex" }
			Cull Back
			ZWrite Off
			ZTest LEqual
			Blend DstColor SrcColor

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex: POSITION;
				float2 uv: TEXCOORD0;
				fixed4 color: COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 pos: SV_POSITION;
				fixed4 color: COLOR;
				float2 uv: TEXCOORD0;
				UNITY_FOG_COORDS(1)
				UNITY_VERTEX_OUTPUT_STEREO
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;

			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = v.color;

				UNITY_TRANSFER_FOG(o, o.pos);
				return o;
			}

			fixed4 frag (v2f i): SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv) * _Color * i.color;
				col.rgb += 0.5;

				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
