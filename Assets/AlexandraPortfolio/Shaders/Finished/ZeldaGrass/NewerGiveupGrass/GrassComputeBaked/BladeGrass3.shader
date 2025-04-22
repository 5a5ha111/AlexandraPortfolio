Shader "Shader Graphs/GrassTryShader3"
{
    Properties
    {
        _BaseColor("_BaseColor", Color) = (0, 0.403, 0, 1)
        _TopColor("_TopColor", Color) = (0, 0.781, 0, 1)
        _RandomJitterRadius("_RandomJitterRadius", Float) = 10
        [NoScaleOffset]_WindTexture("_WindTexture", 2D) = "white" {}
        _WindFrequency("_WindFrequency", Float) = 0
        _WindAmplitude("_WindAmplitude", Float) = 0
        _ShadowLightness("_ShadowLightness", Float) = 0
        [HideInInspector]_QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector]_QueueControl("_QueueControl", Float) = -1
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "UniversalMaterialType" = "Lit"
            "Queue"="Geometry"
            "DisableBatching"="False"
            "ShaderGraphShader"="true"
            "ShaderGraphTargetId"="UniversalLitSubTarget"
        }


        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
        
            // Render State
            Cull Back
            Blend One Zero
            ZTest LEqual
            ZWrite On
            
            // Debug
            // <None>
            
            // --------------------------------------------------
            // Pass
        
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
                #define VARYINGS_NEED_TEXCOORD2
                #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
                #define VARYINGS_NEED_SHADOW_COORD
                #define FEATURES_GRAPH_VERTEX
                // WARNING: $splice Could not find named fragment 'PassInstancing' 
                #define SHADERPASS SHADERPASS_FORWARD
                #define _FOG_FRAGMENT 1
                
                
                // custom interpolator pre-include
                // WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude'
                
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
                // WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' 
                
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
                     float4 texCoord2;
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
                     float4 texCoord2 : INTERP6;
                     float4 fogFactorAndVertexLight : INTERP7;
                     float3 positionWS : INTERP8;
                     float3 normalWS : INTERP9;
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
                    output.texCoord2.xyzw = input.texCoord2;
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
                    output.texCoord2 = input.texCoord2.xyzw;
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
                    float4 _BaseColor;
                    float4 _TopColor;
                    float _RandomJitterRadius;
                    float4 _WindTexture_TexelSize;
                    float _WindFrequency;
                    float _WindAmplitude;
                    float _ShadowLightness;
                CBUFFER_END
                
                
                // Object and Global properties
                TEXTURE2D(_WindTexture);
                SAMPLER(sampler_WindTexture);
                
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
                
                void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
                {
                     float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
                     Out = lerp(Min, Max, randomno);
                }
                
                void Unity_Multiply_float_float(float A, float B, out float Out)
                {
                    Out = A * B;
                }
                
                void Unity_Add_float3(float3 A, float3 B, out float3 Out)
                {
                    Out = A + B;
                }
                
                void Unity_OneMinus_float2(float2 In, out float2 Out)
                {
                    Out = 1 - In;
                }
                
                void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
                {
                    Out = A * B;
                }
                
                void Unity_Saturate_float(float In, out float Out)
                {
                    Out = saturate(In);
                }
                
                struct Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float
                {
                    half4 uv0;
                };
                
                void SG_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float(float _Size, float2 _UV2, bool _UV2_b0c2d170e89c429aa65609e27d9c0451_IsConnected, Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float IN, out float OutVector1_1)
                {
                    float2 _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2 = _UV2;
                    bool _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2_IsConnected = _UV2_b0c2d170e89c429aa65609e27d9c0451_IsConnected;
                    float4 _UV_f1dfde6948824ade8a9d0a9bc2f502ba_Out_0_Vector4 = IN.uv0;
                    float2 _BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2 = _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2_IsConnected ? _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2 : (_UV_f1dfde6948824ade8a9d0a9bc2f502ba_Out_0_Vector4.xy);
                    float2 _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2;
                    Unity_OneMinus_float2(_BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2, _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2);
                    float2 _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2;
                    Unity_Multiply_float2_float2(_BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2, _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2, _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2);
                    float _Split_5f7b1227f3084bafaef1b62cca64b3f1_R_1_Float = _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2[0];
                    float _Split_5f7b1227f3084bafaef1b62cca64b3f1_G_2_Float = _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2[1];
                    float _Split_5f7b1227f3084bafaef1b62cca64b3f1_B_3_Float = 0;
                    float _Split_5f7b1227f3084bafaef1b62cca64b3f1_A_4_Float = 0;
                    float _Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float;
                    Unity_Multiply_float_float(_Split_5f7b1227f3084bafaef1b62cca64b3f1_R_1_Float, _Split_5f7b1227f3084bafaef1b62cca64b3f1_G_2_Float, _Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float);
                    float _Property_0c675402eb3b47908659ab27249b6351_Out_0_Float = _Size;
                    float _Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float;
                    Unity_Multiply_float_float(_Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float, _Property_0c675402eb3b47908659ab27249b6351_Out_0_Float, _Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float);
                    float _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float;
                    Unity_Saturate_float(_Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float, _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float);
                    OutVector1_1 = _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float;
                }
                
                void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
                {
                    Out = lerp(A, B, T);
                }
                
                void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
                {
                    Out = lerp(A, B, T);
                }
                
                // Custom interpolators pre vertex
                // WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex'
                
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
                    float4 _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4 = IN.uv1;
                    float _Swizzle_743d174ad02f45f6a3db534c28bef35c_Out_1_Float = _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4.z;
                    float _RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float;
                    Unity_RandomRange_float((_Swizzle_743d174ad02f45f6a3db534c28bef35c_Out_1_Float.xx), -1, 1, _RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float);
                    float _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float = _RandomJitterRadius;
                    float _Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float;
                    Unity_Multiply_float_float(_RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float, _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float, _Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float);
                    float _Swizzle_94c4d82bbd6c4a019354b14edaf174f5_Out_1_Float = _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4.x;
                    float _RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float;
                    Unity_RandomRange_float((_Swizzle_94c4d82bbd6c4a019354b14edaf174f5_Out_1_Float.xx), -1, 1, _RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float);
                    float _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float;
                    Unity_Multiply_float_float(_RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float, _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float, _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float);
                    float3 _Vector3_7a8d4565538e42afa8736738c67b58db_Out_0_Vector3 = float3(_Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float, 0, _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float);
                    float3 _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3;
                    Unity_Add_float3(_Vector3_7a8d4565538e42afa8736738c67b58db_Out_0_Vector3, IN.ObjectSpacePosition, _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3);
                    float4 _UV_29277badca194b1fa427eb5e1ab65406_Out_0_Vector4 = IN.uv1;
                    float2 _Swizzle_ec06def59e0c478d862c238bd14e6c98_Out_1_Vector2 = _UV_29277badca194b1fa427eb5e1ab65406_Out_0_Vector4.xz;
                    Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22;
                    _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22.uv0 = IN.uv0;
                    float _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float;
                    SG_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float(10, _Swizzle_ec06def59e0c478d862c238bd14e6c98_Out_1_Vector2, true, _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22, _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float);
                    float _Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float;
                    Unity_Saturate_float(_SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float, _Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float);
                    float3 _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3;
                    Unity_Lerp_float3(IN.ObjectSpacePosition, _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3, (_Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float.xxx), _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3);
                    description.Position = _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3;
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
                    SurfaceDescription surface = (SurfaceDescription)0;
                    float4 _Property_2ec2bca0ee244e0094e78d84e3370433_Out_0_Vector4 = _BaseColor;
                    float4 _Property_4b163cfa524e47b894bc50b40abdd196_Out_0_Vector4 = _TopColor;
                    float4 _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4 = IN.uv0;
                    float _Split_d66392bab2044a9a97fb651266eee401_R_1_Float = _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4[0];
                    float _Split_d66392bab2044a9a97fb651266eee401_G_2_Float = _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4[1];
                    float _Split_d66392bab2044a9a97fb651266eee401_B_3_Float = _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4[2];
                    float _Split_d66392bab2044a9a97fb651266eee401_A_4_Float = _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4[3];
                    float4 _Lerp_93c22aaff80e4dc2b825807437590fa2_Out_3_Vector4;
                    Unity_Lerp_float4(_Property_2ec2bca0ee244e0094e78d84e3370433_Out_0_Vector4, _Property_4b163cfa524e47b894bc50b40abdd196_Out_0_Vector4, (_Split_d66392bab2044a9a97fb651266eee401_G_2_Float.xxxx), _Lerp_93c22aaff80e4dc2b825807437590fa2_Out_3_Vector4);
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
                    output.uv0 =                                        input.uv0;
                    output.uv1 =                                        input.uv1;
                
                    return output;
                }

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
                
                
                    output.uv0 = input.texCoord0;
                    output.uv2 = input.texCoord2;
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


                /*void InitializeInputData(Varyings input, SurfaceDescription surfaceDescription, out InputData inputData)
                {
                    inputData = (InputData)0;

                    inputData.positionWS = input.positionWS;

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

                    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                        inputData.shadowCoord = input.shadowCoord;
                    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
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

                PackedVaryings vert(Attributes input)
                {
                    Varyings output = (Varyings)0;
                    output = BuildVaryings(input);
                    PackedVaryings packedOutput = (PackedVaryings)0;
                    packedOutput = PackVaryings(output);
                    return packedOutput;
                }

                void frag(
                    PackedVaryings packedInput
                    , out half4 outColor : SV_Target0
                    #ifdef _WRITE_RENDERING_LAYERS
                        , out float4 outRenderingLayers : SV_Target1
                    #endif
                )
                {
                    Varyings unpacked = UnpackVaryings(packedInput);
                    UNITY_SETUP_INSTANCE_ID(unpacked);
                    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(unpacked);
                    SurfaceDescription surfaceDescription = BuildSurfaceDescription(unpacked);

                    #if defined(_SURFACE_TYPE_TRANSPARENT)
                        bool isTransparent = true;
                    #else
                        bool isTransparent = false;
                    #endif

                    #if defined(_ALPHATEST_ON)
                        half alpha = AlphaDiscard(surfaceDescription.Alpha, surfaceDescription.AlphaClipThreshold);
                    #elif defined(_SURFACE_TYPE_TRANSPARENT)
                        half alpha = surfaceDescription.Alpha;
                    #else
                        half alpha = half(1.0);
                    #endif

                    #if defined(LOD_FADE_CROSSFADE) && USE_UNITY_CROSSFADE
                        LODFadeCrossFade(unpacked.positionCS);
                    #endif

                    InputData inputData;
                    InitializeInputData(unpacked, surfaceDescription, inputData);
                    // TODO: Mip debug modes would require this, open question how to do this on ShaderGraph.
                    //SETUP_DEBUG_TEXTURE_DATA(inputData, unpacked.texCoord1.xy, _MainTex);

                    #ifdef _SPECULAR_SETUP
                        float3 specular = surfaceDescription.Specular;
                        float metallic = 1;
                    #else
                        float3 specular = 0;
                        float metallic = surfaceDescription.Metallic;
                    #endif

                    half3 normalTS = half3(0, 0, 0);
                    
                    #if defined(_NORMALMAP) && defined(_NORMAL_DROPOFF_TS)
                        normalTS = surfaceDescription.NormalTS;
                    #endif

                    SurfaceData surface;
                    surface.albedo              = surfaceDescription.BaseColor;
                    surface.metallic            = saturate(metallic);
                    surface.specular            = specular;
                    surface.smoothness          = saturate(surfaceDescription.Smoothness),
                    surface.occlusion           = surfaceDescription.Occlusion,
                    surface.emission            = surfaceDescription.Emission,
                    surface.alpha               = saturate(alpha);
                    surface.normalTS            = normalTS;
                    surface.clearCoatMask       = 0;
                    surface.clearCoatSmoothness = 1;

                    #ifdef _CLEARCOAT
                        surface.clearCoatMask       = saturate(surfaceDescription.CoatMask);
                        surface.clearCoatSmoothness = saturate(surfaceDescription.CoatSmoothness);
                    #endif

                    surface.albedo = AlphaModulate(surface.albedo, surface.alpha);

                    #ifdef _DBUFFER
                        ApplyDecalToSurfaceData(unpacked.positionCS, surface, inputData);
                    #endif

                    half4 color = UniversalFragmentPBR(inputData, surface);
                    color.rgb = MixFog(color.rgb, inputData.fogCoord);

                    color.a = OutputAlpha(color.a, isTransparent);

                    outColor = color;

                    #ifdef _WRITE_RENDERING_LAYERS
                        uint renderingLayers = GetMeshRenderingLayer();
                        outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
                    #endif
                }*/

                
                // --------------------------------------------------
                // Visual Effect Vertex Invocations
                #ifdef HAVE_VFX_MODIFICATION
                    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                #endif
        
            ENDHLSL
        }

        
        Pass
        {
            Name "GBuffer"
            Tags
            {
                "LightMode" = "UniversalGBuffer"
            }
        
            // Render State
            Cull Back
            Blend One Zero
            ZTest LEqual
            ZWrite On
            
            // Debug
            // <None>
            
            // --------------------------------------------------
            // Pass
            
            HLSLPROGRAM
            
                // Pragmas
                #pragma target 4.5
                #pragma exclude_renderers gles gles3 glcore
                #pragma multi_compile_instancing
                #pragma multi_compile_fog
                #pragma instancing_options renderinglayer
                #pragma vertex vert
                #pragma fragment frag
                
                // Keywords
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
                #define VARYINGS_NEED_TEXCOORD2
                #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
                #define VARYINGS_NEED_SHADOW_COORD
                #define FEATURES_GRAPH_VERTEX
                // WARNING: $splice Could not find named fragment 'PassInstancing' 
                #define SHADERPASS SHADERPASS_GBUFFER
                #define _FOG_FRAGMENT 1
                
                
                // custom interpolator pre-include
                // WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude'
                
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
                // WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' 
                
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
                     float4 texCoord2;
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
                     float4 texCoord2 : INTERP6;
                     float4 fogFactorAndVertexLight : INTERP7;
                     float3 positionWS : INTERP8;
                     float3 normalWS : INTERP9;
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
                    output.texCoord2.xyzw = input.texCoord2;
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
                    output.texCoord2 = input.texCoord2.xyzw;
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
                float4 _BaseColor;
                float4 _TopColor;
                float _RandomJitterRadius;
                float4 _WindTexture_TexelSize;
                float _WindFrequency;
                float _WindAmplitude;
                float _ShadowLightness;
                CBUFFER_END
                
                
                // Object and Global properties
                TEXTURE2D(_WindTexture);
                SAMPLER(sampler_WindTexture);
                
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
                
                void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
                {
                     float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
                     Out = lerp(Min, Max, randomno);
                }
                
                void Unity_Multiply_float_float(float A, float B, out float Out)
                {
                    Out = A * B;
                }
                
                void Unity_Add_float3(float3 A, float3 B, out float3 Out)
                {
                    Out = A + B;
                }
                
                void Unity_OneMinus_float2(float2 In, out float2 Out)
                {
                    Out = 1 - In;
                }
                
                void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
                {
                Out = A * B;
                }
                
                void Unity_Saturate_float(float In, out float Out)
                {
                    Out = saturate(In);
                }
                
                struct Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float
                {
                half4 uv0;
                };
                
                void SG_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float(float _Size, float2 _UV2, bool _UV2_b0c2d170e89c429aa65609e27d9c0451_IsConnected, Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float IN, out float OutVector1_1)
                {
                float2 _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2 = _UV2;
                bool _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2_IsConnected = _UV2_b0c2d170e89c429aa65609e27d9c0451_IsConnected;
                float4 _UV_f1dfde6948824ade8a9d0a9bc2f502ba_Out_0_Vector4 = IN.uv0;
                float2 _BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2 = _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2_IsConnected ? _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2 : (_UV_f1dfde6948824ade8a9d0a9bc2f502ba_Out_0_Vector4.xy);
                float2 _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2;
                Unity_OneMinus_float2(_BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2, _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2);
                float2 _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2;
                Unity_Multiply_float2_float2(_BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2, _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2, _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2);
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_R_1_Float = _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2[0];
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_G_2_Float = _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2[1];
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_B_3_Float = 0;
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_A_4_Float = 0;
                float _Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float;
                Unity_Multiply_float_float(_Split_5f7b1227f3084bafaef1b62cca64b3f1_R_1_Float, _Split_5f7b1227f3084bafaef1b62cca64b3f1_G_2_Float, _Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float);
                float _Property_0c675402eb3b47908659ab27249b6351_Out_0_Float = _Size;
                float _Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float;
                Unity_Multiply_float_float(_Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float, _Property_0c675402eb3b47908659ab27249b6351_Out_0_Float, _Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float);
                float _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float;
                Unity_Saturate_float(_Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float, _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float);
                OutVector1_1 = _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float;
                }
                
                void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
                {
                    Out = lerp(A, B, T);
                }
                
                void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
                {
                    Out = lerp(A, B, T);
                }
                
                // Custom interpolators pre vertex
                // WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex'
                
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
                    float4 _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4 = IN.uv1;
                    float _Swizzle_743d174ad02f45f6a3db534c28bef35c_Out_1_Float = _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4.z;
                    float _RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float;
                    Unity_RandomRange_float((_Swizzle_743d174ad02f45f6a3db534c28bef35c_Out_1_Float.xx), -1, 1, _RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float);
                    float _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float = _RandomJitterRadius;
                    float _Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float;
                    Unity_Multiply_float_float(_RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float, _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float, _Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float);
                    float _Swizzle_94c4d82bbd6c4a019354b14edaf174f5_Out_1_Float = _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4.x;
                    float _RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float;
                    Unity_RandomRange_float((_Swizzle_94c4d82bbd6c4a019354b14edaf174f5_Out_1_Float.xx), -1, 1, _RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float);
                    float _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float;
                    Unity_Multiply_float_float(_RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float, _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float, _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float);
                    float3 _Vector3_7a8d4565538e42afa8736738c67b58db_Out_0_Vector3 = float3(_Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float, 0, _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float);
                    float3 _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3;
                    Unity_Add_float3(_Vector3_7a8d4565538e42afa8736738c67b58db_Out_0_Vector3, IN.ObjectSpacePosition, _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3);
                    float4 _UV_29277badca194b1fa427eb5e1ab65406_Out_0_Vector4 = IN.uv1;
                    float2 _Swizzle_ec06def59e0c478d862c238bd14e6c98_Out_1_Vector2 = _UV_29277badca194b1fa427eb5e1ab65406_Out_0_Vector4.xz;
                    Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22;
                    _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22.uv0 = IN.uv0;
                    float _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float;
                    SG_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float(10, _Swizzle_ec06def59e0c478d862c238bd14e6c98_Out_1_Vector2, true, _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22, _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float);
                    float _Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float;
                    Unity_Saturate_float(_SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float, _Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float);
                    float3 _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3;
                    Unity_Lerp_float3(IN.ObjectSpacePosition, _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3, (_Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float.xxx), _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3);
                    description.Position = _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3;
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
                    SurfaceDescription surface = (SurfaceDescription)0;
                    float4 _Property_2ec2bca0ee244e0094e78d84e3370433_Out_0_Vector4 = _BaseColor;
                    float4 _Property_4b163cfa524e47b894bc50b40abdd196_Out_0_Vector4 = _TopColor;
                    float4 _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4 = IN.uv0;
                    float _Split_d66392bab2044a9a97fb651266eee401_R_1_Float = _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4[0];
                    float _Split_d66392bab2044a9a97fb651266eee401_G_2_Float = _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4[1];
                    float _Split_d66392bab2044a9a97fb651266eee401_B_3_Float = _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4[2];
                    float _Split_d66392bab2044a9a97fb651266eee401_A_4_Float = _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4[3];
                    float4 _Lerp_93c22aaff80e4dc2b825807437590fa2_Out_3_Vector4;
                    Unity_Lerp_float4(_Property_2ec2bca0ee244e0094e78d84e3370433_Out_0_Vector4, _Property_4b163cfa524e47b894bc50b40abdd196_Out_0_Vector4, (_Split_d66392bab2044a9a97fb651266eee401_G_2_Float.xxxx), _Lerp_93c22aaff80e4dc2b825807437590fa2_Out_3_Vector4);
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
                    output.uv0 =                                        input.uv0;
                    output.uv1 =                                        input.uv1;
                
                    return output;
                }
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
                
                
                    output.uv0 = input.texCoord0;
                    output.uv2 = input.texCoord2;
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
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRGBufferPass.hlsl"
                
                // --------------------------------------------------
                // Visual Effect Vertex Invocations
                #ifdef HAVE_VFX_MODIFICATION
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                #endif
            
            ENDHLSL
        }


        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }
        
            // Render State
            Cull Back
            ZTest LEqual
            ZWrite On
            ColorMask 0
            
            // Debug
            // <None>
            
            // --------------------------------------------------
            // Pass
            
            HLSLPROGRAM
            
                // Pragmas
                #pragma target 2.0
                #pragma multi_compile_instancing
                #pragma vertex vert
                #pragma fragment frag
                
                // Keywords
                #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
                // GraphKeywords: <None>
                
                // Defines
                
                #define _NORMALMAP 1
                #define _NORMAL_DROPOFF_TS 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define ATTRIBUTES_NEED_TEXCOORD0
                #define ATTRIBUTES_NEED_TEXCOORD1
                #define VARYINGS_NEED_NORMAL_WS
                #define FEATURES_GRAPH_VERTEX
                // WARNING: $splice Could not find named fragment 'PassInstancing' 
                #define SHADERPASS SHADERPASS_SHADOWCASTER
                
                
                // custom interpolator pre-include
                // WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude'
                
                // Includes
                #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                
                // --------------------------------------------------
                // Structs and Packing
                
                // custom interpolators pre packing
                // WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' 
                
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
                     float3 normalWS;
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
                };
                struct VertexDescriptionInputs
                {
                     float3 ObjectSpaceNormal;
                     float3 ObjectSpaceTangent;
                     float3 ObjectSpacePosition;
                     float4 uv0;
                     float4 uv1;
                };
                struct PackedVaryings
                {
                     float4 positionCS : SV_POSITION;
                     float3 normalWS : INTERP0;
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
                float4 _BaseColor;
                float4 _TopColor;
                float _RandomJitterRadius;
                float4 _WindTexture_TexelSize;
                float _WindFrequency;
                float _WindAmplitude;
                float _ShadowLightness;
                CBUFFER_END
                
                
                // Object and Global properties
                TEXTURE2D(_WindTexture);
                SAMPLER(sampler_WindTexture);
                
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
                
                void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
                {
                     float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
                     Out = lerp(Min, Max, randomno);
                }
                
                void Unity_Multiply_float_float(float A, float B, out float Out)
                {
                    Out = A * B;
                }
                
                void Unity_Add_float3(float3 A, float3 B, out float3 Out)
                {
                    Out = A + B;
                }
                
                void Unity_OneMinus_float2(float2 In, out float2 Out)
                {
                    Out = 1 - In;
                }
                
                void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
                {
                Out = A * B;
                }
                
                void Unity_Saturate_float(float In, out float Out)
                {
                    Out = saturate(In);
                }
                
                struct Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float
                {
                half4 uv0;
                };
                
                void SG_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float(float _Size, float2 _UV2, bool _UV2_b0c2d170e89c429aa65609e27d9c0451_IsConnected, Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float IN, out float OutVector1_1)
                {
                float2 _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2 = _UV2;
                bool _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2_IsConnected = _UV2_b0c2d170e89c429aa65609e27d9c0451_IsConnected;
                float4 _UV_f1dfde6948824ade8a9d0a9bc2f502ba_Out_0_Vector4 = IN.uv0;
                float2 _BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2 = _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2_IsConnected ? _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2 : (_UV_f1dfde6948824ade8a9d0a9bc2f502ba_Out_0_Vector4.xy);
                float2 _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2;
                Unity_OneMinus_float2(_BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2, _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2);
                float2 _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2;
                Unity_Multiply_float2_float2(_BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2, _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2, _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2);
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_R_1_Float = _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2[0];
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_G_2_Float = _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2[1];
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_B_3_Float = 0;
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_A_4_Float = 0;
                float _Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float;
                Unity_Multiply_float_float(_Split_5f7b1227f3084bafaef1b62cca64b3f1_R_1_Float, _Split_5f7b1227f3084bafaef1b62cca64b3f1_G_2_Float, _Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float);
                float _Property_0c675402eb3b47908659ab27249b6351_Out_0_Float = _Size;
                float _Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float;
                Unity_Multiply_float_float(_Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float, _Property_0c675402eb3b47908659ab27249b6351_Out_0_Float, _Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float);
                float _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float;
                Unity_Saturate_float(_Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float, _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float);
                OutVector1_1 = _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float;
                }
                
                void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
                {
                    Out = lerp(A, B, T);
                }
                
                // Custom interpolators pre vertex
                // WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex'
                
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
                    float4 _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4 = IN.uv1;
                    float _Swizzle_743d174ad02f45f6a3db534c28bef35c_Out_1_Float = _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4.z;
                    float _RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float;
                    Unity_RandomRange_float((_Swizzle_743d174ad02f45f6a3db534c28bef35c_Out_1_Float.xx), -1, 1, _RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float);
                    float _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float = _RandomJitterRadius;
                    float _Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float;
                    Unity_Multiply_float_float(_RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float, _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float, _Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float);
                    float _Swizzle_94c4d82bbd6c4a019354b14edaf174f5_Out_1_Float = _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4.x;
                    float _RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float;
                    Unity_RandomRange_float((_Swizzle_94c4d82bbd6c4a019354b14edaf174f5_Out_1_Float.xx), -1, 1, _RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float);
                    float _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float;
                    Unity_Multiply_float_float(_RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float, _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float, _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float);
                    float3 _Vector3_7a8d4565538e42afa8736738c67b58db_Out_0_Vector3 = float3(_Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float, 0, _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float);
                    float3 _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3;
                    Unity_Add_float3(_Vector3_7a8d4565538e42afa8736738c67b58db_Out_0_Vector3, IN.ObjectSpacePosition, _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3);
                    float4 _UV_29277badca194b1fa427eb5e1ab65406_Out_0_Vector4 = IN.uv1;
                    float2 _Swizzle_ec06def59e0c478d862c238bd14e6c98_Out_1_Vector2 = _UV_29277badca194b1fa427eb5e1ab65406_Out_0_Vector4.xz;
                    Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22;
                    _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22.uv0 = IN.uv0;
                    float _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float;
                    SG_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float(10, _Swizzle_ec06def59e0c478d862c238bd14e6c98_Out_1_Vector2, true, _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22, _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float);
                    float _Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float;
                    Unity_Saturate_float(_SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float, _Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float);
                    float3 _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3;
                    Unity_Lerp_float3(IN.ObjectSpacePosition, _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3, (_Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float.xxx), _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3);
                    description.Position = _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3;
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
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
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
                    output.uv0 =                                        input.uv0;
                    output.uv1 =                                        input.uv1;
                
                    return output;
                }
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
                
                    
                
                
                
                
                
                
                    #if UNITY_UV_STARTS_AT_TOP
                    #else
                    #endif
                
                
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
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"
                
                // --------------------------------------------------
                // Visual Effect Vertex Invocations
                #ifdef HAVE_VFX_MODIFICATION
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                #endif
            
            ENDHLSL
        }


        // --------------------------------------------------
        // My Shadow Pass
        /*Pass 
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
                //#pragma vertex Vertex
                //#pragma fragment Fragment
                #pragma vertex ShadowPassVertex
                #pragma fragment ShadowPassFragment

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

                // Incude our logic file
                //#include "BladeGrass.hlsl"

                float4 _BaseMap_ST;
                float4 _BaseColor;
                float _Cutoff;

                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

            ENDHLSL
        }*/

        // --------------------------------------------------
        // My Depth Pass
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


        /*Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }
        
            // Render State
            Cull Back
            ZTest LEqual
            ZWrite On
            ColorMask R
            
            // Debug
            // <None>
            
            // --------------------------------------------------
            // Pass
            
            HLSLPROGRAM
            
                // Pragmas
                #pragma target 2.0
                #pragma multi_compile_instancing
                #pragma vertex vert
                #pragma fragment frag
                
                // Keywords
                // PassKeywords: <None>
                // GraphKeywords: <None>
                
                // Defines
                
                #define _NORMALMAP 1
                #define _NORMAL_DROPOFF_TS 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define ATTRIBUTES_NEED_TEXCOORD0
                #define ATTRIBUTES_NEED_TEXCOORD1
                #define FEATURES_GRAPH_VERTEX
                // WARNING: $splice Could not find named fragment 'PassInstancing' 
                #define SHADERPASS SHADERPASS_DEPTHONLY
                
                
                // custom interpolator pre-include
                // WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude'
                
                // Includes
                #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                
                // --------------------------------------------------
                // Structs and Packing
                
                // custom interpolators pre packing
                // WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' 
                
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
                };
                struct VertexDescriptionInputs
                {
                     float3 ObjectSpaceNormal;
                     float3 ObjectSpaceTangent;
                     float3 ObjectSpacePosition;
                     float4 uv0;
                     float4 uv1;
                };
                struct PackedVaryings
                {
                     float4 positionCS : SV_POSITION;
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
                float4 _BaseColor;
                float4 _TopColor;
                float _RandomJitterRadius;
                float4 _WindTexture_TexelSize;
                float _WindFrequency;
                float _WindAmplitude;
                float _ShadowLightness;
                CBUFFER_END
                
                
                // Object and Global properties
                TEXTURE2D(_WindTexture);
                SAMPLER(sampler_WindTexture);
                
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
                
                void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
                {
                     float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
                     Out = lerp(Min, Max, randomno);
                }
                
                void Unity_Multiply_float_float(float A, float B, out float Out)
                {
                    Out = A * B;
                }
                
                void Unity_Add_float3(float3 A, float3 B, out float3 Out)
                {
                    Out = A + B;
                }
                
                void Unity_OneMinus_float2(float2 In, out float2 Out)
                {
                    Out = 1 - In;
                }
                
                void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
                {
                Out = A * B;
                }
                
                void Unity_Saturate_float(float In, out float Out)
                {
                    Out = saturate(In);
                }
                
                struct Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float
                {
                half4 uv0;
                };
                
                void SG_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float(float _Size, float2 _UV2, bool _UV2_b0c2d170e89c429aa65609e27d9c0451_IsConnected, Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float IN, out float OutVector1_1)
                {
                float2 _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2 = _UV2;
                bool _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2_IsConnected = _UV2_b0c2d170e89c429aa65609e27d9c0451_IsConnected;
                float4 _UV_f1dfde6948824ade8a9d0a9bc2f502ba_Out_0_Vector4 = IN.uv0;
                float2 _BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2 = _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2_IsConnected ? _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2 : (_UV_f1dfde6948824ade8a9d0a9bc2f502ba_Out_0_Vector4.xy);
                float2 _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2;
                Unity_OneMinus_float2(_BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2, _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2);
                float2 _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2;
                Unity_Multiply_float2_float2(_BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2, _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2, _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2);
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_R_1_Float = _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2[0];
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_G_2_Float = _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2[1];
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_B_3_Float = 0;
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_A_4_Float = 0;
                float _Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float;
                Unity_Multiply_float_float(_Split_5f7b1227f3084bafaef1b62cca64b3f1_R_1_Float, _Split_5f7b1227f3084bafaef1b62cca64b3f1_G_2_Float, _Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float);
                float _Property_0c675402eb3b47908659ab27249b6351_Out_0_Float = _Size;
                float _Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float;
                Unity_Multiply_float_float(_Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float, _Property_0c675402eb3b47908659ab27249b6351_Out_0_Float, _Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float);
                float _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float;
                Unity_Saturate_float(_Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float, _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float);
                OutVector1_1 = _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float;
                }
                
                void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
                {
                    Out = lerp(A, B, T);
                }
                
                // Custom interpolators pre vertex
                // WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex'
                
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
                    float4 _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4 = IN.uv1;
                    float _Swizzle_743d174ad02f45f6a3db534c28bef35c_Out_1_Float = _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4.z;
                    float _RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float;
                    Unity_RandomRange_float((_Swizzle_743d174ad02f45f6a3db534c28bef35c_Out_1_Float.xx), -1, 1, _RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float);
                    float _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float = _RandomJitterRadius;
                    float _Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float;
                    Unity_Multiply_float_float(_RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float, _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float, _Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float);
                    float _Swizzle_94c4d82bbd6c4a019354b14edaf174f5_Out_1_Float = _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4.x;
                    float _RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float;
                    Unity_RandomRange_float((_Swizzle_94c4d82bbd6c4a019354b14edaf174f5_Out_1_Float.xx), -1, 1, _RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float);
                    float _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float;
                    Unity_Multiply_float_float(_RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float, _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float, _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float);
                    float3 _Vector3_7a8d4565538e42afa8736738c67b58db_Out_0_Vector3 = float3(_Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float, 0, _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float);
                    float3 _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3;
                    Unity_Add_float3(_Vector3_7a8d4565538e42afa8736738c67b58db_Out_0_Vector3, IN.ObjectSpacePosition, _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3);
                    float4 _UV_29277badca194b1fa427eb5e1ab65406_Out_0_Vector4 = IN.uv1;
                    float2 _Swizzle_ec06def59e0c478d862c238bd14e6c98_Out_1_Vector2 = _UV_29277badca194b1fa427eb5e1ab65406_Out_0_Vector4.xz;
                    Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22;
                    _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22.uv0 = IN.uv0;
                    float _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float;
                    SG_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float(10, _Swizzle_ec06def59e0c478d862c238bd14e6c98_Out_1_Vector2, true, _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22, _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float);
                    float _Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float;
                    Unity_Saturate_float(_SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float, _Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float);
                    float3 _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3;
                    Unity_Lerp_float3(IN.ObjectSpacePosition, _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3, (_Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float.xxx), _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3);
                    description.Position = _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3;
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
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
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
                    output.uv0 =                                        input.uv0;
                    output.uv1 =                                        input.uv1;
                
                    return output;
                }
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
                
                    
                
                
                
                
                
                
                    #if UNITY_UV_STARTS_AT_TOP
                    #else
                    #endif
                
                
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
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"
                
                // --------------------------------------------------
                // Visual Effect Vertex Invocations
                #ifdef HAVE_VFX_MODIFICATION
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                #endif
            
            ENDHLSL
        }*/


        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }
        
            // Render State
            Cull Back
            ZTest LEqual
            ZWrite On
            
            // Debug
            // <None>
            
            // --------------------------------------------------
            // Pass
            
            HLSLPROGRAM
            
                // Pragmas
                #pragma target 2.0
                #pragma multi_compile_instancing
                #pragma vertex vert
                #pragma fragment frag
                
                // Keywords
                // PassKeywords: <None>
                // GraphKeywords: <None>
                
                // Defines
                
                #define _NORMALMAP 1
                #define _NORMAL_DROPOFF_TS 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define ATTRIBUTES_NEED_TEXCOORD0
                #define ATTRIBUTES_NEED_TEXCOORD1
                #define ATTRIBUTES_NEED_TEXCOORD2
                #define VARYINGS_NEED_NORMAL_WS
                #define VARYINGS_NEED_TANGENT_WS
                #define VARYINGS_NEED_TEXCOORD2
                #define FEATURES_GRAPH_VERTEX
                // WARNING: $splice Could not find named fragment 'PassInstancing' 
                #define SHADERPASS SHADERPASS_DEPTHNORMALS
                
                
                // custom interpolator pre-include
                // WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude'
                
                // Includes
                #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
                #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                
                // --------------------------------------------------
                // Structs and Packing
                
                // custom interpolators pre packing
                // WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' 
                
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
                     float3 normalWS;
                     float4 tangentWS;
                     float4 texCoord2;
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
                struct PackedVaryings
                {
                     float4 positionCS : SV_POSITION;
                     float4 tangentWS : INTERP0;
                     float4 texCoord2 : INTERP1;
                     float3 normalWS : INTERP2;
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
                    output.tangentWS.xyzw = input.tangentWS;
                    output.texCoord2.xyzw = input.texCoord2;
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
                    output.tangentWS = input.tangentWS.xyzw;
                    output.texCoord2 = input.texCoord2.xyzw;
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
                float4 _BaseColor;
                float4 _TopColor;
                float _RandomJitterRadius;
                float4 _WindTexture_TexelSize;
                float _WindFrequency;
                float _WindAmplitude;
                float _ShadowLightness;
                CBUFFER_END
                
                
                // Object and Global properties
                TEXTURE2D(_WindTexture);
                SAMPLER(sampler_WindTexture);
                
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
                
                void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
                {
                     float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
                     Out = lerp(Min, Max, randomno);
                }
                
                void Unity_Multiply_float_float(float A, float B, out float Out)
                {
                    Out = A * B;
                }
                
                void Unity_Add_float3(float3 A, float3 B, out float3 Out)
                {
                    Out = A + B;
                }
                
                void Unity_OneMinus_float2(float2 In, out float2 Out)
                {
                    Out = 1 - In;
                }
                
                void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
                {
                Out = A * B;
                }
                
                void Unity_Saturate_float(float In, out float Out)
                {
                    Out = saturate(In);
                }
                
                struct Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float
                {
                half4 uv0;
                };
                
                void SG_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float(float _Size, float2 _UV2, bool _UV2_b0c2d170e89c429aa65609e27d9c0451_IsConnected, Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float IN, out float OutVector1_1)
                {
                float2 _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2 = _UV2;
                bool _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2_IsConnected = _UV2_b0c2d170e89c429aa65609e27d9c0451_IsConnected;
                float4 _UV_f1dfde6948824ade8a9d0a9bc2f502ba_Out_0_Vector4 = IN.uv0;
                float2 _BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2 = _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2_IsConnected ? _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2 : (_UV_f1dfde6948824ade8a9d0a9bc2f502ba_Out_0_Vector4.xy);
                float2 _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2;
                Unity_OneMinus_float2(_BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2, _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2);
                float2 _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2;
                Unity_Multiply_float2_float2(_BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2, _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2, _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2);
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_R_1_Float = _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2[0];
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_G_2_Float = _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2[1];
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_B_3_Float = 0;
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_A_4_Float = 0;
                float _Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float;
                Unity_Multiply_float_float(_Split_5f7b1227f3084bafaef1b62cca64b3f1_R_1_Float, _Split_5f7b1227f3084bafaef1b62cca64b3f1_G_2_Float, _Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float);
                float _Property_0c675402eb3b47908659ab27249b6351_Out_0_Float = _Size;
                float _Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float;
                Unity_Multiply_float_float(_Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float, _Property_0c675402eb3b47908659ab27249b6351_Out_0_Float, _Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float);
                float _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float;
                Unity_Saturate_float(_Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float, _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float);
                OutVector1_1 = _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float;
                }
                
                void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
                {
                    Out = lerp(A, B, T);
                }
                
                // Custom interpolators pre vertex
                // WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex'
                
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
                    float4 _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4 = IN.uv1;
                    float _Swizzle_743d174ad02f45f6a3db534c28bef35c_Out_1_Float = _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4.z;
                    float _RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float;
                    Unity_RandomRange_float((_Swizzle_743d174ad02f45f6a3db534c28bef35c_Out_1_Float.xx), -1, 1, _RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float);
                    float _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float = _RandomJitterRadius;
                    float _Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float;
                    Unity_Multiply_float_float(_RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float, _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float, _Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float);
                    float _Swizzle_94c4d82bbd6c4a019354b14edaf174f5_Out_1_Float = _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4.x;
                    float _RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float;
                    Unity_RandomRange_float((_Swizzle_94c4d82bbd6c4a019354b14edaf174f5_Out_1_Float.xx), -1, 1, _RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float);
                    float _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float;
                    Unity_Multiply_float_float(_RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float, _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float, _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float);
                    float3 _Vector3_7a8d4565538e42afa8736738c67b58db_Out_0_Vector3 = float3(_Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float, 0, _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float);
                    float3 _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3;
                    Unity_Add_float3(_Vector3_7a8d4565538e42afa8736738c67b58db_Out_0_Vector3, IN.ObjectSpacePosition, _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3);
                    float4 _UV_29277badca194b1fa427eb5e1ab65406_Out_0_Vector4 = IN.uv1;
                    float2 _Swizzle_ec06def59e0c478d862c238bd14e6c98_Out_1_Vector2 = _UV_29277badca194b1fa427eb5e1ab65406_Out_0_Vector4.xz;
                    Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22;
                    _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22.uv0 = IN.uv0;
                    float _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float;
                    SG_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float(10, _Swizzle_ec06def59e0c478d862c238bd14e6c98_Out_1_Vector2, true, _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22, _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float);
                    float _Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float;
                    Unity_Saturate_float(_SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float, _Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float);
                    float3 _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3;
                    Unity_Lerp_float3(IN.ObjectSpacePosition, _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3, (_Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float.xxx), _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3);
                    description.Position = _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3;
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
                    float3 NormalTS;
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
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
                    surface.NormalTS = _Transform_41c37aa95bdf4610857b46b714d517b7_Out_1_Vector3;
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
                    output.uv0 =                                        input.uv0;
                    output.uv1 =                                        input.uv1;
                
                    return output;
                }
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
                
                
                    output.uv2 = input.texCoord2;
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
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"
                
                // --------------------------------------------------
                // Visual Effect Vertex Invocations
                #ifdef HAVE_VFX_MODIFICATION
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                #endif
            
            ENDHLSL
        }


        /*Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }
        
            // Render State
            Cull Off
            
            // Debug
            // <None>
            
            // --------------------------------------------------
            // Pass
            
            HLSLPROGRAM
            
                // Pragmas
                #pragma target 2.0
                #pragma vertex vert
                #pragma fragment frag
                
                // Keywords
                #pragma shader_feature _ EDITOR_VISUALIZATION
                // GraphKeywords: <None>
                
                // Defines
                
                #define _NORMALMAP 1
                #define _NORMAL_DROPOFF_TS 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define ATTRIBUTES_NEED_TEXCOORD0
                #define ATTRIBUTES_NEED_TEXCOORD1
                #define ATTRIBUTES_NEED_TEXCOORD2
                #define VARYINGS_NEED_TEXCOORD0
                #define VARYINGS_NEED_TEXCOORD1
                #define VARYINGS_NEED_TEXCOORD2
                #define FEATURES_GRAPH_VERTEX
                // WARNING: $splice Could not find named fragment 'PassInstancing' 
                #define SHADERPASS SHADERPASS_META
                #define _FOG_FRAGMENT 1
                
                
                // custom interpolator pre-include
                // WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude'
                
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                
                // --------------------------------------------------
                // Structs and Packing
                
                // custom interpolators pre packing
                // WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' 
                
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
                     float4 texCoord0;
                     float4 texCoord1;
                     float4 texCoord2;
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
                     float4 uv0;
                };
                struct VertexDescriptionInputs
                {
                     float3 ObjectSpaceNormal;
                     float3 ObjectSpaceTangent;
                     float3 ObjectSpacePosition;
                     float4 uv0;
                     float4 uv1;
                };
                struct PackedVaryings
                {
                     float4 positionCS : SV_POSITION;
                     float4 texCoord0 : INTERP0;
                     float4 texCoord1 : INTERP1;
                     float4 texCoord2 : INTERP2;
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
                    output.texCoord0.xyzw = input.texCoord0;
                    output.texCoord1.xyzw = input.texCoord1;
                    output.texCoord2.xyzw = input.texCoord2;
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
                    output.texCoord0 = input.texCoord0.xyzw;
                    output.texCoord1 = input.texCoord1.xyzw;
                    output.texCoord2 = input.texCoord2.xyzw;
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
                float4 _BaseColor;
                float4 _TopColor;
                float _RandomJitterRadius;
                float4 _WindTexture_TexelSize;
                float _WindFrequency;
                float _WindAmplitude;
                float _ShadowLightness;
                CBUFFER_END
                
                
                // Object and Global properties
                TEXTURE2D(_WindTexture);
                SAMPLER(sampler_WindTexture);
                
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
                
                void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
                {
                     float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
                     Out = lerp(Min, Max, randomno);
                }
                
                void Unity_Multiply_float_float(float A, float B, out float Out)
                {
                    Out = A * B;
                }
                
                void Unity_Add_float3(float3 A, float3 B, out float3 Out)
                {
                    Out = A + B;
                }
                
                void Unity_OneMinus_float2(float2 In, out float2 Out)
                {
                    Out = 1 - In;
                }
                
                void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
                {
                Out = A * B;
                }
                
                void Unity_Saturate_float(float In, out float Out)
                {
                    Out = saturate(In);
                }
                
                struct Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float
                {
                half4 uv0;
                };
                
                void SG_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float(float _Size, float2 _UV2, bool _UV2_b0c2d170e89c429aa65609e27d9c0451_IsConnected, Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float IN, out float OutVector1_1)
                {
                float2 _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2 = _UV2;
                bool _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2_IsConnected = _UV2_b0c2d170e89c429aa65609e27d9c0451_IsConnected;
                float4 _UV_f1dfde6948824ade8a9d0a9bc2f502ba_Out_0_Vector4 = IN.uv0;
                float2 _BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2 = _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2_IsConnected ? _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2 : (_UV_f1dfde6948824ade8a9d0a9bc2f502ba_Out_0_Vector4.xy);
                float2 _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2;
                Unity_OneMinus_float2(_BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2, _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2);
                float2 _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2;
                Unity_Multiply_float2_float2(_BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2, _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2, _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2);
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_R_1_Float = _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2[0];
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_G_2_Float = _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2[1];
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_B_3_Float = 0;
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_A_4_Float = 0;
                float _Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float;
                Unity_Multiply_float_float(_Split_5f7b1227f3084bafaef1b62cca64b3f1_R_1_Float, _Split_5f7b1227f3084bafaef1b62cca64b3f1_G_2_Float, _Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float);
                float _Property_0c675402eb3b47908659ab27249b6351_Out_0_Float = _Size;
                float _Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float;
                Unity_Multiply_float_float(_Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float, _Property_0c675402eb3b47908659ab27249b6351_Out_0_Float, _Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float);
                float _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float;
                Unity_Saturate_float(_Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float, _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float);
                OutVector1_1 = _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float;
                }
                
                void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
                {
                    Out = lerp(A, B, T);
                }
                
                void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
                {
                    Out = lerp(A, B, T);
                }
                
                // Custom interpolators pre vertex
                // WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex'
                
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
                    float4 _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4 = IN.uv1;
                    float _Swizzle_743d174ad02f45f6a3db534c28bef35c_Out_1_Float = _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4.z;
                    float _RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float;
                    Unity_RandomRange_float((_Swizzle_743d174ad02f45f6a3db534c28bef35c_Out_1_Float.xx), -1, 1, _RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float);
                    float _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float = _RandomJitterRadius;
                    float _Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float;
                    Unity_Multiply_float_float(_RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float, _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float, _Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float);
                    float _Swizzle_94c4d82bbd6c4a019354b14edaf174f5_Out_1_Float = _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4.x;
                    float _RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float;
                    Unity_RandomRange_float((_Swizzle_94c4d82bbd6c4a019354b14edaf174f5_Out_1_Float.xx), -1, 1, _RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float);
                    float _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float;
                    Unity_Multiply_float_float(_RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float, _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float, _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float);
                    float3 _Vector3_7a8d4565538e42afa8736738c67b58db_Out_0_Vector3 = float3(_Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float, 0, _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float);
                    float3 _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3;
                    Unity_Add_float3(_Vector3_7a8d4565538e42afa8736738c67b58db_Out_0_Vector3, IN.ObjectSpacePosition, _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3);
                    float4 _UV_29277badca194b1fa427eb5e1ab65406_Out_0_Vector4 = IN.uv1;
                    float2 _Swizzle_ec06def59e0c478d862c238bd14e6c98_Out_1_Vector2 = _UV_29277badca194b1fa427eb5e1ab65406_Out_0_Vector4.xz;
                    Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22;
                    _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22.uv0 = IN.uv0;
                    float _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float;
                    SG_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float(10, _Swizzle_ec06def59e0c478d862c238bd14e6c98_Out_1_Vector2, true, _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22, _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float);
                    float _Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float;
                    Unity_Saturate_float(_SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float, _Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float);
                    float3 _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3;
                    Unity_Lerp_float3(IN.ObjectSpacePosition, _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3, (_Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float.xxx), _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3);
                    description.Position = _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3;
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
                    float3 Emission;
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
                    float4 _Property_2ec2bca0ee244e0094e78d84e3370433_Out_0_Vector4 = _BaseColor;
                    float4 _Property_4b163cfa524e47b894bc50b40abdd196_Out_0_Vector4 = _TopColor;
                    float4 _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4 = IN.uv0;
                    float _Split_d66392bab2044a9a97fb651266eee401_R_1_Float = _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4[0];
                    float _Split_d66392bab2044a9a97fb651266eee401_G_2_Float = _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4[1];
                    float _Split_d66392bab2044a9a97fb651266eee401_B_3_Float = _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4[2];
                    float _Split_d66392bab2044a9a97fb651266eee401_A_4_Float = _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4[3];
                    float4 _Lerp_93c22aaff80e4dc2b825807437590fa2_Out_3_Vector4;
                    Unity_Lerp_float4(_Property_2ec2bca0ee244e0094e78d84e3370433_Out_0_Vector4, _Property_4b163cfa524e47b894bc50b40abdd196_Out_0_Vector4, (_Split_d66392bab2044a9a97fb651266eee401_G_2_Float.xxxx), _Lerp_93c22aaff80e4dc2b825807437590fa2_Out_3_Vector4);
                    surface.BaseColor = (_Lerp_93c22aaff80e4dc2b825807437590fa2_Out_3_Vector4.xyz);
                    surface.Emission = float3(0, 0, 0);
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
                    output.uv0 =                                        input.uv0;
                    output.uv1 =                                        input.uv1;
                
                    return output;
                }
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
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"
                
                // --------------------------------------------------
                // Visual Effect Vertex Invocations
                #ifdef HAVE_VFX_MODIFICATION
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                #endif
            
            ENDHLSL
        }*/


        /*Pass
        {
            Name "SceneSelectionPass"
            Tags
            {
                "LightMode" = "SceneSelectionPass"
            }
        
            // Render State
            Cull Off
            
            // Debug
            // <None>
            
            // --------------------------------------------------
            // Pass
            
            HLSLPROGRAM
            
                // Pragmas
                #pragma target 2.0
                #pragma vertex vert
                #pragma fragment frag
                
                // Keywords
                // PassKeywords: <None>
                // GraphKeywords: <None>
                
                // Defines
                
                #define _NORMALMAP 1
                #define _NORMAL_DROPOFF_TS 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define ATTRIBUTES_NEED_TEXCOORD0
                #define ATTRIBUTES_NEED_TEXCOORD1
                #define FEATURES_GRAPH_VERTEX
                // WARNING: $splice Could not find named fragment 'PassInstancing' 
                #define SHADERPASS SHADERPASS_DEPTHONLY
                #define SCENESELECTIONPASS 1
                #define ALPHA_CLIP_THRESHOLD 1
                
                
                // custom interpolator pre-include
                // WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude'
                
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                
                // --------------------------------------------------
                // Structs and Packing
                
                // custom interpolators pre packing
                // WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' 
                
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
                };
                struct VertexDescriptionInputs
                {
                     float3 ObjectSpaceNormal;
                     float3 ObjectSpaceTangent;
                     float3 ObjectSpacePosition;
                     float4 uv0;
                     float4 uv1;
                };
                struct PackedVaryings
                {
                     float4 positionCS : SV_POSITION;
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
                float4 _BaseColor;
                float4 _TopColor;
                float _RandomJitterRadius;
                float4 _WindTexture_TexelSize;
                float _WindFrequency;
                float _WindAmplitude;
                float _ShadowLightness;
                CBUFFER_END
                
                
                // Object and Global properties
                TEXTURE2D(_WindTexture);
                SAMPLER(sampler_WindTexture);
                
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
                
                void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
                {
                     float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
                     Out = lerp(Min, Max, randomno);
                }
                
                void Unity_Multiply_float_float(float A, float B, out float Out)
                {
                    Out = A * B;
                }
                
                void Unity_Add_float3(float3 A, float3 B, out float3 Out)
                {
                    Out = A + B;
                }
                
                void Unity_OneMinus_float2(float2 In, out float2 Out)
                {
                    Out = 1 - In;
                }
                
                void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
                {
                Out = A * B;
                }
                
                void Unity_Saturate_float(float In, out float Out)
                {
                    Out = saturate(In);
                }
                
                struct Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float
                {
                half4 uv0;
                };
                
                void SG_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float(float _Size, float2 _UV2, bool _UV2_b0c2d170e89c429aa65609e27d9c0451_IsConnected, Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float IN, out float OutVector1_1)
                {
                float2 _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2 = _UV2;
                bool _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2_IsConnected = _UV2_b0c2d170e89c429aa65609e27d9c0451_IsConnected;
                float4 _UV_f1dfde6948824ade8a9d0a9bc2f502ba_Out_0_Vector4 = IN.uv0;
                float2 _BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2 = _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2_IsConnected ? _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2 : (_UV_f1dfde6948824ade8a9d0a9bc2f502ba_Out_0_Vector4.xy);
                float2 _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2;
                Unity_OneMinus_float2(_BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2, _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2);
                float2 _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2;
                Unity_Multiply_float2_float2(_BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2, _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2, _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2);
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_R_1_Float = _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2[0];
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_G_2_Float = _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2[1];
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_B_3_Float = 0;
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_A_4_Float = 0;
                float _Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float;
                Unity_Multiply_float_float(_Split_5f7b1227f3084bafaef1b62cca64b3f1_R_1_Float, _Split_5f7b1227f3084bafaef1b62cca64b3f1_G_2_Float, _Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float);
                float _Property_0c675402eb3b47908659ab27249b6351_Out_0_Float = _Size;
                float _Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float;
                Unity_Multiply_float_float(_Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float, _Property_0c675402eb3b47908659ab27249b6351_Out_0_Float, _Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float);
                float _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float;
                Unity_Saturate_float(_Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float, _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float);
                OutVector1_1 = _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float;
                }
                
                void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
                {
                    Out = lerp(A, B, T);
                }
                
                // Custom interpolators pre vertex
                // WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex'
                
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
                    float4 _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4 = IN.uv1;
                    float _Swizzle_743d174ad02f45f6a3db534c28bef35c_Out_1_Float = _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4.z;
                    float _RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float;
                    Unity_RandomRange_float((_Swizzle_743d174ad02f45f6a3db534c28bef35c_Out_1_Float.xx), -1, 1, _RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float);
                    float _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float = _RandomJitterRadius;
                    float _Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float;
                    Unity_Multiply_float_float(_RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float, _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float, _Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float);
                    float _Swizzle_94c4d82bbd6c4a019354b14edaf174f5_Out_1_Float = _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4.x;
                    float _RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float;
                    Unity_RandomRange_float((_Swizzle_94c4d82bbd6c4a019354b14edaf174f5_Out_1_Float.xx), -1, 1, _RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float);
                    float _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float;
                    Unity_Multiply_float_float(_RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float, _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float, _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float);
                    float3 _Vector3_7a8d4565538e42afa8736738c67b58db_Out_0_Vector3 = float3(_Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float, 0, _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float);
                    float3 _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3;
                    Unity_Add_float3(_Vector3_7a8d4565538e42afa8736738c67b58db_Out_0_Vector3, IN.ObjectSpacePosition, _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3);
                    float4 _UV_29277badca194b1fa427eb5e1ab65406_Out_0_Vector4 = IN.uv1;
                    float2 _Swizzle_ec06def59e0c478d862c238bd14e6c98_Out_1_Vector2 = _UV_29277badca194b1fa427eb5e1ab65406_Out_0_Vector4.xz;
                    Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22;
                    _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22.uv0 = IN.uv0;
                    float _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float;
                    SG_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float(10, _Swizzle_ec06def59e0c478d862c238bd14e6c98_Out_1_Vector2, true, _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22, _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float);
                    float _Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float;
                    Unity_Saturate_float(_SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float, _Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float);
                    float3 _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3;
                    Unity_Lerp_float3(IN.ObjectSpacePosition, _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3, (_Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float.xxx), _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3);
                    description.Position = _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3;
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
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
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
                    output.uv0 =                                        input.uv0;
                    output.uv1 =                                        input.uv1;
                
                    return output;
                }
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
                
                    
                
                
                
                
                
                
                    #if UNITY_UV_STARTS_AT_TOP
                    #else
                    #endif
                
                
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
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"
                
                // --------------------------------------------------
                // Visual Effect Vertex Invocations
                #ifdef HAVE_VFX_MODIFICATION
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                #endif
            
            ENDHLSL
        }


        Pass
        {
            Name "ScenePickingPass"
            Tags
            {
                "LightMode" = "Picking"
            }
        
            // Render State
            Cull Back
            
            // Debug
            // <None>
            
            // --------------------------------------------------
            // Pass
            
            HLSLPROGRAM
            
                // Pragmas
                #pragma target 2.0
                #pragma vertex vert
                #pragma fragment frag
                
                // Keywords
                // PassKeywords: <None>
                // GraphKeywords: <None>
                
                // Defines
                
                #define _NORMALMAP 1
                #define _NORMAL_DROPOFF_TS 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define ATTRIBUTES_NEED_TEXCOORD0
                #define ATTRIBUTES_NEED_TEXCOORD1
                #define FEATURES_GRAPH_VERTEX
                // WARNING: $splice Could not find named fragment 'PassInstancing' 
                #define SHADERPASS SHADERPASS_DEPTHONLY
                #define SCENEPICKINGPASS 1
                #define ALPHA_CLIP_THRESHOLD 1
                
                
                // custom interpolator pre-include
                // WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude'
                
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                
                // --------------------------------------------------
                // Structs and Packing
                
                // custom interpolators pre packing
                // WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' 
                
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
                };
                struct VertexDescriptionInputs
                {
                     float3 ObjectSpaceNormal;
                     float3 ObjectSpaceTangent;
                     float3 ObjectSpacePosition;
                     float4 uv0;
                     float4 uv1;
                };
                struct PackedVaryings
                {
                     float4 positionCS : SV_POSITION;
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
                float4 _BaseColor;
                float4 _TopColor;
                float _RandomJitterRadius;
                float4 _WindTexture_TexelSize;
                float _WindFrequency;
                float _WindAmplitude;
                float _ShadowLightness;
                CBUFFER_END
                
                
                // Object and Global properties
                TEXTURE2D(_WindTexture);
                SAMPLER(sampler_WindTexture);
                
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
                
                void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
                {
                     float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
                     Out = lerp(Min, Max, randomno);
                }
                
                void Unity_Multiply_float_float(float A, float B, out float Out)
                {
                    Out = A * B;
                }
                
                void Unity_Add_float3(float3 A, float3 B, out float3 Out)
                {
                    Out = A + B;
                }
                
                void Unity_OneMinus_float2(float2 In, out float2 Out)
                {
                    Out = 1 - In;
                }
                
                void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
                {
                Out = A * B;
                }
                
                void Unity_Saturate_float(float In, out float Out)
                {
                    Out = saturate(In);
                }
                
                struct Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float
                {
                half4 uv0;
                };
                
                void SG_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float(float _Size, float2 _UV2, bool _UV2_b0c2d170e89c429aa65609e27d9c0451_IsConnected, Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float IN, out float OutVector1_1)
                {
                float2 _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2 = _UV2;
                bool _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2_IsConnected = _UV2_b0c2d170e89c429aa65609e27d9c0451_IsConnected;
                float4 _UV_f1dfde6948824ade8a9d0a9bc2f502ba_Out_0_Vector4 = IN.uv0;
                float2 _BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2 = _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2_IsConnected ? _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2 : (_UV_f1dfde6948824ade8a9d0a9bc2f502ba_Out_0_Vector4.xy);
                float2 _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2;
                Unity_OneMinus_float2(_BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2, _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2);
                float2 _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2;
                Unity_Multiply_float2_float2(_BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2, _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2, _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2);
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_R_1_Float = _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2[0];
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_G_2_Float = _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2[1];
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_B_3_Float = 0;
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_A_4_Float = 0;
                float _Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float;
                Unity_Multiply_float_float(_Split_5f7b1227f3084bafaef1b62cca64b3f1_R_1_Float, _Split_5f7b1227f3084bafaef1b62cca64b3f1_G_2_Float, _Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float);
                float _Property_0c675402eb3b47908659ab27249b6351_Out_0_Float = _Size;
                float _Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float;
                Unity_Multiply_float_float(_Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float, _Property_0c675402eb3b47908659ab27249b6351_Out_0_Float, _Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float);
                float _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float;
                Unity_Saturate_float(_Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float, _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float);
                OutVector1_1 = _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float;
                }
                
                void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
                {
                    Out = lerp(A, B, T);
                }
                
                // Custom interpolators pre vertex
                // WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex'
                
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
                    float4 _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4 = IN.uv1;
                    float _Swizzle_743d174ad02f45f6a3db534c28bef35c_Out_1_Float = _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4.z;
                    float _RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float;
                    Unity_RandomRange_float((_Swizzle_743d174ad02f45f6a3db534c28bef35c_Out_1_Float.xx), -1, 1, _RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float);
                    float _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float = _RandomJitterRadius;
                    float _Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float;
                    Unity_Multiply_float_float(_RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float, _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float, _Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float);
                    float _Swizzle_94c4d82bbd6c4a019354b14edaf174f5_Out_1_Float = _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4.x;
                    float _RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float;
                    Unity_RandomRange_float((_Swizzle_94c4d82bbd6c4a019354b14edaf174f5_Out_1_Float.xx), -1, 1, _RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float);
                    float _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float;
                    Unity_Multiply_float_float(_RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float, _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float, _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float);
                    float3 _Vector3_7a8d4565538e42afa8736738c67b58db_Out_0_Vector3 = float3(_Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float, 0, _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float);
                    float3 _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3;
                    Unity_Add_float3(_Vector3_7a8d4565538e42afa8736738c67b58db_Out_0_Vector3, IN.ObjectSpacePosition, _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3);
                    float4 _UV_29277badca194b1fa427eb5e1ab65406_Out_0_Vector4 = IN.uv1;
                    float2 _Swizzle_ec06def59e0c478d862c238bd14e6c98_Out_1_Vector2 = _UV_29277badca194b1fa427eb5e1ab65406_Out_0_Vector4.xz;
                    Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22;
                    _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22.uv0 = IN.uv0;
                    float _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float;
                    SG_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float(10, _Swizzle_ec06def59e0c478d862c238bd14e6c98_Out_1_Vector2, true, _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22, _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float);
                    float _Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float;
                    Unity_Saturate_float(_SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float, _Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float);
                    float3 _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3;
                    Unity_Lerp_float3(IN.ObjectSpacePosition, _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3, (_Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float.xxx), _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3);
                    description.Position = _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3;
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
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
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
                    output.uv0 =                                        input.uv0;
                    output.uv1 =                                        input.uv1;
                
                    return output;
                }
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
                
                    
                
                
                
                
                
                
                    #if UNITY_UV_STARTS_AT_TOP
                    #else
                    #endif
                
                
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
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"
                
                // --------------------------------------------------
                // Visual Effect Vertex Invocations
                #ifdef HAVE_VFX_MODIFICATION
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                #endif
            
            ENDHLSL
        }*/
        /*Pass
        {
            // Name: <None>
            Tags
            {
                "LightMode" = "Universal2D"
            }
        
            // Render State
            Cull Back
            Blend One Zero
            ZTest LEqual
            ZWrite On
            
            // Debug
            // <None>
            
            // --------------------------------------------------
            // Pass
            
            HLSLPROGRAM
            
                // Pragmas
                #pragma target 2.0
                #pragma vertex vert
                #pragma fragment frag
                
                // Keywords
                // PassKeywords: <None>
                // GraphKeywords: <None>
                
                // Defines
                
                #define _NORMALMAP 1
                #define _NORMAL_DROPOFF_TS 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define ATTRIBUTES_NEED_TEXCOORD0
                #define ATTRIBUTES_NEED_TEXCOORD1
                #define VARYINGS_NEED_TEXCOORD0
                #define FEATURES_GRAPH_VERTEX
                // WARNING: $splice Could not find named fragment 'PassInstancing' 
                #define SHADERPASS SHADERPASS_2D
                
                
                // custom interpolator pre-include
                // WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude'
                
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                
                // --------------------------------------------------
                // Structs and Packing
                
                // custom interpolators pre packing
                // WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' 
                
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
                     float4 texCoord0;
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
                     float4 uv0;
                };
                struct VertexDescriptionInputs
                {
                     float3 ObjectSpaceNormal;
                     float3 ObjectSpaceTangent;
                     float3 ObjectSpacePosition;
                     float4 uv0;
                     float4 uv1;
                };
                struct PackedVaryings
                {
                     float4 positionCS : SV_POSITION;
                     float4 texCoord0 : INTERP0;
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
                    output.texCoord0.xyzw = input.texCoord0;
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
                    output.texCoord0 = input.texCoord0.xyzw;
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
                float4 _BaseColor;
                float4 _TopColor;
                float _RandomJitterRadius;
                float4 _WindTexture_TexelSize;
                float _WindFrequency;
                float _WindAmplitude;
                float _ShadowLightness;
                CBUFFER_END
                
                
                // Object and Global properties
                TEXTURE2D(_WindTexture);
                SAMPLER(sampler_WindTexture);
                
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
                
                void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
                {
                     float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
                     Out = lerp(Min, Max, randomno);
                }
                
                void Unity_Multiply_float_float(float A, float B, out float Out)
                {
                    Out = A * B;
                }
                
                void Unity_Add_float3(float3 A, float3 B, out float3 Out)
                {
                    Out = A + B;
                }
                
                void Unity_OneMinus_float2(float2 In, out float2 Out)
                {
                    Out = 1 - In;
                }
                
                void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
                {
                Out = A * B;
                }
                
                void Unity_Saturate_float(float In, out float Out)
                {
                    Out = saturate(In);
                }
                
                struct Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float
                {
                half4 uv0;
                };
                
                void SG_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float(float _Size, float2 _UV2, bool _UV2_b0c2d170e89c429aa65609e27d9c0451_IsConnected, Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float IN, out float OutVector1_1)
                {
                float2 _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2 = _UV2;
                bool _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2_IsConnected = _UV2_b0c2d170e89c429aa65609e27d9c0451_IsConnected;
                float4 _UV_f1dfde6948824ade8a9d0a9bc2f502ba_Out_0_Vector4 = IN.uv0;
                float2 _BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2 = _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2_IsConnected ? _Property_13dcd70c02134da0aefd241fe4ca2f42_Out_0_Vector2 : (_UV_f1dfde6948824ade8a9d0a9bc2f502ba_Out_0_Vector4.xy);
                float2 _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2;
                Unity_OneMinus_float2(_BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2, _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2);
                float2 _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2;
                Unity_Multiply_float2_float2(_BranchOnInputConnection_5dfabc134aee4023a69b105ab6d380d8_Out_3_Vector2, _OneMinus_2b9afcb053794ef6bf8efe81899c6c4f_Out_1_Vector2, _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2);
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_R_1_Float = _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2[0];
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_G_2_Float = _Multiply_77d811f971a74f5498e088585defc6d5_Out_2_Vector2[1];
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_B_3_Float = 0;
                float _Split_5f7b1227f3084bafaef1b62cca64b3f1_A_4_Float = 0;
                float _Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float;
                Unity_Multiply_float_float(_Split_5f7b1227f3084bafaef1b62cca64b3f1_R_1_Float, _Split_5f7b1227f3084bafaef1b62cca64b3f1_G_2_Float, _Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float);
                float _Property_0c675402eb3b47908659ab27249b6351_Out_0_Float = _Size;
                float _Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float;
                Unity_Multiply_float_float(_Multiply_e66af9f66a2f481aaf5ef9f021876a93_Out_2_Float, _Property_0c675402eb3b47908659ab27249b6351_Out_0_Float, _Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float);
                float _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float;
                Unity_Saturate_float(_Multiply_a5d4c9fd59b941dda0f931eeada26695_Out_2_Float, _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float);
                OutVector1_1 = _Saturate_dba58058bda946ca9c0767cbd1d931e5_Out_1_Float;
                }
                
                void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
                {
                    Out = lerp(A, B, T);
                }
                
                void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
                {
                    Out = lerp(A, B, T);
                }
                
                // Custom interpolators pre vertex
                // WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex'
                
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
                    float4 _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4 = IN.uv1;
                    float _Swizzle_743d174ad02f45f6a3db534c28bef35c_Out_1_Float = _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4.z;
                    float _RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float;
                    Unity_RandomRange_float((_Swizzle_743d174ad02f45f6a3db534c28bef35c_Out_1_Float.xx), -1, 1, _RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float);
                    float _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float = _RandomJitterRadius;
                    float _Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float;
                    Unity_Multiply_float_float(_RandomRange_2e57a0deff9340c7900baf5b1a55d52e_Out_3_Float, _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float, _Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float);
                    float _Swizzle_94c4d82bbd6c4a019354b14edaf174f5_Out_1_Float = _UV_44722cd4615649f39a9e664142f2181b_Out_0_Vector4.x;
                    float _RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float;
                    Unity_RandomRange_float((_Swizzle_94c4d82bbd6c4a019354b14edaf174f5_Out_1_Float.xx), -1, 1, _RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float);
                    float _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float;
                    Unity_Multiply_float_float(_RandomRange_0085adff9e664718b92012024cd3886b_Out_3_Float, _Property_f1bcab9b20ab405ab7a0dac18d9bb2cc_Out_0_Float, _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float);
                    float3 _Vector3_7a8d4565538e42afa8736738c67b58db_Out_0_Vector3 = float3(_Multiply_9f1fb6013873461a98e38a57b3603dca_Out_2_Float, 0, _Multiply_15fbfefd2d32485ba092715f4d60ce34_Out_2_Float);
                    float3 _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3;
                    Unity_Add_float3(_Vector3_7a8d4565538e42afa8736738c67b58db_Out_0_Vector3, IN.ObjectSpacePosition, _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3);
                    float4 _UV_29277badca194b1fa427eb5e1ab65406_Out_0_Vector4 = IN.uv1;
                    float2 _Swizzle_ec06def59e0c478d862c238bd14e6c98_Out_1_Vector2 = _UV_29277badca194b1fa427eb5e1ab65406_Out_0_Vector4.xz;
                    Bindings_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22;
                    _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22.uv0 = IN.uv0;
                    float _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float;
                    SG_SGMaskRoundedEdge_12d4d53da5bb5814cbba565d7fe4aeb2_float(10, _Swizzle_ec06def59e0c478d862c238bd14e6c98_Out_1_Vector2, true, _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22, _SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float);
                    float _Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float;
                    Unity_Saturate_float(_SGMaskRoundedEdge_0f2de4298b7941f3a7fc2894c698fd22_OutVector1_1_Float, _Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float);
                    float3 _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3;
                    Unity_Lerp_float3(IN.ObjectSpacePosition, _Add_d10a85053fbf4778b073f66112d584b1_Out_2_Vector3, (_Saturate_036cfbc2df13468f970c4dd4e3d41178_Out_1_Float.xxx), _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3);
                    description.Position = _Lerp_572490d2f9894a419e9cfe11079177ab_Out_3_Vector3;
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
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
                    float4 _Property_2ec2bca0ee244e0094e78d84e3370433_Out_0_Vector4 = _BaseColor;
                    float4 _Property_4b163cfa524e47b894bc50b40abdd196_Out_0_Vector4 = _TopColor;
                    float4 _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4 = IN.uv0;
                    float _Split_d66392bab2044a9a97fb651266eee401_R_1_Float = _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4[0];
                    float _Split_d66392bab2044a9a97fb651266eee401_G_2_Float = _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4[1];
                    float _Split_d66392bab2044a9a97fb651266eee401_B_3_Float = _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4[2];
                    float _Split_d66392bab2044a9a97fb651266eee401_A_4_Float = _UV_99ad40f7837544179782e9193f97bcbf_Out_0_Vector4[3];
                    float4 _Lerp_93c22aaff80e4dc2b825807437590fa2_Out_3_Vector4;
                    Unity_Lerp_float4(_Property_2ec2bca0ee244e0094e78d84e3370433_Out_0_Vector4, _Property_4b163cfa524e47b894bc50b40abdd196_Out_0_Vector4, (_Split_d66392bab2044a9a97fb651266eee401_G_2_Float.xxxx), _Lerp_93c22aaff80e4dc2b825807437590fa2_Out_3_Vector4);
                    surface.BaseColor = (_Lerp_93c22aaff80e4dc2b825807437590fa2_Out_3_Vector4.xyz);
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
                    output.uv0 =                                        input.uv0;
                    output.uv1 =                                        input.uv1;
                
                    return output;
                }
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
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"
                
                // --------------------------------------------------
                // Visual Effect Vertex Invocations
                #ifdef HAVE_VFX_MODIFICATION
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                #endif
                
            ENDHLSL
        }*/
    }
    CustomEditor "UnityEditor.ShaderGraph.GenericShaderGraphMaterialGUI"
    CustomEditorForRenderPipeline "UnityEditor.ShaderGraphLitGUI" "UnityEngine.Rendering.Universal.UniversalRenderPipelineAsset"
    FallBack "Hidden/Shader Graph/FallbackError"
}