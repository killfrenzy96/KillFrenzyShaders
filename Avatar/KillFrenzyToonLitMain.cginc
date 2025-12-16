// #define KF_CUTOUT
// #define KF_TRANSPARENT
// #define KF_TEXTUREALT
// #define KF_SHADOW
// #define KF_NORMAL
// #define KF_SPECULAR
// #define KF_EMISSION
// #define KF_EMISSIONALT
// #define KF_RIMLIGHT
// #define KF_RIMSHADOW
// #define KF_OUTLINE
// #define KF_CUBEMAP
// #define KF_MATCAP
// #define KF_HSB

#include "LightVolumes.cginc"

#ifdef KF_OUTLINE
	#define KF_GEOMETRY
#endif

#ifndef KF_DEFINES
	#include "KillFrenzyToonLitDefines.cginc"
#endif

#ifdef KF_INSERT_DECLARE
	KF_INSERT_DECLARE
#endif

#ifndef KF_HELPER
	#include "KillFrenzyToonLitHelper.cginc"
#endif

#ifdef KF_INSERT_FUNCTION
	KF_INSERT_FUNCTION
#endif

v2f vert(appdata v)
{
	v2f o;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

	#ifdef KF_INSERT_VERT_START
		KF_INSERT_VERT_START
	#endif

	#ifdef KF_GEOMETRY
		o.vertex = v.vertex;
	#endif

	o.pos = UnityObjectToClipPos(v.vertex);
	o.worldPos = mul(unity_ObjectToWorld, v.vertex);
	o.worldNormal = UnityObjectToWorldNormal(v.normal);
	o.color = v.color;
	o.normal = v.normal;
	o.uv.xy = TRANSFORM_TEX(v.uv.xy, _MainTex);

	#ifdef KF_CUTOUT
		#ifdef KF_OUTLINE
			o.screenPos = ComputeScreenPos(o.pos);
		#else
			o.screenPos = ComputeScreenPos(o.pos);
		#endif
	#endif

	#ifdef LIGHTMAP_ON
		o.lightmapUv = v.uv2 * unity_LightmapST.xy + unity_LightmapST.zw;
	#endif

	#ifdef KF_OUTLINE
		half outlineWidthMask = tex2Dlod(_OutlineMask, float4(o.uv.xy, 0, 0)).r;
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

	#ifdef KF_VERTEX
		half3 viewPos = UnityObjectToViewPos(v.vertex.xyz);
		half3 viewNormal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, v.normal));

		[unroll]
		for (int k = 0; k < 4; k++) {
			half3 toLight = unity_LightPosition[k].xyz - viewPos.xyz * unity_LightPosition[k].w;
			half lengthSq = dot(toLight, toLight);

			// don't produce NaNs if some vertex position overlaps with the light
			lengthSq = max(lengthSq, 0.000001);

			toLight *= rsqrt(lengthSq);

			half atten = 1.0 / (1.0 + lengthSq * unity_LightAtten[k].z);
			if (unity_LightAtten[k].x != -1 && unity_LightAtten[k].y != 1) // if spotlight
			{
				float rho = max (0, dot(toLight, unity_SpotDirection[k].xyz));
				float spotAtt = (rho - unity_LightAtten[k].x) * unity_LightAtten[k].y;
				atten *= saturate(spotAtt);
			}
			// half diff = max (0, dot (viewNormal, toLight));
			// half3 light = unity_LightColor[k].rgb * atten;

			// o.light[k] = atten * diff;
			o.light[k] = atten;
		}
	#endif

	#ifdef KF_INSERT_VERT_END
		KF_INSERT_VERT_END
	#endif

	#ifdef SHADOW_COORDS
		UNITY_TRANSFER_SHADOW(o, o.uv.xy);
	#endif
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
	#if defined(UNITY_PASS_FORWARDBASE) || defined(KF_VERTEX)
		half3 additiveEmit = half3(0, 0, 0);
	#endif
	half3 multiply = half3(1, 1, 1);

	#ifdef KF_INSERT_FRAG_START
		KF_INSERT_FRAG_START
	#endif

	// Main colour
	half4 col = UNITY_SAMPLE_TEX2D(_MainTex, i.uv.xy) * _Color;

	// Alt colour
	#ifdef KF_TEXTUREALT
		col = lerp(col, UNITY_SAMPLE_TEX2D_SAMPLER(_AltTex, _MainTex, i.uv.xy) * _AltColor, _AltTexStrength);
	#endif

	// Vertex colour
	col.rgba *= lerp(1, i.color.rgba, _VertexColorAlbedo);

	#ifdef KF_TRANSPARENT
		col.a *= lerp(1, i.color.r, _VertexColorAlpha);
	#endif

	#ifdef KF_INSERT_FRAG_EARLY
		KF_INSERT_FRAG_EARLY
	#endif

	// Backface calculations
	#if defined(KF_NORMAL) || (defined(KF_OUTLINE) && defined(KF_CUTOUT))
		bool face = facing > 0; // True if on front face, False if on back face
		if (!face) {
			#if defined(KF_OUTLINE) && defined(KF_CUTOUT)
				// Outline
				// Using discard is very slow, only use for cutout variant (which already uses clip).
				// Allows outlines to be used with culling off.
				if (i.outlineColor.a > 0.01) {
					col.a -= 1.0;
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
		// col.a *= 1 + CalcMipLevel(i.uv.xy * _MainTex_TexelSize.zw) * 0.25;
		#ifndef KF_TRANSPARENT
			col.a = lerp(col.a, (col.a - _Cutoff) / max(fwidth(col.a), 0.0001) + 0.5, _AlphaToMaskSharpen);
		#endif

		// Strength of dither/noise (Fast sin approximation between 0 and 1)
		half alphaStrength = 4 * col.a * (1 - col.a);

		// Alpha Dither
		float2 screenUv = i.screenPos.xy / (i.screenPos.w + 0.0000000001); //0.0x1 Stops division by 0 warning in console.
		#if UNITY_SINGLE_PASS_STEREO
			screenUv *= half2(_ScreenParams.x * 2, _ScreenParams.y);
		#else
			screenUv *= _ScreenParams.xy;
		#endif
		col.a += ((alphaStrength * 0.5) - (calcDither(screenUv) * alphaStrength)) * _AlphaDither;

		// Alpha Noise
		col.a += ((alphaStrength * 0.5) - frac(frac(_Time.a * dot(i.uv.xy, float2(12.9898, 78.233))) * 43758.5453123) * alphaStrength) * _AlphaNoise;

		clip(col.a * (1 + _Cutoff * _AlphaToMaskSharpen) - _Cutoff);
		col.a = clamp(col.a, 0, 1);
	#endif

	// Normal
	#ifdef KF_NORMAL
		half3 nMap = UnpackScaleNormal(UNITY_SAMPLE_TEX2D_SAMPLER(_BumpMap, _MainTex, i.normalUV.xy), _BumpScale);
		half3 detNMap = UnpackScaleNormal(UNITY_SAMPLE_TEX2D_SAMPLER(_DetailNormalMap, _MainTex, i.normalUV.zw), _DetailNormalMapScale);
		half detailMask = UNITY_SAMPLE_TEX2D_SAMPLER(_DetailMask, _MainTex, i.uv.xy).r;

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
		half4 emissionMap = UNITY_SAMPLE_TEX2D_SAMPLER(_EmissionMap, _MainTex, i.uv.xy) * _EmissionColor;
		#ifdef KF_EMISSIONALT
			emissionMap = lerp(emissionMap, UNITY_SAMPLE_TEX2D_SAMPLER(_EmissionMapAlt, _MainTex, i.uv.xy) * _EmissionAltColor, _EmissionMapAltStrength);
		#endif
		half3 emission = emissionMap.rgb;
		emission.rgb *= emissionMap.a;
	#endif

	// Hue/Saturation/Brightness slider
	#ifdef KF_HSB
		half4 hslaMask = UNITY_SAMPLE_TEX2D(_HSLAMask, i.uv.xy);

		// col.rgb = hue(col, half4(_HSLAAdjust.x, 0.0, _HSLAAdjust.zw), hslaMask.rgb); // Main Hue/Brightness
		col.rgb = lerp(col.rgb, applyHue(col.rgb, _RainbowMainHueUVX * i.uv.x + _RainbowMainHueUVY * i.uv.y + _RainbowMainHueSpeed * _Time.y + _MainHue), hslaMask.r); // Main Hue
		col.rgb = lerp(dot(col.rgb, grayscaleVec), col.rgb, (_MainSaturation * hslaMask.g) + 1.0); // Main Saturation
		col.rgb *= 1.0 + _MainBrightness * hslaMask.b; // Main Brightness

		#ifdef KF_HSBALT
			half4 hslaMaskAlt = UNITY_SAMPLE_TEX2D_SAMPLER(_HSLAMaskAlt, _HSLAMask, i.uv.xy);

			col.rgb = lerp(col.rgb, applyHue(col.rgb, _RainbowAltHueUVX * i.uv.x + _RainbowAltHueUVY * i.uv.y + _RainbowAltHueSpeed * _Time.y + _AltHue), hslaMaskAlt.r); // Alt Hue
			col.rgb = lerp(dot(col.rgb, grayscaleVec), col.rgb, (_AltSaturation * hslaMaskAlt.g) + 1.0); // Alt Saturation
			col.rgb *= 1.0 + _AltBrightness * hslaMaskAlt.b; // Alt Brightness
		#endif

		#ifdef KF_EMISSION
			half4 hslaMaskEmission = UNITY_SAMPLE_TEX2D_SAMPLER(_HSLAMaskEmission, _HSLAMask, i.uv.xy);

			// emission = hue(emission, half4(_HSLAAdjustEmission.x, 0.0, _HSLAAdjustEmission.zw), hslaMaskEmission); // Emission Hue/Brightness
			emission = lerp(emission, applyHue(emission, _RainbowEmissionHueUVX * i.uv.x + _RainbowEmissionHueUVY * i.uv.y + _RainbowEmissionHueSpeed * _Time.y + _EmissionHue), hslaMaskEmission.r); // Emission Hue
			emission = lerp(dot(emission, grayscaleVec), emission, (_EmissionSaturation * hslaMaskEmission.g) + 1.0); // Emission Saturation
			emission *= 1.0 + _EmissionBrightness * hslaMaskEmission.b; // Emission Brightness

			#ifdef KF_HSBALT
				half4 hslaMaskEmissionAlt = UNITY_SAMPLE_TEX2D_SAMPLER(_HSLAMaskEmissionAlt, _HSLAMask, i.uv.xy);

				emission = lerp(emission, applyHue(emission, _RainbowEmissionAltHueUVX * i.uv.x + _RainbowEmissionAltHueUVY * i.uv.y + _RainbowEmissionAltHueSpeed * _Time.y + _EmissionAltHue), hslaMaskEmissionAlt.r); // Emission Hue
				emission = lerp(dot(emission, grayscaleVec), emission, (_EmissionAltSaturation * hslaMaskEmissionAlt.g) + 1.0); // Emission Saturation
				emission *= 1.0 + _EmissionAltBrightness * hslaMaskEmissionAlt.b; // Emission Brightness
			#endif
		#endif
	#endif

	#ifdef KF_INSERT_FRAG_HSB
		KF_INSERT_FRAG_HSB
	#endif

	// Emission
	#ifdef KF_EMISSION
		half lightScale = _ScaleWithLightSensitivity;
		#if defined(UNITY_PASS_FORWARDBASE) || defined(KF_VERTEX)
			additiveLit += emission * lightScale; // Emission affects lit texture
			additiveEmit += emission * (1 - lightScale); // Emission glows
		#else
			additiveLit += emission;
		#endif
		col.rgb += emission; // Emission always affects main texture
	#endif

	// Clamp base colour brightness and move it to additive lit
	half colBrightness = getBrightness(col.rgb);
	if (colBrightness > 1.0) {
		half3 extraCol = col.rgb;
		col.rgb *= 1.0 / colBrightness;
		additiveLit += extraCol - col.rgb;
	}

	// Lighting (Ambient and Colour)
	half4 vertexLightAtten = half4(0, 0, 0, 0);
	half3 L0, L1r, L1g, L1b;
	LightVolumeSH(i.worldPos, L0, L1r, L1g, L1b);

	#ifdef KF_VERTEX
		half3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
	#else
		// half3 ambient = ShadeSH9(half4(0, 0.5, 0, 1));
		// LightVolumeSH(i.worldPos, L0, L1r, L1g, L1b);
		half3 ambient = LightVolumeEvaluate(half4(0, 0.5, 0, 1), L0, L1r, L1g, L1b);

		#if defined(VERTEXLIGHT_ON)
			ambient += get4VertexLightsColFalloff(i.worldPos, i.normal, vertexLightAtten);
		#endif
	#endif

	// ambient = lerp(dot(ambient, grayscaleVec), ambient, _LightingSaturation); // Desaturate ambient light
	// ambient = min(ambient, _MaxBrightness); // Limit maximum ambient

	// Dot Products and general calculations
	LightVolumeEvaluate(i.worldNormal, L0, L1r, L1g, L1b);
	half3 lightDir = calcLightDir(i, vertexLightAtten, L0, L1r, L1g, L1b);
	half dotNdl = dot(i.worldNormal, lightDir);

	#if defined(KF_RIMLIGHT) || defined(KF_RIMSHADOW) || defined(KF_CUBEMAP) || defined(KF_MATCAP)
		half3 stereoViewDir = calcStereoViewDir(i.worldPos);
		// half dotSvdn = abs(dot(stereoViewDir, i.worldNormal));
		half dotSvdn2 = saturate(1 - abs(dot(stereoViewDir, i.worldNormal)));
	#endif

	half3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

	// Lighting (Attenuation and Shadows)
	half3 lightCol = half3(0, 0, 0);

	#ifdef KF_VERTEX
		lightCol.rgb += unity_LightColor[0] * i.light.x;
		lightCol.rgb += unity_LightColor[1] * i.light.y;
		lightCol.rgb += unity_LightColor[2] * i.light.z;
		lightCol.rgb += unity_LightColor[3] * i.light.w;

		half3 brightness = lightCol + ambient;

	#elif LIGHTMAP_ON
		calcLightCol(ambient, lightCol);

		half3 lightMap = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lightmapUv));
		lightMap = lerp(lightMap, 0.0, 1 - _ShadowStrength);
		lightMap = lightMap + (ambient * _ShadowLit);

		LightVolumeAdditiveSH(i.worldPos, L0, L1r, L1g, L1b);
		half3 lightVolume = LightVolumeEvaluate(i.worldNormal, L0, L1r, L1g, L1b);

		half3 brightness = lightCol + lightMap + lightVolume;

	#else
		calcLightCol(ambient, lightCol);

		fixed shadow = UNITY_SHADOW_ATTENUATION(i, i.worldPos.xyz);

		#ifdef POINT
			unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(i.worldPos.xyz, 1)).xyz;
			half attenuation = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).r;
			shadow = lerp(shadow, 1.0, 1 - _ShadowStrength);
		#endif

		#ifdef SPOT
			DECLARE_LIGHT_COORD(i, i.worldPos.xyz);
			half attenuation = (lightCoord.z > 0) * UnitySpotCookie(lightCoord) * UnitySpotAttenuate(lightCoord.xyz);
			shadow = lerp(shadow, 1.0, 1 - _ShadowStrength);
		#endif

		#ifdef POINT_COOKIE
			DECLARE_LIGHT_COORD(i, i.worldPos.xyz);
			half attenuation = tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).r * texCUBE(_LightTexture0, lightCoord).w;
			shadow = lerp(shadow, 1.0, 1 - _ShadowStrength);
		#endif

		#ifdef DIRECTIONAL_COOKIE
			DECLARE_LIGHT_COORD(i, i.worldPos.xyz);
			half attenuation = tex2D(_LightTexture0, lightCoord).w;
			shadow = lerp(shadow, 1.0, 1 - _ShadowStrength);
		#endif

		#ifdef DIRECTIONAL
			half attenuation = 1.0;
		#endif

		#if defined(UNITY_PASS_FORWARDBASE) && !defined(DIRECTIONAL)
			if (all(_LightColor0.rgb == 0.0)) {
				attenuation = 1.0;
			}
		#endif

		attenuation = min(attenuation, _MaxBrightness);
		half3 brightness = attenuation * lightCol + ambient;
	#endif

	// Lighting (Brightness level)
	// half3 brightness = attenuation * lightCol + ambient;
	brightness = lerp(dot(brightness, grayscaleVec), brightness, _LightingSaturation); // Desaturate light colour

	#if defined(UNITY_PASS_FORWARDBASE) || defined(KF_VERTEX)
		brightness = max(brightness, _MinBrightness); // Limit minimum brightness
	#endif
	brightness = min(brightness, _MaxBrightness); // Limit maximum brightness

	// Apply realtime shadows
	#if !defined(KF_VERTEX) && !defined(LIGHTMAP_ON)
		brightness *= lerp(shadow, 1.0, (1 - _ShadowStrength) + (ambient * _ShadowLit));
	#endif

	// Shadow Ramp
	#if defined(KF_SHADOW) && !defined(LIGHTMAP_ON)
		half3 ramp = tex2D(_Ramp, half2((dotNdl * 0.5 + 0.5), 0.5)).rgb;
		ramp = ramp * _RampStrength + (1.0 - _RampStrength);

		half ambientRamp = ambient * _RampLit;
		brightness *= (ramp * (1 - ambientRamp)) + ambientRamp;
	#endif

	#ifdef KF_INSERT_FRAG_LIGHTING
		KF_INSERT_FRAG_LIGHTING
	#endif

	// Lighting Part 3
	brightness = lerp(brightness, col.rgb * brightness * 2, _Contrast); // Contrast adjustment
	multiply *= smoothMin(brightness, _MaxBrightness);

	// Cubemap / Matcap Part 1
	#if defined(KF_CUBEMAP) || defined(KF_MATCAP)
		half4 reflectivityMask = UNITY_SAMPLE_TEX2D_SAMPLER(_ReflectivityMask, _MainTex, i.uv.xy);
	#endif

	// Cubemap
	#ifdef KF_CUBEMAP
		half roughness = (1 - _MatcapArea * reflectivityMask.b);
		roughness *= 1.7 - 0.7 * roughness;
		roughness *= UNITY_SPECCUBE_LOD_STEPS;

		half3 reflView = reflect(-viewDir, i.worldNormal);
		half4 cubeMap = texCUBElod(_BakedCubemap, half4(reflView, roughness));
		if (cubeMap.a < 0.51) cubeMap.rgb = 0;
		cubeMap.rgb *= _MatcapTint;
		cubeMap.rgb += UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflView, roughness) * _WorldReflectionTint;
		#ifndef KF_MATCAP
			cubeMap.rgb *= lerp(1, col.rgb * 2, _MatcapTintToDiffuse * reflectivityMask.g);
			cubeMap.rgb *= reflectivityMask.r;
			matCap *= lerp(1, dotSvdn2, _MatcapFresnel * reflectivityMask.a);
			additiveSoftLit += cubeMap.rgb;
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
			matCap *= lerp(1, col.rgb * 2, _MatcapTintToDiffuse * reflectivityMask.g);
			matCap *= reflectivityMask.r;
			matCap *= lerp(1, dotSvdn2, _MatcapFresnel * reflectivityMask.a);
			additiveSoftLit += matCap;
		#endif
	#endif

	// Cubemap / Matcap Part 2
	#if defined(KF_CUBEMAP) && defined(KF_MATCAP)
		matCap += cubeMap;
		matCap *= lerp(1, col.rgb * 2, _MatcapTintToDiffuse * reflectivityMask.g);
		matCap *= reflectivityMask.r;
		matCap *= lerp(1, dotSvdn2, _MatcapFresnel * reflectivityMask.a);
		additiveSoftLit += matCap;
	#endif

	// Specular
	#ifdef KF_SPECULAR
		half3 reflLight = normalize(reflect(lightDir, i.worldNormal));
		half dotRdv = saturate(dot(reflLight, half4(-viewDir, 0)));

		fixed3 specularMap = UNITY_SAMPLE_TEX2D_SAMPLER(_SpecularMap, _MainTex, i.uv.xy).rgb;
		half specularIntensity = _SpecularIntensity * specularMap.r;
		half smoothness = max(0.01, (_SpecularArea * specularMap.b));
		smoothness *= 1.7 - 0.7 * smoothness;

		// smoothness *= 128;
		// half reflectionUntouched = saturate(pow(dotRdv, smoothness));

		smoothness *= 192;
		half reflectionUntouched = min(exp2(smoothness * dotRdv - smoothness), 1.0); // Optimized estimation
		half specular = smoothstep(max(_SpecularArea - _SpecularSharpness, 0.0), min(_SpecularArea + _SpecularSharpness, 1.0), reflectionUntouched) * specularIntensity;
		additiveSoftLit += lerp(specular, col.rgb * specular, _SpecularAlbedoTint * specularMap.g); // Should specular highlight be tinted based on the albedo of the object?
	#endif

	// Rim light
	#ifdef KF_RIMLIGHT
		half rimIntensity = dotSvdn2 * max(dotNdl, 0);
		rimIntensity = smoothstep(_RimRange - _RimSharpness, _RimRange + _RimSharpness, rimIntensity);
		additiveSoftLit += rimIntensity * lerp(1.0, col.rgb, _RimAlbedoTint) * _RimIntensity * _RimColor * normalize(max(lightCol, 0.001));
	#endif

	// Rim shadow
	#ifdef KF_RIMSHADOW
		half shadowIntensity = dotSvdn2 * max(dotNdl * -1, 0);
		shadowIntensity = smoothstep(_ShadowRimRange - _ShadowRimSharpness, _ShadowRimRange + _ShadowRimSharpness, shadowIntensity);
		half3 shadowRim = lerp(1.0 - shadowIntensity, 1.0, _ShadowRim);
		multiply *= shadowRim;
	#endif

	#ifdef KF_INSERT_FRAG_MID
		KF_INSERT_FRAG_MID
	#endif

	// Combine data
	// col.rgb = lerp(col.rgb, 1.0, min(additiveSoftLit, 1.0));
	// smoothMin(additiveSoftLit, (_MaxBrightness * 0.5) / (multiply + 0.0001));
	col.rgb += additiveSoftLit;
	col.rgb *= multiply;
	col.rgb = smoothMin(col.rgb, _MaxBrightness);
	col.rgb += additiveLit * multiply; // * log2(getBrightness(additiveLit) * 4.0 + 1.0) * 0.175;
	// col.rgb *= multiply;
	// col.rgb = min(col.rgb, 1.0);
	#if defined(UNITY_PASS_FORWARDBASE) || defined(KF_VERTEX)
		col.rgb += additiveEmit;
	#endif

	// Outline colour
	#ifdef KF_OUTLINE
		col.rgb *= i.outlineColor.rgb;
	#endif

	// Transparent blending
	#if defined(KF_TRANSPARENT) && defined(UNITY_PASS_FORWARDADD)
		col.rgb *= col.a;
	#endif

	#ifdef KF_INSERT_FRAG_END
		KF_INSERT_FRAG_END
	#endif

	#if !defined(KF_CUTOUT) && !defined(KF_TRANSPARENT)
		col.a = 1;
	#endif

	// Fog
	UNITY_APPLY_FOG(i.fogCoord, col);
	return col;
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

		#ifdef KF_INSERT_GEOM_START
			KF_INSERT_GEOM_START
		#endif

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

			half fov = atan(1.0f / unity_CameraProjection._m11) * (360.0 / UNITY_PI);
		#endif

		// Main mesh
		[unroll]
		for (int k = 0; k < 3; k++)
		{
			IN[k].outlineColor = half4(1,1,1,-1);
			#ifdef KF_INSERT_GEOM_LOOP
				KF_INSERT_GEOM_LOOP
			#endif
			triStream.Append(IN[k]);
		}

		triStream.RestartStrip();

		// Outlines Part 2
		#ifdef KF_OUTLINE
			half outlineVisibility = (outlineWidth.r / cameraDistance.r) - (((1080.0 * 0.1) / _ScreenParams.y) * (fov / 60.0));
			if (
				outlineVisibility > 0.0 && // Skip if outline is too small to see
				outlineWidthMask.r + outlineWidthMask.g + outlineWidthMask.b > 0.01 // Skip if outline is masked out
			) {
				outlineVisibility = smoothstep(outlineVisibility * 100.0, 0.0, 1.0);
				outlineWidth *= min(cameraDistance * 3, 1) * .01;

				[unroll]
				for (int j = 2; j >= 0; j--) {
					IN[j].vertex.xyz += normalize(IN[j].normal) * outlineWidth[j];

					#ifdef KF_CUTOUT
						float4 pos = UnityObjectToClipPos(IN[j].vertex.xyz);
						IN[j].pos = pos;
						IN[j].screenPos = ComputeScreenPos(pos);
					#else
						IN[j].pos = UnityObjectToClipPos(IN[j].vertex.xyz);
					#endif

					IN[j].outlineColor = half4(lerp(_OutlineColor.rgb, 1.0, (1.0 - outlineVisibility) * _OutlineFade), outlineWidthMask[j]);

					#ifdef KF_INSERT_GEOM_OUTLINE_LOOP
						KF_INSERT_GEOM_OUTLINE_LOOP
					#endif
					triStream.Append(IN[j]);
				}

				triStream.RestartStrip();
			}
		#endif

		#ifdef KF_INSERT_GEOM_END
			KF_INSERT_GEOM_END
		#endif
	}
#endif
