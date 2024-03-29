#include "UnityCG.cginc"

// #define KF_CUTOUT
// #define KF_SHADOW
// #define KF_RIMLIGHT
// #define KF_RIMSHADOW


fixed4 _Color;
UNITY_DECLARE_TEX2D(_MainTex);
half4 _MainTex_ST;

fixed _MinBrightness;
fixed _MaxBrightness;
fixed _Contrast;

fixed _VertexColorAlbedo;

#ifdef KF_TRANSPARENT
	fixed _VertexColorAlpha;
#endif

#ifdef KF_CUTOUT
	fixed _Cutoff;
#endif

#ifdef KF_SHADOW
	fixed _RampStrength;
	fixed _RampSharpness;
#endif

#ifdef KF_SPECULAR
	half _SpecularIntensity;
	fixed _SpecularArea;
#endif

#ifdef KF_EMISSION
	UNITY_DECLARE_TEX2D_NOSAMPLER(_EmissionMap);
	fixed4 _EmissionColor;
#endif

#ifdef KF_RIMLIGHT
	fixed4 _RimColor;
	half _RimIntensity;
	fixed _RimRange;
	fixed _RimSharpness;
#endif

#ifdef KF_RIMSHADOW
	fixed4 _ShadowRim;
	fixed _ShadowRimRange;
	fixed _ShadowRimSharpness;
#endif

#ifdef KF_MATCAP
	sampler2D _Matcap;
	fixed4 _MatcapTint;
	fixed _MatcapTintToDiffuse;
#endif

#ifdef LIGHTMAP_ON
	// sampler2D unity_Lightmap;
	// float4 unity_LightmapST;
	fixed _ShadowStrength;
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
};

struct v2f
{
	float4 pos: SV_POSITION;
	fixed4 light: COLOR0;
	#ifdef KF_SHADOW
		float3 uvShadow: TEXCOORD0;
	#else
		float2 uvShadow: TEXCOORD0;
	#endif
	#ifdef KF_MATCAP
		half2 matcapUV: TEXCOORD1;
	#endif
	#ifdef LIGHTMAP_ON
		float2 lightmapUv: TEXCOORD2;
	#endif
	UNITY_VERTEX_OUTPUT_STEREO
};

#include "KillFrenzyToonVertexLitHelper.cginc"

v2f vert(appdata v)
{
	v2f o;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

	o.pos = UnityObjectToClipPos(v.vertex);
	o.uvShadow.xy = TRANSFORM_TEX(v.uv, _MainTex);

	half3 viewpos = UnityObjectToViewPos (v.vertex.xyz);
	half3 viewN = normalize (mul ((float3x3)UNITY_MATRIX_IT_MV, v.normal));

	half3 lightColor = UNITY_LIGHTMODEL_AMBIENT.xyz;
	#ifdef KF_SHADOW
		half lightSources = 0;
		half shadow = 0;
	#endif

	#ifdef LIGHTMAP_ON
		o.lightmapUv = v.uv2 * unity_LightmapST.xy + unity_LightmapST.zw;
		o.light = 1.0;
	#else
		for (int i = 0; i < 4; i++) {
			half3 toLight = unity_LightPosition[i].xyz - viewpos.xyz * unity_LightPosition[i].w;
			half lengthSq = dot(toLight, toLight);

			// don't produce NaNs if some vertex position overlaps with the light
			lengthSq = max(lengthSq, 0.000001);

			toLight *= rsqrt(lengthSq);

			half atten = 1.0 / (1.0 + lengthSq * unity_LightAtten[i].z);
			if (unity_LightAtten[i].x != -1 && unity_LightAtten[i].y != 1) // if spotlight
			{
				float rho = max (0, dot(toLight, unity_SpotDirection[i].xyz));
				float spotAtt = (rho - unity_LightAtten[i].x) * unity_LightAtten[i].y;
				atten *= saturate(spotAtt);
			}
			half3 light = unity_LightColor[i].rgb * atten;

			lightColor += light;

			#ifdef KF_SHADOW
				half diff = max (0, dot (viewN, toLight));
				half brightness = (light.r + light.g + light.b) * atten;
				shadow += diff * brightness;
				lightSources = max(lightSources, brightness);
			#endif
		}

		o.light = fixed4(clamp(lightColor, _MinBrightness, _MaxBrightness), 1.0);
	#endif

	#if defined(KF_RIMLIGHT) || defined(KF_RIMSHADOW) || defined(KF_SPECULAR) || defined(KF_MATCAP)
		#define KF_LIGHTING_EFFECTS
	#endif

	#if defined(KF_SHADOW) || defined(KF_LIGHTING_EFFECTS)
		half3 worldNormal = UnityObjectToWorldNormal(v.normal);
	#endif

	#ifdef KF_SHADOW
		if (lightSources > 0.001) {
			o.uvShadow.z = shadow / lightSources;
		} else {
			o.uvShadow.z = (worldNormal.y + 1.0) / 2;
		}
	#endif

	// Dot Products and general calculations
	#ifdef KF_LIGHTING_EFFECTS
		half3 additiveLit = half3(0, 0, 0);
		half3 multiply = half3(1, 1, 1);

		half3 worldPos = mul(unity_ObjectToWorld, v.vertex);
		half3 viewDir = normalize(_WorldSpaceCameraPos - worldPos);

		half3 lightDir = calcLightDir(worldPos, half4(0, 0, 0, 0));
		half dotNdl = dot(worldNormal, lightDir);

		half3 stereoViewDir = calcStereoViewDir(worldPos);
		// half dotSvdn = abs(dot(stereoViewDir, worldNormal));
		half dotSvdn2 = saturate(1 - abs(dot(stereoViewDir, worldNormal)));
	#endif

	// Vertex colour
	#ifdef KF_LIGHTING_EFFECTS
		multiply *= lerp(1, v.color.rgb, _VertexColorAlbedo);
		o.light.a *= lerp(1, v.color.a, _VertexColorAlbedo);
	#else
		o.light *= lerp(1, v.color, _VertexColorAlbedo);
	#endif

	#ifdef KF_TRANSPARENT
		o.light.a *= lerp(1, v.color.r, _VertexColorAlpha);
	#endif

	// Specular
	#ifdef KF_SPECULAR
		half3 reflLight = normalize(reflect(lightDir, worldNormal));
		half dotRdv = saturate(dot(reflLight, half4(-viewDir, 0)));

		half specularIntensity = _SpecularIntensity;
		half smoothness = max(0.01, (_SpecularArea));
		smoothness *= 1.7 - 0.7 * smoothness;

		// smoothness *= 128;
		// half reflectionUntouched = saturate(pow(dotRdv, smoothness));

		smoothness *= 192;
		half reflectionUntouched = min(exp2(smoothness * dotRdv - smoothness), 1.0); // Optimized estimation

		half3 specular = reflectionUntouched * specularIntensity * (_SpecularArea + 0.5);

		specular *= o.light.rgb;
		additiveLit += specular;
	#endif

	// Rim light
	#ifdef KF_RIMLIGHT
		half rimIntensity = dotSvdn2 * max(dotNdl, 0);
		rimIntensity = smoothstep(_RimRange - _RimSharpness, _RimRange + _RimSharpness, rimIntensity);
		additiveLit += rimIntensity * o.light.rgb * _RimIntensity * _RimColor;
	#endif

	// Rim shadow
	#ifdef KF_RIMSHADOW
		half shadowIntensity = dotSvdn2 * max(dotNdl * -1, 0);
		shadowIntensity = smoothstep(_ShadowRimRange - _ShadowRimSharpness, _ShadowRimRange + _ShadowRimSharpness, shadowIntensity);
		half3 shadowRim = lerp(1.0 - shadowIntensity, 1.0, _ShadowRim);
		multiply *= shadowRim;
	#endif

	// Matcap
	#ifdef KF_MATCAP
		half3 worldUp = half3(0, 1, 0);
		half3 worldViewUp = normalize(worldUp - viewDir * dot(viewDir, worldUp));
		half3 worldViewRight = normalize(cross(viewDir, worldViewUp));
		o.matcapUV = half2(dot(worldViewRight, worldNormal), dot(worldViewUp, worldNormal)) * 0.5 + 0.5;
	#endif

	// Combine data
	#ifdef KF_LIGHTING_EFFECTS
		o.light.rgb += additiveLit;
		o.light.rgb *= multiply;
	#endif

	return o;
}

half4 frag(v2f i) : SV_Target
{
	// Main colour
	half4 col = UNITY_SAMPLE_TEX2D(_MainTex, i.uvShadow.xy) * _Color;

	// Lighting
	i.light = lerp(i.light, col * i.light * 2, _Contrast); // Contrast adjustment
	col *= i.light;

	// Lightmap
	#ifdef LIGHTMAP_ON
		half3 brightness = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lightmapUv));
		brightness = lerp(brightness, 1.0, 1 - _ShadowStrength);
		col.rgb *= brightness;
	#endif

	// Cutout
	#ifdef KF_CUTOUT
		clip(col.a - _Cutoff);
	#endif

	// Matcap
	#ifdef KF_MATCAP
		half3 matCap = tex2D(_Matcap, i.matcapUV) * _MatcapTint;
		matCap *= lerp(1, col * 2, _MatcapTintToDiffuse);
		col.rgb += matCap;
	#endif

	// Light shadows
	#ifdef KF_SHADOW
		col.rgb *= smoothstep(0.5 - _RampSharpness, 0.5 + _RampSharpness, i.uvShadow.z) * _RampStrength + (1 - _RampStrength);
	#endif

	// Emission texture
	#ifdef KF_EMISSION
		col.rgb += UNITY_SAMPLE_TEX2D_SAMPLER(_EmissionMap, _MainTex, i.uvShadow.xy) * _EmissionColor;
	#endif

	return col;
}