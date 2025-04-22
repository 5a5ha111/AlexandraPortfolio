// Include some helper functions
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
//#include "NMGGrassBladeGraphicsHelpers.hlsl"

// This describes a vertex on the generated mesh
/*struct DrawVertex {
    float3 positionWS; // The position in world space
    float height; // The height of this vertex on the grass blade
};
// A triangle on the generated mesh
struct DrawTriangle {
    float3 lightingNormalWS; // A normal, in world space, to use in the lighting algorithm
    DrawVertex vertices[3]; // The three points on the triangle
};*/
// A buffer containing the generated mesh
/*StructuredBuffer<DrawTriangle> _DrawTriangles;*/

 struct appdata
{
    float2 uv : TEXCOORD0;
    float4 texcoord1 : TEXCOORD1;
};

struct VertexOutput {
    float2 uv            : TEXCOORD0; // The height of this vertex on the grass blade
    float3 positionWS   : TEXCOORD1; // Position in world space
    float3 normalWS     : TEXCOORD2; // Normal vector in world space

    float4 positionCS   : SV_POSITION; // Position in clip space
    float fogCoord                  : TEXCOORD4;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 3);
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

// Properties

CBUFFER_START(UnityPerMaterial)
    float4 _BottomTint;
    float4 _TopTint;
    float _AdLightConst;
CBUFFER_END



// Returns the view direction in world space
float3 GetViewDirectionFromPosition(float3 positionWS) 
{
    return normalize(GetCameraPositionWS() - positionWS);
}

// If this is the shadow caster pass, we also need this variable, which URP sets
#ifdef SHADOW_CASTER_PASS
    float3 _LightDirection;
#endif

// Calculates the position in clip space, taking into account various strategies
// to improve shadow quality in the shadow caster pass
float4 CalculatePositionCSWithShadowCasterLogic(float3 positionWS, float3 normalWS) 
{
    float4 positionCS;

    #ifdef SHADOW_CASTER_PASS
        // From URP's ShadowCasterPass.hlsl
        // If this is the shadow caster pass, we need to adjust the clip space position to account
        // for shadow bias and offset (this helps reduce shadow artifacts)
        positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
    #if UNITY_REVERSED_Z
        positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #else
        positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #endif
    #else
        // This built in function transforms from world space to clip space
        positionCS = TransformWorldToHClip(positionWS);
    #endif

    return positionCS;
}

// Calculates the shadow texture coordinate for lighting calculations
float4 CalculateShadowCoord(float3 positionWS, float4 positionCS) 
{
    // Calculate the shadow coordinate depending on the type of shadows currently in use
    #if SHADOWS_SCREEN
        return ComputeScreenPos(positionCS);
    #else
        return TransformWorldToShadowCoord(positionWS);
    #endif
}

void Unity_Rotate_Radians_float(float2 UV, float2 Center, float Rotation, out float2 Out)
{
    UV -= Center;
    float s = sin(Rotation);
    float c = cos(Rotation);
    float2x2 rMatrix = float2x2(c, -s, s, c);
    rMatrix *= 0.5;
    rMatrix += 0.5;
    rMatrix = rMatrix * 2 - 1;
    UV.xy = mul(UV.xy, rMatrix);
    UV += Center;
    Out = UV;
}

float3 _SGRotateNormals(float3 Normal, float Rotation)
{
    float2 _CombineNormalXY = Normal.xy;
    float2 _Rotate_Res_Vector2;
    Unity_Rotate_Radians_float(_CombineNormalXY, float2 (0, 0), Rotation, _Rotate_Res_Vector2);
    return float3(_Rotate_Res_Vector2, Normal.z);
}

// Vertex functions

VertexOutput Vertex(uint vertexID: SV_VertexID, appdata v) 
{
    // Initialize the output struct
    VertexOutput output = (VertexOutput)0;

    // Get the vertex from the buffer
    // Since the buffer is structured in triangles, we need to divide the vertexID by three
    // to get the triangle, and then modulo by 3 to get the vertex on the triangle
    DrawTriangle tri = _DrawTriangles[vertexID / 3];
    DrawVertex input = tri.vertices[vertexID % 3];

    float _WindSpeed = 2;
    float _WindStrength = 0.05f;

    float3 wind1 = float3(
    sin(_Time.y * _WindSpeed + input.positionWS.x) + sin(
    _Time.y * _WindSpeed + input.positionWS.z * 2) + sin(
    _Time.y * _WindSpeed * 0.1 + input.positionWS.x), 0,
    cos(_Time.y * _WindSpeed + input.positionWS.x * 2) + cos(
    _Time.y * _WindSpeed + input.positionWS.z));
    wind1 *= _WindStrength;

    output.positionWS = input.positionWS /*+(wind1 * input.uv.y)*/;
    output.normalWS = tri.normalOS;
    output.uv = input.uv;
    output.positionCS = TransformWorldToHClip(output.positionWS);
    output.fogCoord = ComputeFogFactor(output.positionCS.z);

    OUTPUT_LIGHTMAP_UV( v.texcoord1, unity_LightmapST, output.lightmapUV );
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH );

    return output;
}

// Fragment functions

half4 Fragment(VertexOutput input) : SV_Target 
{
    // Gather some data for the lighting algorithm
    UNITY_SETUP_INSTANCE_ID(input);
    InputData lightingInput = (InputData)0;
    /*float3 _Camera_Direction = -1 * mul(UNITY_MATRIX_M, transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V)) [2].xyz);
    float d = dot(_Camera_Direction, input.normalWS);
    if (d <= 0)
    {
        lightingInput.normalWS = input.normalWS; // No need to normalize, triangles share a normal
    }
    else
    {
        lightingInput.normalWS = input.normalWS * -1;
    }*/

    half3 normalTS = half3(0, 1, 0);
    normalTS = _SGRotateNormals(input.normalWS, (input.uv.x - 0.5) * 1.5f);
    float3 _Transform_Out = mul(UNITY_MATRIX_I_V, float4(normalTS, 1)).xyz;

    /*VertexPositionInputs vertexInput = (VertexPositionInputs)0;
    vertexInput.positionWS = input.positionWS;*/
    float3 WorldPos = input.positionWS;
    half4 Shadowmask = half4(1,1,1,1);
    //Shadowmask = SAMPLE_SHADOWMASK(input.lightmapUV);

    /*float4 shadowCoord = GetShadowCoord(vertexInput);
    half shadowAttenutation = MainLightRealtimeShadow(shadowCoord);*/

    /*#if defined(_MAIN_LIGHT_SHADOWS_SCREEN) && !defined(_SURFACE_TYPE_TRANSPARENT)
    float4 shadowCoord = ComputeScreenPos(TransformWorldToHClip(WorldPos));
    #else
    float4 shadowCoord = TransformWorldToShadowCoord(WorldPos);
    #endif*/
    float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
    half ShadowAtten = MainLightShadow(shadowCoord, WorldPos, Shadowmask, _MainLightOcclusionProbes);

    Light mainLight = GetMainLight();
    ShadowAtten = MainLightRealtimeShadow(shadowCoord);
    //ShadowAtten = MainLightRealtimeShadow(TransformWorldToShadowCoord(WorldPos));


    lightingInput.normalWS = normalize(normalTS); // No need to normalize, triangles share a normal
    lightingInput.positionWS = input.positionWS;
    //lightingInput.viewDirectionWS = GetViewDirectionFromPosition(input.positionWS); // Calculate the view direction
    lightingInput.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
    //lightingInput.shadowCoord = CalculateShadowCoord(input.positionWS, input.positionCS);
    lightingInput.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
    //lightingInput.shadowCoord = input.positionCS;
    //lightingInput.positionCS = CalculatePositionCSWithShadowCasterLogic(input.positionWS, input.normalWS);
    lightingInput.positionCS = input.positionCS;
    lightingInput.bakedGI = SAMPLE_GI( input.lightmapUV, input.vertexSH, lightingInput.normalWS ) + _AdLightConst;
    lightingInput.fogCoord = input.fogCoord;

    // Lerp between the base and tip color based on the blade height
    float3 albedo = lerp(_BottomTint.rgb, _TopTint.rgb, input.uv.y);
    //albedo = lerp(albedo, albedo / 2, (1.0 - ShadowAtten));
    //albedo = _BottomTint.rgb;

    // The URP simple lit algorithm
    // The arguments are lighting input data, albedo color, specular color, smoothness, emission color, and alpha
    SurfaceData surface = (SurfaceData)0;
    surface.albedo              = albedo;
    surface.metallic            = 0;
    surface.specular            = albedo;
    surface.smoothness          = 0.1f,
    surface.occlusion           = 1,
    surface.emission            = 0,
    surface.alpha               = 1;
    surface.clearCoatMask       = 0;
    surface.clearCoatSmoothness = 0;

    surface.normalTS            = normalTS;

    // BRDFData holds energy conserving diffuse and specular material reflections and its roughness.
    // It's easy to plugin your own shading fuction. You just need replace LightingPhysicallyBased function
    // below with your own.
    //BRDFData brdfData;
    //InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);

    return UniversalFragmentPBR(lightingInput, surface);

    //return half4(albedo, 1);
}