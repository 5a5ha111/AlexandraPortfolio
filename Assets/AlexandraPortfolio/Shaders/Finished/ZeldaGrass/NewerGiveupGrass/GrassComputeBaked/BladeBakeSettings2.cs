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

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "PyramidBakeSettings", menuName = "NedMakesGames/PyramidBakeSettings")]
public class PyramidBakeSettings2 : ScriptableObject {
    [Tooltip("The source mesh to build off of")]
    public Mesh sourceMesh;
    public ComputeShader computeShader;
    [Tooltip("The submesh index of the source mesh to use")]
    public int sourceSubMeshIndex;
    [Tooltip("A scale to apply to the source mesh before generating pyramids")]
    public Vector3 scale;
    [Tooltip("A rotation to apply to the source mesh before generating pyramids. Euler angles, in degrees")]
    public Vector3 rotation;
    [Tooltip("An offset to the random function used in the compute shader")]
    public Vector3 randomOffset;
    [Tooltip("The number of segments per blade. Will be clamped by the max value in the compute shader")]
    public int numBladeSegments;
    [Tooltip("The curveature shape of a grass blade")]
    public float curvature;
    [Tooltip("The maximum bend angle of a grass blade. In degrees")]
    public float maxBendAngle;
    [Tooltip("Grass blade height")]
    public float height;
    [Tooltip("Grass blade height variance")]
    public float heightVariance;
    [Tooltip("Grass blade width")]
    public float width;
    [Tooltip("Grass blade width variance")]
    public float widthVariance;
}
