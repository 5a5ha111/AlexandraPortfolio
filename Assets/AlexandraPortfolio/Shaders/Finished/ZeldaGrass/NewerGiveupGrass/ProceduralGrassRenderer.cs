using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class ProceduralGrassRenderer : MonoBehaviour
{
    [System.Serializable] public class GrassSetings
    {
        public float grassHeight = 0.5f;
        public int maxLayers = 16;
        public bool useWorldPositionAsUv;
        public float worldPositonUVScale;

        public float lodMinCameraDistance = 1;
        public float lodMaxCameraDistance = 1;
        public float lodFactor = 2;
    }

    [SerializeField] private Mesh sourceMesh = default;
    [SerializeField] private ComputeShader grassComputeShader = default;
    [SerializeField] private ComputeShader triVertComputeshader = default;
    [SerializeField] private Material material = default;

    [SerializeField] private GrassSetings grassSetings = default;

    [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
    private struct SourceVertex
    {
        public Vector3 position; 
        public Vector3 normal;
        public Vector2 uv;
    }

    private bool initialized;
    private ComputeBuffer sourceVertBuffer;
    private ComputeBuffer sourceTriBuffer;
    private ComputeBuffer drawBuffer;
    private ComputeBuffer argsBuffer;

    private ComputeShader instantiatedGrassComputeShader;
    private ComputeShader instantiatedTriToVertComuteShader;
    private Material instantiatedMaterial;

    private int idGrassKernel;
    private int idTriKernel;
    private int dispatchSize;
    private Bounds localBounds;

    // The size of one entry into the various compute buffers
    private const int SOURCE_VERT_STRIDE = sizeof(float) * (3 + 3 + 2); // postion + normal + UV
    private const int SOURCE_TRI_STRIDE = sizeof(int);
    private const int DRAW_STRIDE = sizeof(float) * (2 + (3 + 3 + 2) * 3); // height + 3 * (position + normal + UV)
    private const int ARGS_STRIDE = sizeof(int) * 4;


    private void OnEnable()
    {
        if (initialized)
        {
            OnDisable();
        }
        initialized = true;

        // Instantiate the shaders so they can point to their own buffers
        instantiatedGrassComputeShader = Instantiate(grassComputeShader);
        instantiatedTriToVertComuteShader = Instantiate(triVertComputeshader);
        instantiatedMaterial = Instantiate(material);

        Vector3[] positions = sourceMesh.vertices;
        Vector3[] normals = sourceMesh.normals;
        Vector2[] uvs = sourceMesh.uv;
        int[] tris = sourceMesh.triangles;

        SourceVertex[] vertices = new SourceVertex[positions.Length];
        for (int i = 0; i < vertices.Length; i++)
        {
            vertices[i] = new SourceVertex()
            {
                position = positions[i],
                normal = normals[i],
                uv = uvs[i],
            };
        }
        int numTriangles = tris.Length / 3;


        sourceVertBuffer = new ComputeBuffer(vertices.Length, SOURCE_VERT_STRIDE, ComputeBufferType.Structured, ComputeBufferMode.Immutable);
        sourceVertBuffer.SetData(vertices);
        sourceTriBuffer = new ComputeBuffer(tris.Length, SOURCE_TRI_STRIDE, ComputeBufferType.Structured, ComputeBufferMode.Immutable);
        sourceTriBuffer.SetData(tris);
        drawBuffer = new ComputeBuffer(numTriangles * grassSetings.maxLayers, DRAW_STRIDE, ComputeBufferType.Append);
        drawBuffer.SetCounterValue(0);
        argsBuffer = new ComputeBuffer(1, ARGS_STRIDE, ComputeBufferType.IndirectArguments);
        // The data in the args buffer correspond to:
        // 0: vertex count per draw instance. We will only use one instance
        // 1: instance count. One
        // 2: start vertex location if using a Graphics Buffer
        // 3: and start instance location if using a Graphics Buffer
        argsBuffer.SetData(new int[] { 0, 1, 0, 0 });

        idGrassKernel = grassComputeShader.FindKernel("Main");
        idTriKernel = triVertComputeshader.FindKernel("Main");

        instantiatedGrassComputeShader.SetBuffer(idGrassKernel, "_SourceVertices", sourceVertBuffer);
        instantiatedGrassComputeShader.SetBuffer(idGrassKernel, "_SourceTriangles", sourceTriBuffer);
        instantiatedGrassComputeShader.SetBuffer(idGrassKernel, "_DrawTriangles", drawBuffer);

        instantiatedGrassComputeShader.SetInt("_NumSourceTriangles", numTriangles);
        instantiatedGrassComputeShader.SetFloat("_TotalHeight", grassSetings.grassHeight);
        instantiatedGrassComputeShader.SetFloat("_MaxLayers", grassSetings.maxLayers);
        instantiatedGrassComputeShader.SetFloat("_WorldPositionToUVScale", grassSetings.worldPositonUVScale);
        if (grassSetings.useWorldPositionAsUv)
        {
            instantiatedGrassComputeShader.EnableKeyword("USE_WORLD_POSITION_AS_UV");
        }
        instantiatedGrassComputeShader.SetFloat("_CameraDistanceMin", grassSetings.lodMinCameraDistance);
        instantiatedGrassComputeShader.SetFloat("_CameraDistanceMax", grassSetings.lodMaxCameraDistance);
        instantiatedGrassComputeShader.SetFloat("_CameraDistanceFactor", Mathf.Max(0, grassSetings.lodFactor));

        instantiatedTriToVertComuteShader.SetBuffer(idTriKernel, "_IndirectArgsBuffer", argsBuffer);

        instantiatedMaterial.SetBuffer("_DrawTriangles", drawBuffer);

        // Calculate the number of threads to use. Get the thread size from the kernel
        // Then, divide the number of triangles by that size
        instantiatedGrassComputeShader.GetKernelThreadGroupSizes(idGrassKernel, out uint threadGroupSize, out _, out _);
        dispatchSize = Mathf.CeilToInt((float)numTriangles / threadGroupSize);

        // Get the bounds of the source mesh
        localBounds = sourceMesh.bounds;
        localBounds.Expand(grassSetings.grassHeight);
    }

    private void OnDisable()
    {
        // Dispose of buffers and copied shaders here
        if (initialized)
        {
            //If the application is not in play mode, we have to call DestroyImmediate
            if (Application.isPlaying)
            {
                Destroy(instantiatedGrassComputeShader);
                Destroy(instantiatedTriToVertComuteShader);
                Destroy(instantiatedMaterial);
            }
            else
            {
                DestroyImmediate(instantiatedGrassComputeShader);
                DestroyImmediate(instantiatedTriToVertComuteShader);
                DestroyImmediate(instantiatedMaterial);
            }
            // Release each buffer
            sourceVertBuffer.Release();
            sourceTriBuffer.Release();
            drawBuffer.Release();
            argsBuffer.Release();
        }
        initialized = false;
    }

    /// <summary>
    /// Transform bounds to world space
    /// </summary>
    /// <param name="boundOS"></param>
    /// <returns></returns>
    public Bounds TransformBounds(Bounds boundOS)
    {
        var center = transform.TransformPoint(boundOS.center);

        // transform the local extents' axes
        var extents = boundOS.extents;
        var axisX = transform.TransformVector(extents.x, 0, 0);
        var axisY = transform.TransformVector(0, extents.y, 0);
        var axisZ = transform.TransformVector(0, 0, extents.z);

        extents.x = Mathf.Abs(axisX.x) + Mathf.Abs(axisY.x) + Mathf.Abs(axisZ.x);
        extents.y = Mathf.Abs(axisX.y) + Mathf.Abs(axisY.y) + Mathf.Abs(axisZ.y);
        extents.z = Mathf.Abs(axisX.z) + Mathf.Abs(axisY.z) + Mathf.Abs(axisZ.z);

        return new Bounds { center = center, extents = extents };
    }

    private void LateUpdate()
    {
        // If in edit mode, we need to update the shaders each Update to make sure settings changes are applied
        // Don't worry, in edit mode, Update isn't called each frame
        if (Application.isPlaying == false)
        {
            OnDisable();
            OnEnable();
        }
        // Clear the draw buffer of last frame's data
        drawBuffer.SetCounterValue(0);

        Bounds bounds = TransformBounds(localBounds);

        // Update the shader with frame specific data
        instantiatedGrassComputeShader.SetMatrix("_LocalToWorld", transform.localToWorldMatrix);
        instantiatedGrassComputeShader.SetVector("_CameraPosition", Camera.main.transform.position);
        //Debug.Log("Camera.main.transform.position " + Camera.main.transform.position);

        instantiatedGrassComputeShader.Dispatch(idGrassKernel, dispatchSize, 1, 1);

        // Copy the count (stack size) of the draw buffer to the args buffer, at byte position zero
        // This sets the vertex count for our draw procediral indirect call
        ComputeBuffer.CopyCount(drawBuffer, argsBuffer, 0);

        // This the compute shader outputs triangles, but the graphics shader needs the number of vertices,
        // we need to multiply the vertex count by three. We'll do this on the GPU with a compute shader 
        // so we don't have to transfer data back to the CPU
        instantiatedTriToVertComuteShader.Dispatch(idTriKernel, 1, 1, 1);

        // DrawProceduralIndirect queues a draw call up for our generated mesh
        // It will receive a shadow casting pass, like normal
        Graphics.DrawProceduralIndirect(instantiatedMaterial, bounds, MeshTopology.Triangles, argsBuffer, 0,
            null, null, ShadowCastingMode.Off, true, gameObject.layer);
    }

}
