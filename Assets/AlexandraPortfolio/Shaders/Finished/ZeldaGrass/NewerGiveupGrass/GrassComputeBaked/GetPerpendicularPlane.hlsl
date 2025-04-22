//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

void GetPerpendicularPlane (float3 normal, out float3 tangent, out float3 bitangent) 
{
	// Calculate a tangent and bitangent. Their direction doesn't really matter as long as they're orthogonal
	tangent = cross(normal, float3(-normal.z, normal.x, normal.y));
	bitangent = cross(normal, tangent);
}

void GetPerpendicularPlane_float (float3 normal, out float3 tangent, out float3 bitangent) 
{
	// Calculate a tangent and bitangent. Their direction doesn't really matter as long as they're orthogonal
	tangent = cross(normal, float3(-normal.z, normal.x, normal.y));
	bitangent = cross(normal, tangent);
}

// Returns a pseudorandom number. By Ronja Böhringer
float rand(float4 value) {
    float4 smallValue = sin(value);
    float random = dot(smallValue, float4(12.9898, 78.233, 37.719, 09.151));
    random = frac(sin(random) * 143758.5453);
    return random;
}
float rand(float3 pos, float offset) {
    return rand(float4(pos, offset));
}

float randNegative1to1(float3 pos, float offset) {
    return rand(pos, offset) * 2 - 1;
}
void randNegative1to1_float(float3 pos, float offset, out float New) {
    New = rand(pos, offset) * 2 - 1;
}

void rotatete_float (float3 bladeAnchorOS, float3 normalOS, float3 positionOS, float _RandomJitterRadius, out float3 positionWS)
{
	float3 bladeAnchorWS = /*GetVertexPositionInputs(bladeAnchorOS).positionWS */ TransformObjectToWorld(bladeAnchorOS);
    // Get a plane perpendicular to the normal
    float3 normalWS = /*GetVertexNormalInputs(normalOS).normalWS*/ TransformObjectToWorldNormal(normalOS);
    float3 tangentWS, bitangentWS;
    GetPerpendicularPlane(normalWS, tangentWS, bitangentWS);
    // Calculate a random jitter amount based on world space position. Use the blade anchor so the entire blade
    // has the same jitter offset
    float3 randomOffset = normalWS * randNegative1to1(bladeAnchorOS, 0) + bitangentWS * randNegative1to1(bladeAnchorOS, 1);
    randomOffset *= _RandomJitterRadius;
    /*bladeAnchorWS += randomOffset; // Apply jitter to the anchor for wind

    // Calculate the wind axis, which also encodes the wind strength
    // The windUV is affected by the world position and time. TRANSFORM_TEX applies _WindTexture_ST values
    float2 windUV = TRANSFORM_TEX(bladeAnchorWS.xz, _WindTexture) + _Time.y * _WindFrequency;
    // Sample the wind noise texture and remap it to range between -1 and 1
    float2 windNoise = SAMPLE_TEXTURE2D_LOD(_WindTexture, sampler_WindTexture, windUV, 0).xy * 2 - 1;
    // Offset blade points in a vector perpendular to it's normal, but also consistent
    // across blades.
    float3 windOffset = cross(normalWS, float3(windNoise.x, 0, windNoise.y));
    // Then scale by the amplitude and UV.y, so points near the base of the blade are blown less
    windOffset *= _WindAmplitude * input.uv.y;*/

    positionWS = TransformObjectToWorld(positionOS) + randomOffset /*+ windOffset*/;
}