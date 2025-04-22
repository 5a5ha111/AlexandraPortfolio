using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "PyramidBakeSettings", menuName = "NedMakesGames/PyramidBakeSettings")]
public class PyramidBakeSettings : MonoBehaviour
{
    [Tooltip("The source mesh to build off of")]
    public Mesh sourceMesh;
    [Tooltip("The submesh index of the source mesh to use")]
    public int sourceSubMeshIndex;
    [Tooltip("A scale to apply to the source mesh before generating pyramids")]
    public Vector3 scale;
    [Tooltip("A rotation to apply to the source mesh before generating pyramids. Euler angles, in degrees")]
    public Vector3 rotation;
    [Tooltip("The height of each extruded pyramid")]
    public float pyramidHeight;
    [Tooltip("How many times mesh should be tesselated")]
    public int Tesselationtimes;
    public ComputeShader computeShader;
}