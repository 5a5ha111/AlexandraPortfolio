Shader "Custom/AgainGrass"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _TipColor("Tip Color", Color) = (1, 1, 1, 1)
        _BladeTexture("Blade Texture", 2D) = "white" {}

        _BladeWidthMin("Blade Width (Min)", Range(0, 0.1)) = 0.02
        _BladeWidthMax("Blade Width (Max)", Range(0, 0.1)) = 0.05
        _BladeHeightMin("Blade Height (Min)", Range(0, 2)) = 0.1
        _BladeHeightMax("Blade Height (Max)", Range(0, 2)) = 0.2

        _BladeSegments("Blade Segments", Range(1, 10)) = 3
        _BladeBendDistance("Blade Forward Amount", Float) = 0.38
        _BladeBendCurve("Blade Curvature Amount", Range(1, 4)) = 2

        _BendDelta("Bend Variation", Range(0, 1)) = 0.2

        _TessellationGrassDistance("Tessellation Grass Distance", Range(0.01, 2)) = 0.1

        _GrassMap("Grass Visibility Map", 2D) = "white" {}
        _GrassThreshold("Grass Visibility Threshold", Range(-0.1, 1)) = 0.5
        _GrassFalloff("Grass Visibility Fade-In Falloff", Range(0, 0.5)) = 0.05

        _WindMap("Wind Offset Map", 2D) = "bump" {}
        _WindVelocity("Wind Velocity", Vector) = (1, 0, 0, 0)
        _WindFrequency("Wind Pulse Frequency", Range(0, 1)) = 0.01
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100
        Cull Off

        HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            #define UNITY_PI 3.14159265359f
            #define UNITY_TWO_PI 6.28318530718f
            #define BLADE_SEGMENTS 4

            #define GrassSegments 5 // segments per blade
            #define GrassBlades 4 // blades per vertex
            
            CBUFFER_START(UnityPerMaterial)
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
                float4 _WindVelocity;
                float  _WindFrequency;

                float4 _ShadowColor;
            CBUFFER_END


            struct Attributes
            {
                float4 positionOS  : POSITION;
                float3 normal  : NORMAL;
                float2 uv      : TEXCOORD0;
                float4 tangent : TANGENT;
            };

            struct v2g
            {
                float4 pos  : SV_POSITION;
                float3 normal  : NORMAL;
                float2 uv      : TEXCOORD0;
                float4 tangent : TANGENT;
            };

            struct g2f
            {
                float4 pos : SV_POSITION;
                float3 normal: NORMAL;
                float2 uv  : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };



            uniform float3 _PositionMoving;

            //----------------------------------------------
            float4 GetShadowPositionHClip(float3 input, float3 normal)
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

            // per new grass pos
            /*g2f GrassVertex(float3 vertexPos, float width, float height, float offset, float curve, float2 uv, float3x3 rotation, float3 faceNormal, float3 color) 
            {
                g2f OUT;
                float3 offsetvertices = vertexPos + mul(rotation, float3(width, height, curve) + float3(0, 0, offset));
                
                float3 positionWS = TransformObjectToWorld(vertexPos.xyz);
                float3 normalWS = TransformObjectToWorldNormal(faceNormal);

                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, 0));
         
                //OUT.pos = GetShadowPositionHClip(offsetvertices, faceNormal);
                OUT.normal = faceNormal;
                OUT.pos = positionCS;
                OUT.normal = faceNormal;
                //OUT.diffuseColor = color;
                OUT.uv = uv;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(vertexPos + mul(rotation, float3(width, height, curve)));
                OUT.worldPos = vertexInput.positionWS;
                //float fogFactor = ComputeFogFactor(OUT.pos.z);
                //OUT.fogFactor = fogFactor;
                return OUT;
            }*/

            g2f GrassVertex(float3 vertexPos, float width, float height, float offset, float curve, float2 uv, float3x3 rotation, float3 faceNormal, float3 color) 
            {
                g2f OUT;
                float3 offsetvertices = vertexPos + mul(rotation, float3(width, height, curve) + float3(0, 0, offset));
         
         
                OUT.pos = GetShadowPositionHClip(offsetvertices, faceNormal);
                OUT.normal = faceNormal;
                //OUT.diffuseColor = color;
                OUT.uv = uv;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(vertexPos + mul(rotation, float3(width, height, curve)));
                OUT.worldPos = vertexInput.positionWS;
                float fogFactor = ComputeFogFactor(OUT.pos.z);
                //OUT.fogFactor = fogFactor;
                return OUT;
            }


            //-----------------------------------------------
            // Regular pos shader used by typical shaders.
            v2g vert(Attributes v)
            {
                float3 v0 = v.positionOS.xyz;
     
                v2g OUT;
                OUT.pos = v.positionOS;
                OUT.normal = v.normal;
                OUT.uv = v.uv;
                //OUT.color = v.color;
         
                OUT.normal = TransformObjectToWorldNormal(v.normal);
                OUT.tangent = v.tangent;
                return OUT;
            }

            /*// pos shader which translates from object to world space.
            v2g geomVert (Attributes v)
            {
                v2g o; 
                o.pos = float4(TransformObjectToWorld(v.positionOS), 1.0f);
                o.normal = TransformObjectToWorldNormal(v.normal);
                o.tangent = v.tangent;
                o.uv = TRANSFORM_TEX(v.uv, _GrassMap);
                return o;
            }*/

            // Geometry functions derived from Roystan's tutorial:
            // https://roystan.net/articles/grass-shader.html
            // This function applies a transformation (during the geometry shader),
            // converting to clip space in the process.
            g2f TransformObjectToClip(float3 pos, float3 offset, float3x3 transformationMatrix, float2 uv)
            {
                g2f o;

                o.pos = TransformObjectToHClip(pos + mul(transformationMatrix, offset));
                o.uv = uv;
                o.worldPos = TransformObjectToWorld(pos + mul(transformationMatrix, offset));
                o.normal = float3(0, 1, 0);
                return o;
            }

            [maxvertexcount(3)]
            void geom(point v2g input[1], inout TriangleStream<g2f> triStream)
            {
                g2f o;
                float4 prePos = input[0].pos;
                //float3 pos = input[0].pos.xyz;
                float3 pos = TransformObjectToWorld(prePos);
                float3 normal = input[0].normal;
                float4 tangent = input[0].tangent;
                float3 bitangent = cross(normal, tangent.xyz) * tangent.w;

                float3x3 transformationMatrix = float3x3
                (
                    1, 0, 0,
                    0, 1, 0,
                    0, 0, 1
                );

                float3x3 facingRotationMatrix = AngleAxis3x3(rand(input[0].pos.xyz) * TWO_PI + 0, float3(0, 1, -0.1));
     
                transformationMatrix = facingRotationMatrix;

                float offset = (1 - 0.3f) * 0.6f;
                float3 faceNormal = float3(0, 1, 0);
                float3 prepos1_WS = pos + float3(-0.1f, 0.0f, 0.0f);
                float3 prepos2_WS = pos + float3(0.1f, 0.0f, 0.0f);
                float3 prepos3_WS = pos + float3(0.0f, 0.5f, 0.0f);

                float3 pos1_OS = TransformWorldToObject(prepos1_WS);
                float3 pos2_OS = TransformWorldToObject(prepos2_WS);
                float3 pos3_OS = TransformWorldToObject(prepos3_WS);
                //triStream.Append(GrassVertex(pos1_OS, -0.1f, 0.0f, offset, 0.5f, float2(1,1), transformationMatrix, faceNormal, float3(1.0f, 1.0f, 1.0f)));
                //triStream.Append(GrassVertex(pos2_OS, 0.1f, 0.0f, offset, 0.5f, float2(1,1), transformationMatrix, faceNormal, float3(1.0f, 1.0f, 1.0f)));
                //triStream.Append(GrassVertex(pos3_OS, 0.5f, 0.0f, offset, 0.5f, float2(1,1), transformationMatrix, faceNormal, float3(1.0f, 1.0f, 1.0f)));
                
                /*triStream.Append(TransformObjectToClip(pos1_OS, float3(-0.1f, 0.0f, 0.0f), transformationMatrix, float2(0.0f, 0.0f)));
                triStream.Append(TransformObjectToClip(pos2_OS, float3(0.1f, 0.0f, 0.0f), transformationMatrix, float2(0.0f, 0.0f)));
                triStream.Append(TransformObjectToClip(pos3_OS, float3(0.0f, 0.5f, 0.0f), transformationMatrix, float2(0.0f, 0.0f)));*/


                triStream.Append(TransformObjectToClip(pos1_OS, float3(0.0f, 0.0f, 0.0f), transformationMatrix, float2(0.0f, 0.0f)));
                triStream.Append(TransformObjectToClip(pos2_OS, float3(0.0f, 0.0f, 0.0f), transformationMatrix, float2(0.0f, 0.0f)));
                triStream.Append(TransformObjectToClip(pos3_OS, float3(0.0f, 0.0f, 0.0f), transformationMatrix, float2(0.0f, 0.0f)));

                triStream.RestartStrip();
            }

            /*[maxvertexcount(48)]
            void geom(point v2g IN[1], inout TriangleStream<g2f> triStream)
            {
                //-----------------------------------
                //Prop
                float _BladeForward = 0.38;
                float _BladeCurve = 2;
                float _WindSpeed = 100;
                float _Radius = 0.3;
                float _Rad = 0.06;
                float _Strength = 5;
                float3 color = float3(1,1,1);
                float _MinDist = 40;
                float _MaxDist = 60;
                float _WindStrength = 0.05;
                float _GrassHeight = 1;
                float _GrassWidth = 0.06;
                float _RandomHeight = 0.25;


                //------------------------
                float forward = rand(IN[0].pos.yyz) * _BladeForward;
                // just use an up facing normal, works nicest
                float3 faceNormal = float3(0, 1, 0);
                float3 worldPos = TransformObjectToWorld(IN[0].pos.xyz);
                // camera distance for culling 
                float distanceFromCamera = distance(worldPos, _WorldSpaceCameraPos);
                float distanceFade = 1 - saturate((distanceFromCamera - _MinDist) / _MaxDist);
                // wind
                float3 v0 = IN[0].pos.xyz;
                float3 wind1 = float3(sin(_Time.x * _WindSpeed + v0.x) + sin(_Time.x * _WindSpeed + v0.z * 2) + sin(_Time.x * _WindSpeed * 0.1 + v0.x), 0,
                    cos(_Time.x * _WindSpeed + v0.x * 2) + cos(_Time.x * _WindSpeed + v0.z));
                wind1 *= _WindStrength;
         
                // Interactivity
                float3 dis = distance(_PositionMoving, worldPos); // distance for radius
                float3 radius = 1 - saturate(dis / _Radius); // in world radius based on objects interaction radius
                float3 sphereDisp = worldPos - _PositionMoving; // position comparison
                sphereDisp *= radius; // position multiplied by radius for falloff
                                      // increase strength
                sphereDisp = clamp(sphereDisp.xyz * _Strength, -0.8, 0.8);
         
                // set vertex color
                //float3 color = (IN[0].color).rgb;
                // set grass height from tool, uncomment if youre not using the tool!
                _GrassHeight *= IN[0].uv.y;
                _GrassWidth *= IN[0].uv.x;
                _GrassHeight *= clamp(rand(IN[0].pos.xyz), 1 - _RandomHeight, 1 + _RandomHeight);
         
                // grassblades geometry
                for (int j = 0; j < (GrassBlades * distanceFade); j++)
                {
                    // set rotation and radius of the blades
                    float3x3 facingRotationMatrix = AngleAxis3x3(rand(IN[0].pos.xyz) * TWO_PI + j, float3(0, 1, -0.1));
         
                    float3x3 transformationMatrix = facingRotationMatrix;
         
                    faceNormal = mul(faceNormal, transformationMatrix);
                    float radius = j / (float)GrassBlades;
                    float offset = (1 - radius) * _Rad;
                    for (int i = 0; i < GrassSegments; i++)
                    {
                        // taper width, increase height;
                        float t = i / (float)GrassSegments;
                        float segmentHeight = _GrassHeight * t;
                        float segmentWidth = _GrassWidth * (1 - t);
         
                        // the first (0) grass segment is thinner
                        segmentWidth = i == 0 ? _GrassWidth * 0.3 : segmentWidth;
         
                        float segmentForward = pow(abs(t), _BladeCurve) * forward;
         
                        // Add below the line declaring float segmentWidth.
                        float3x3 transformMatrix = i == 0 ? facingRotationMatrix : transformationMatrix;
         
                        // first grass (0) segment does not get displaced by interactivity
                        float3 newPos = i == 0 ? v0 : v0 + ((float3(sphereDisp.x, sphereDisp.y, sphereDisp.z) + wind1) * t);
         
                        // every segment adds 2 new triangles
                        triStream.Append(GrassVertex(newPos, segmentWidth, segmentHeight, offset, segmentForward, float2(0, t), transformMatrix, faceNormal, color));
                        triStream.Append(GrassVertex(newPos, -segmentWidth, segmentHeight, offset, segmentForward, float2(1, t), transformMatrix, faceNormal, color));
                    }
                    // Add just below the loop to insert the vertex at the tip of the blade.
                    triStream.Append(GrassVertex(v0 + float3(sphereDisp.x * 1.5, sphereDisp.y, sphereDisp.z * 1.5) + wind1, 0, _GrassHeight, offset, forward, float2(0.5, 1), transformationMatrix, faceNormal, color));
                    // restart the strip to start another grass blade
                    triStream.RestartStrip();
                }
            }*/


            /*void surf (Input IN, inout SurfaceOutputStandard o)
            {
                // Albedo comes from a texture tinted by color
                fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
                o.Albedo = c.rgb;
                // Metallic and smoothness come from slider variables
                o.Metallic = _Metallic;
                o.Smoothness = _Glossiness;
                o.Alpha = c.a;
            }*/
        ENDHLSL

        Pass
        {
            Name "GrassPass"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
                //#pragma require geometry
                //#pragma require tessellation tessHW

                //#pragma pos vert
                #pragma vertex vert
                //#pragma hull hull
                //#pragma domain domain
                #pragma require geometry
                #pragma geometry geom
                #pragma fragment frag

                // The lighting sections of the frag shader taken from this helpful post by Ben Golus:
                // https://forum.unity.com/threads/water-shader-graph-transparency-and-shadows-universal-render-pipeline-order.748142/#post-5518747
                float4 frag (g2f i) : SV_Target
                {
                    float4 color = tex2D(_BladeTexture, i.uv);

                    /*#ifdef _MAIN_LIGHT_SHADOWS
                        posPositionInputs Attributes = (posPositionInputs)0;
                        Attributes.positionWS = i.worldPos;

                        float4 shadowCoord = GetShadowCoord(Attributes);
                        half shadowAttenuation = saturate(MainLightRealtimeShadow(shadowCoord) + 0.25f);
                        float4 shadowColor = lerp(0.0f, 1.0f, shadowAttenuation);
                        color *= shadowColor;
                    #endif*/

                    return color * lerp(_BaseColor, _TipColor, i.uv.y);
                }

            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
