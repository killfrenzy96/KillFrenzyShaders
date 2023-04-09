
// #define grayscaleVec half3(0.2125, 0.7154, 0.0721)
#define grayscaleVec half3(0.2125, 0.7154, 0.2125)

half3 getVertexLightsDir(v2f i, half4 vertexLightAtten)
{
	half3 toLightX = half3(unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x);
	half3 toLightY = half3(unity_4LightPosX0.y, unity_4LightPosY0.y, unity_4LightPosZ0.y);
	half3 toLightZ = half3(unity_4LightPosX0.z, unity_4LightPosY0.z, unity_4LightPosZ0.z);
	half3 toLightW = half3(unity_4LightPosX0.w, unity_4LightPosY0.w, unity_4LightPosZ0.w);

	half3 dirX = toLightX - i.worldPos;
	half3 dirY = toLightY - i.worldPos;
	half3 dirZ = toLightZ - i.worldPos;
	half3 dirW = toLightW - i.worldPos;

	dirX *= length(toLightX) * vertexLightAtten.x * unity_LightColor[0];
	dirY *= length(toLightY) * vertexLightAtten.y * unity_LightColor[1];
	dirZ *= length(toLightZ) * vertexLightAtten.z * unity_LightColor[2];
	dirW *= length(toLightW) * vertexLightAtten.w * unity_LightColor[3];

	half3 dir = (dirX + dirY + dirZ + dirW) / 4;
	return dir;
}

// Get the most intense light Dir from probes OR from a light source. Method developed by Xiexe / Merlin
half3 calcLightDir(v2f i, half4 vertexLightAtten)
{
	half3 lightDir = UnityWorldSpaceLightDir(i.worldPos);

	half3 probeLightDir = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz;
	lightDir = (lightDir + probeLightDir); //Make light dir the average of the probe direction and the light source direction.

	#if defined(VERTEXLIGHT_ON)
		half3 vertexDir = getVertexLightsDir(i, vertexLightAtten);
		lightDir = (lightDir + probeLightDir + vertexDir);
	#endif

	#if !defined(POINT) && !defined(SPOT) && !defined(VERTEXLIGHT_ON) // if the average length of the light probes is null, and we don't have a directional light in the scene, fall back to our fallback lightDir
		if(length(unity_SHAr.xyz*unity_SHAr.w + unity_SHAg.xyz*unity_SHAg.w + unity_SHAb.xyz*unity_SHAb.w) == 0 && length(lightDir) < 0.1)
		{
			lightDir = half4(1, 1, 1, 0);
		}
		// half lightLength = length(unity_SHAr.xyz * unity_SHAr.w + unity_SHAg.xyz * unity_SHAg.w + unity_SHAb.xyz * unity_SHAb.w) + length(lightDir);
		// lightDir = lerp(half4(1, 1, 1, 0), lightDir, lightLength);
	#endif

	return normalize(lightDir);
}

// Helper Functions
half3 get4VertexLightsColFalloff(half3 worldPos, half3 normal, inout half4 vertexLightAtten)
{
	half3 lightColor = 0;

	#if defined(VERTEXLIGHT_ON)
	half4 toLightX = unity_4LightPosX0 - worldPos.x;
	half4 toLightY = unity_4LightPosY0 - worldPos.y;
	half4 toLightZ = unity_4LightPosZ0 - worldPos.z;

	half4 lengthSq = 0;
	lengthSq += toLightX * toLightX;
	lengthSq += toLightY * toLightY;
	lengthSq += toLightZ * toLightZ;

	float4 atten = 1.0 / (1.0 + lengthSq * unity_4LightAtten0);
	float4 atten2 = saturate(1 - (lengthSq * unity_4LightAtten0 / 25));
	atten = min(atten, atten2 * atten2);

	// Cleaner, nicer looking falloff. Also prevents the "Snapping in" effect that Unity's normal integration of vertex lights has.
	vertexLightAtten = atten;

	// This is lerping between a white color and the actual color of the light based on the falloff, that way with our lighting model
	// we don't end up with *very* red/green/blue lights. This is a stylistic choice and can be removed for other lighting models.
	// without it, it would just be "lightColor.rgb = unity_Lightcolor[i] * atten.x/y/z/w;"
	// half gs0 = dot(unity_LightColor[0], grayscaleVec);
	// half gs1 = dot(unity_LightColor[1], grayscaleVec);
	// half gs2 = dot(unity_LightColor[2], grayscaleVec);
	// half gs3 = dot(unity_LightColor[3], grayscaleVec);

	lightColor.rgb += unity_LightColor[0] * atten.x;
	lightColor.rgb += unity_LightColor[1] * atten.y;
	lightColor.rgb += unity_LightColor[2] * atten.z;
	lightColor.rgb += unity_LightColor[3] * atten.w;
	#endif

	return lightColor;
}

half3 calcStereoViewDir(half3 worldPos)
{
	#if UNITY_SINGLE_PASS_STEREO
		half3 cameraPos = half3((unity_StereoWorldSpaceCameraPos[0]+ unity_StereoWorldSpaceCameraPos[1])*.5);
	#else
		half3 cameraPos = _WorldSpaceCameraPos;
	#endif
	half3 viewDir = cameraPos - worldPos;
	return normalize(viewDir);
}

void calcLightCol(inout half3 indirectDiffuse, inout half3 lightColor)
{
	//If we're in an environment with a realtime light, then we should use the light color, and indirect color raw.
	bool lightEnv = any(_WorldSpaceLightPos0.xyz);
	if(lightEnv) {
		lightColor = _LightColor0.rgb;
		lightColor = lerp(dot(lightColor, grayscaleVec), lightColor, _LightingSaturation); // Desaturate light colour
		// indirectDiffuse = indirectDiffuse;
	} else {
		// ...Otherwise
		// Keep overall light to 100% - these should never go over 100%
		// ex. If we have indirect 100% as the light color and Indirect 50% as the indirect color,
		// we end up with 150% of the light from the scene.
		lightColor = indirectDiffuse * 0.6;
		indirectDiffuse = indirectDiffuse * 0.4;
	}
}

/*half3 rgb2hsv(half3 c)
{
	half4 K = half4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	half4 p = lerp(half4(c.bg, K.wz), half4(c.gb, K.xy), step(c.b, c.g));
	half4 q = lerp(half4(p.xyw, c.r), half4(c.r, p.yzx), step(p.x, c.r));

	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return half3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

half3 hsv2rgb(half3 c, half3 hsvb, half3 mask)
{
	c = half3(c.x, c.y, max(c.z + (hsvb.z * mask.z), 0.0));
	half4 K = half4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	half3 p = lerp(abs(frac(c.xxx + K.xyz) * 6.0 - K.www), abs(frac((c.xxx + hsvb.xxx) + K.xyz) * 6.0 - K.www), mask.x);
	return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

half3 hue(half3 color, half4 hsvb, half3 mask)
{
	half3 hsv = rgb2hsv(color.rgb);
	half3 rgb = hsv2rgb(hsv, hsvb.xyz, mask.xyz);
	return rgb * (hsvb.w * mask.z + 1.0);
}*/

half3 applyHue(half3 aColor, half aHue)
{
	half angle = aHue * (3.1415926535 * 2);
	half3 k = half3(0.57735, 0.57735, 0.57735);
	half sinAngle = sin(angle);
	half cosAngle = cos(angle);
	// Rodrigues' rotation formula
	return aColor * cosAngle + cross(k, aColor) * sinAngle + k * dot(k, aColor) * (1 - cosAngle);
}

half getBrightness(half3 col)
{
	// return (col.r + col.g + col.b) / 3;
	return max(max(col.r, col.g), col.b);
}

half remap(half a, half b, half x) {
	return x * (1.0 / (b - a)) - (a / (b - a));
}

/*half smoothMin(half brightness, half maxValue)
{
	if (brightness <= maxValue) {
		return brightness;
	} else {
		half mapped = brightness * maxValue / brightness;
		mapped = lerp(mapped, maxValue, min(log10((brightness - maxValue) * 2.0 + 1.0), 1.0));
		return mapped;
	}
	// return min(brightness, maxValue);
}*/

half3 smoothMin(half3 col, half maxValue)
{
	half brightness = getBrightness(col);
	if (brightness <= maxValue) {
		return col;
	} else {
		half3 mapped = col * maxValue / brightness;
		half multiplier = min(log2((brightness - maxValue) * 4.0 + 1.0) * 0.175, 1.0);
		// mapped = lerp(mapped, maxValue, multiplier);
		mapped *= 1.0 + multiplier;
		return mapped;
	}
	// return min(col, maxValue);
}

float CalcMipLevel(float2 texture_coord)
{
	float2 dx = ddx(texture_coord);
	float2 dy = ddy(texture_coord);
	float delta_max_sqr = max(dot(dx, dx), dot(dy, dy));

	return max(0.0, 0.5 * log2(delta_max_sqr));
}
