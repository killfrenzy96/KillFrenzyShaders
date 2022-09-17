Shader "KillFrenzy/Fake Light/Fake Spot Light"
{
	Properties
	{
		[Enum(Off,0,Front,1,Back,2)] _Culling("Culling Mode", Int) = 1
		[HDR]_Color("Light Color", Color) = (1, 1, 1, 1)
		_Radius("Light Radius", Float) = 0.5
		// _MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="AlphaTest+60" "DisableBatching"="True" }
		LOD 100

		Pass
		{
			Tags { "LightMode" = "Vertex" }
			Cull [_Culling]
			ZWrite Off
			ZTest Always
			Blend DstColor SrcColor

			CGPROGRAM
			#pragma target 2.0
			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#pragma instancing_options procedural:vertInstancingSetup

			#include "UnityCG.cginc"
			#include "UnityStandardParticleInstancing.cginc"

			sampler2D_float _CameraDepthTexture;

			half4 _Color;
			half _Radius;

			struct appdata
			{
				float4 vertex: POSITION;
				fixed4 color: COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 pos: SV_POSITION;
				fixed4 color: COLOR;
				UNITY_FOG_COORDS(1)
				float4 screenPos: TEXCOORD2;
				float3 ray: TEXCOORD3;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.color = v.color;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.screenPos = ComputeScreenPos(o.pos);

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.ray = worldPos - _WorldSpaceCameraPos;

				UNITY_TRANSFER_FOG(o, o.pos);
				return o;
			}

			half4 frag (v2f i) : SV_Target
			{
				vertInstancingSetup();

				//get depth from depth texture
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.screenPos.xy / i.screenPos.w);
				depth = Linear01Depth(depth) * _ProjectionParams.z;

				//get a ray thats 1 long on the axis from the camera away (because thats how depth is defined)
				i.ray = normalize(i.ray);

				//the 3rd row of the view matrix has the camera forward vector encoded, so a dot product with that will give the inverse distance in that direction
				i.ray /= dot(i.ray, -UNITY_MATRIX_V[2].xyz);

				//with that reconstruct world and object space positions
				float3 worldPos = _WorldSpaceCameraPos + i.ray * depth;
				float3 pixelPos = mul(unity_WorldToObject, float4(worldPos, 1)).xyz;

				half light = distance(0, pixelPos.xyz);
				light = max(_Radius - light, 0.0) / _Radius;
				light *= light;

				light *= max(0, dot(normalize(pixelPos.xyz), half3(0, 0, 1)));

				half4 col = half4(_Color.rgb * light, _Color.a) * i.color;
				col.rgb += 0.5;

				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
