// Example Shader for Universal RP
// Written by @Cyanilux
// https://www.cyanilux.com/tutorials/urp-shader-code

/*
Roughly equivalent to the URP/SimpleLit.shader (but Forward path only)
https://github.com/Unity-Technologies/Graphics/blob/master/Packages/com.unity.render-pipelines.universal/Shaders/SimpleLit.shader
*/

Shader "SashaMakesGames/ProcedurBrick2" {
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
        
        // Pragmas
        #pragma target 2.0
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma vertex vert
        #pragma fragment frag
        
        // Keywords
        #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DYNAMICLIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
        #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
        #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
        #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
        #pragma multi_compile_fragment _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
        #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
        #pragma multi_compile_fragment _ _LIGHT_LAYERS
        #pragma multi_compile_fragment _ DEBUG_DISPLAY
        #pragma multi_compile_fragment _ _LIGHT_COOKIES
        #pragma multi_compile _ _FORWARD_PLUS
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #define VARYINGS_NEED_SHADOW_COORD
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_FORWARD
        #define _FOG_FRAGMENT 1
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 tangentWS;
             float4 texCoord0;
            #if defined(LIGHTMAP_ON)
             float2 staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
             float2 dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
             float3 sh;
            #endif
             float4 fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
             float4 shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
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
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 TangentSpaceNormal;
             float3 WorldSpaceTangent;
             float3 WorldSpaceBiTangent;
             float3 WorldSpacePosition;
             float4 uv0;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
            #if defined(LIGHTMAP_ON)
             float2 staticLightmapUV : INTERP0;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
             float2 dynamicLightmapUV : INTERP1;
            #endif
            #if !defined(LIGHTMAP_ON)
             float3 sh : INTERP2;
            #endif
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
             float4 shadowCoord : INTERP3;
            #endif
             float4 tangentWS : INTERP4;
             float4 texCoord0 : INTERP5;
             float4 fogFactorAndVertexLight : INTERP6;
             float3 positionWS : INTERP7;
             float3 normalWS : INTERP8;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
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
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            #if defined(LIGHTMAP_ON)
            output.staticLightmapUV = input.staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.dynamicLightmapUV = input.dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.sh;
            #endif
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.shadowCoord = input.shadowCoord;
            #endif
            output.tangentWS.xyzw = input.tangentWS;
            output.texCoord0.xyzw = input.texCoord0;
            output.fogFactorAndVertexLight.xyzw = input.fogFactorAndVertexLight;
            output.positionWS.xyz = input.positionWS;
            output.normalWS.xyz = input.normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            #if defined(LIGHTMAP_ON)
            output.staticLightmapUV = input.staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.dynamicLightmapUV = input.dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.sh;
            #endif
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.shadowCoord = input.shadowCoord;
            #endif
            output.tangentWS = input.tangentWS.xyzw;
            output.texCoord0 = input.texCoord0.xyzw;
            output.fogFactorAndVertexLight = input.fogFactorAndVertexLight.xyzw;
            output.positionWS = input.positionWS.xyz;
            output.normalWS = input.normalWS.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        CBUFFER_END
        
        
        // Object and Global properties
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Divide_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A / B;
        }
        
        void Unity_Floor_float(float In, out float Out)
        {
            Out = floor(In);
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Fraction_float2(float2 In, out float2 Out)
        {
            Out = frac(In);
        }
        
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
        
        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }
        
        void Unity_Sine_float3(float3 In, out float3 Out)
        {
            Out = sin(In);
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Fraction_float3(float3 In, out float3 Out)
        {
            Out = frac(In);
        }
        
        struct Bindings_SGHash23_9d48aaf0e4c45684fa6de5bdb189fadc_float
        {
        };
        
        void SG_SGHash23(float2 _UV/*, Bindings_SGHash23_9d48aaf0e4c45684fa6de5bdb189fadc_float IN*/, out float3 Random_1)
        {
            float2 _Property_335f21645ca94e2189fe9254f53013db_Out_0_Vector2 = _UV;
            float3 _Swizzle_9062f02e732c41038e925fc8c00b8e77_Out_1_Vector3 = _Property_335f21645ca94e2189fe9254f53013db_Out_0_Vector2.xyx;
            float _DotProduct_fa6820a17e5b47d392bc4414d260452b_Out_2_Float;
            Unity_DotProduct_float3(_Swizzle_9062f02e732c41038e925fc8c00b8e77_Out_1_Vector3, float3(127.1, 311.7, 74.7), _DotProduct_fa6820a17e5b47d392bc4414d260452b_Out_2_Float);
            float3 _Swizzle_a0be12a49a83433f8329a0cd30c6ff06_Out_1_Vector3 = _Property_335f21645ca94e2189fe9254f53013db_Out_0_Vector2.yxx;
            float _DotProduct_0905982609db4ff1be83f00524672bef_Out_2_Float;
            Unity_DotProduct_float3(_Swizzle_a0be12a49a83433f8329a0cd30c6ff06_Out_1_Vector3, float3(269.5, 183.3, 246.1), _DotProduct_0905982609db4ff1be83f00524672bef_Out_2_Float);
            float3 _Swizzle_faa0e218d5b14daaa6d1410017f58e4b_Out_1_Vector3 = _Property_335f21645ca94e2189fe9254f53013db_Out_0_Vector2.xyy;
            float _DotProduct_588a87af43084513977eb1e0fc898acf_Out_2_Float;
            Unity_DotProduct_float3(_Swizzle_faa0e218d5b14daaa6d1410017f58e4b_Out_1_Vector3, float3(113.5, 271.9, 124.6), _DotProduct_588a87af43084513977eb1e0fc898acf_Out_2_Float);
            float4 _Combine_1c5457c6b3584839974d62f85818adb3_RGBA_4_Vector4;
            float3 _Combine_1c5457c6b3584839974d62f85818adb3_RGB_5_Vector3;
            float2 _Combine_1c5457c6b3584839974d62f85818adb3_RG_6_Vector2;
            Unity_Combine_float(_DotProduct_fa6820a17e5b47d392bc4414d260452b_Out_2_Float, _DotProduct_0905982609db4ff1be83f00524672bef_Out_2_Float, _DotProduct_588a87af43084513977eb1e0fc898acf_Out_2_Float, 0, _Combine_1c5457c6b3584839974d62f85818adb3_RGBA_4_Vector4, _Combine_1c5457c6b3584839974d62f85818adb3_RGB_5_Vector3, _Combine_1c5457c6b3584839974d62f85818adb3_RG_6_Vector2);
            float3 _Sine_46bcb9060b6a48d5b11119836b8605c3_Out_1_Vector3;
            Unity_Sine_float3(_Combine_1c5457c6b3584839974d62f85818adb3_RGB_5_Vector3, _Sine_46bcb9060b6a48d5b11119836b8605c3_Out_1_Vector3);
            float _Float_2426b82cd2c443eb8a3e606480912164_Out_0_Float = 43759.5;
            float3 _Multiply_bf6293145c6a4ac898512c76a6745050_Out_2_Vector3;
            Unity_Multiply_float3_float3(_Sine_46bcb9060b6a48d5b11119836b8605c3_Out_1_Vector3, (_Float_2426b82cd2c443eb8a3e606480912164_Out_0_Float.xxx), _Multiply_bf6293145c6a4ac898512c76a6745050_Out_2_Vector3);
            float3 _Fraction_5860de97901f43cb9509c71b585cd4c1_Out_1_Vector3;
            Unity_Fraction_float3(_Multiply_bf6293145c6a4ac898512c76a6745050_Out_2_Vector3, _Fraction_5860de97901f43cb9509c71b585cd4c1_Out_1_Vector3);
            Random_1 = _Fraction_5860de97901f43cb9509c71b585cd4c1_Out_1_Vector3;
        }
        
        void Unity_NormalFromHeight_Tangent_float(float In, float Strength, float3 Position, float3x3 TangentMatrix, out float3 Out)
        {
            
                    #if defined(SHADER_STAGE_RAY_TRACING) && defined(RAYTRACING_SHADER_GRAPH_DEFAULT)
                    #error 'Normal From Height' node is not supported in ray tracing, please provide an alternate implementation, relying for instance on the 'Raytracing Quality' keyword
                    #endif
            float3 worldDerivativeX = ddx(Position);
            float3 worldDerivativeY = ddy(Position);
        
            float3 crossX = cross(TangentMatrix[2].xyz, worldDerivativeX);
            float3 crossY = cross(worldDerivativeY, TangentMatrix[2].xyz);
            float d = dot(worldDerivativeX, crossY);
            float sgn = d < 0.0 ? (-1.0f) : 1.0f;
            float surface = sgn / max(0.000000000000001192093f, abs(d));
        
            float dHdx = ddx(In);
            float dHdy = ddy(In);
            float3 surfGrad = surface * (dHdx*crossY + dHdy*crossX);
            Out = SafeNormalize(TangentMatrix[2].xyz - (Strength * surfGrad));
            Out = TransformWorldToTangent(Out, TangentMatrix);
        }

        // Sine distance field, generate normal
        void SG_RectangleSDF(float2 _UV, float2 WidthHeight, out float OutSDF)
        {
            float2 UV_N = abs(_UV * 2 - 1) + WidthHeight;
            float max_UV_N = max(UV_N.x, UV_N.y);
            float result = saturate((1 - max_UV_N) * 2);
            OutSDF = result;
        }
        void Unity_InverseLerp_float(float A, float B, float T, out float Out)
        {
            Out = (T - A)/(B - A);
        }
        void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
        {
            float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
            Out = lerp(Min, Max, randomno);
        }
        void Unity_ColorspaceConversion_HSV_RGB_float(float3 In, out float3 Out)
        {
            float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            float3 P = abs(frac(In.xxx + K.xyz) * 6.0 - K.www);
            Out = In.z * lerp(K.xxx, saturate(P - K.xxx), In.y);
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
            return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float Smoothness;
            float Occlusion;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {

            //Brick Pattern
            float4 UV_IN = IN.uv0;
            float2 UV_Swizzle = UV_IN.xy;
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

            float2 fraction = frac(combine);
            float rectangle; 
            Unity_Rectangle_Fastest_float(fraction, 0.888f, 0.8f, rectangle);

            float3 A = float3(1.0f, 0.765f, 0.765f);
            float3 lerpP = lerp(A, BrickColorConversed, rectangle);

            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _UV_Out_0_Vector4 = IN.uv0;
            float2 _Swizzle_Vector2 = _UV_Out_0_Vector4.xy;
            float2 _Divide_Out_2_Vector2;
            Unity_Divide_float2(_Swizzle_Vector2, float2(0.2, 0.1), _Divide_Out_2_Vector2);
            float _Split_R_1_Float = _Divide_Out_2_Vector2[0];
            float _Split_G_2_Float = _Divide_Out_2_Vector2[1];
            float _Split_33f0b4b7fef8405685d0127f894b7345_B_3_Float = 0;
            float _Split_33f0b4b7fef8405685d0127f894b7345_A_4_Float = 0;
            float _Floor_Out_1_Float;
            Unity_Floor_float(_Split_G_2_Float, _Floor_Out_1_Float);
            float _Multiply_Out_2_Float;
            Unity_Multiply_float_float(0.5, _Floor_Out_1_Float, _Multiply_Out_2_Float);
            float _Add_Out_2_Float;
            Unity_Add_float(_Multiply_Out_2_Float, _Split_R_1_Float, _Add_Out_2_Float);
            float4 _Combine_011394313c9c4182b4bc90af5e53ab2d_RGBA_4_Vector4;
            float3 _Combine_011394313c9c4182b4bc90af5e53ab2d_RGB_5_Vector3;
            float2 _Combine_RG_6_Vector2;
            Unity_Combine_float(_Add_Out_2_Float, _Split_G_2_Float, 0, 0, _Combine_011394313c9c4182b4bc90af5e53ab2d_RGBA_4_Vector4, _Combine_011394313c9c4182b4bc90af5e53ab2d_RGB_5_Vector3, _Combine_RG_6_Vector2);
            float2 _Fraction_Out_1_Vector2;
            Unity_Fraction_float2(_Combine_RG_6_Vector2, _Fraction_Out_1_Vector2);
            float _Rectangle_Out_3_Float;
            Unity_Rectangle_Fastest_float(_Fraction_Out_1_Vector2, 0.888, 0.8, _Rectangle_Out_3_Float);
            //Bindings_SGHash23_9d48aaf0e4c45684fa6de5bdb189fadc_float _SGHash23_Binding;
            float3 _SGHash23_Vector3;
            SG_SGHash23((_Rectangle_Out_3_Float.xx)/*, _SGHash23_Binding*/, _SGHash23_Vector3);
            
            float OutSDF;
            SG_RectangleSDF(_Fraction_Out_1_Vector2, float2(0.07, 0.14), OutSDF);
            float OutInverseLerp;
            Unity_InverseLerp_float(0, 0.3, OutSDF, OutInverseLerp);
            OutInverseLerp = saturate(OutInverseLerp);

            float3 _NormalFromHeight_Out;
            float3x3 _NormalFromHeight_TangentMatrix = float3x3(IN.WorldSpaceTangent, IN.WorldSpaceBiTangent, IN.WorldSpaceNormal);
            float3 _NormalFromHeight_PositionWS = IN.WorldSpacePosition;
            Unity_NormalFromHeight_Tangent_float(OutInverseLerp,0.01,_NormalFromHeight_PositionWS,_NormalFromHeight_TangentMatrix, _NormalFromHeight_Out);
            //surface.BaseColor = _Rectangle_Out_3_Float.x;
            surface.BaseColor = (lerpP);
            surface.NormalTS = _NormalFromHeight_Out;
            surface.Emission = float3(0, 0, 0);
            surface.Metallic = 0;
            surface.Smoothness = 0.5;
            surface.Occlusion = 1;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
            #ifdef HAVE_VFX_MODIFICATION
            #if VFX_USE_GRAPH_VALUES
                uint instanceActiveIndex = asuint(UNITY_ACCESS_INSTANCED_PROP(PerInstance, _InstanceActiveIndex));
                /* WARNING: $splice Could not find named fragment 'VFXLoadGraphValues' */
            #endif
                /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
            
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
        
            output.WorldSpacePosition = input.positionWS;
        
            #if UNITY_UV_STARTS_AT_TOP
            #else
            #endif
            
            
                output.uv0 = input.texCoord0;
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
            #else
            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
            #endif
            #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
            
                    return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
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
