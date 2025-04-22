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

// Make sure this file is not included twice
#ifndef GRASSBLADES_INCLUDED
#define GRASSBLADES_INCLUDED

// Include some helper functions
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "NMGBladeGrassGraphicsHelpers.hlsl"

struct Attributes 
{
    float3 positionOS           : POSITION;
    float3 normalOS             : NORMAL;
    float2 uv                   : TEXCOORD0;
    float3 bladeAnchorOS        : TEXCOORD1;
    float3 shadowCastNormalOS   : TEXCOORD2;
    float2 lightmapUV   : TEXCOORD3;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertexOutput 
{
    float2 uv           : TEXCOORD0; // The height of this vertex on the grass blade
    float3 positionWS   : TEXCOORD1; // Position in world space
    float3 normalWS     : TEXCOORD2; // Normal vector in world space
    float3 shadowCastNormalOS : TEXCOORD3;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 4);

    float4 positionCS   : SV_POSITION; // Position in clip space
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

// Properties
float4 _BaseColor;
float4 _TipColor;
float _RandomJitterRadius;
float _ShadowLightness;

TEXTURE2D(_WindTexture); SAMPLER(sampler_WindTexture); float4 _WindTexture_ST;
float _WindFrequency;
float _WindAmplitude;

// Vertex functions

VertexOutput Vertex(Attributes input) 
{
    // Initialize the output struct
    VertexOutput output = (VertexOutput)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);



    float3 bladeAnchorWS = GetVertexPositionInputs(input.bladeAnchorOS).positionWS;
    // Get a plane perpendicular to the normal
    float3 normalWS = GetVertexNormalInputs(input.normalOS).normalWS;
    float3 tangentWS, bitangentWS;
    GetPerpendicularPlane(normalWS, tangentWS, bitangentWS);
    // Calculate a random jitter amount based on world space position. Use the blade anchor so the entire blade
    // has the same jitter offset
    float3 randomOffset = tangentWS * randNegative1to1(input.bladeAnchorOS, 0) + bitangentWS * randNegative1to1(input.bladeAnchorOS, 1);
    randomOffset *= _RandomJitterRadius;
    bladeAnchorWS += randomOffset; // Apply jitter to the anchor for wind

    // Calculate the wind axis, which also encodes the wind strength
    // The windUV is affected by the world position and time. TRANSFORM_TEX applies _WindTexture_ST values
    float2 windUV = TRANSFORM_TEX(bladeAnchorWS.xz, _WindTexture) + _Time.y * _WindFrequency;
    // Sample the wind noise texture and remap it to range between -1 and 1
    float2 windNoise = SAMPLE_TEXTURE2D_LOD(_WindTexture, sampler_WindTexture, windUV, 0).xy * 2 - 1;
    // Offset blade points in a vector perpendular to it's normal, but also consistent
    // across blades.
    float3 windOffset = cross(normalWS, float3(windNoise.x, 0, windNoise.y));
    // Then scale by the amplitude and UV.y, so points near the base of the blade are blown less
    windOffset *= _WindAmplitude * input.uv.y;

    float3 positionWS = GetVertexPositionInputs(input.positionOS).positionWS + randomOffset + windOffset;
    output.positionWS = positionWS;
    output.normalWS = normalWS;
    output.uv = input.uv;
    output.positionCS = CalculatePositionCSWithShadowCasterLogic(positionWS, GetVertexNormalInputs(input.shadowCastNormalOS).normalWS);

    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
    //float3x3 tangentTransform_World = float3x3(IN.WorldSpaceTangent, IN.WorldSpaceBiTangent, IN.WorldSpaceNormal);
    //float3 _Transform_Out = TransformWorldToTangent(TransformObjectToWorld(In), tangentTransform_World);

    //output.shadowCastNormalOS = TransformWorldToTangent(TransformObjectToWorld(input.shadowCastNormalOS));
    output.shadowCastNormalOS = input.shadowCastNormalOS;

    return output;
}

// Fragment functions

half4 Fragment(VertexOutput input) : SV_Target 
{
    UNITY_SETUP_INSTANCE_ID(input);
    float colorLerp = input.uv.y;
    float3 albedo = lerp(_BaseColor.rgb, _TipColor.rgb, colorLerp);

    #ifdef SHADOW_CASTER_PASS
        return 0;
    #else
        // Gather some data for the lighting algorithm
        InputData lightingInput = (InputData)0;
        lightingInput.positionWS = input.positionWS;
        lightingInput.normalWS = TransformObjectToWorldNormal(input.shadowCastNormalOS); // No need to normalize, triangles share a normal
        //lightingInput.normalWS = input.normalWS; // No need to normalize, triangles share a normal
        lightingInput.viewDirectionWS = GetViewDirectionFromPosition(input.positionWS); // Calculate the view direction
        lightingInput.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
        lightingInput.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
        lightingInput.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, lightingInput.normalWS);
        lightingInput.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(TransformWorldToHClip(input.positionWS));
        //lightingInput.positionCS = TransformWorldToHClip(input.positionWS);

        

        float4 shadowCoord = lightingInput.shadowCoord;
        #if _MAIN_LIGHT_SHADOWS_CASCADE || _MAIN_LIGHT_SHADOWS
            Light mainLight = GetMainLight(shadowCoord);
        #else
            Light mainLight = GetMainLight();
        #endif
        float shadow = mainLight.shadowAttenuation;
        float3 extraLights;
        int pixelLightCount = GetAdditionalLightsCount();
        for (int j = 0; j < pixelLightCount; ++j) 
        {
            Light light = GetAdditionalLight(j, input.positionWS, half4(1, 1, 1, 1));
            float3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
            extraLights += attenuatedLightColor;
        }

        float4 litColor = float4((albedo * mainLight.color),1);
                 
        litColor += float4(extraLights,1);
        // multiply with vertex color, and shadows
        float4 final = litColor * shadow;
        // add in basecolor when lights turned down
        final += float4(saturate((1 - shadow) * albedo * 0.2), 1);
        // fog
        //float fogFactor = i.fogFactor;
     
        // Mix the pixel color with fogColor. 
        //final.rgb = MixFog(final.rgb, fogFactor);
        // add in ambient color
        final += (unity_AmbientSky * /*_AmbientStrength*/ 0.5f);
        /*return final;*/

        //Light mainLight = GetMainLight(shadowCoord);
        half3 attenuatedLightColor = mainLight.color * (mainLight.distanceAttenuation * mainLight.shadowAttenuation);
        half3 bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, lightingInput.normalWS);
        MixRealtimeAndBakedGI(mainLight, lightingInput.normalWS, bakedGI);
        half3 shading = bakedGI + LightingLambert(attenuatedLightColor, mainLight.direction, lightingInput.normalWS);

        //return half4(final.rgb * shading, 1);

        // Lerp between the base and tip color based on the blade height
        //float colorLerp = input.uv.y;
        //float3 albedo = lerp(_BaseColor.rgb, _TipColor.rgb, colorLerp);

        // The URP simple lit algorithm
        // The arguments are lighting input data, albedo color, specular color, smoothness, emission color, and alpha
        /*return UniversalFragmentBlinnPhong(lightingInput, albedo * (1 - _ShadowLightness), 1, 0, albedo * _ShadowLightness, 1);*/
        SurfaceData surface = (SurfaceData)0; // Found in URP/SurfaceData.hlsl
        surface.albedo = final * shading /*shadow*/ /*GetMainLightShadowStrength()*/;
        surface.alpha = 1;
        surface.metallic = 0;
        //surface.normalTS = input.shadowCastNormalOS /*float3(0, 1, 0)*/;
        surface.smoothness = 0.0f;
        surface.specular = 1;
        surface.occlusion = 1;
        return UniversalFragmentPBR(lightingInput, surface);
    #endif
}

#endif