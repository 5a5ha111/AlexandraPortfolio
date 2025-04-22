// MIT License

// Copyright (c) 2021 NedMakesGames

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

Shader "Grass/BladeGrass" 
{
    Properties
    {
        _BaseColor("Base color", Color) = (0, 0.5, 0, 1) // Color of the lowest layer
        _TipColor("Tip color", Color) = (0, 1, 0, 1) // Color of the highest layer
        _RandomJitterRadius("Random jitter radius", Float) = 0.1
        _WindTexture("Wind texture", 2D) = "white" {}
        _WindFrequency("Wind frequency", Float) = 1
        _WindAmplitude("Wind strength", Float) = 1
        _ShadowLightness("_ShadowLightness", Range(0,1)) = 0
    }

    SubShader
    {
        // UniversalPipeline needed to have this render in URP
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}

        // Forward Lit Pass
        Pass 
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            ZWrite On ZTest LEqual

            HLSLPROGRAM
            // Signal this shader requires a compute buffer
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            // Lighting and shadow keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT

            #if UNITY_VERSION >= 202120
                #pragma multi_compile_fragment _ DEBUG_DISPLAY
            #endif
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            // Register our functions
            #pragma vertex Vertex
            #pragma fragment Fragment

            // Incude our logic file
            #include "BladeGrass.hlsl"    

            ENDHLSL
        }

        // Forward Lit Pass
        Pass 
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            HLSLPROGRAM
                // Signal this shader requires a compute buffer
                #pragma prefer_hlslcc gles
                #pragma exclude_renderers d3d11_9x

                // GPU Instancing
                #pragma multi_compile_instancing
                #pragma multi_compile _ DOTS_INSTANCING_ON

                #define SHADOW_CASTER_PASS

                // Register our functions
                /*#pragma vertex Vertex
                #pragma fragment Fragment*/
                #pragma vertex ShadowPassVertex
                #pragma fragment ShadowPassFragment

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

                // Incude our logic file
                /*#include "BladeGrass.hlsl"*/

                float4 _BaseMap_ST;
                float4 _BaseColor;
                float _Cutoff;

                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

            ENDHLSL
        }

        // DepthOnly, used for Camera Depth Texture (if cannot copy depth buffer instead, and the DepthNormals below isn't used)
        /*Pass 
        {
            Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }

            ColorMask 0
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
                #pragma vertex DepthOnlyVertex
                #pragma fragment DepthOnlyFragment

                // Material Keywords
                #pragma shader_feature_local_fragment _ALPHATEST_ON
                #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

                // GPU Instancing
                #pragma multi_compile_instancing
                //#pragma multi_compile _ DOTS_INSTANCING_ON

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

                float4 _BaseMap_ST;
                float4 _BaseColor;
                float _Cutoff;

                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"

            
            ENDHLSL
        }*/


    }
}