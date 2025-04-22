Shader "Custom/AgainGrass3"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _TipColor("Tip Color", Color) = (1, 1, 1, 1)
        _BladeTexture("Blade Texture", 2D) = "white" {}

        _BladeWidthMin("Blade Width (Min)", Range(0, 0.5)) = 0.02
        _BladeWidthMax("Blade Width (Max)", Range(0, 0.5)) = 0.05
        _BladeHeightMin("Blade Height (Min)", Range(0, 2)) = 0.1
        _BladeHeightMax("Blade Height (Max)", Range(0, 2)) = 0.2

        _BladeSegments("Blade Segments", Range(1, 10)) = 3
        _BladeBendDistance("Blade Forward Amount", Float) = 0.38
        _BladeBendCurve("Blade Curvature Amount", Range(0, 2)) = 0.25

        _BendDelta("Bend Variation", Range(0, 1)) = 0.2

        _TessellationGrassDistance("Tessellation Grass Distance", Range(0.01, 2)) = 0.1

        _GrassMap("Grass Visibility Map", 2D) = "white" {}
        _GrassThreshold("Grass Visibility Threshold", Range(-0.1, 1)) = 0.5
        _GrassFalloff("Grass Visibility Fade-In Falloff", Range(0, 0.5)) = 0.05

        _WindMap("Wind Offset Map", 2D) = "bump" {}
        _WindVelocity("Wind Velocity", Vector) = (1, 0, 0, 0)
        _WindFrequency("Wind Pulse Frequency", Range(0, 1)) = 0.01
        [Space][Space][Space]
        [KeywordEnum(INTEGER, FRAC_EVEN, FRAC_ODD, POW2)] _PARTITIONING("Partition algoritm", Float) = 0
        // This allows us to choose between tessellation factor methods
        [KeywordEnum(CONSTANT, WORLD, SCREEN, WORLD_WITH_DEPTH)] _TESSELLATION_FACTOR("Tessellation mode", Float) = 0
        // This factor is applied differently per factor mode
        //  Constant: not used
        //  World: this is the ideal edge length in world units. The algorithm will try to keep all edges at this value
        //  Screen: this is the ideal edge length in screen pixels. The algorithm will try to keep all edges at this value
        //  World with depth: similar to world, except the edge length is decreased quadratically as the camera gets closer 
        _TessellationFactor("Tessellation factor", Float) = 1
        // This value is added to the tessellation factor. Use if your model should be more or less tessellated by default
        _TessellationBias("Tessellation bias", Float) = 0
        // Enable this setting to multiply a vector's green color channel into the tessellation factor
        [Toggle(_TESSELLATION_FACTOR_VCOLORS)]_TessellationFactorVColors("Multiply VColor.Green in factor", Float) = 0
        // This keyword selects a tessellation smoothing method
        //  Flat: no smoothing
        //  Phong: use Phong tessellation, as described here: http://www.klayge.org/material/4_0/PhongTess/PhongTessellation.pdf'
        //  Bezier linear normals: use bezier tessellation for poistions, as described here: https://alex.vlachos.com/graphics/CurvedPNTriangles.pdf
        //  Bezier quad normals: the same as above, except it also applies quadratic smoothing to normal vectors
        [KeywordEnum(FLAT, PHONG, BEZIER_LINEAR_NORMALS, BEZIER_QUAD_NORMALS)] _TESSELLATION_SMOOTHING("Smoothing mode", Float) = 0
        // A factor to interpolate between flat and the selected smoothing method
        _TessellationSmoothing("Smoothing factor", Range(0, 1)) = 0.75
        // If enabled, multiply the vertex's red color channel into the smoothing factor
        [Toggle(_TESSELLATION_SMOOTHING_VCOLORS)]_TessellationSmoothingVColors("Multiply VColor.Red in smoothing", Float) = 0
        // A tolerance to frustum culling. Increase if triangles disappear when on screen
        _FrustumCullTolerance("Frustum cull tolerance", Float) = 0.01
        // A tolerance to back face culling. Increase if holes appear on your mesh
        _BackFaceCullTolerance("Back face cull tolerance", Float) = 0.01

        [Space][Space][Space][Space]
        _FirstStepDistance("FSD", Float) = 40
        _DetailStepDistance("DSD", Float) = 10
        _GeomStepDistance("GSD", Float) = 9
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "TransparentCutout"
            "Queue" = "Geometry"
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100
        Cull Off

        Blend One Zero
        ZTest LEqual
        ZWrite On
        //AlphaToMask On

        HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            /*#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT*/

            #define UNITY_PI 3.14159265359f
            #define UNITY_TWO_PI 6.28318530718f
            #define BLADE_SEGMENTS 4

            #define GrassSegments 5 // segments per blade
            #define GrassBlades 4 // blades per vertex

            #define OFFSET_MULTIPLAYER 16
            
            //CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _TipColor;
                sampler2D _BladeTexture;

                float _BladeWidthMin;
                float _BladeWidthMax;
                float _BladeHeightMin;
                float _BladeHeightMax;

                float _BladeBendDistance;
                float _BladeBendCurve;

                float _BendDelta;

                float _TessellationGrassDistance;
                
                sampler2D _GrassMap;
                float4 _GrassMap_ST;
                float  _GrassThreshold;
                float  _GrassFalloff;

                sampler2D _WindMap;
                float4 _WindMap_ST;
                float2 _WindVelocity;
                float  _WindFrequency;

                float4 _ShadowColor;

                float _TessellationFactor;
                float _TessellationBias;
                float _TessellationSmoothing;
                float _FrustumCullTolerance;
                float _BackFaceCullTolerance;

                float _FirstStepDistance;
                float _DetailStepDistance;
                float _GeomStepDistance;
            //CBUFFER_END



            /*struct Attributes
            {
                float4 positionOS  : POSITION;
                float3 normalOS  : NORMAL;
                float2 uv      : TEXCOORD0;
                float4 tangent : TANGENT;
            };*/

            /*struct TessellationControlPoint //v2g
            {
                float3 pos  : SV_POSITION;
                float3 normal  : NORMAL;
                float2 uv      : TEXCOORD0;
                float4 tangent : TANGENT;
            };*/

            struct VeertIn //vertex input
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float4 uv : TEXCOORD0;
                #ifdef LIGHTMAP_ON
                    float2 lightmapUV : TEXCOORD1;
                #endif
                #ifdef REQUIRES_VERTEX_COLORS
                    float4 color : COLOR;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Interpolators
            {
                float3 positionWS : TEXCOORD0;
                float4 uv         : TEXCOORD1;
                float4 tangentWS  : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            struct g2f //g2f
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS: NORMAL;
                float2 uv  : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float4 tangentWS : TEXCOORD2;
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 4); // Lightmap UVs or light probe color
                float4 fogFactorAndVertexLight  : TEXCOORD5;
                float ditherAmount : TEXCOORD6;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };



            uniform float3 _PositionMoving;

            //----------------------------------------------
            float4 GetShadopositWSsitionHClip(float3 input, float3 normal)
            {
                float3 positionWS = TransformObjectToWorld(input.xyz);
                float3 normalWS = TransformObjectToWorldNormal(normal);
         
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, 0));
         
         
                #if UNITY_REVERSED_Z
                        positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #else
                        positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #endif
                return positionCS;
            }
            float rand(float3 co)
            {
                return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
            }
            // Construct a rotation matrix that rotates around the provided axis, sourced from:
            // https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
            float3x3 AngleAxis3x3(float angle, float3 axis)
            {
                float c, s;
                sincos(angle, s, c);
         
                float t = 1 - c;
                float x = axis.x;
                float y = axis.y;
                float z = axis.z;
         
                return float3x3(
                    t * x * x + c, t * x * y - s * z, t * x * z + s * y,
                    t * x * y + s * z, t * y * y + c, t * y * z - s * x,
                    t * x * z - s * y, t * y * z + s * x, t * z * z + c
                    );
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
            float SG_MaskSquere(float2 UV, float MaskSize)
            {
                float2 uv1 = saturate(UV * MaskSize);
                float2 uv2 = saturate((1 -UV) * MaskSize);
                float2 nUV = uv1 * uv2;
                float Mask = saturate(nUV.r * nUV.g);
                return Mask;
            }
            inline float unity_noise_randomValue (float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
            }

            inline float unity_noise_interpolate (float a, float b, float t)
            {
                return (1.0-t)*a + (t*b);
            }

            inline float unity_valueNoise (float2 uv)
            {
                float2 i = floor(uv);
                float2 f = frac(uv);
                f = f * f * (3.0 - 2.0 * f);

                uv = abs(frac(uv) - 0.5);
                float2 c0 = i + float2(0.0, 0.0);
                float2 c1 = i + float2(1.0, 0.0);
                float2 c2 = i + float2(0.0, 1.0);
                float2 c3 = i + float2(1.0, 1.0);
                float r0 = unity_noise_randomValue(c0);
                float r1 = unity_noise_randomValue(c1);
                float r2 = unity_noise_randomValue(c2);
                float r3 = unity_noise_randomValue(c3);

                float bottomOfGrid = unity_noise_interpolate(r0, r1, f.x);
                float topOfGrid = unity_noise_interpolate(r2, r3, f.x);
                float t = unity_noise_interpolate(bottomOfGrid, topOfGrid, f.y);
                return t;
            }

            void Unity_SimpleNoise_float(float2 UV, float Scale, out float Out)
            {
                float t = 0.0;

                float freq = pow(2.0, float(0));
                float amp = pow(0.5, float(3-0));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                freq = pow(2.0, float(1));
                amp = pow(0.5, float(3-1));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                freq = pow(2.0, float(2));
                amp = pow(0.5, float(3-2));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                Out = t;
            }

            float3 RotatePointAroundPivot(float3 pointWS, float3 pivotWS, float3 angles) 
            {
                float3 dir = pointWS - pivotWS; // get point direction relative to pivot
                
                float sinX, cosX, sinY, cosY, sinZ, cosZ;
                sincos(angles.x, sinX, cosX);
                sincos(angles.y, sinY, cosY);
                sincos(angles.z, sinZ, cosZ);

                float3x3 rotationMatrix = float3x3(
                    cosY * cosZ, cosY * sinZ, -sinY,
                    sinX * sinY * cosZ - cosX * sinZ, 
                    sinX * sinY * sinZ + cosX * cosZ, 
                    sinX * cosY,
                    cosX * sinY * cosZ + sinX * sinZ, 
                    cosX * sinY * sinZ - sinX * cosZ, 
                    cosX * cosY
                );
                dir = mul(rotationMatrix, dir); // rotate it
                return dir + pivotWS; // calculate rotated point
                //return point; // return it
            }
            float3 CalculateSurfaceNormal(float3 p1, float3 p2, float3 p3)
            {
                float3 U = p2 - p1;
                float3 V = p3 - p1;

                float3 normal;
                normal.x = (U.y * V.z) - (U.z * V.y);
                normal.y = (U.z * V.x) - (U.x * V.z);
                normal.z = (U.x * V.y) - (U.y * V.x);

                return normalize(normal);
            }

            float GetDistanceToCamera(float3 pointWS)
            {
                float3 _Camera_Position = _WorldSpaceCameraPos;
                float resDistance = length(_Camera_Position - pointWS);
                return resDistance;
            }

            inline float2 unity_voronoi_noise_randomVector (float2 UV, float offset)
            {
                float2x2 m = float2x2(15.27, 47.63, 99.41, 89.98);
                UV = frac(sin(mul(UV, m)) * 46839.32);
                return float2(sin(UV.y*+offset)*0.5+0.5, cos(UV.x*offset)*0.5+0.5);
            }

            void Unity_Voronoi_float(float2 UV, float AngleOffset, float CellDensity, out float Out, out float Cells)
            {
                float2 g = floor(UV * CellDensity);
                float2 f = frac(UV * CellDensity);
                float t = 8.0;
                float3 res = float3(8.0, 0.0, 0.0);

                for(int y=-1; y<=1; y++)
                {
                    for(int x=-1; x<=1; x++)
                    {
                        float2 lattice = float2(x,y);
                        float2 offset = unity_voronoi_noise_randomVector(lattice + g, AngleOffset);
                        float d = distance(lattice + offset, f);
                        if(d < res.x)
                        {
                            res = float3(d, offset.x, offset.y);
                            Out = res.x;
                            Cells = res.y;
                        }
                    }
                }
            }
            void Unity_Dither_float4(float In, float2 ScreenPosition, out float Out)
            {
                float2 uv = ScreenPosition.xy * _ScreenParams.xy;
                float DITHER_THRESHOLDS[16] =
                {
                    1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
                    13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
                    4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
                    16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
                };
                uint index = (uint(uv.x) % 4) * 4 + uint(uv.y) % 4;
                Out = In - DITHER_THRESHOLDS[index];
            }
            float3 RotateAboutAxis(float3 normalizedRotationAxis, float rotationAngle, float3 pivotPoint, float3 position)
            {
                float sinHalfAngle = sin(rotationAngle * 0.5);
                float4 q = float4(normalizedRotationAxis * sinHalfAngle, cos(rotationAngle * 0.5));


                // Translate the position to be relative to the pivot point
                float3 relativePosition = position - pivotPoint;

                // Perform the quaternion rotation
                float3 rotatedPosition = 2.0 * cross(q.xyz, cross(q.xyz, relativePosition) + q.w * relativePosition) + relativePosition;

                // Translate the position back to the original coordinate system
                return rotatedPosition + pivotPoint;
            }
            float ConstantBiasScale(float inF)
            {
                return pow((inF + 1.0f), 0.5f);
            }

            /*float3 SimpleGrassWind(float2 WindDirection, float WindWeight, float WindSpeed, float WindAmplitude, float3 positWS)
            {   
                float3 res = float3(0.0f, 0.0f, 0.0f);
                float2 WindDir = normalize(WindDirection);
                float3 nWindDir =normalize(float3(-WindDirection.x, 0.0f, WindDirection.y));

                float Time_Time = _Time.y;
                float ts = Time_Time * WindSpeed * 1;
                float dotProduct = WindDir.x * positWS.x + WindDir.y * positWS.z;

                float2 WindDirByTS = WindDirection * ts;

                //def 1.024f  & 0.2f
                float2 noisePos1 = (positWS.xz / 1.024f) + dotProduct + Time_Time;
                float2 noisePos2 = (positWS.xz / 1.024f) + dotProduct + Time_Time;
                noisePos1 = ConstantBiasScale(sin(noisePos1));
                noisePos2 = ConstantBiasScale(sin(noisePos2));

                float dott = dot(WindDir, noisePos1);
                float dott2 = dot(noisePos2, noisePos2);
                float sqrtdot2 = sqrt(dott2);
                float rotationAngle = dott + sqrtdot2;

                float3 none = float3(0.0f, 0.0f, 0.0f);
                float3 pivot = none + float3(0, -WindAmplitude, 0);

                float3 npositWS = RotateAboutAxis(nWindDir, rotationAngle, pivot, none);
                npositWS = npositWS * WindWeight;
                return none + npositWS;
            }*/
            
            float3 fragmentFBM(float3 positWS, float WindSpeed, float WindAmplitude, float2 WindDirection) {
                float f = /*_FragmentFrequency*/ 1;
                float a = WindAmplitude;
                float speed = WindSpeed;
                float seed = /*_FragmentSeed*/ 1;
                float _FragmentSeedIter = 0.25f;
                float _FragmentWaveCount = 1;
                float _FragmentMaxPeak = 0.5f;
                float _FragmentPeakOffset = 0.25f;
                float _FragmentDrag = 1;
                float _FragmentFrequencyMult = 1;
                float _FragmentAmplitudeMult = 1;
                float _FragmentSpeedRamp = 1;
                float _FragmentHeight = 1;
                float3 posWS = positWS;

                float h = 0.0f;
                float2 n = 0.0f;
                
                float amplitudeSum = 0.0f;

                for (int wi = 0; wi < _FragmentWaveCount; ++wi) {
                    float2 d = normalize(float2(cos(seed), sin(seed)));

                    float x = dot(d, posWS.xz * normalize(WindDirection)) * f + _Time.y * speed;
                    float wave = a * exp(_FragmentMaxPeak * sin(x) - _FragmentPeakOffset);
                    float2 dw = f * d * (_FragmentMaxPeak * wave * cos(x));
                    
                    h += wave;
                    posWS.xz += -dw * a * _FragmentDrag;
                    
                    n += dw;
                    
                    amplitudeSum += a;
                    f *= _FragmentFrequencyMult;
                    a *= _FragmentAmplitudeMult;
                    speed *= _FragmentSpeedRamp;
                    seed += _FragmentSeedIter;
                }
                
                float3 output = float3(h, n.x, n.y) / amplitudeSum;
                output.x *= _FragmentHeight;

                return output;
            }
            float3 fragmentFBM2(float3 positWS, float WindSpeed, float WindAmplitude, float2 WindDirection) {
                float f = /*_FragmentFrequency*/ 1;
                float a = WindAmplitude;
                float speed = WindSpeed;
                float seed = /*_FragmentSeed*/ 1;
                float _FragmentSeedIter = 0.25f;
                float _FragmentWaveCount = 1;
                float _FragmentMaxPeak = 0.5f;
                float _FragmentPeakOffset = 0.25f;
                float _FragmentDrag = 1;
                float _FragmentFrequencyMult = 1;
                float _FragmentAmplitudeMult = 1;
                float _FragmentSpeedRamp = 1;
                float _FragmentHeight = 1;
                float3 posWS = positWS;

                float h = 0.0f;
                float2 n = 0.0f;
                
                float amplitudeSum = 0.0f;

                for (int wi = 0; wi < _FragmentWaveCount; ++wi) {
                    float2 d = normalize(float2(cos(seed), sin(seed)));

                    float x = dot(d, posWS.xz * normalize(WindDirection)) * f + _Time.y * speed;
                    float wave = a * exp(_FragmentMaxPeak * sin(x) - _FragmentPeakOffset);
                    float2 dw = f * d * (_FragmentMaxPeak * wave * cos(x));
                    
                    h += wave;
                    //posWS.xz += -dw * a * _FragmentDrag;
                    
                    //n += dw;
                    
                    amplitudeSum += a;
                    //f *= _FragmentFrequencyMult;
                    a *= _FragmentAmplitudeMult;
                    speed *= _FragmentSpeedRamp;
                    seed += _FragmentSeedIter;
                }
                
                float3 output = float3(h, 0.0f, 0.0f) / amplitudeSum;
                output.x *= _FragmentHeight;

                return output;
            }
            float3 SimpleGrassWind2(float2 WindDirection, float WindWeight, float WindSpeed, float WindAmplitude, float3 positWS)
            {   
                float3 res = float3(0.0f, 0.0f, 0.0f);
                //float2 WindDir = normalize(WindDirection);
                float3 nWindDir =normalize(float3(WindDirection.y, 0.0f, WindDirection.x));

                /*float Time_Time = _Time.y;
                float ts = Time_Time * WindSpeed * 1;*/
                //float dotProduct = WindDir.x * positWS.x + WindDir.y * positWS.z;

                //float2 WindDirByTS = WindDirection * ts;


                /*float dott = dot(WindDir, noisePos1);
                float dott2 = dot(noisePos2, noisePos2);
                float sqrtdot2 = sqrt(dott2);
                float rotationAngle = dott + sqrtdot2;*/

                float rotationAngle = fragmentFBM2(positWS / 1.0f, WindSpeed * 8, WindAmplitude, WindDirection).x * PI / 1;

                float3 none = float3(0.0f, 0.0f, 0.0f);
                float3 pivot = none + float3(0, -WindAmplitude, 0);

                float3 npositWS = RotateAboutAxis(nWindDir, rotationAngle, pivot, none);
                npositWS = npositWS * WindWeight;
                return none + npositWS;
            }

            float3 GetViewDirectionFromPosition(float3 positionWS) 
            {
                return normalize(GetCameraPositionWS() - positionWS);
            }
            float4 GetShadowCoord(float3 positionWS, float4 positionCS) 
            {
                // Calculate the shadow coordinate depending on the type of shadows currently in use
                #if SHADOWS_SCREEN
                    return ComputeScreenPos(positionCS);
                #else
                    return TransformWorldToShadowCoord(positionWS);
                #endif
            }

            /*float3 SimpleGrassWind(float2 WindDirection, float WindWeight, float WindSpeed, float WindAmplitude, float3 positWS)
            {   
                float3 res = float3(0.0f, 0.0f, 0.0f);
                float2 WindDir = normalize(WindDirection);
                float3 nWindDir = normalize(float3(-WindDirection.x, 0.0f, -WindDirection.y));

                float Time_Time = _Time.y;
                float ts = Time_Time * WindSpeed * 1;

                // Calculate noise for the first axis (X and Z)
                float2 WindDirByTS = WindDir * ts;
                float2 noisePos1 = positWS.xz / 1.024f + WindDirByTS;
                noisePos1 = ConstantBiasScale(sin(noisePos1));

                // Calculate noise for the second axis (X and Z)
                float2 noisePos2 = positWS.xz / 0.2f + WindDirByTS;
                noisePos2 = ConstantBiasScale(sin(noisePos2));

                // Calculate rotation for the first axis
                float dott = dot(WindDir, noisePos1);
                float sqrtdot2 = sqrt(dot(noisePos1, noisePos1));
                float rotationAngleX = dott + sqrtdot2;

                // Calculate rotation for the second axis
                float dott2 = dot(WindDir, noisePos2);
                float sqrtdot22 = sqrt(dot(noisePos2, noisePos2));
                float rotationAngleZ = dott2 + sqrtdot22;

                float3 none = float3(0.0f, 0.0f, 0.0f); 
                float3 pivot = none + float3(-WindAmplitude, -WindAmplitude, 0);

                // Rotate around both X and Z axes
                float3 npositWS = RotateAboutAxis(nWindDir, rotationAngleX, pivot, none);
                npositWS = RotateAboutAxis(nWindDir, rotationAngleZ, pivot, npositWS);

                npositWS = npositWS * WindWeight;
                return none + npositWS;
            }*/

            //#include "Tessellation.hlsl"


            //-----------------------------------------------

            Interpolators Vertex(VeertIn input) 
            {
                Interpolators output;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                VertexPositionInputs posnInputs = GetVertexPositionInputs(input.positionOS);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.positionWS = posnInputs.positionWS;
                //output.positionCS = posnInputs.positionCS;
                //output.normalWS = normalInputs.normalWS;
                output.tangentWS = float4(normalInputs.tangentWS, input.tangentOS.w); // tangent.w containts bitangent multiplier
                output.uv = /*TRANSFORM_TEX(*/input.uv/*, _MainTexture)*/; // Apply texture tiling and offset
                /*#ifdef LIGHTMAP_ON
                    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                #endif
                #ifdef REQUIRES_VERTEX_COLORS
                    output.color = input.color;
                #endif*/

                return output;
            }


            //-----------------------------------------------

            g2f TransformObjectToClip(float3 pos, float3x3 transformationMatrix, float2 uv, float3 faceNormal, float4 tangentWS, 
                float ditherAmount)
            {
                g2f output = (g2f)0;

                output.uv = uv;
                output.positionCS = TransformObjectToHClip(pos);
                //float3 faceNormal = float3(0, 1, 0);
                output.normalWS = TransformObjectToWorldNormal(faceNormal);
                output.positionWS = TransformObjectToWorld(pos);
                output.tangentWS =  tangentWS;
                output.ditherAmount = ditherAmount;
                
                /*#ifdef LIGHTMAP_ON
                    output.lightmapUV = BARYCENTRIC_INTERPOLATE(lightmapUV);
                #else
                    OUTPUT_SH(output.normalWS, output.vertexSH);
                #endif
                float fogFactor = ComputeFogFactor(output.positionCS.z);
                float3 vertexLight = VertexLighting(output.positionWS, output.normalWS);
                output.fogFactorAndVertexLight = float4(fogFactor, vertexLight);*/

                return output;
            }

            // This is the geometry shader. For each vertex on the mesh, a leaf
            // blade is created by generating additional vertices.
            [maxvertexcount(BLADE_SEGMENTS * 4 + 1)]
            void geom(point Interpolators input[1], inout TriangleStream<g2f> triStream)
            {
                Interpolators o;
                float3 pos = input[0].positionWS;
                //float3 normal = input[0].normalWS;
                float3 faceNormal = float3(0, 1, 0);
                float3 backFaceNormal = float3(0, 0, 1);
                float4 tangent = input[0].tangentWS;
                //float3 bitangent = cross(normal, tangent.xyz) * tangent.w;

                float width  = _BladeWidthMax;
                float ffff = ceil((GetDistanceToCamera(pos) - _FirstStepDistance) / (_DetailStepDistance));
                float geomDetail = ceil((GetDistanceToCamera(pos) - _FirstStepDistance) / (_GeomStepDistance));
                float ditherAmount = 1 - ffff + (GetDistanceToCamera(pos) - _FirstStepDistance) / (_DetailStepDistance) + 0.5f;
                //float ditherAmount = 1;
                //float _BLADE_SEGMENTS = round(clamp(BLADE_SEGMENTS / ffff, 1, BLADE_SEGMENTS));
                float _BLADE_SEGMENTS = BLADE_SEGMENTS;
                [branch] if((GetDistanceToCamera(pos) - _FirstStepDistance) > 0)
                {
                    _BLADE_SEGMENTS = clamp(BLADE_SEGMENTS * rcp(geomDetail), 2, BLADE_SEGMENTS);
                }

                /*float noise1;
                float noise2;
                Unity_SimpleNoise_float(input[0].uv, 200.0f, noise1);
                Unity_SimpleNoise_float(input[0].uv.yx, 200.0f, noise2);
                noise1 = lerp(-1, 1, noise1);
                noise2 = lerp(-1, 1, noise2);*/
                float3 offsetPos;
                //float sc = 100;
                SG_SGHash23(pos.xz, offsetPos);
                float voronoiOut;
                float voronoiOut2;
                float voronoiCells;
                float voronoiCells2;
                Unity_Voronoi_float(pos.xz /  40.0f, 5.0f, 5.0f, voronoiOut, voronoiCells);
                //Unity_Voronoi_float(pos.zx /  40.0f, 5.0f, 5.0f, voronoiOut2, voronoiCells2);
                offsetPos = lerp(-1, 1, offsetPos) / round(_TessellationFactor + _TessellationBias);
                offsetPos = offsetPos * SG_MaskSquere(input[0].uv.xy, 100);
                pos = pos + float3(offsetPos.x, 0, offsetPos.y) * OFFSET_MULTIPLAYER;

                //float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos) * TWO_PI + 0, float3(0, 1, -0.1));
                float3x3 facingRotationMatrix = AngleAxis3x3(pos + 0, float3(0, 1, -0.1));
     
                float3x3 transformationMatrix = facingRotationMatrix;

                
                float height = lerp(_BladeHeightMin, _BladeHeightMax, voronoiOut);
                float baseMaxHeight = height /*- (_BladeHeightMax / BLADE_SEGMENTS) * 0.75f*/;
                float bladeCurve = _BladeBendCurve - ((_BladeBendCurve / _BLADE_SEGMENTS) * 1.0f);

                //float offset = (1 - 0.3f) * 0.6f;
                //width = clamp(width * ffff, width, width * /*25*/ 3);
                [branch] if((GetDistanceToCamera(pos) - _FirstStepDistance) < 0)
                {
                    ffff = 1;
                }
                float3 prepos1_WS = pos + float3(- width / 2, 0.0f, 0.0f);
                float3 prepos2_WS = pos + float3(width / 2, 0.0f, 0.0f);
                float3 prepos3_WS = pos + float3(0.0f, height, _BladeBendCurve);
                //faceNormal = CalculateNormalWS(prepos1_WS, prepos2_WS, prepos3_WS);

                float angle = ((1 - voronoiOut) * PI - 0.5f * PI) / 3 /*1.5708*/;

                float2 WindDir = _WindVelocity.xy;
                float WindSpeed = 0.5f;
                float WindWeight = 0.000525f;
                float WindAmplitude = 80.0f/* * voronoiOut*/; //80
                prepos3_WS = prepos3_WS + SimpleGrassWind2(WindDir, WindWeight, WindSpeed, WindAmplitude, prepos3_WS) * 1.25f;
                prepos3_WS = RotatePointAroundPivot(prepos3_WS, pos + float3(0.0f, height, 0.0f), angle);
                //prepos3_WS = prepos3_WS + float3(_BladeBendCurve * -WindDir.x, 0.0f, _BladeBendCurve * -WindDir.y);
                //prepos3_WS = float3(prepos3_WS.x, prepos3_WS.y - 0.0725f, prepos3_WS.z);
                //prepos3_WS = float3(prepos3_WS.x /*+ WindAmplitude / 20*/, prepos3_WS.y /*- WindAmplitude / 10*/, prepos3_WS.z);

                // Create blade segments by adding two vertices at once.
                for (int i = 0; i < _BLADE_SEGMENTS; ++i)
                {
                    float t = i / (float)_BLADE_SEGMENTS;

                    float3 offset = float3(width * (1 - t), baseMaxHeight * t, smoothstep(0, 1, t) * bladeCurve);
                    float3 nPos = pos + offset;
                    float3 posToRotate = pos + float3(0.0f, offset.y, 0.0f);
                    nPos = nPos + SimpleGrassWind2(WindDir, WindWeight, WindSpeed, WindAmplitude, nPos) * t /** 0.95f*/;
                    nPos = RotatePointAroundPivot(nPos, posToRotate, angle);
                    float3 nPosOS = TransformWorldToObject(nPos);
                    offset = float3(-offset.x, offset.yz);
                    posToRotate = pos + float3(0.0f, offset.y, 0.0f);
                    float3 nPos2 = pos + offset;
                    nPos2 = nPos2 + SimpleGrassWind2(WindDir, WindWeight, WindSpeed, WindAmplitude, nPos2) * t /** 0.95f*/;
                    nPos2 = RotatePointAroundPivot(nPos2, posToRotate, angle);
                    float3 nPos2OS = TransformWorldToObject(nPos2);
                    faceNormal = CalculateSurfaceNormal(nPos, nPos2, prepos3_WS);
                    triStream.Append(TransformObjectToClip(nPosOS, transformationMatrix, float2(0, t), faceNormal, tangent, ditherAmount));
                    triStream.Append(TransformObjectToClip(nPos2OS, transformationMatrix, float2(1, t), faceNormal, tangent, ditherAmount));
                }

                float3 pos3_OS = TransformWorldToObject(prepos3_WS);
                triStream.Append(TransformObjectToClip(pos3_OS, transformationMatrix, float2(0.5f, 1.0f), faceNormal, tangent, ditherAmount));
                triStream.RestartStrip();

            }

        ENDHLSL

        Pass
        {
            Name "GrassPass"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM


                //--------------
                #pragma target 5.0 // 5.0 required for tessellation


                #pragma vertex Vertex
                /*#pragma hull Hull
                #pragma domain Domain*/
                #pragma geometry geom
                #pragma fragment frag


                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
                //#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
                //#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
                //#pragma multi_compile_fragment _ _SHADOWS_SOFT
                //#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
                //#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
                //#pragma multi_compile _ SHADOWS_SHADOWMASK
                //#pragma multi_compile _ DIRLIGHTMAP_COMBINED
                //#pragma multi_compile _ LIGHTMAP_ON
                #pragma multi_compile_fog
                #pragma multi_compile_instancing

                // Material keywords
                #pragma shader_feature_local _PARTITIONING_INTEGER _PARTITIONING_FRAC_EVEN _PARTITIONING_FRAC_ODD _PARTITIONING_POW2
                #pragma shader_feature_local _TESSELLATION_SMOOTHING_FLAT _TESSELLATION_SMOOTHING_PHONG _TESSELLATION_SMOOTHING_BEZIER_LINEAR_NORMALS _TESSELLATION_SMOOTHING_BEZIER_QUAD_NORMALS
                #pragma shader_feature_local _TESSELLATION_FACTOR_CONSTANT _TESSELLATION_FACTOR_WORLD _TESSELLATION_FACTOR_SCREEN _TESSELLATION_FACTOR_WORLD_WITH_DEPTH
                #pragma shader_feature_local _TESSELLATION_SMOOTHING_VCOLORS
                #pragma shader_feature_local _TESSELLATION_FACTOR_VCOLORS
                #pragma shader_feature_local _GENERATE_NORMALS_MAP _GENERATE_NORMALS_HEIGHT

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


                // The lighting sections of the frag shader taken from this helpful post by Ben Golus:
                // https://forum.unity.com/threads/water-shader-graph-transparency-and-shadows-universal-render-pipeline-order.748142/#post-5518747
                float4 frag (g2f i) : SV_Target
                {
                    float _Cutoff;
                    Unity_Dither_float4(1, i.positionCS, _Cutoff);
                    //clip(i.ditherAmount - _Cutoff);

                    float4 color = tex2D(_BladeTexture, i.uv);

                    float3x3 tangentToWorld = CreateTangentToWorld(i.normalWS, i.tangentWS.xyz, i.tangentWS.w);
                    // Calculate a tangent space normal either from the normal map or the height map
                    /*#if defined(_GENERATE_NORMALS_MAP)
                        float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv), _NormalStrength);
                    #elif defined(_GENERATE_NORMALS_HEIGHT)
                        float3 normalTS = GenerateNormalFromHeightMap(input.uv);
                    #else
                        float3 normalTS = float3(0, 0, 1);
                    #endif*/
                    float3 _Camera_Position = _WorldSpaceCameraPos;
                    float3 _Camera_Direction = -1 * mul(UNITY_MATRIX_M, transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V)) [2].xyz);
                    
                    float3 normalTS = float3(0, 0, 1);
                    float3 normalWS = normalize(TransformTangentToWorld(normalTS, tangentToWorld)); // Convert to world space
                    //normalWS *= IS_FRONT_VFACE(frontFace, 1.0, -1.0);
                    //normalTS = TransformWorldToTangentNormal(i.normalWS);

                    // Fill the various lighting and surface data structures for the PBR algorithm
                    InputData lightingInput = (InputData)0; // Found in URP/Input.hlsl
                    lightingInput.positionWS = i.positionWS;
                    lightingInput.normalWS = i.normalWS;
                    lightingInput.viewDirectionWS = GetViewDirectionFromPosition(lightingInput.positionWS);
                    lightingInput.shadowCoord = GetShadowCoord(lightingInput.positionWS, i.positionCS);
                    lightingInput.fogCoord = i.fogFactorAndVertexLight.x;
                    //lightingInput.vertexLighting = i.fogFactorAndVertexLight.yzw;
                    //lightingInput.bakedGI = SAMPLE_GI(i.lightmapUV, i.vertexSH, lightingInput.normalWS);
                    //lightingInput.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(i.positionCS);
                    //lightingInput.shadowMask = SAMPLE_SHADOWMASK(i.lightmapUV);


                    SurfaceData surface = (SurfaceData)0; // Found in URP/SurfaceData.hlsl
                    surface.albedo = lerp(_BaseColor, _TipColor, i.uv.y);
                    surface.alpha = AlphaDiscard(i.ditherAmount, _Cutoff);
                    surface.metallic = 0;
                    surface.smoothness = 0.0f;
                    surface.normalTS = normalTS;
                    surface.occlusion = 1;

                    return UniversalFragmentPBR(lightingInput, surface);
                }

                /*SurfaceDescription SurfaceDescriptionFunction(g2f i)
                {
                    float _Cutoff;
                    Unity_Dither_float4(1, i.positionCS, _Cutoff);
                    float3 normalTS = float3(0, 0, 1);

                    SurfaceDescription surface = (SurfaceDescription)0;
                    surface.BaseColor = lerp(_BaseColor, _TipColor, i.uv.y);
                    surface.Alpha = i.ditherAmount;
                    surface.Metallic = 0;
                    surface.Smoothness = 0.5f;
                    surface.NormalTS = normalTS;
                    surface.Occlusion = 1;
                    surface.AlphaClipThreshold = _Cutoff;

                    surface.BaseColor = IsGammaSpace() ? float3(0.5, 0.5, 0.5) : SRGBToLinear(float3(0.5, 0.5, 0.5));
                    surface.NormalTS = IN.TangentSpaceNormal;
                    surface.Emission = float3(0, 0, 0);
                    surface.Metallic = 0;
                    surface.Smoothness = 0.5;
                    surface.Occlusion = 1;
                    surface.Alpha = Slider_132c2f98e02c4b49b450144ea6024224;
                    surface.AlphaClipThreshold = _Dither_0544840e6c17410a96dcf87df0a9c4ca_Out_2_Float;
                    return surface;
                }*/

                /*SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(g2f i)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
                
                    output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
                
                    #if UNITY_UV_STARTS_AT_TOP
                    output.PixelPosition = float2(i.positionCS.x, (_ProjectionParams.x < 0) ? (_ScaledScreenParams.y - i.positionCS.y) : i.positionCS.y);
                    #else
                    output.PixelPosition = float2(i.positionCS.x, (_ProjectionParams.x > 0) ? (_ScaledScreenParams.y - i.positionCS.y) : i.positionCS.y);
                    #endif
                
                    output.NDCPosition = output.PixelPosition.xy / _ScaledScreenParams.xy;
                    output.NDCPosition.y = 1.0f - output.NDCPosition.y;
                
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                    #else
                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                    #endif
                    #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
            
                    return output;
                }
                #include "Varings.hlsl"
                #include "PBRForwardPass.hlsl"*/

            ENDHLSL
        }
        // shadow casting pass with empty fragment
        /*Pass
        {
            Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster" }
     
            ZWrite On
            ZTest LEqual
     
            HLSLPROGRAM
                #pragma vertex Vertex
                #pragma hull Hull
                #pragma domain Domain
                #pragma geometry geom
                #pragma fragment frag

                #define SHADERPASS_SHADOWCASTER
         
                #pragma shader_feature_local _ DISTANCE_DETAIL
         
                half4 frag(g2f input) : SV_TARGET{
                    return 1;
                 }
 
            ENDHLSL
        }*/
    }
    FallBack "Diffuse"
}
