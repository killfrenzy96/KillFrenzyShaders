#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

// #define KF_CUTOUT
// #define KF_TRANSPARENT
// #define KF_TEXTUREALT
// #define KF_SHADOW
// #define KF_NORMAL
// #define KF_SPECULAR
// #define KF_EMISSION
// #define KF_RIMLIGHT
// #define KF_RIMSHADOW
// #define KF_OUTLINE
// #define KF_CUBEMAP
// #define KF_MATCAP
// #define KF_HSB

#ifdef KF_OUTLINE
	#define KF_GEOMETRY
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

#ifdef KF_TEXTUREALT
	half4 _AltColor;
	UNITY_DECLARE_TEX2D_NOSAMPLER(_AltTex);
	fixed _AltTexStrength;
#endif

#ifdef KF_CUTOUT
	fixed _Cutoff;
	fixed _AlphaNoise;
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
#endif

#ifdef KF_EMISSION
	UNITY_DECLARE_TEX2D_NOSAMPLER(_EmissionMap);
	half4 _EmissionColor;
	fixed _ScaleWithLightSensitivity;
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
#endif

#ifdef KF_CUBEMAP
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
#endif

struct appdata
{
	float4 vertex: POSITION;
	fixed4 color: COLOR;
	half3 normal: NORMAL;
	float2 uv: TEXCOORD0;
	UNITY_VERTEX_INPUT_INSTANCE_ID
	#ifdef KF_NORMAL
		half4 tangent: TANGENT;
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
	UNITY_VERTEX_OUTPUT_STEREO
};

#include "KillFrenzyToonLitHelper.cginc"

v2f vert(appdata v)
{
	v2f o;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

	#ifdef KF_GEOMETRY
		o.vertex = v.vertex;
	#endif

	o.pos = UnityObjectToClipPos(v.vertex);
	o.worldPos = mul(unity_ObjectToWorld, v.vertex);
	o.worldNormal = UnityObjectToWorldNormal(v.normal);
	o.color = v.color;
	o.normal = v.normal;
	o.uv = TRANSFORM_TEX(v.uv, _MainTex);

	#ifdef KF_OUTLINE
		half outlineWidthMask = tex2Dlod(_OutlineMask, float4(o.uv, 0, 0)).r;
		o.outlineColor = half4(
			outlineWidthMask, // Outline Width Mask
			distance(o.worldPos, _WorldSpaceCameraPos), // Camera Distance
			outlineWidthMask * _OutlineWidth, // Outline Width
			0.0
		);
	#endif

	#ifdef KF_NORMAL
		o.normalUV.xy = TRANSFORM_TEX(v.uv, _BumpMap);
		// o.detailNormalUV = TRANSFORM_TEX(v.uv, _DetailNormalMap);
		o.normalUV.zw = TRANSFORM_TEX(v.uv, _DetailNormalMap);

		half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
		half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
		half3 wBitangent = cross(o.worldNormal, wTangent) * tangentSign;

		o.tspace0 = half3(wTangent.x, wBitangent.x, o.worldNormal.x);
		o.tspace1 = half3(wTangent.y, wBitangent.y, o.worldNormal.y);
		o.tspace2 = half3(wTangent.z, wBitangent.z, o.worldNormal.z);
	#endif

	UNITY_TRANSFER_SHADOW(o, o.uv);
	UNITY_TRANSFER_FOG(o, o.pos);
	return o;
}

#if defined(KF_NORMAL) || (defined(KF_OUTLINE) && defined(KF_CUTOUT))
	fixed4 frag(v2f i, uint facing: SV_IsFrontFace) : SV_Target
#else
	fixed4 frag(v2f i) : SV_Target
#endif
{
	half3 additiveSoftLit = half3(0, 0, 0);
	half3 additiveLit = half3(0, 0, 0);
	#ifdef UNITY_PASS_FORWARDBASE
		half3 additiveEmit = half3(0, 0, 0);
	#endif
	half3 multiply = half3(1, 1, 1);

	// Main colour
	half4 albedo = UNITY_SAMPLE_TEX2D(_MainTex, i.uv) * _Color;

	// Alt colour
	#ifdef KF_TEXTUREALT
		albedo = lerp(albedo, UNITY_SAMPLE_TEX2D_SAMPLER(_AltTex, _MainTex, i.uv) * _AltColor, _AltTexStrength);
	#endif

	half3 col = albedo.rgb;
	half alpha = albedo.a;

	// Vertex colour
	col *= lerp(1, i.color.rgb, _VertexColorAlbedo);
	alpha *= lerp(1, i.color.a, _VertexColorAlbedo);

	// Backface calculations
	#if defined(KF_NORMAL) || (defined(KF_OUTLINE) && defined(KF_CUTOUT))
		bool face = facing > 0; // True if on front face, False if on back face
		if (!face) {
			#if defined(KF_OUTLINE) && defined(KF_CUTOUT)
				// Outline
				// Using discard is very slow, only use for cutout variant (which already uses clip).
				// Allows outlines to be used with culling off.
				if (i.outlineColor.a > 0.01) {
					alpha -= 1.0;
				}
			#endif

			// Invert Normals based on face
			#ifdef KF_NORMAL
				i.tspace0 *= -i.tspace0;
				i.tspace1 *= -i.tspace1;
				i.tspace2 *= -i.tspace2;
			#endif
		}
	#endif

	// Cutout
	#ifdef KF_CUTOUT
		alpha *= (1.0 - _AlphaNoise * 0.5) + frac(frac(_Time.a * dot(i.uv, float2(12.9898, 78.233))) * 43758.5453123) * _AlphaNoise;
		clip(alpha * (1 + _Cutoff) - _Cutoff);
	#endif

	// Normal
	#ifdef KF_NORMAL
		half3 nMap = UnpackScaleNormal(UNITY_SAMPLE_TEX2D_SAMPLER(_BumpMap, _MainTex, i.normalUV.xy), _BumpScale);
		half3 detNMap = UnpackScaleNormal(UNITY_SAMPLE_TEX2D_SAMPLER(_DetailNormalMap, _MainTex, i.normalUV.zw), _DetailNormalMapScale);
		half detailMask = UNITY_SAMPLE_TEX2D_SAMPLER(_DetailMask, _MainTex, i.uv).r;

		half3 blendedNormal = lerp(nMap, BlendNormals(nMap, detNMap), detailMask);

		half3 calcedNormal;
		calcedNormal.x = dot(i.tspace0, blendedNormal);
		calcedNormal.y = dot(i.tspace1, blendedNormal);
		calcedNormal.z = dot(i.tspace2, blendedNormal);

		i.worldNormal = normalize(calcedNormal);
		// i.tangent = (cross(i.bitangent, calcedNormal));
		// i.bitangent = (cross(calcedNormal, bumpedTangent));
	#endif

	// Emission colour
	#ifdef KF_EMISSION
		half4 emissionMap = UNITY_SAMPLE_TEX2D_SAMPLER(_EmissionMap, _MainTex, i.uv) * _EmissionColor;
		half3 emission = emissionMap.rgb;
		emission.rgb *= emissionMap.a;
	#endif

	// Hue/Saturation/Brightness slider
	#ifdef KF_HSB
		half4 hslaMask = UNITY_SAMPLE_TEX2D_SAMPLER(_HSLAMask, _MainTex, i.uv);
		half4 hslaMaskEmission = UNITY_SAMPLE_TEX2D_SAMPLER(_HSLAMaskEmission, _MainTex, i.uv);

		// col = hue(col, half4(_HSLAAdjust.x, 0.0, _HSLAAdjust.zw), hslaMask.rgb); // Main Hue/Brightness
		col = lerp(col, applyHue(col, _MainHue), hslaMask.r); // Main Hue
		col = lerp(dot(col, grayscaleVec), col, (_MainSaturation * hslaMask.g) + 1.0); // Main Saturation
		col *= 1.0 + _MainBrightness * hslaMask.b; // Main Brightness

		#ifdef KF_EMISSION
			// emission = hue(emission, half4(_HSLAAdjustEmission.x, 0.0, _HSLAAdjustEmission.zw), hslaMaskEmission); // Emission Hue/Brightness
			emission = lerp(emission, applyHue(emission, _EmissionHue), hslaMaskEmission.r); // Emission Hue
			emission = lerp(dot(emission, grayscaleVec), emission, (_EmissionSaturation * hslaMaskEmission.g) + 1.0); // Emission Saturation
			emission *= 1.0 + _EmissionBrightness * hslaMaskEmission.b; // Emission Brightness
		#endif
	#endif

	// Emission
	#ifdef KF_EMISSION
		half lightScale = _ScaleWithLightSensitivity;
		#ifdef UNITY_PASS_FORWARDBASE
			additiveLit += emission * lightScale; // Emission affects lit texture
			additiveEmit += emission * (1 - lightScale); // Emission glows
		#else
			additiveLit += emission;
		#endif
		col += emission; // Emission always affects main texture
	#endif

	// Clamp base colour brightness and move it to additive lit
	half colBrightness = getBrightness(col);
	if (colBrightness > 1.0) {
		half3 extraCol = col;
		col *= 1.0 / colBrightness;
		additiveLit += extraCol - col;
	}

	// Lighting (Ambient and Colour)
	half4 vertexLightAtten = half4(0, 0, 0, 0);
	half3 ambient = ShadeSH9(half4(0, 0.5, 0, 1));
	#if defined(VERTEXLIGHT_ON)
		ambient += get4VertexLightsColFalloff(i.worldPos, i.normal, vertexLightAtten);
	#endif
	ambient = lerp(dot(ambient, grayscaleVec), ambient, _LightingSaturation); // Desaturate ambient light
	// ambient = min(ambient, _MaxBrightness); // Limit maximum ambient

	// Dot Products and general calculations
	half3 lightDir = calcLightDir(i, vertexLightAtten);
	half dotNdl = dot(i.worldNormal, lightDir);

	#if defined(KF_RIMLIGHT) || defined(KF_RIMSHADOW)
		half3 stereoViewDir = calcStereoViewDir(i.worldPos);
		// half dotSvdn = abs(dot(stereoViewDir, i.worldNormal));
		half dotSvdn2 = saturate(1 - abs(dot(stereoViewDir, i.worldNormal)));
	#endif

	half3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

	half3 lightCol = half3(0, 0, 0);
	calcLightCol(ambient, lightCol);

	// Lighting (Attenuation and Shadows)
	fixed shadow = UNITY_SHADOW_ATTENUATION(i, i.worldPos.xyz);

	#ifdef POINT
		unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(i.worldPos.xyz, 1)).xyz;
		fixed attenuation = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).r;
		shadow = lerp(shadow, 1.0, 1 - _ShadowStrength);
	#endif

	#ifdef SPOT
		DECLARE_LIGHT_COORD(i, i.worldPos.xyz);
		fixed attenuation = (lightCoord.z > 0) * UnitySpotCookie(lightCoord) * UnitySpotAttenuate(lightCoord.xyz);
		shadow = lerp(shadow, 1.0, 1 - _ShadowStrength);
	#endif

	#ifdef POINT_COOKIE
		DECLARE_LIGHT_COORD(i, i.worldPos.xyz);
		fixed attenuation = tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).r * texCUBE(_LightTexture0, lightCoord).w;
		shadow = lerp(shadow, 1.0, 1 - _ShadowStrength);
	#endif

	#ifdef DIRECTIONAL_COOKIE
		DECLARE_LIGHT_COORD(i, i.worldPos.xyz);
		fixed attenuation = tex2D(_LightTexture0, lightCoord).w;
		shadow = lerp(shadow, 1.0, 1 - _ShadowStrength);
	#endif

	#ifdef DIRECTIONAL
		fixed attenuation = 1.0;
	#endif

	#if defined(UNITY_PASS_FORWARDBASE) && !defined(DIRECTIONAL)
		if (all(_LightColor0.rgb == 0.0)) {
			attenuation = 1.0;
		}
	#endif

	// Lighting (Brightness level)
	half3 brightness = min(attenuation, _MaxBrightness) * lightCol + ambient;

	#ifdef UNITY_PASS_FORWARDBASE
		brightness = max(brightness, _MinBrightness); // Limit minimum brightness
	#endif
	brightness = min(brightness, _MaxBrightness); // Limit maximum brightness

	// Apply realtime shadows
	brightness *= lerp(shadow, 1.0, (1 - _ShadowStrength) + (ambient * _ShadowLit));

	// Shadow Ramp
	#ifdef KF_SHADOW
		half3 ramp = tex2D(_Ramp, half2((dotNdl * 0.5 + 0.5), 0.5)).rgb;
		ramp = ramp * _RampStrength + (1.0 - _RampStrength);

		half ambientRamp = ambient * _RampLit;
		brightness *= (ramp * (1 - ambientRamp)) + ambientRamp;
	#endif

	// Lighting Part 3
	brightness = lerp(brightness, col * brightness * 2, _Contrast); // Contrast adjustment
	multiply *= smoothMin(brightness, _MaxBrightness);

	// Cubemap / Matcap Part 1
	#if defined(KF_CUBEMAP) || defined(KF_MATCAP)
		half3 reflectivityMask = UNITY_SAMPLE_TEX2D_SAMPLER(_ReflectivityMask, _MainTex, i.uv).rgb;
	#endif

	// Cubemap
	#ifdef KF_CUBEMAP
		half roughness = (1 - _MatcapArea * reflectivityMask.b);
		roughness *= 1.7 - 0.7 * roughness;
		roughness *= UNITY_SPECCUBE_LOD_STEPS;

		half3 reflView = reflect(-viewDir, i.worldNormal);
		half3 cubeMap = texCUBElod(_BakedCubemap, half4(reflView, roughness)) * _MatcapTint;
		#ifndef KF_MATCAP
			cubeMap *= lerp(1, col * 2, _MatcapTintToDiffuse * reflectivityMask.g);
			cubeMap *= reflectivityMask.r;
			additiveSoftLit += cubeMap;
		#endif
	#endif

	// Matcap
	#ifdef KF_MATCAP
		half3 worldUp = half3(0, 1, 0);
		half3 worldViewUp = normalize(worldUp - viewDir * dot(viewDir, worldUp));
		half3 worldViewRight = normalize(cross(viewDir, worldViewUp));
		half2 remapUV = half2(dot(worldViewRight, i.worldNormal), dot(worldViewUp, i.worldNormal)) * 0.5 + 0.5;

		half3 matCap = tex2Dlod(_Matcap, half4(remapUV, 0, (1 - _MatcapArea * reflectivityMask.b) * 7.0)) * _MatcapTint;
		#ifndef KF_CUBEMAP
			matCap *= lerp(1, col * 2, _MatcapTintToDiffuse * reflectivityMask.g);
			matCap *= reflectivityMask.r;
			additiveSoftLit += matCap;
		#endif
	#endif

	// Cubemap / Matcap Part 2
	#if defined(KF_CUBEMAP) && defined(KF_MATCAP)
		matCap += cubeMap;
		matCap *= lerp(1, col * 2, _MatcapTintToDiffuse * reflectivityMask.g);
		matCap *= reflectivityMask.r;
		additiveSoftLit += matCap;
	#endif

	// Specular
	#ifdef KF_SPECULAR
		half3 reflLight = normalize(reflect(lightDir, i.worldNormal));
		half dotRdv = saturate(dot(reflLight, half4(-viewDir, 0)));

		fixed3 specularMap = UNITY_SAMPLE_TEX2D_SAMPLER(_SpecularMap, _MainTex, i.uv).rgb;
		half specularIntensity = _SpecularIntensity * specularMap.r;
		half smoothness = max(0.01, (_SpecularArea * specularMap.b));
		smoothness *= 1.7 - 0.7 * smoothness;

		// smoothness *= 128;
		// half reflectionUntouched = saturate(pow(dotRdv, smoothness));

		smoothness *= 192;
		half reflectionUntouched = min(exp2(smoothness * dotRdv - smoothness), 1.0); // Optimized estimation

		half3 specular = reflectionUntouched * specularIntensity * (_SpecularArea + 0.5);

		specular = lerp(specular, specular * col, _SpecularAlbedoTint * specularMap.g); // Should specular highlight be tinted based on the albedo of the object?
		additiveSoftLit += specular;
	#endif

	// Rim light
	#ifdef KF_RIMLIGHT
		half rimIntensity = dotSvdn2 * max(dotNdl, 0);
		rimIntensity = smoothstep(_RimRange - _RimSharpness, _RimRange + _RimSharpness, rimIntensity);
		additiveSoftLit += rimIntensity * lerp(1.0, col, _RimAlbedoTint) * _RimIntensity * _RimColor;
	#endif

	// Rim shadow
	#ifdef KF_RIMSHADOW
		half shadowIntensity = dotSvdn2 * max(1 - dotNdl, 0);
		shadowIntensity = smoothstep(_ShadowRimRange - _ShadowRimSharpness, _ShadowRimRange + _ShadowRimSharpness, shadowIntensity);
		half3 shadowRim = lerp(1.0 - shadowIntensity, 1.0, _ShadowRim);
		multiply *= shadowRim;
	#endif

	// Combine data
	// col = lerp(col, 1.0, min(additiveSoftLit, 1.0));
	// smoothMin(additiveSoftLit, (_MaxBrightness * 0.5) / (multiply + 0.0001));
	col += additiveSoftLit;
	col *= multiply;
	col = smoothMin(col, _MaxBrightness);
	col += additiveLit * multiply; // * log2(getBrightness(additiveLit) * 4.0 + 1.0) * 0.175;
	// col *= multiply;
	// col = min(col, 1.0);
	#ifdef UNITY_PASS_FORWARDBASE
		col += additiveEmit;
	#endif

	// Outline colour
	#ifdef KF_OUTLINE
		col *= i.outlineColor.rgb;
	#endif

	// Fog
	UNITY_APPLY_FOG(i.fogCoord, col);
	return fixed4(col, alpha);
}

#ifdef KF_GEOMETRY
	#ifdef KF_OUTLINE
		[maxvertexcount(6)]
	#else
		[maxvertexcount(3)]
	#endif
	void geom(triangle v2f IN[3], inout TriangleStream<v2f> triStream)
	{
		// v2f o;

		// Outlines Part 1
		#ifdef KF_OUTLINE
			half3 outlineWidthMask = half3(
				IN[0].outlineColor.r,
				IN[1].outlineColor.r,
				IN[2].outlineColor.r
			);

			half3 cameraDistance = half3(
				IN[0].outlineColor.g,
				IN[1].outlineColor.g,
				IN[2].outlineColor.g
			);

			half3 outlineWidth = half3(
				IN[0].outlineColor.b,
				IN[1].outlineColor.b,
				IN[2].outlineColor.b
			);
		#endif

		// Main mesh
		[unroll]
		for (int k = 0; k < 3; k++)
		{
			IN[k].outlineColor = 1.0;
			triStream.Append(IN[k]);
		}

		triStream.RestartStrip();

		// Outlines Part 2
		#ifdef KF_OUTLINE
			if (
				(outlineWidth.r / cameraDistance.r) > (1080.0 * 0.05) / _ScreenParams.y && // Skip if outline is too small to see
				outlineWidthMask.r + outlineWidthMask.g + outlineWidthMask.b > 0.01 // Skip if outline is masked out
			) {
				outlineWidth *= min(cameraDistance * 3, 1) * .01;

				[unroll]
				for (int j = 2; j >= 0; j--) {
					IN[j].vertex.xyz += normalize(IN[j].normal) * outlineWidth[j];
					IN[j].pos = UnityObjectToClipPos(IN[j].vertex.xyz);
					IN[j].outlineColor = half4(_OutlineColor.rgb, outlineWidthMask[j]);

					triStream.Append(IN[j]);
				}

				triStream.RestartStrip();
			}
		#endif
	}
#endif
