#if UNITY_EDITOR

using UnityEditor;
using UnityEngine;
using System.Reflection;

public class KillFrenzyToonLitEditor: ShaderGUI
{

	KillFrenzyToonLitMaterialProperties properties = new KillFrenzyToonLitMaterialProperties();
	KillFrenzyToonLitFeatures featureEnabled = null;
	KillFrenzyToonLitFeatures featureShow = new KillFrenzyToonLitFeatures();

	public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
	{
		Material material = materialEditor.target as Material;
		Shader shader = material.shader;

		//Find all material properties listed in the script using reflection, and set them using a loop only if they're of type MaterialProperty.
		//This makes things a lot nicer to maintain and cleaner to look at.
		foreach (var property in properties.GetType().GetFields(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Static)) {
			try {
				property.SetValue(properties, FindProperty(property.Name, props));
			} catch {
				// Is it really a problem if it doesn't exist?
			}
		}

		featureEnabled = new KillFrenzyToonLitFeatures();

		if (shader.name.Contains("Cutout")) {
			featureEnabled.cutout = true;
		}

		if (shader.name.Contains("Transparent")) {
			featureEnabled.cutout = true;
			featureEnabled.transparent = true;
		}

		if (shader.name.Contains("Outline")) {
			featureEnabled.outline = true;
		}

		if (shader.name.Contains("Low")) {
			featureEnabled.shadow = true;
			featureEnabled.rimLight = true;
			featureEnabled.rimShadow = true;

		} else if (shader.name.Contains("Medium")) {
			featureEnabled.shadow = true;
			featureEnabled.specular = true;
			featureEnabled.emission = true;
			featureEnabled.rimLight = true;
			featureEnabled.rimShadow = true;

		} else if (shader.name.Contains("High")) {
			featureEnabled.textureAlt = true;
			featureEnabled.shadow = true;
			featureEnabled.specular = true;
			featureEnabled.emission = true;
			featureEnabled.rimLight = true;
			featureEnabled.rimShadow = true;
			featureEnabled.matCap = true;
			featureEnabled.hsb = true;

		} else if (shader.name.Contains("Full")) {
			featureEnabled.textureAlt = true;
			featureEnabled.shadow = true;
			featureEnabled.normal = true;
			featureEnabled.specular = true;
			featureEnabled.emission = true;
			featureEnabled.rimLight = true;
			featureEnabled.rimShadow = true;
			featureEnabled.cubeMap = true;
			featureEnabled.matCap = true;
			featureEnabled.hsb = true;
		}

		EditorGUI.BeginChangeCheck();

		DrawMain(materialEditor, ref featureShow.main);
		if (featureEnabled.cutout) DrawCutout(materialEditor, ref featureShow.cutout);
		if (featureEnabled.textureAlt) DrawTextureAlt(materialEditor, ref featureShow.textureAlt);
		if (featureEnabled.shadow) DrawShadow(materialEditor, ref featureShow.shadow);
		if (featureEnabled.normal) DrawNormal(materialEditor, ref featureShow.normal);
		if (featureEnabled.specular) DrawSpecular(materialEditor, ref featureShow.specular);
		if (featureEnabled.emission) DrawEmission(materialEditor, ref featureShow.emission);
		if (featureEnabled.rimLight) DrawRimLight(materialEditor, ref featureShow.rimLight);
		if (featureEnabled.rimShadow) DrawRimShadow(materialEditor, ref featureShow.rimShadow);
		if (featureEnabled.outline) DrawOutline(materialEditor, ref featureShow.outline);
		if (featureEnabled.cubeMap) {
			DrawCubeMap(materialEditor, ref featureShow.cubeMap);
		} else if (featureEnabled.matCap) {
			DrawMatCap(materialEditor, ref featureShow.matCap);
		}
		if (featureEnabled.hsb) DrawHSB(materialEditor, ref featureShow.hsb);
		DrawAdvanced(materialEditor, ref featureShow.advanced);

		DrawLabel("KillFrenzy's Avatar Toon Lit Shaders v0.9.1e");
	}

	private void DrawMain(MaterialEditor materialEditor, ref bool show) {
		ShurikenFoldout("Main", ref show);
		if (!show) return;

		materialEditor.ShaderProperty(properties._Culling, new GUIContent("Culling Mode", "Off = Draw both front and back faces. Front = Remove front faces. Back = Remove Back faces."));
		materialEditor.ShaderProperty(properties._VertexColorAlbedo, new GUIContent("Vertex Colour Tint", "Multiply colour by vertex colour data."));

		SeparatorThin();
		// materialEditor.ShaderProperty(properties._Color, new GUIContent("Color Tint", "Main texture colour tint."));
		materialEditor.TexturePropertySingleLine(new GUIContent("Main Texture", "Main Albedo texture."), properties._MainTex, properties._Color);
		materialEditor.TextureScaleOffsetProperty(properties._MainTex);

		SeparatorThin();
		materialEditor.ShaderProperty(properties._MinBrightness, new GUIContent("Minimum Brightness", "Lowest lighting brightness level allowed."));
		materialEditor.ShaderProperty(properties._MaxBrightness, new GUIContent("Maximum Brightness", "Highest lighting brightness level allowed."));
		materialEditor.ShaderProperty(properties._Contrast, new GUIContent("Contrast Adjustment", "Increases brightness difference between dark and bright colours."));
		materialEditor.ShaderProperty(properties._LightingSaturation, new GUIContent("Lighting Saturation", "Lower values will convert coloured light sources to grayscale."));

		SeparatorThin();
		materialEditor.ShaderProperty(properties._ShadowStrength, new GUIContent("Recieved Shadow Strength", "Strength of recieved realtime shadows."));
		materialEditor.ShaderProperty(properties._ShadowLit, new GUIContent("Received Shadow Ambient Tint", "How much realtime shadows is affected by ambient lighting. Low values will force realtime shadows to be rendered at full strength."));

		DrawSpace();
	}

	private void DrawTextureAlt(MaterialEditor materialEditor, ref bool show) {
		ShurikenFoldout("Alternate Texture", ref show);
		if (!show) return;

		DrawLabel("The alternate texture replaces the main texture depending on the 'Alternate Texture Strength' value.");

		SeparatorThin();
		// materialEditor.ShaderProperty(properties._AltColor, new GUIContent("Alternate Color Tint", "Alternate texture colour tint."));
		materialEditor.TexturePropertySingleLine(new GUIContent("Alternate Texture", "Alternate texture to replace the main texture."), properties._AltTex, properties._AltColor);
		materialEditor.ShaderProperty(properties._AltTexStrength, new GUIContent("Alternate Texture Strength", "1 will completely replace the main texture with the alternate texture. 0 will only use the main texture."));

		DrawSpace();
	}

	private void DrawCutout(MaterialEditor materialEditor, ref bool show) {
		ShurikenFoldout("Cutout", ref show);
		if (!show) return;

		DrawLabel("Cutout will hide parts of the model based on the alpha channel of the main texture.");

		SeparatorThin();
		materialEditor.ShaderProperty(properties._AlphaMask, new GUIContent("Alpha To Mask", "Softens the cutout with transparency when MSAA is enabled."));
		materialEditor.ShaderProperty(properties._Cutoff, new GUIContent("Cutoff", "Minimum alpha level where texture is visible."));
		materialEditor.ShaderProperty(properties._AlphaNoise, new GUIContent("Cutoff Noise", "Applies noise to the cutoff to help smoothen the cutout."));

		DrawSpace();
	}


	private void DrawShadow(MaterialEditor materialEditor, ref bool show) {
		ShurikenFoldout("Shadow Ramp", ref show);
		if (!show) return;

		DrawLabel("The shadow ramp will remap the shadow brightness level to a custom shadow ramp texture. The texture should be dark on the left, and bright on the right.");

		SeparatorThin();
		materialEditor.TexturePropertySingleLine(new GUIContent("Shadow Ramp", "Shadow brightness level ramp. Dark on left side, bright on right side."), properties._Ramp);
		materialEditor.ShaderProperty(properties._RampStrength, new GUIContent("Shadow Ramp Strength", "Stength of the shadow ramp."));
		materialEditor.ShaderProperty(properties._RampLit, new GUIContent("Shadow Ramp Ambient Tint", "How much shadow ramp is affected by ambient lighting. Low values will force the shadow ramp to be rendered at full strength."));

		DrawSpace();
	}

	private void DrawNormal(MaterialEditor materialEditor, ref bool show) {
		ShurikenFoldout("Normal Map", ref show);
		if (!show) return;

		DrawLabel("Normal maps allow you to use textures to create bumpy surfaces on the model.");

		SeparatorThin();
		materialEditor.TexturePropertySingleLine(new GUIContent("Normal Map", "Texture containing normal bump map data."), properties._BumpMap);
		materialEditor.TextureScaleOffsetProperty(properties._BumpMap);
		materialEditor.ShaderProperty(properties._BumpScale, new GUIContent("Normal Scale", "Stength of the normal map."));

		SeparatorThin();
		materialEditor.TexturePropertySingleLine(new GUIContent("Detail Normal Map", "Texture containing the detailed normal bump map data."), properties._DetailNormalMap);
		materialEditor.TextureScaleOffsetProperty(properties._DetailNormalMap);
		materialEditor.TexturePropertySingleLine(new GUIContent("Detail Mask", "Mask for the detail normal map. White = enable detail normal map. Black = disable detail normal map."), properties._DetailMask);
		materialEditor.ShaderProperty(properties._DetailNormalMapScale, new GUIContent("Detail Normal Scale", "Stength of the detailed normal map."));

		DrawSpace();
	}

	private void DrawSpecular(MaterialEditor materialEditor, ref bool show) {
		ShurikenFoldout("Specular", ref show);
		if (!show) return;

		DrawLabel("Specular creates bright highlights and make the model look shiny.");

		SeparatorThin();
		materialEditor.TexturePropertySingleLine(new GUIContent("Specular Mask", "Mask for specular. Red = Specular Intensity. Green = Specular Albedo Tint. Blue = Specular Area."), properties._SpecularMap);
		materialEditor.ShaderProperty(properties._SpecularIntensity, new GUIContent("Specular Intensity", "Stength of the specular effect."));
		materialEditor.ShaderProperty(properties._SpecularAlbedoTint, new GUIContent("Specular Albedo Tint", "How much the main texture colour affects the specular brightness."));
		materialEditor.ShaderProperty(properties._SpecularArea, new GUIContent("Specular Area", "Low values will blur the specular over a larger area. High values will focus the specular on a smaller area."));

		DrawSpace();
	}

	private void DrawEmission(MaterialEditor materialEditor, ref bool show) {
		ShurikenFoldout("Emission", ref show);
		if (!show) return;

		DrawLabel("Emission makes the model glow.");

		SeparatorThin();
		// materialEditor.ShaderProperty(properties._EmissionColor, new GUIContent("Emission Color", "Emission colour tint. Alpha also affects emission intensity."));
		materialEditor.TexturePropertySingleLine(new GUIContent("Emission Map", "Texture for emission. This will makes the model glow. Alpha will affect emission intensity."), properties._EmissionMap, properties._EmissionColor);
		materialEditor.ShaderProperty(properties._ScaleWithLightSensitivity, new GUIContent("Emission Scale with Light", "Prevents the emission from making the model glow in the dark."));

		DrawSpace();
	}

	private void DrawRimLight(MaterialEditor materialEditor, ref bool show) {
		ShurikenFoldout("Rim Light", ref show);
		if (!show) return;

		DrawLabel("Rim lighting creates bright highlights along the sides of the model.");

		SeparatorThin();
		constrainedShaderProperty(materialEditor, properties._RimColor, new GUIContent("Rimlight Tint", "Colour of the rim light."));
		materialEditor.ShaderProperty(properties._RimAlbedoTint, new GUIContent("Rimlight Albedo Tint", "How much the main texture colour affects the rim light brightness."));
		materialEditor.ShaderProperty(properties._RimIntensity, new GUIContent("Rimlight Intensity", "Brightness of the rim light."));
		materialEditor.ShaderProperty(properties._RimRange, new GUIContent("Rim Range", "High values will light up more of the model."));
		materialEditor.ShaderProperty(properties._RimSharpness, new GUIContent("Rim Sharpness", "Low values will sharpen the rim light."));

		DrawSpace();
	}

	private void DrawRimShadow(MaterialEditor materialEditor, ref bool show) {
		ShurikenFoldout("Rim Shadow", ref show);
		if (!show) return;

		DrawLabel("Rim shadows darkens along the sides of the model.");

		SeparatorThin();
		constrainedShaderProperty(materialEditor, properties._ShadowRim, new GUIContent("Shadow Rim Tint", "Colour of the rim shadow."));
		materialEditor.ShaderProperty(properties._ShadowRimRange, new GUIContent("Shadow Rim Range", "High values will darken more of the model."));
		materialEditor.ShaderProperty(properties._ShadowRimSharpness, new GUIContent("Shadow Rim Sharpness", "Low values will sharpen the rim shadow."));

		DrawSpace();
	}

	private void DrawOutline(MaterialEditor materialEditor, ref bool show) {
		ShurikenFoldout("Outline", ref show);
		if (!show) return;

		DrawLabel("Outlines create dark edges on the sides of the model. The outline colour is affected by the model's colour and lighting.");

		SeparatorThin();
		materialEditor.TexturePropertySingleLine(new GUIContent("Outline Mask", "Mask for outlines. White = Show outlines. Black = Hide outlines. Gray colours affect outline thickness."), properties._OutlineMask);
		constrainedShaderProperty(materialEditor, properties._OutlineColor, new GUIContent("Outline Color", "Colour of outline. This is affected by the model's colour and lighting."));
		materialEditor.ShaderProperty(properties._OutlineWidth, new GUIContent("Outline Width", "Thickness of outline. Higher numbers create a thicker outline."));

		DrawSpace();
	}

	private void DrawCubeMap(MaterialEditor materialEditor, ref bool show) {
		ShurikenFoldout("Reflection", ref show);
		if (!show) return;

		DrawLabel("Reflections make the model look shiny. Unlike specular, a texture is provided to give the shine some detail.");

		SeparatorThin();
		constrainedShaderProperty(materialEditor, properties._MatcapTint, new GUIContent("Reflection Tint", "Colour and intensity of the reflection."));
		materialEditor.TexturePropertySingleLine(new GUIContent("Cubemap Reflection", "Cube map texture used for reflection."), properties._BakedCubemap);
		materialEditor.TexturePropertySingleLine(new GUIContent("Matcap Reflection", "Texture used for reflection."), properties._Matcap);
		materialEditor.TexturePropertySingleLine(new GUIContent("Reflection Mask", "Mask for reflection. Red = Reflection Intensity. Green = Reflection Albedo Tint. Blue = Reflection Area."), properties._ReflectivityMask);
		materialEditor.ShaderProperty(properties._MatcapTintToDiffuse, new GUIContent("Reflection Albedo Tint", "How much the main texture colour affects the reflection brightness."));
		materialEditor.ShaderProperty(properties._MatcapArea, new GUIContent("Reflection Area", "Low values will blur the reflection. High values will focus the reflection."));

		DrawSpace();
	}

	private void DrawMatCap(MaterialEditor materialEditor, ref bool show) {
		ShurikenFoldout("Reflection", ref show);
		if (!show) return;

		DrawLabel("Reflections make the model look shiny. Unlike specular, a texture is provided to give the shine some detail.");

		SeparatorThin();
		// materialEditor.ShaderProperty(properties._MatcapTint, new GUIContent("Reflection Tint", "Colour and intensity of the matcap."));
		materialEditor.TexturePropertySingleLine(new GUIContent("Matcap Reflection", "Texture used for reflection."), properties._Matcap, properties._MatcapTint);
		materialEditor.TexturePropertySingleLine(new GUIContent("Reflection Mask", "Mask for reflection. Red = Reflection Intensity. Green = Reflection Albedo Tint. Blue = Reflection Area."), properties._ReflectivityMask);
		materialEditor.ShaderProperty(properties._MatcapTintToDiffuse, new GUIContent("Reflection Albedo Tint", "How much the main texture colour affects the reflection brightness."));
		materialEditor.ShaderProperty(properties._MatcapArea, new GUIContent("Reflection Area", "Low values will blur the reflection. High values will focus the reflection."));

		DrawSpace();
	}

	private void DrawHSB(MaterialEditor materialEditor, ref bool show) {
		ShurikenFoldout("Hue / Saturation / Brightness", ref show);
		if (!show) return;

		DrawLabel("HSB (Hue, Saturation, Brightness) will modify textures providing a way to change the texture's colour, saturation, and brightness. The mask modifies the strength of the HSB sliders.");

		SeparatorThin();
		materialEditor.TexturePropertySingleLine(new GUIContent("HSB Mask Main", "Mask for main texture HSB. Red = Hue Intensity. Green = Saturation Intensity. Blue = Brightness Intensity."), properties._HSLAMask);
		materialEditor.ShaderProperty(properties._MainHue, new GUIContent("Main Hue", "Main texture hue slider. Usually you only need values from 0 to 1."));
		materialEditor.ShaderProperty(properties._MainSaturation, new GUIContent("Main Saturation", "Main texture saturation slider. -1 will be grayscale. High values will saturate the main texture."));
		materialEditor.ShaderProperty(properties._MainBrightness, new GUIContent("Main Brightness", "Main texture brightness slider. -1 will be black. High values will brighten the main texture."));

		SeparatorThin();
		materialEditor.TexturePropertySingleLine(new GUIContent("HSB Mask Emission", "Mask for emission texture HSB. Red = Hue Intensity. Green = Saturation Intensity. Blue = Brightness Intensity."), properties._HSLAMaskEmission);
		materialEditor.ShaderProperty(properties._EmissionHue, new GUIContent("Emission Hue", "Emission texture hue slider. Usually you only need values from 0 to 1."));
		materialEditor.ShaderProperty(properties._EmissionSaturation, new GUIContent("Emission Saturation", "Emission texture saturation slider. -1 will be grayscale. High values will saturate the emission texture."));
		materialEditor.ShaderProperty(properties._EmissionBrightness, new GUIContent("Emission Brightness", "Emission texture brightness slider. -1 will be black. High values will brighten the emission texture."));

		DrawSpace();
	}

	private void DrawAdvanced(MaterialEditor materialEditor, ref bool show) {
		ShurikenFoldout("Advanced", ref show);
		if (!show) return;

		DrawLabel("Additional ShaderLab commands. If you don't know what you're doing, leave these values alone.");

		SeparatorThin();
		materialEditor.ShaderProperty(properties._Stencil, new GUIContent("Stencil ID [0-255]", "The ID of stencil to render to. This should be a whole number from 0 to 255."));
		materialEditor.ShaderProperty(properties._StencilComp, new GUIContent("Stencil Comparison", "The ID of stencil to compare to. Usually you would use 'Always' when writing the stencil, and use 'Equal' when reading the stencil. Use 'Disabled' to ignore stencil operations."));
		materialEditor.ShaderProperty(properties._StencilOp, new GUIContent("Stencil Operation", "Usually you want to use 'Replace' when writing the stencil. Use 'Keep' to avoid writing to the stencil."));

		SeparatorThin();
		materialEditor.ShaderProperty(properties._Offset, new GUIContent("Z Offset", "Depth offset, which moves vectors closer or further from the camera. Often used to avoid Z-fighting."));

		SeparatorThin();
		materialEditor.ShaderProperty(properties._ZClip, new GUIContent("Z Clip", "Setting this to False will make objects visible if they are outside a camera's near and far clip range. There will be Z ordering issues outside the clip range."));

		SeparatorThin();
		materialEditor.RenderQueueField();
		materialEditor.EnableInstancingField();
		materialEditor.DoubleSidedGIField();
	}

	private static Rect DrawShuriken(string title, Vector2 contentOffset, int HeaderHeight)
	{
		var style = new GUIStyle("ShurikenModuleTitle");
		style.font = new GUIStyle(EditorStyles.boldLabel).font;
		style.border = new RectOffset(15, 7, 4, 4);
		style.fixedHeight = HeaderHeight;
		style.contentOffset = contentOffset;
		var rect = GUILayoutUtility.GetRect(16f, HeaderHeight, style);

		GUI.Box(rect, title, style);
		return rect;
	}

	private static void ShurikenFoldout(string title, ref bool display)
	{
		var rect = DrawShuriken(title, new Vector2(20f, -2f), 22);
		var e = Event.current;
		var toggleRect = new Rect(rect.x + 4f, rect.y + 2f, 13f, 13f);
		if (e.type == EventType.Repaint)
		{
			EditorStyles.foldout.Draw(toggleRect, false, false, display, false);
		}
		if (e.type == EventType.MouseDown && rect.Contains(e.mousePosition))
		{
			display = !display;
			e.Use();
		}
	}

	public static void DrawLabel(string title)
	{
		var style = new GUIStyle("Label");
		style.font = new GUIStyle(EditorStyles.boldLabel).font;
		style.border = new RectOffset(15, 7, 4, 4);
		style.wordWrap = true;

		// style.fixedHeight = HeaderHeight;
		// style.contentOffset = new Vector2(20f, -2f);
		GUIContent content = new GUIContent(title);
		var rect = GUILayoutUtility.GetRect(16f, 44, style);

		// GUI.Box(rect, title, style);
		GUI.Label(rect, content, style);
	}

	public static void DrawSpace()
	{
		var style = new GUIStyle("Label");
		var rect = GUILayoutUtility.GetRect(16f, 11);
		GUI.Box(rect, "", style);
	}

	public static void constrainedShaderProperty(MaterialEditor materialEditor, MaterialProperty prop, GUIContent style, int tabSize = 0)
	{
		EditorGUILayout.BeginHorizontal(GUILayout.MaxWidth(30));
			materialEditor.ShaderProperty(prop, style, tabSize);
		EditorGUILayout.EndHorizontal();
	}

	static public void GUILine(Color color, float height = 2f)
	{
		Rect position = GUILayoutUtility.GetRect(0f, float.MaxValue, height, height, LineStyle);

		if (Event.current.type == EventType.Repaint)
		{
			Color orgColor = GUI.color;
			GUI.color = orgColor * color;
			LineStyle.Draw(position, false, false, false, false);
			GUI.color = orgColor;
		}
	}
	static public void SeparatorThin()
	{
		GUILayout.Space(2);
		GUILine(new Color(.1f, .1f, .1f), 1f);
		GUILine(new Color(.3f, .3f, .3f), 1f);
		GUILayout.Space(2);
	}

	static public GUIStyle _LineStyle;
	static public GUIStyle LineStyle
	{
		get
		{
			if (_LineStyle == null)
			{
				_LineStyle = new GUIStyle();
				_LineStyle.normal.background = EditorGUIUtility.whiteTexture;
				_LineStyle.stretchWidth = true;
			}

			return _LineStyle;
		}
	}
}


public class KillFrenzyToonLitFeatures
{
	public bool main = true;
	public bool cutout = false;
	public bool transparent = false;
	public bool textureAlt = false;
	public bool shadow = false;
	public bool normal = false;
	public bool specular = false;
	public bool emission = false;
	public bool rimLight = false;
	public bool rimShadow = false;
	public bool outline = false;
	public bool cubeMap = false;
	public bool matCap = false;
	public bool hsb = false;
	public bool advanced = false;
}

public class KillFrenzyToonLitMaterialProperties
{
	public MaterialProperty _Culling = null;
	public MaterialProperty _VertexColorAlbedo = null;

	public MaterialProperty _Color = null;
	public MaterialProperty _MainTex = null;

	public MaterialProperty _AltColor = null;
	public MaterialProperty _AltTex = null;
	public MaterialProperty _AltTexStrength = null;

	public MaterialProperty _MinBrightness = null;
	public MaterialProperty _MaxBrightness = null;
	public MaterialProperty _Contrast = null;
	public MaterialProperty _LightingSaturation = null;
	public MaterialProperty _ShadowStrength = null;
	public MaterialProperty _ShadowLit = null;

	public MaterialProperty _AlphaMask = null;
	public MaterialProperty _Cutoff = null;
	public MaterialProperty _AlphaNoise = null;

	public MaterialProperty _Ramp = null;
	public MaterialProperty _RampStrength = null;
	public MaterialProperty _RampLit = null;

	public MaterialProperty _BumpMap = null;
	public MaterialProperty _BumpScale = null;
	public MaterialProperty _DetailNormalMap = null;
	public MaterialProperty _DetailMask = null;
	public MaterialProperty _DetailNormalMapScale = null;

	public MaterialProperty _SpecularMap = null;
	public MaterialProperty _SpecularAlbedoTint = null;
	public MaterialProperty _SpecularIntensity = null;
	public MaterialProperty _SpecularArea = null;

	public MaterialProperty _EmissionColor = null;
	public MaterialProperty _EmissionMap = null;
	public MaterialProperty _ScaleWithLightSensitivity = null;

	public MaterialProperty _RimColor = null;
	public MaterialProperty _RimAlbedoTint = null;
	public MaterialProperty _RimIntensity = null;
	public MaterialProperty _RimRange = null;
	public MaterialProperty _RimSharpness = null;

	public MaterialProperty _ShadowRim = null;
	public MaterialProperty _ShadowRimRange = null;
	public MaterialProperty _ShadowRimSharpness = null;

	public MaterialProperty _OutlineColor = null;
	public MaterialProperty _OutlineMask = null;
	public MaterialProperty _OutlineWidth = null;

	public MaterialProperty _MatcapTint = null;
	public MaterialProperty _BakedCubemap = null;
	public MaterialProperty _Matcap = null;
	public MaterialProperty _MatcapTintToDiffuse = null;
	public MaterialProperty _ReflectivityMask = null;
	public MaterialProperty _MatcapArea = null;

	public MaterialProperty _HSLAMask = null;
	public MaterialProperty _MainHue = null;
	public MaterialProperty _MainSaturation = null;
	public MaterialProperty _MainBrightness = null;
	public MaterialProperty _HSLAMaskEmission = null;
	public MaterialProperty _EmissionHue = null;
	public MaterialProperty _EmissionSaturation = null;
	public MaterialProperty _EmissionBrightness = null;

	public MaterialProperty _Stencil = null;
	public MaterialProperty _StencilComp = null;
	public MaterialProperty _StencilOp = null;
	public MaterialProperty _Offset = null;
	public MaterialProperty _ZClip = null;
}

#endif