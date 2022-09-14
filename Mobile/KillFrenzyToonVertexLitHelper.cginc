
half3 getVertexLightsDir(float3 worldPos, half4 vertexLightAtten)
{
	half3 toLightX = half3(unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x);
	half3 toLightY = half3(unity_4LightPosX0.y, unity_4LightPosY0.y, unity_4LightPosZ0.y);
	half3 toLightZ = half3(unity_4LightPosX0.z, unity_4LightPosY0.z, unity_4LightPosZ0.z);
	half3 toLightW = half3(unity_4LightPosX0.w, unity_4LightPosY0.w, unity_4LightPosZ0.w);

	half3 dirX = toLightX - worldPos;
	half3 dirY = toLightY - worldPos;
	half3 dirZ = toLightZ - worldPos;
	half3 dirW = toLightW - worldPos;

	dirX *= length(toLightX) * vertexLightAtten.x * unity_LightColor[0];
	dirY *= length(toLightY) * vertexLightAtten.y * unity_LightColor[1];
	dirZ *= length(toLightZ) * vertexLightAtten.z * unity_LightColor[2];
	dirW *= length(toLightW) * vertexLightAtten.w * unity_LightColor[3];

	half3 dir = (dirX + dirY + dirZ + dirW) / 4;
	return dir;
}

// Get the most intense light Dir from probes OR from a light source. Method developed by Xiexe / Merlin
half3 calcLightDir(float3 worldPos, half4 vertexLightAtten)
{
	half3 lightDir = UnityWorldSpaceLightDir(worldPos);

	half3 probeLightDir = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz;
	lightDir = (lightDir + probeLightDir); //Make light dir the average of the probe direction and the light source direction.

	#if defined(VERTEXLIGHT_ON)
		half3 vertexDir = getVertexLightsDir(worldPos, vertexLightAtten);
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
