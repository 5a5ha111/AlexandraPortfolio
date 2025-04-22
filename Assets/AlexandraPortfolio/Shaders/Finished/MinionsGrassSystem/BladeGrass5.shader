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

Shader "Grass/BladeGrass5" 
{
    Properties
    {
        [ToggleUI]_Blend("Blend", Float) = 0
        _TopTint("TopTint", Color) = (0.130696, 0.8396226, 0.1850561, 0)
        _BottomTint("BottomTint", Color) = (0, 0, 0, 0)
        _BlendMult("BlendMult", Float) = 0
        _BlendOff("BlendOff", Float) = 0
        _AdLightConst("Additional light", Float) = 0.5
    }

    SubShader
    {
        // UniversalPipeline needed to have this render in URP
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}


        HLSLINCLUDE

        #include "Assets/AlexandraPortfolio/Shaders/Finished/MinionsGrassSystem/Grass.hlsl"

        ENDHLSL

        // Forward Lit Pass
        Pass 
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            ZWrite On ZTest LEqual
            Cull Off
            //Cull Back

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

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog

            #if UNITY_VERSION >= 202120
                #pragma multi_compile_fragment _ DEBUG_DISPLAY
            #endif
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            // Register our functions
            /*#pragma vertex Vertex
            #pragma fragment Fragment*/
            #pragma vertex Vertex
            #pragma fragment Fragment

            // Incude our logic file
            #include "BladeGrass.hlsl"

            /*float4 _BaseMap_ST;
            float4 _BaseColor;
            float _Cutoff;*/

            /*#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitForwardPass.hlsl"

            // Based on Standard (Physically Based) shader
            Varyings LitPassVertex2(uint vertexID: SV_VertexID, Attributes input)
            {
                DrawTriangle tri = _DrawTriangles[vertexID / 3];
                DrawVertex inn = tri.vertices[vertexID % 3];
                float3 positionOS = mul(unity_ObjectToWorld, float4(inn.positionWS, 1));
                float3 normalOS = TransformWorldToObjectNormal(tri.normalOS);
                float3 positionCS = CalculatePositionCSWithShadowCasterLogic(inn.positionWS, tri.normalOS);;


                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(positionOS.xyz);

                // normalWS and tangentWS already normalize.
                // this is required to avoid skewing the direction during interpolation
                // also required for per-vertex lighting and SH evaluation
                VertexNormalInputs normalInput = GetVertexNormalInputs(normalOS, input.tangentOS);

                half3 vertexLight = VertexLighting(inn.positionWS, tri.normalOS);

                half fogFactor = 0;
                #if !defined(_FOG_FRAGMENT)
                    fogFactor = ComputeFogFactor(positionCS.z);
                #endif

                output.uv = inn.uv;

                // already normalized from normal transform to WS.
                output.normalWS = tri.normalOS;
                #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR) || defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
                    real sign = input.tangentOS.w * GetOddNegativeScale();
                    half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
                #endif
                #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
                    output.tangentWS = tangentWS;
                #endif

                #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
                    half3 viewDirWS = GetViewDirectionFromPosition(inn.positionWS);
                    half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, output.normalWS, viewDirWS);
                    output.viewDirTS = viewDirTS;
                #endif

                    OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
                #ifdef DYNAMICLIGHTMAP_ON
                    output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
                #endif
                    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
                #else
                    output.fogFactor = fogFactor;
                #endif

                #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                    output.positionWS = inn.positionWS;
                #endif

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    output.shadowCoord = CalculateShadowCoord(inn.positionWS, positionCS);
                #endif

                output.positionCS = positionCS.xyzx;

                return output;
            }*/


            ENDHLSL
        }

        // Forward Lit Pass
        Pass 
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}
            Cull Off
            ZWrite On ZTest LEqual

            HLSLPROGRAM
                // Signal this shader requires a compute buffer
                #pragma prefer_hlslcc gles
                #pragma exclude_renderers d3d11_9x

                // GPU Instancing
                #pragma multi_compile_instancing
                #pragma multi_compile _ DOTS_INSTANCING_ON

                //#define SHADOW_CASTER_PASS

                // Register our functions
                /*#pragma vertex Vertex
                #pragma fragment Fragment*/
                #pragma vertex ShadowPassVertex2
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

                Varyings ShadowPassVertex2(uint vertexID: SV_VertexID)
                {
                    DrawTriangle tri = _DrawTriangles[vertexID / 3];
                    DrawVertex input = tri.vertices[vertexID % 3];

                    Varyings output;
                    UNITY_SETUP_INSTANCE_ID(input);
                    float _WindSpeed = 2;
                    float _WindStrength = 0.05f;

                    float3 wind1 = float3(
                    sin(_Time.y * _WindSpeed + input.positionWS.x) + sin(
                    _Time.y * _WindSpeed + input.positionWS.z * 2) + sin(
                    _Time.y * _WindSpeed * 0.1 + input.positionWS.x), 0,
                    cos(_Time.y * _WindSpeed + input.positionWS.x * 2) + cos(
                    _Time.y * _WindSpeed + input.positionWS.z));
                    wind1 *= _WindStrength;

                    //output.positionWS = input.positionWS +(wind1 * input.uv.y);

                    //output.uv = input.uv;
                    //output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                    output.positionCS = TransformWorldToHClip(input.positionWS /*+(wind1 * input.uv.y)*/);
                    //output.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS +(wind1 * input.uv.y), input.normalWS, _LightDirection));
                    return output;
                }

                half4 ShadowPassFragment2(Varyings input) : SV_TARGET
                {
                    //Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);

                    /*#ifdef LOD_FADE_CROSSFADE
                        LODFadeCrossFade(input.positionCS);
                    #endif*/

                    return 0;
                }

            ENDHLSL
        }

        // DepthOnly, used for Camera Depth Texture (if cannot copy depth buffer instead, and the DepthNormals below isn't used)
        Pass 
        {
            Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }

            //ColorMask 0
            ZWrite On
            ZTest LEqual
            Cull Off

            HLSLPROGRAM
                #pragma vertex DepthOnlyVertex2
                #pragma fragment DepthOnlyFragment2

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

                Varyings DepthOnlyVertex2(uint vertexID: SV_VertexID)
                {
                    DrawTriangle tri = _DrawTriangles[vertexID / 3];
                    DrawVertex input = tri.vertices[vertexID % 3];

                    Varyings output = (Varyings)0;
                    UNITY_SETUP_INSTANCE_ID(input);
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                    float _WindSpeed = 2;
                    float _WindStrength = 0.05f;

                    float3 wind1 = float3(
                    sin(_Time.y * _WindSpeed + input.positionWS.x) + sin(
                    _Time.y * _WindSpeed + input.positionWS.z * 2) + sin(
                    _Time.y * _WindSpeed * 0.1 + input.positionWS.x), 0,
                    cos(_Time.y * _WindSpeed + input.positionWS.x * 2) + cos(
                    _Time.y * _WindSpeed + input.positionWS.z));
                    wind1 *= _WindStrength;

                    //output.positionWS = input.positionWS +(wind1 * input.uv.y);

                    //output.uv = input.uv;
                    output.positionCS = TransformWorldToHClip(input.positionWS /*+(wind1 * input.uv.y)*/);
                    return output;
                }

                half DepthOnlyFragment2(Varyings input) : SV_TARGET
                {
                    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                    //Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);

                #ifdef LOD_FADE_CROSSFADE
                    LODFadeCrossFade(input.positionCS);
                #endif

                    return input.positionCS.z;
                }

            
            ENDHLSL
        }

        Pass 
        {
            Name "DepthNormalOnly"
            Tags { "LightMode"="DepthNormals" }

            //ColorMask 0
            ZWrite On
            ZTest LEqual
            Cull Off

            HLSLPROGRAM
                #pragma vertex DepthNormalsVertex2
                #pragma fragment DepthNormalsFragment

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
                #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"


                Varyings DepthNormalsVertex2(uint vertexID: SV_VertexID)
                {
                    DrawTriangle tri = _DrawTriangles[vertexID / 3];
                    DrawVertex input = tri.vertices[vertexID % 3];

                    Varyings output = (Varyings)0;
                    UNITY_SETUP_INSTANCE_ID(input);
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                    /*output.uv         = TRANSFORM_TEX(input.texcoord, _BaseMap);
                    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);

                    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal, input.tangentOS);
                    output.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);*/

                    float _WindSpeed = 2;
                    float _WindStrength = 0.05f;

                    float3 wind1 = float3(
                    sin(_Time.y * _WindSpeed + input.positionWS.x) + sin(
                    _Time.y * _WindSpeed + input.positionWS.z * 2) + sin(
                    _Time.y * _WindSpeed * 0.1 + input.positionWS.x), 0,
                    cos(_Time.y * _WindSpeed + input.positionWS.x * 2) + cos(
                    _Time.y * _WindSpeed + input.positionWS.z));
                    wind1 *= _WindStrength;

                    //output.positionWS = input.positionWS +(wind1 * input.uv.y);

                    TRANSFORM_TEX(input.uv, _BaseMap);
                    output.positionCS = TransformWorldToHClip(input.positionWS /*+(wind1 * input.uv.y)*/);
                    //output.uv = input.uv;

                    //VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal, input.tangentOS);
                    output.normalWS = tri.normalOS;

                    return output;
                }

                void DepthNormalsFragment2(
                    Varyings input
                    , out half4 outNormalWS : SV_Target0
                #ifdef _WRITE_RENDERING_LAYERS
                    , out float4 outRenderingLayers : SV_Target1
                #endif
                )
                {
                    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                    //Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);

                #ifdef LOD_FADE_CROSSFADE
                    LODFadeCrossFade(input.positionCS);
                #endif

                    #if defined(_GBUFFER_NORMALS_OCT)
                    float3 normalWS = normalize(input.normalWS);
                    float2 octNormalWS = PackNormalOctQuadEncode(normalWS);           // values between [-1, +1], must use fp32 on some platforms.
                    float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);   // values between [ 0,  1]
                    half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);      // values between [ 0,  1]
                    outNormalWS = half4(packedNormalWS, 0.0);
                    #else
                    float3 normalWS = NormalizeNormalPerPixel(input.normalWS);
                    outNormalWS = half4(normalWS, 0.0);
                    #endif

                    #ifdef _WRITE_RENDERING_LAYERS
                        uint renderingLayers = GetMeshRenderingLayer();
                        outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
                    #endif
                }

            
            ENDHLSL
        }

        Pass 
        {
            Name "GBuffer"
            Tags { "LightMode"="UniversalGBuffer" }

            ColorMask 0
            Cull Back
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
                #pragma vertex LitGBufferPassVertex2
                #pragma fragment frag

                // Material Keywords
                #pragma shader_feature_local_fragment _ALPHATEST_ON
                #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

                #pragma multi_compile _ LIGHTMAP_ON
                #pragma multi_compile _ DYNAMICLIGHTMAP_ON
                #pragma multi_compile _ DIRLIGHTMAP_COMBINED
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
                #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
                #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
                #pragma multi_compile_fragment _ _SHADOWS_SOFT
                #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
                #pragma multi_compile _ SHADOWS_SHADOWMASK
                #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
                #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
                #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
                #pragma multi_compile_fragment _ _RENDER_PASS_ENABLED
                #pragma multi_compile_fragment _ DEBUG_DISPLAY

                // GPU Instancing
                #pragma multi_compile_instancing
                //#pragma multi_compile _ DOTS_INSTANCING_ON

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

                /*float4 _BaseMap_ST;
                float4 _BaseColor;
                float _Cutoff;*/

                float4 _BottomTint;
                float4 _TopTint;


                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
                //#include "Packages/com.unity.render-pipelines.universal/Shaders/LitGBufferPass.hlsl"

                #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"

                struct Attributes
                {
                     float3 positionOS : POSITION;
                     float3 normalOS : NORMAL;
                     float4 tangentOS : TANGENT;
                     float4 uv0 : TEXCOORD0;
                     float4 uv1 : TEXCOORD1;
                    #if UNITY_ANY_INSTANCING_ENABLED
                     uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                     float4 positionCS : SV_POSITION;
                     float3 positionWS : TEXCOORD7;
                     float3 normalWS   : NORMAL;
                     float4 tangentWS  : TANGENT;
                     float2 uv         : TEXCOORD0;
                     /*float4 texCoord0;
                     float4 texCoord2;*/
                    #if defined(LIGHTMAP_ON)
                     float2 staticLightmapUV : TEXCOORD1;
                    #endif
                    #if defined(DYNAMICLIGHTMAP_ON)
                     float2 dynamicLightmapUV : TEXCOORD2;
                    #endif
                    #if !defined(LIGHTMAP_ON)
                     //float3 sh;
                     float3 sh : TEXCOORD3;
                    #endif
                     float4 fogFactorAndVertexLight : TEXCOORD4;
                    //#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                     float4 shadowCoord : TEXCOORD5;
                    //#endif
                    #if UNITY_ANY_INSTANCING_ENABLED
                     uint instanceID : CUSTOM_INSTANCE_ID : TEXCOORD6;
                    #endif
                    float3 viewDirTS : TEXCOORD8;
                    float3 bakedGI : TEXCOORD9;
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                     uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                     uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                     FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
                struct SurfaceDescription
                {
                    float3 BaseColor;
                    float3 NormalTS;
                    float3 Emission;
                    float Metallic;
                    float Smoothness;
                    float Occlusion;
                };
                struct SurfaceDescriptionInputs
                {
                     float3 WorldSpaceNormal;
                     float3 TangentSpaceNormal;
                     float3 WorldSpaceTangent;
                     float3 WorldSpaceBiTangent;
                     float4 uv0;
                     float4 uv2;
                };
                struct VertexDescriptionInputs
                {
                     float3 ObjectSpaceNormal;
                     float3 ObjectSpaceTangent;
                     float3 ObjectSpacePosition;
                     float4 uv0;
                     float4 uv1;
                };
                SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
                
                    #ifdef HAVE_VFX_MODIFICATION
                    #if VFX_USE_GRAPH_VALUES
                        uint instanceActiveIndex = asuint(UNITY_ACCESS_INSTANCED_PROP(PerInstance, _InstanceActiveIndex));
                        // WARNING: $splice Could not find named fragment 'VFXLoadGraphValues'
                    #endif
                        // WARNING: $splice Could not find named fragment 'VFXSetFragInputs'
                    
                    #endif
                
                    
                
                    // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
                    float3 unnormalizedNormalWS = input.normalWS;
                    const float renormFactor = 1.0 / length(unnormalizedNormalWS);
                
                    // use bitangent on the fly like in hdrp
                    // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
                    float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0)* GetOddNegativeScale();
                    float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);
                
                    output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
                    output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
                
                    // to pr               eserve mikktspace compliance we use same scale renormFactor as was used on the normal.
                    // This                is explained in section 2.2 in "surface gradient based bump mapping framework"
                    output.WorldSpaceTangent = renormFactor * input.tangentWS.xyz;
                    output.WorldSpaceBiTangent = renormFactor * bitang;
                
                
                    #if UNITY_UV_STARTS_AT_TOP
                    #else
                    #endif
                
                
                    output.uv0 = input.uv.xyxy;
                    output.uv2 = input.fogFactorAndVertexLight;
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                    #else
                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                    #endif
                    #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                
                        return output;
                }
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
                    //float4 _Property_2ec2bca0ee244e0094e78d84e3370433_Out_0_Vector4 = _BottomTint;
                    //float4 _Property_4b163cfa524e47b894bc50b40abdd196_Out_0_Vector4 = _TopTint;
                    float4 _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4 = IN.uv0;
                    float _Split_d66392bab2044a9a97fb651266eee401_R_1_Float = _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4[0];
                    float _Split_d66392bab2044a9a97fb651266eee401_G_2_Float = _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4[1];
                    float _Split_d66392bab2044a9a97fb651266eee401_B_3_Float = _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4[2];
                    float _Split_d66392bab2044a9a97fb651266eee401_A_4_Float = _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4[3];
                    float4 _Lerp_93c22aaff80e4dc2b825807437590fa2_Out_3_Vector4 = lerp(_BottomTint, _TopTint, IN.uv0);
                    //Unity_Lerp_float4(_Property_2ec2bca0ee244e0094e78d84e3370433_Out_0_Vector4, _Property_4b163cfa524e47b894bc50b40abdd196_Out_0_Vector4, (_Split_d66392bab2044a9a97fb651266eee401_G_2_Float.xxxx), _Lerp_93c22aaff80e4dc2b825807437590fa2_Out_3_Vector4);
                    float4 _UV_75a9f5d78cee47539c081f45bf86e6ff_Out_0_Vector4 = IN.uv2;
                    float _Split_43ef9ee946804418a8e8969c4b4a45ea_R_1_Float = _UV_75a9f5d78cee47539c081f45bf86e6ff_Out_0_Vector4[0];
                    float _Split_43ef9ee946804418a8e8969c4b4a45ea_G_2_Float = _UV_75a9f5d78cee47539c081f45bf86e6ff_Out_0_Vector4[1];
                    float _Split_43ef9ee946804418a8e8969c4b4a45ea_B_3_Float = _UV_75a9f5d78cee47539c081f45bf86e6ff_Out_0_Vector4[2];
                    float _Split_43ef9ee946804418a8e8969c4b4a45ea_A_4_Float = _UV_75a9f5d78cee47539c081f45bf86e6ff_Out_0_Vector4[3];
                    float3 _Vector3_78447658b34541ec89a24f968fe17bf9_Out_0_Vector3 = float3(_Split_43ef9ee946804418a8e8969c4b4a45ea_R_1_Float, _Split_43ef9ee946804418a8e8969c4b4a45ea_G_2_Float, _Split_43ef9ee946804418a8e8969c4b4a45ea_B_3_Float);
                    float3 _Transform_41c37aa95bdf4610857b46b714d517b7_Out_1_Vector3;
                    {
                        // Converting Normal from Object to Tangent via world space
                        float3 world;
                        world = TransformObjectToWorldNormal(_Vector3_78447658b34541ec89a24f968fe17bf9_Out_0_Vector3.xyz, false);
                        {
                            float3x3 tangentTransform = float3x3(IN.WorldSpaceTangent, IN.WorldSpaceBiTangent, IN.WorldSpaceNormal);
                            _Transform_41c37aa95bdf4610857b46b714d517b7_Out_1_Vector3 = TransformWorldToTangent(world, tangentTransform, true);
                        }
                    }
                    surface.BaseColor = (_Lerp_93c22aaff80e4dc2b825807437590fa2_Out_3_Vector4.xyz);
                    surface.NormalTS = _Transform_41c37aa95bdf4610857b46b714d517b7_Out_1_Vector3;
                    surface.Emission = float3(0, 0, 0);
                    surface.Metallic = 0;
                    surface.Smoothness = 0;
                    surface.Occlusion = 1;
                    return surface;
                }
                void InitializeInputData(Varyings input, SurfaceDescription surfaceDescription, out InputData inputData)
                {
                    inputData = (InputData)0;

                    inputData.positionWS = input.positionWS;
                    inputData.positionCS = input.positionCS;

                    #ifdef _NORMALMAP
                        // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
                        float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
                        float3 bitangent = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

                        inputData.tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
                        #if _NORMAL_DROPOFF_TS
                            inputData.normalWS = TransformTangentToWorld(surfaceDescription.NormalTS, inputData.tangentToWorld);
                        #elif _NORMAL_DROPOFF_OS
                            inputData.normalWS = TransformObjectToWorldNormal(surfaceDescription.NormalOS);
                        #elif _NORMAL_DROPOFF_WS
                            inputData.normalWS = surfaceDescription.NormalWS;
                        #endif
                    #else
                        inputData.normalWS = input.normalWS;
                    #endif
                    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
                    inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);

                    #if defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                        inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
                    #else
                        inputData.shadowCoord = float4(0, 0, 0, 0);
                    #endif

                    inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactorAndVertexLight.x);
                    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
                    #if defined(DYNAMICLIGHTMAP_ON)
                        inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV.xy, input.sh, inputData.normalWS);
                    #else
                        inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.sh, inputData.normalWS);
                    #endif
                    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                    inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);

                    #if defined(DEBUG_DISPLAY)
                        #if defined(DYNAMICLIGHTMAP_ON)
                        inputData.dynamicLightmapUV = input.dynamicLightmapUV.xy;
                        #endif
                        #if defined(LIGHTMAP_ON)
                        inputData.staticLightmapUV = input.staticLightmapUV;
                        #else
                        inputData.vertexSH = input.sh;
                        #endif
                    #endif
                }

                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"


                Varyings LitGBufferPassVertex2(uint vertexID: SV_VertexID, Attributes inn)
                {
                    DrawTriangle tri = _DrawTriangles[vertexID / 3];
                    DrawVertex input = tri.vertices[vertexID % 3];

                    Varyings output = (Varyings)0;



                    UNITY_SETUP_INSTANCE_ID(output);
                    //UNITY_TRANSFER_INSTANCE_ID(input, output);
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                    float3 positionOS = mul(unity_ObjectToWorld, float4(input.positionWS, 1));

                    VertexPositionInputs vertexInput = GetVertexPositionInputs(positionOS.xyz);

                    // normalWS and tangentWS already normalize.
                    // this is required to avoid skewing the direction during interpolation
                    // also required for per-vertex lighting and SH evaluation
                    //VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                    output.uv = input.uv;

                    // already normalized from normal transform to WS.
                    output.normalWS = tri.normalOS;

                    /*#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR) || defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
                        real sign = input.tangentOS.w * GetOddNegativeScale();
                        half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
                    #endif*/

                    /*#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
                        output.tangentWS = tangentWS;
                    #endif*/

                    #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
                        half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                        half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, output.normalWS, viewDirWS);
                        output.viewDirTS = viewDirWS;
                    #endif

                    OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
                    #ifdef DYNAMICLIGHTMAP_ON
                        output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy +
                         unity_DynamicLightmapST.zw;
                    #endif
                    OUTPUT_SH(output.normalWS.xyz, output.sh);

                    #ifdef _ADDITIONAL_LIGHTS_VERTEX
                        half3 vertexLight = VertexLighting(input.positionWS, output.normalWS);
                        output.vertexLighting = vertexLight;
                    #endif

                    #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                        output.positionWS = input.positionWS;
                    #endif

                    //#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                        output.shadowCoord = TransformWorldToHClip(input.positionWS);
                    //#endif

                    #if defined(DYNAMICLIGHTMAP_ON)
                        output.bakedGI = SAMPLE_GI(output.staticLightmapUV, output.dynamicLightmapUV.xy, output.shadowCoord, output.normalWS);
                    #else
                        output.bakedGI = SAMPLE_GI(output.staticLightmapUV, output.shadowCoord, output.normalWS);
                    #endif

                    output.positionCS = TransformWorldToHClip(input.positionWS);

                    output = BuildVaryings(inn);

                    return output;
                }

                FragmentOutput frag(Varyings input)
                {
                    /*Varyings unpacked = UnpackVaryings(packedInput);
                    UNITY_SETUP_INSTANCE_ID(unpacked);
                    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(unpacked);
                    SurfaceDescription surfaceDescription = BuildSurfaceDescription(unpacked);

                    #if _ALPHATEST_ON
                        half alpha = surfaceDescription.Alpha;
                        clip(alpha - surfaceDescription.AlphaClipThreshold);
                    #elif _SURFACE_TYPE_TRANSPARENT
                        half alpha = surfaceDescription.Alpha;
                    #else
                        half alpha = 1;
                    #endif

                    #if defined(LOD_FADE_CROSSFADE) && USE_UNITY_CROSSFADE
                        LODFadeCrossFade(unpacked.positionCS);
                    #endif

                    InputData inputData;
                    InitializeInputData(unpacked, surfaceDescription, inputData);
                    // TODO: Mip debug modes would require this, open question how to do this on ShaderGraph.
                    //SETUP_DEBUG_TEXTURE_DATA(inputData, unpacked.uv, _MainTex);

                    #ifdef _SPECULAR_SETUP
                        float3 specular = surfaceDescription.Specular;
                        float metallic = 1;
                    #else
                        float3 specular = 0;
                        float metallic = surfaceDescription.Metallic;
                    #endif

                    #ifdef _DBUFFER
                        ApplyDecal(unpacked.positionCS,
                            surfaceDescription.BaseColor,
                            specular,
                            inputData.normalWS,
                            metallic,
                            surfaceDescription.Occlusion,
                            surfaceDescription.Smoothness);
                    #endif*/

                    InputData inputData = (InputData)0;
                    inputData.shadowCoord = TransformWorldToHClip(input.positionWS);
                    inputData.positionWS = input.positionWS;
                    inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
                    inputData.normalWS = input.normalWS;
                    inputData.bakedGI = input.bakedGI;
                    inputData.viewDirectionWS = input.viewDirTS;


                    float3 albedo = lerp(_BottomTint.rgb, _TopTint.rgb, input.uv.y);
                    half3 normalTS = half3(0, 0, 0);

                    SurfaceData surfaceDescription = (SurfaceData)0;
                    surfaceDescription.albedo              = albedo;
                    surfaceDescription.metallic            = 0;
                    surfaceDescription.specular            = albedo;
                    surfaceDescription.smoothness          = 0.2f,
                    surfaceDescription.occlusion           = 1,
                    surfaceDescription.emission            = 0,
                    surfaceDescription.alpha               = 1;

                    surfaceDescription.normalTS            = normalTS;

                    SurfaceDescription surfaceDescription2 = BuildSurfaceDescription(input);
                    InitializeInputData(input, surfaceDescription2, inputData);


                // in LitForwardPass GlobalIllumination (and temporarily LightingPhysicallyBased) are called inside 
                //UniversalFragmentPBR
                // in Deferred rendering we store the sum of these values (and of emission as well) in the GBuffer
                /*BRDFData brdfData;
                InitializeBRDFData(surfaceDescription.albedo, surfaceDescription.metallic, surfaceDescription.specular,
                 surfaceDescription.smoothness, surfaceDescription.alpha,
                 brdfData);

                Light mainLight = GetMainLight(input.shadowCoord, input.positionWS, inputData.shadowMask);
                MixRealtimeAndBakedGI(mainLight, input.normalWS, input.bakedGI, inputData.shadowMask);
                half3 color = GlobalIllumination(brdfData, input.bakedGI, surfaceDescription.occlusion, input.positionWS, 
                    input.normalWS, inputData.viewDirectionWS);

                return BRDFDataToGbuffer(brdfData, inputData, surfaceDescription.smoothness, surfaceDescription.emission + color, surfaceDescription.occlusion);*/

                BRDFData brdfData;
                InitializeBRDFData(surfaceDescription.albedo, surfaceDescription.metallic, surfaceDescription.specular,
                 surfaceDescription.smoothness, surfaceDescription.alpha,
                 brdfData);

                Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, inputData.shadowMask);
                MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, inputData.shadowMask);
                half3 color = GlobalIllumination(brdfData, inputData.bakedGI, surfaceDescription.occlusion, inputData.positionWS, inputData.normalWS, inputData.viewDirectionWS);

                return BRDFDataToGbuffer(brdfData, inputData, surfaceDescription.smoothness, surfaceDescription.emission + color, surfaceDescription.occlusion);
                }

            
            ENDHLSL
        }


    }
}