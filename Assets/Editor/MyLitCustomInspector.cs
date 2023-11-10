using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;

public class MyLitCustomInspector : ShaderGUI
{
    private enum SurfaceType
    {
        Opaque, TransparentBlendAlpha, TransparentCutout
    }

    private enum FaceRenderingMode
    {
        FrontOnly, NoCuling, DoubleSided
    }

    private const string _SurfaceType = "_SurfaceType";
    private const string _RenderType = "RenderType";
    
    private const string _Opaque = "Opaque";
    private const string _Transparent = "Transparent";
    private const string _TransparentCutout = "TransparentCutout";

    private const string _SourceBlend = "_SourceBlend";
    private const string _DestBlend = "_DestBlend";
    private const string _ZWrite = "_ZWrite";
    private const string _ShadowCaster = "ShadowCaster";

    public override void AssignNewShaderToMaterial(Material material, Shader oldShader, Shader newShader)
    {
        base.AssignNewShaderToMaterial(material, oldShader, newShader);
        if (newShader.name == "SashaMakesGames/MyLit")
        {
            UpdateSurfaceType(material);
        }
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        Material material = materialEditor.target as Material;

        var surfaceProp = BaseShaderGUI.FindProperty(_SurfaceType, properties, propertyIsMandatory: true);
        var faceProp = BaseShaderGUI.FindProperty("_FaceRenderingMode", properties, propertyIsMandatory: true);

        EditorGUI.BeginChangeCheck();
        surfaceProp.floatValue = (int)(SurfaceType)EditorGUILayout.EnumPopup("Surface type", (SurfaceType)surfaceProp.floatValue);
        faceProp.floatValue = (int)(FaceRenderingMode)EditorGUILayout.EnumPopup("Face rendering mode", (FaceRenderingMode)faceProp.floatValue);
        if (EditorGUI.EndChangeCheck())
        {
            UpdateSurfaceType(material);
        }

        base.OnGUI(materialEditor, properties);
    }

    private void UpdateSurfaceType(Material material)
    {
        SurfaceType surfaceType = (SurfaceType)material.GetFloat(_SurfaceType);
        switch (surfaceType)
        {
            case SurfaceType.Opaque:
                material.renderQueue = (int)RenderQueue.Geometry;
                material.SetOverrideTag(_RenderType, _Opaque);
                material.SetInt(_SourceBlend, (int)BlendMode.One);
                material.SetInt(_DestBlend, (int)BlendMode.Zero);
                material.SetInt(_ZWrite, 1);
                break;
            case SurfaceType.TransparentBlendAlpha:
                material.renderQueue = (int)RenderQueue.Transparent;
                material.SetOverrideTag(_RenderType, _TransparentCutout);
                material.SetInt(_SourceBlend, (int)BlendMode.SrcAlpha);
                material.SetInt(_DestBlend, (int)BlendMode.OneMinusSrcAlpha);
                material.SetInt(_ZWrite, 0);
                break;
            case SurfaceType.TransparentCutout:
                material.renderQueue = (int)RenderQueue.AlphaTest;
                material.SetOverrideTag(_RenderType, _Transparent);
                material.SetInt(_SourceBlend, (int)BlendMode.One);
                material.SetInt(_DestBlend, (int)BlendMode.Zero);
                material.SetInt(_ZWrite, 1);
                break;
        }

        material.SetShaderPassEnabled(_ShadowCaster, surfaceType != SurfaceType.TransparentBlendAlpha);

        if (surfaceType == SurfaceType.TransparentCutout)
        {
            material.EnableKeyword("_ALPHA_CUTOUT");
        }
        else
        {
            material.DisableKeyword("_ALPHA_CUTOUT");
        }

        FaceRenderingMode faceRenderingMode = (FaceRenderingMode)material.GetFloat("_FaceRenderingMode");
        if (faceRenderingMode == FaceRenderingMode.FrontOnly)
        {
            material.SetFloat("_Cull", (float)UnityEngine.Rendering.CullMode.Back);
        }
        else
        {
            material.SetFloat("_Cull", (float)UnityEngine.Rendering.CullMode.Off);
        }

        if (faceRenderingMode == FaceRenderingMode.DoubleSided)
        {
            material.EnableKeyword("_DOUBLE_SIDED_NORMALS");
        }
        else
        {
            material.DisableKeyword("_DOUBLE_SIDED_NORMALS");
        }

    }
}
