// MIT License

// Copyright (c) 2020 NedMakesGames

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

Shader "Grass/GrassLayers" 
{
    Properties 
    {
        _BaseColor("Base color", Color) = (0, 0.5, 0, 1) // Color of the lowest layer
        _TopColor("Top color", Color) = (0, 1, 0, 1) // Color of the highest layer
        //_TotalHeight("Grass height", Float) = 1 // Height of the highest layer
        _DetailNoiseTexture("Grainy noise", 2D) = "white" {} // Texture A used to clip layers
        _DetailDepthScale("Grainy depth scale", Range(0, 1)) = 1 // The influence of Texture A
        _SmoothNoiseTexture("Smooth noise", 2D) = "white" {} // Texture B used to clip layers
        _SmoothDepthScale("Smooth depth scale", Range(0, 1)) = 1 // The influence of Texture B
        _WindNoiseTexture("Wind noise texture", 2D) = "white" {} // A wind noise texture
        _WindTimeMult("Wind frequency", Float) = 1 // Wind noise offset by time
        _WindAmplitude("Wind strength", Float) = 1 // The largest UV offset of wind
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
            Cull Back

            HLSLPROGRAM
                // Signal this shader requires geometry function support
                #pragma prefer_hlslcc gles
                #pragma exclude_renderers d3d11_9x
                #pragma target 5.0
                //#pragma require geometry

                // Lighting and shadow keywords
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
                #pragma multi_compile _ _ADDITIONAL_LIGHTS
                #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
                #pragma multi_compile _ _SHADOWS_SOFT

                // Register our functions
                #pragma vertex Vertex
                //#pragma geometry Geometry
                #pragma fragment Fragment

                // Incude our logic file
                #include "GrassLayer.hlsl"    

            ENDHLSL
        }

        Pass 
        {

            Name "ShadowCaster"
            Tags {"LightMode" = "ShadowCaster"}

            HLSLPROGRAM
                // Signal this shader requires geometry function support
                #pragma prefer_hlslcc gles
                #pragma exclude_renderers d3d11_9x
                #pragma target 5.0
                //#pragma require geometry

                // Support all the various light types and shadow paths
                #pragma multi_compile_shadowcaster

                // Register our functions
                #pragma vertex Vertex
                //#pragma geometry Geometry
                #pragma fragment Fragment

                // A custom keyword to modify logic during the shadow caster pass
                #define SHADOW_CASTER_PASS
                // Incude our logic file
                #include "GrassLayer.hlsl"

            ENDHLSL
        }
    }
}