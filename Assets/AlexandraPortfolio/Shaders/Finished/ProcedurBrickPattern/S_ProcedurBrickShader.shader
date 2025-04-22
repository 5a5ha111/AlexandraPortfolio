// Example Shader for Universal RP
// Written by @Cyanilux
// https://www.cyanilux.com/tutorials/urp-shader-code

/*
Roughly equivalent to the URP/SimpleLit.shader (but Forward path only)
https://github.com/Unity-Technologies/Graphics/blob/master/Packages/com.unity.render-pipelines.universal/Shaders/SimpleLit.shader
*/

Shader "SashaMakesGames/ProcedurBrick" {
    Properties {
        [MainTexture] _BaseMap("Base Map (RGB) Smoothness / Alpha (A)", 2D) = "white" {}
        [MainColor]   _BaseColor("Base Color", Color) = (1, 1, 1, 1)

        [Toggle(_NORMALMAP)] _NormalMapToggle ("Normal Mapping", Float) = 0
        [NoScaleOffset] _BumpMap("Normal Map", 2D) = "bump" {}

        [HDR] _EmissionColor("Emission Color", Color) = (0,0,0)
        [Toggle(_EMISSION)] _Emission ("Emission", Float) = 0
        [NoScaleOffset]_EmissionMap("Emission Map", 2D) = "white" {}

        [Toggle(_ALPHATEST_ON)] _AlphaTestToggle ("Alpha Clipping", Float) = 0
        _Cutoff ("Alpha Cutoff", Float) = 0.5

        [Toggle(_SPECGLOSSMAP)] _SpecGlossMapToggle ("Use Specular Gloss Map", Float) = 0
        _SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 0.5)
        _SpecGlossMap("Specular Map", 2D) = "white" {}
        [Toggle(_GLOSSINESS_FROM_BASE_ALPHA)] _GlossSource ("Glossiness Source, from Albedo Alpha (if on) vs from Specular (if off)", Float) = 0
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
    }
    SubShader {
        Tags {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "Queue"="Geometry"
            "UniversalMaterialType" = "Lit"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _BaseMap_ST;
        float4 _BaseColor;
        float4 _EmissionColor;
        float4 _SpecColor;
        float _Cutoff;
        float _Smoothness;
        CBUFFER_END
        ENDHLSL

        Pass {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            //#pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
            //#pragma shader_feature_local_fragment _ _SPECGLOSSMAP _SPECULAR_COLOR
            #pragma shader_feature_local_fragment _ _SPECGLOSSMAP
            #define _SPECULAR_COLOR // always on
            #pragma shader_feature_local_fragment _GLOSSINESS_FROM_BASE_ALPHA

            // URP Keywords
            //#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            //#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            // Note, v11 changes this to :
            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN

            //#pragma multi_compile _ _SHADOWS_SOFT
            //#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            //#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING // v10+ only, renamed from "_MIXED_LIGHTING_SUBTRACTIVE"
            #pragma multi_compile _ SHADOWS_SHADOWMASK // v10+ only

            // Unity Keywords
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile_fog

            // GPU Instancing (not supported)
            //#pragma multi_compile_instancing

            // -------------------------------------
            // Includes my
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _LIGHT_LAYERS
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _FORWARD_PLUS
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"


            // -------------------------------------
            // Structs
            struct Attributes {
                float4 positionOS   : POSITION;
                float4 normalOS     : NORMAL;
                #ifdef _NORMALMAP
                    float4 tangentOS    : TANGENT;
                #endif
                float4 uv           : TEXCOORD0;
                float2 lightmapUV   : TEXCOORD1;
                float4 color        : COLOR;
                //UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings {
                float4 positionCS                   : SV_POSITION;
                float4 uv                           : TEXCOORD0;
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
                float3 positionWS                   : TEXCOORD2;

                //#ifdef _NORMALMAP
                float4 normalWS                  : TEXCOORD3;    // xyz: normal, w: viewDir.x
                half4 tangentWS                 : TEXCOORD4;    // xyz: tangent, w: viewDir.y
                half4 bitangentWS               : TEXCOORD5;    // xyz: bitangent, w: viewDir.z
                //#else
                //    half3 normalWS                  : TEXCOORD3;
                //#endif
                
                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light
                #else
                    half  fogFactor                 : TEXCOORD6;
                #endif

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    float4 shadowCoord              : TEXCOORD7;
                #endif

                float4 color                        : COLOR;
                //UNITY_VERTEX_INPUT_INSTANCE_ID
                //UNITY_VERTEX_OUTPUT_STEREO
            };

            // Textures, Samplers & Global Properties
            // (note, BaseMap, BumpMap and EmissionMap is being defined by the SurfaceInput.hlsl include)
            TEXTURE2D(_SpecGlossMap);   SAMPLER(sampler_SpecGlossMap);

            // Functions
            half4 SampleSpecularSmoothness(float2 uv, half alpha, half4 specColor, TEXTURE2D_PARAM(specMap, sampler_specMap)) {
                half4 specularSmoothness = half4(0.0h, 0.0h, 0.0h, 1.0h);
                #ifdef _SPECGLOSSMAP
                    specularSmoothness = SAMPLE_TEXTURE2D(specMap, sampler_specMap, uv) * specColor;
                #elif defined(_SPECULAR_COLOR)
                    specularSmoothness = specColor;
                #endif

                #if UNITY_VERSION >= 202120 // or #if SHADER_LIBRARY_VERSION_MAJOR < 12, but that versioning method is deprecated for newer versions
                    // v12 is changing this, so it's calculated later. Likely so that smoothness value stays 0-1 so it can display better for debug views.
                    #ifdef _GLOSSINESS_FROM_BASE_ALPHA
                        specularSmoothness.a = exp2(10 * alpha + 1);
                    #else
                        specularSmoothness.a = exp2(10 * specularSmoothness.a + 1);
                    #endif
                #endif
                return specularSmoothness;
            }

            // Generate brick Pattern
            // Usefull Functions 
            void Unity_Rectangle_Fastest_float(float2 UV, float Width, float Height, out float Out)
            {
                float2 d = abs(UV * 2 - 1) - float2(Width, Height);
                #if defined(SHADER_STAGE_RAY_TRACING)
                    d = saturate((1 - saturate(d * 1e7)));
                #else
                    d = saturate(1 - d / fwidth(d));
                #endif
                Out = min(d.x, d.y);
            }

            void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
            {
                float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
                Out = lerp(Min, Max, randomno);
            }
            void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
            {
                Out = dot(A, B);
            }
            void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
            {
                RGBA = float4(R, G, B, A);
                RGB = float3(R, G, B);
                RG = float2(R, G);
            }
            void Unity_ColorspaceConversion_HSV_RGB_float(float3 In, out float3 Out)
            {
                float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 P = abs(frac(In.xxx + K.xyz) * 6.0 - K.www);
                Out = In.z * lerp(K.xxx, saturate(P - K.xxx), In.y);
            }
            void Unity_NormalFromHeight_Tangent(float In, float3 positionWS, float3x3 TangentMatrix, out float3 Out)
            {
                float3 worldDirivativeX = ddx(positionWS * 100);
                float3 worldDirivativeY = ddy(positionWS * 100);
                float3 crossX = cross(TangentMatrix[2].xyz, worldDirivativeX);
                float3 crossY = cross(TangentMatrix[2].xyz, worldDirivativeY);
                float3 d = abs(dot(crossY, worldDirivativeX));
                float3 inToNormal = ((((In + ddx(In)) - In) * crossY) + (((In + ddy(In)) - In) * crossX)) * sign(d);
                inToNormal.y *= -1.0;
                Out = normalize((d * TangentMatrix[2].xyz) - inToNormal);
                Out = TransformWorldToTangent(Out, TangentMatrix);
            }

            void Unity_NormalFromHeight_Tangent_float(float In, float Strength, float3 Position, float3x3 TangentMatrix, out float3 Out)
            {
                float3 worldDerivativeX = ddx(Position);
                float3 worldDerivativeY = ddy(Position);

                float3 crossX = cross(TangentMatrix[2].xyz, worldDerivativeX);
                float3 crossY = cross(worldDerivativeY, TangentMatrix[2].xyz);
                float d = dot(worldDerivativeX, crossY);
                float sgn = d < 0.0 ? (-1.0f) : 1.0f;
                float surface = sgn / max(0.00000000000001192093f, abs(d));

                float dHdx = ddx(In);
                float dHdy = ddy(In);
                float3 surfGrad = surface * (dHdx*crossY + dHdy*crossX);
                Out = SafeNormalize(TangentMatrix[2].xyz - (Strength * surfGrad));
                //Out = TransformWorldToTangent(Out, TangentMatrix);
            }

            void Unity_InverseLerp_float(float A, float B, float T, out float Out)
            {
                Out = (T - A)/(B - A);
            }

            void SG_SGHash23(float2 _UV, out float3 Random_3)
            {
                float2 UV_IN = _UV;
                float3 _Swizzle_xyx = UV_IN.xyx;
                float _DotProduct_1;
                Unity_DotProduct_float3(_Swizzle_xyx, float3(127.1, 311.7, 74.7), _DotProduct_1);
                float3 _Swizzle_yxx = UV_IN.yxx;
                float _DotProduct_2;
                Unity_DotProduct_float3(_Swizzle_yxx, float3(269.5, 183.3, 246.1), _DotProduct_2);
                float3 _Swizzle_xyy = UV_IN.xyy;
                float _DotProduct_3;
                Unity_DotProduct_float3(_Swizzle_xyy, float3(113.5, 271.9, 124.6), _DotProduct_3);
                float4 _Combine_RGBA_4_Vector4;
                float3 _Combine_RGB_5_Vector3;
                float2 _Combine_RG_6_Vector2;
                Unity_Combine_float(_DotProduct_1, _DotProduct_2, _DotProduct_3, 0, _Combine_RGBA_4_Vector4, _Combine_RGB_5_Vector3, _Combine_RG_6_Vector2);
                float3 _Sine_Out_1_Vector3 = sin(_Combine_RGB_5_Vector3);
                //Unity_Sine_float3(_Combine_RGB_5_Vector3, _Sine_Out_1_Vector3);
                float _Float_ConstMltiplyTo = 43759.5;
                float3 _Multiply_Out_2_Vector3 = _Sine_Out_1_Vector3 * (_Float_ConstMltiplyTo.xxx);
                //Unity_Multiply_float3_float3(_Sine_Out_1_Vector3, (_Float_ConstMltiplyTo.xxx), _Multiply_Out_2_Vector3);
                float3 _Fraction_Result_Out_1_Vector3 = frac(_Multiply_Out_2_Vector3);
                //Unity_Fraction_float3(_Multiply_Out_2_Vector3, _Fraction_Result_Out_1_Vector3);
                Random_3 = _Fraction_Result_Out_1_Vector3;
            }

            // Sine distance field, generate normal
            void SG_RectangleSDF(float2 _UV, float2 WidthHeight, out float OutSDF)
            {
                float2 UV_N = abs(_UV * 2 - 1) + WidthHeight;
                float max_UV_N = max(UV_N.x, UV_N.y);
                float result = saturate((1 - max_UV_N) * 2);
                OutSDF = result;
            }

            //  SurfaceData & InputData
            void InitalizeSurfaceData(Varyings IN, out SurfaceData surfaceData){
                surfaceData = (SurfaceData)0; // avoids "not completely initalized" errors

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);

                #ifdef _ALPHATEST_ON
                    // Alpha Clipping
                    clip(baseMap.a - _Cutoff);
                #endif

                half4 diffuse = baseMap * _BaseColor * IN.color;

                //Brick Pattern
                float4 UV_IN = IN.uv;
                float2 UV_Swizzle = IN.uv.xy;
                float2 DivideRes = UV_Swizzle / float2(0.2f, 0.1f);
                float floorDivide = floor(DivideRes.y) * 0.5f;
                float addd = floorDivide + DivideRes.x;
                float2 combine = float2(addd, DivideRes.y);
                
                float2 floorCombine = floor(combine);
                //float2 multiplyFloor = floorCombine * float2(0.1, 0.1);
                float RandomRangeRes;
                Unity_RandomRange_float(floorCombine, 0.0, 1.0, RandomRangeRes);
                float3 Hash23;
                SG_SGHash23(floorCombine, Hash23);
                float3 Hash23TonedDown = (Hash23 * 2 - 1) * float3(0.01, 0.2, 0.1);
                float3 BensBrickColor_HSV = float3(0.03, 0.6, 0.3);
                float3 ColorToConverse = BensBrickColor_HSV + Hash23TonedDown;
                float3 BrickColorConversed;
                Unity_ColorspaceConversion_HSV_RGB_float(ColorToConverse, BrickColorConversed);
                
                float3 darkBrickColor = float3(0.5613, 0.3265, 0.2224);
                float3 lightBrickColor = float3(0.7783, 0.5404, 0.4772);
                float3 lerpBrickColor = lerp(darkBrickColor, lightBrickColor, RandomRangeRes);

                float2 fraction = frac(combine);
                float rectangle; 
                Unity_Rectangle_Fastest_float(fraction, 0.888f, 0.8f, rectangle);
                float OutSDF;
                SG_RectangleSDF(fraction, float2(0.07, 0.14), OutSDF);
                float OutInverseLerp;
                Unity_InverseLerp_float(0, 0.3, OutSDF, OutInverseLerp);
                OutInverseLerp = saturate(OutInverseLerp);

                float3 B = float3(0.259, 0.055, 0.055);
                float3 A = float3(1.0f, 0.765f, 0.765f);
                float3 lerpP = lerp(A, BrickColorConversed, rectangle);
                surfaceData.albedo = (lerpP);

                float3 positionWS = IN.positionWS;
                float3 bittangent = cross(IN.normalWS.xyz, IN.tangentWS.xyz) * IN.tangentWS.w;

                // ------------
                // i try to get bittangent
                /*float3 unnormalizedNormalWS = IN.normalWS;
                const float renormFactor = 1.0 / length(unnormalizedNormalWS);
                        
                // use bitangent on the fly like in hdrp
                // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
                float crossSign = (IN.tangentWS.w > 0.0 ? 1.0 : -1.0)* GetOddNegativeScale();
                float3 bitang = crossSign * cross(IN.normalWS.xyz, IN.tangentWS.xyz);
                        
                float3 WorldSpaceNormal = renormFactor * IN.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
                float3 TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
                        
                // to pr               eserve mikktspace compliance we use same scale renormFactor as was used on the normal.
                // This                is explained in section 2.2 in "surface gradient based bump mapping framework"
                float3 WorldSpaceTangent = renormFactor * IN.tangentWS.xyz;
                float3 WorldSpaceBiTangent = renormFactor * bitang;*/

                // ----------------------------
                float3x3 TangentMatrix = float3x3(IN.tangentWS.xyz, IN.bitangentWS.xyz, IN.normalWS.xyz);
                //float3x3 TangentMatrix2 = float3x3(WorldSpaceTangent, bitang, WorldSpaceNormal);
                float3 normalTS;
                Unity_NormalFromHeight_Tangent(OutInverseLerp, positionWS, TangentMatrix, normalTS);
                //Unity_NormalFromHeight_Tangent_float(OutInverseLerp, 0.01, positionWS, TangentMatrix, normalTS);
                surfaceData.normalTS = normalTS;

                //surfaceData.albedo = normalTS;

                //surfaceData.albedo = diffuse.rgb;
                //surfaceData.normalTS = SampleNormal(IN.uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap));
                surfaceData.emission = SampleEmission(IN.uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
                surfaceData.occlusion = 1.0; // unused

                half4 specular = SampleSpecularSmoothness(IN.uv, diffuse.a, _SpecColor, TEXTURE2D_ARGS(_SpecGlossMap, sampler_SpecGlossMap));
                surfaceData.specular = specular.rgb;


                //Fix smoothness
                //surfaceData.smoothness = specular.a * _Smoothness;
                surfaceData.smoothness = /*specular.a **/ _Smoothness;
            }

            void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData) {
                inputData = (InputData)0; // avoids "not completely initalized" errors

                inputData.positionWS = input.positionWS;

                #ifdef _NORMALMAP
                    half3 viewDirWS = half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);
                    inputData.normalWS = TransformTangentToWorld(normalTS,half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
                #else
                    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(inputData.positionWS);
                    inputData.normalWS = input.normalWS;
                #endif

                inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);

                viewDirWS = SafeNormalize(viewDirWS);
                inputData.viewDirectionWS = viewDirWS;

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    inputData.shadowCoord = input.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
                #else
                    inputData.shadowCoord = float4(0, 0, 0, 0);
                #endif

                // Fog
                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    inputData.fogCoord = input.fogFactorAndVertexLight.x;
                    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
                #else
                    inputData.fogCoord = input.fogFactor;
                    inputData.vertexLighting = half3(0, 0, 0);
                #endif

                /* in v11/v12?, could use :
                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    inputData.fogCoord = InitializeInputDataFog(float4(inputData.positionWS, 1.0), input.fogFactorAndVertexLight.x);
                    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
                #else
                    inputData.fogCoord = InitializeInputDataFog(float4(inputData.positionWS, 1.0), input.fogFactor);
                    inputData.vertexLighting = half3(0, 0, 0);
                #endif
                */

                inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
            }

            // Vertex Shader
            Varyings LitPassVertex(Attributes IN) {
                Varyings OUT;

                //UNITY_SETUP_INSTANCE_ID(IN);
                //UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
                //UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                #ifdef _NORMALMAP
                    VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS.xyz, IN.tangentOS);
                #else
                    VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS.xyz);
                #endif
                

                OUT.positionCS = positionInputs.positionCS;
                OUT.positionWS = positionInputs.positionWS;

                half3 viewDirWS = GetWorldSpaceViewDir(positionInputs.positionWS);
                half3 vertexLight = VertexLighting(positionInputs.positionWS, normalInputs.normalWS);
                half fogFactor = ComputeFogFactor(positionInputs.positionCS.z);
                
                //#ifdef _NORMALMAP
                    OUT.normalWS = half4(normalInputs.normalWS, viewDirWS.x);
                    OUT.tangentWS = half4(normalInputs.tangentWS, viewDirWS.y);
                    OUT.bitangentWS = half4(normalInputs.bitangentWS, viewDirWS.z);
                //#else
                    OUT.normalWS =float4( NormalizeNormalPerVertex(normalInputs.normalWS.xyz).xyz ,1);
                    //OUT.viewDirWS = viewDirWS;
                //#endif

                OUTPUT_LIGHTMAP_UV(IN.lightmapUV, unity_LightmapST, OUT.lightmapUV);
                OUTPUT_SH(OUT.normalWS.xyz, OUT.vertexSH);

                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    OUT.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
                #else
                    OUT.fogFactor = fogFactor;
                #endif

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    OUT.shadowCoord = GetShadowCoord(positionInputs);
                #endif

                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap).xyxy;
                OUT.color = IN.color;
                return OUT;
            }

            // Fragment Shader
            half4 LitPassFragment(Varyings IN) : SV_Target {
                //UNITY_SETUP_INSTANCE_ID(IN);
                //UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

                // Setup SurfaceData
                SurfaceData surfaceData;
                InitalizeSurfaceData(IN, surfaceData);

                // Setup InputData
                InputData inputData;
                InitializeInputData(IN, surfaceData.normalTS, inputData);

                // Simple Lighting (Lambert & BlinnPhong)
                half4 color = UniversalFragmentBlinnPhong(inputData, surfaceData); // v12 only
                //Comment the code below, because get issues



                //half4 color = UniversalFragmentBlinnPhong(inputData, surfaceData.albedo, half4(surfaceData.specular, 1), 
                //surfaceData.smoothness, surfaceData.emission, surfaceData.alpha);
                // See Lighting.hlsl to see how this is implemented.
                // https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl

                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                //color.a = OutputAlpha(color.a, _Surface);
                return color;
            }
            ENDHLSL
        }

        // UsePass "Universal Render Pipeline/Lit/ShadowCaster"
        // UsePass "Universal Render Pipeline/Lit/DepthOnly"
        // Would be nice if we could just use the passes from existing shaders,
        // However this breaks SRP Batcher compatibility. Instead, we should define them :

        // ShadowCaster, for casting shadows
        Pass {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }

            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // GPU Instancing
            #pragma multi_compile_instancing
            //#pragma multi_compile _ DOTS_INSTANCING_ON

            // Universal Pipeline Keywords
            // (v11+) This is used during shadow map generation to differentiate between directional and punctual (point/spot) light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

            // Note if we do any vertex displacement, we'll need to change the vertex function. e.g. :
            /*
            #pragma vertex DisplacedShadowPassVertex (instead of ShadowPassVertex above)
            
            Varyings DisplacedShadowPassVertex(Attributes input) {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                
                // Example Displacement
                input.positionOS += float4(0, _SinTime.y, 0, 0);
                
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionCS = GetShadowPositionHClip(input);
                return output;
            }
            */
            ENDHLSL
        }

        // DepthOnly, used for Camera Depth Texture (if cannot copy depth buffer instead, and the DepthNormals below isn't used)
        Pass {
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

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"

            // Note if we do any vertex displacement, we'll need to change the vertex function. e.g. :
            /*
            #pragma vertex DisplacedDepthOnlyVertex (instead of DepthOnlyVertex above)
            
            Varyings DisplacedDepthOnlyVertex(Attributes input) {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                // Example Displacement
                input.positionOS += float4(0, _SinTime.y, 0, 0);
                
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionCS = TransformObjectToHClip(input.position.xyz);
                return output;
            }
            */
            
            ENDHLSL
        }

        // DepthNormals, used for SSAO & other custom renderer features that request it
        Pass {
            Name "DepthNormals"
            Tags { "LightMode"="DepthNormals" }

            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // GPU Instancing
            #pragma multi_compile_instancing
            //#pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"

            // Note if we do any vertex displacement, we'll need to change the vertex function. e.g. :
            /*
            #pragma vertex DisplacedDepthNormalsVertex (instead of DepthNormalsVertex above)

            Varyings DisplacedDepthNormalsVertex(Attributes input) {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                // Example Displacement
                input.positionOS += float4(0, _SinTime.y, 0, 0);
                
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionCS = TransformObjectToHClip(input.position.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal, input.tangentOS);
                output.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);
                return output;
            }
            */
            
            ENDHLSL
        }

    }
}
