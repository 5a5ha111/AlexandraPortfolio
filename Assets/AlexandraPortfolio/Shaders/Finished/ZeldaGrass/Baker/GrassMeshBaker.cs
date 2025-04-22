using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class GrassMeshBaker
{
    // The structure to send to the compute shader
    // This layout kind assures that the data is laid out sequentially
    [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
    private struct SourceVertex
    {
        public Vector3 position;
        public Vector2 uv;
    }

    // The structure received from the compute shader
    [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
    private struct GeneratedVertex
    {
        public Vector3 position;
        public Vector3 normal;
        public Vector2 uv;
    }

    // The size of one entry in the various compute buffers
    private const int SOURCE_VERT_STRIDE = sizeof(float) * (3 + 2);
    private const int SOURCE_INDEX_STRIDE = sizeof(int);
    private const int GENERATED_VERT_STRIDE = sizeof(float) * (3 + 3 + 2);
    private const int GENERATED_INDEX_STRIDE = sizeof(int);

    // This function takes in a mesh and submesh and decomposes it into vertex and index arrays
    // A submesh is a subset of triangles in the mesh. This might happen, for instance, if a mesh
    // has a multiple materials.
    private static void DecomposeMesh(Mesh mesh, int subMeshIndex, out SourceVertex[] verts,
        out int[] indices)
    {
        var subMesh = mesh.GetSubMesh(subMeshIndex);

        Vector3[] allVertices = mesh.vertices;
        Vector2[] allUVs = mesh.uv;
        int[] allIndices = mesh.triangles;

        verts = new SourceVertex[subMesh.vertexCount];
        indices = new int[subMesh.indexCount];
        for (int i = 0; i < subMesh.vertexCount; i++)
        {
            int wholeMeshIndex = i + subMesh.firstVertex;
            verts[i] = new SourceVertex()
            {
                position = allVertices[wholeMeshIndex],
                uv = allUVs[wholeMeshIndex]
            };
        }
        for (int i = 0;i < subMesh.indexCount; i++) 
        {
            // We need to offset the indices in the mesh index buffer to match
            // the indices in our new vertex buffer. Subtract by subMesh.firstVertex
            // .baseVertex is an offset Unity may define which is a global
            // offset for all indices in this submesh
            indices[i] = allIndices[i + subMesh.indexStart] + subMesh.baseVertex - subMesh.firstVertex;
        }
    }

    private static Mesh ComposeMesh(GeneratedVertex[] verts, int[] indices)
    {
        Mesh mesh = new Mesh();
        mesh.name = "TestBaked";
        Vector3[] vertices = new Vector3[verts.Length];
        Vector3[] normals = new Vector3[verts.Length];
        Vector2[] uvs = new Vector2[verts.Length];

        for (int i = 0; i < verts.Length; i++)
        {
            var v = verts[i];
            vertices[i] = v.position;
            normals[i] = v.normal;
            uvs[i] = v.uv;
        }

        /*if (vertices.Length > 60000)
        {
            //mesh.SetVertices()
            //mesh.SetTriangles()
        }*/

        mesh.SetVertices(vertices);
        mesh.SetNormals(normals);
        mesh.SetUVs(0, uvs); //TEXCOORD0
        // This sets the index list as triangles
        mesh.SetIndices(indices, MeshTopology.Triangles, 0, true);
        //Debug.Log("mesh.vertexCount " + mesh.vertexCount);
        //mesh.
        //mesh.Optimize(); // Let Unity optimize the buffer orders
        //Debug.Log("mesh.vertexCount " + mesh.vertexCount);
        return mesh;
    }
    private static SourceVertex[] FromGenVertToSource(GeneratedVertex[] verts)
    {
        SourceVertex[] res = new SourceVertex[verts.Length];
        for (int i = 0; i < verts.Length; i++)
        {
            var v = verts[i];
            res[i] = new SourceVertex();
            res[i].position = v.position;
            res[i].uv = v.uv;
        }
        return res;
    }

    private const string _SourceVerticesConst = "_SourceVertices";
    private const string _SourceIndicesConst = "_SourceIndices";
    private const string _GeneratedVerticesConst = "_GeneratedVertices";
    private const string _GeneratedIndicesConst = "_GeneratedIndices";

    public static bool Run(ComputeShader shader, PyramidBakeSettings settings, out Mesh generatedMesh)
    {
        // Decompose the mesh into vertex/index buffers
        DecomposeMesh(settings.sourceMesh, 0, out var sourceVertices
            , out var sourceIndices);

        Debug.Log("//----------------------------------------------");
        Debug.Log("sourceVertices.Length " + sourceVertices.Length);
        Debug.Log("sourceIndices.Length " + sourceIndices.Length);

        // The mesh topology is triangles, so there are three indices per triangle
        int numSourcetriangles = sourceIndices.Length / 3;

        // We generate 3 triangles per source triangle, and there are three vertices per triangle
        GeneratedVertex[] generatedVertices = new GeneratedVertex[numSourcetriangles * 6];
        int[] generatedIndices = new int[numSourcetriangles * 12];

        // A graphics buffer is a better version of the compute buffer
        GraphicsBuffer sourceVertBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, 
            sourceVertices.Length, SOURCE_VERT_STRIDE);
        GraphicsBuffer sourceIndexBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured,
            sourceIndices.Length, SOURCE_INDEX_STRIDE);
        GraphicsBuffer genVertBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured,
            generatedVertices.Length, GENERATED_VERT_STRIDE);
        GraphicsBuffer genIndexBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured,
            generatedIndices.Length, GENERATED_INDEX_STRIDE);

        // Cache the kernel ID
        int idGrassKernel = shader.FindKernel("CSMain");

        // Set buffers and variables (set memory location, not the data inside)
        shader.SetBuffer(idGrassKernel, _SourceVerticesConst, sourceVertBuffer);
        shader.SetBuffer(idGrassKernel, _SourceIndicesConst, sourceIndexBuffer);
        shader.SetBuffer(idGrassKernel, _GeneratedVerticesConst, genVertBuffer);
        shader.SetBuffer(idGrassKernel, _GeneratedIndicesConst, genIndexBuffer);
        // Convert the scale and rotation settings into a transformation matrix
        //TRS = transform, rotation, scale
        shader.SetMatrix("_Transform", Matrix4x4.TRS(Vector3.zero, 
            Quaternion.Euler(Vector3.zero), Vector3.one));
        Renderer r = new Renderer();
        //Transform t = new();
        
        shader.SetMatrix("_TransformOStoWS", settings.transform.localToWorldMatrix);
        shader.SetMatrix("_TransformWStoOS", settings.transform.worldToLocalMatrix);
        shader.SetFloat("_PyramidHeight", settings.pyramidHeight);
        shader.SetInt("_NumSourceTriangles", numSourcetriangles);

        // Set data in the buffers
        sourceVertBuffer.SetData(sourceVertices);
        sourceIndexBuffer.SetData(sourceIndices);

        // Find the needed dispatch size, so that each triangle will be run over
        shader.GetKernelThreadGroupSizes(idGrassKernel, out uint threadGeoupSize, out _, out _);
        int dispatchSize = Mathf.CeilToInt((float)numSourcetriangles / threadGeoupSize);
        // Dispatch the compute shader
        shader.Dispatch(idGrassKernel, dispatchSize, 1, 1);

        for (int i = 0; i < settings.Tesselationtimes; i++)
        {
            genVertBuffer.GetData(generatedVertices);
            genIndexBuffer.GetData(generatedIndices);
            Debug.Log("generatedVertices count = " + generatedVertices.Length + " equal " + generatedVertices.Length * GENERATED_VERT_STRIDE / 1024 + " kb");
            Debug.Log("generatedIndices.Length " + generatedIndices.Length);

            SourceVertex[] nSourceVertices = FromGenVertToSource(generatedVertices);
            int[] nSourceIndices = generatedIndices;


            int sourceVerticesLenght = nSourceVertices.Length;
            int sourceIndicesLenght = nSourceIndices.Length;

            numSourcetriangles = nSourceIndices.Length / 3;
            generatedVertices = new GeneratedVertex[numSourcetriangles * 3 * 2];
            generatedIndices = new int[generatedVertices.Length * 2];

            sourceVertBuffer.Release();
            sourceIndexBuffer.Release();
            genVertBuffer.Release();
            genIndexBuffer.Release();

            sourceVertBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, nSourceVertices.Length, SOURCE_VERT_STRIDE);
            sourceIndexBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, nSourceIndices.Length, SOURCE_INDEX_STRIDE);
            genVertBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, generatedVertices.Length, GENERATED_VERT_STRIDE);
            genIndexBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, generatedIndices.Length, GENERATED_INDEX_STRIDE);

            shader.SetBuffer(idGrassKernel, _SourceVerticesConst, sourceVertBuffer);
            shader.SetBuffer(idGrassKernel, _SourceIndicesConst, sourceIndexBuffer);
            shader.SetBuffer(idGrassKernel, _GeneratedVerticesConst, genVertBuffer);
            shader.SetBuffer(idGrassKernel, _GeneratedIndicesConst, genIndexBuffer);

            shader.SetInt("_NumSourceTriangles", numSourcetriangles);

            sourceVertBuffer.SetData(nSourceVertices);
            sourceIndexBuffer.SetData(nSourceIndices);

            dispatchSize = Mathf.CeilToInt((float)numSourcetriangles / threadGeoupSize);
            // Dispatch the compute shader
            shader.Dispatch(idGrassKernel, dispatchSize, 1, 1);
        }

        //Get the data from the compite shader
        //Unity will wait here until the compute shader is completed
        //Don't do this as runtime. Look into AsyncGPUReadback
        genVertBuffer.GetData(generatedVertices);
        genIndexBuffer.GetData(generatedIndices);

        Debug.Log("generatedVertices count = " + generatedVertices.Length + " equal " + generatedVertices.Length * GENERATED_VERT_STRIDE / 1024 + " kb");
        Debug.Log("generatedIndices.Length " + generatedIndices.Length);
        Debug.Log(generatedIndices[generatedIndices.Length - 1]); // 484
        Debug.Log(generatedIndices[0]); // 0

        generatedMesh = ComposeMesh(generatedVertices, generatedIndices);

        // Release the graphics buffers, disposing them
        sourceVertBuffer.Release();
        sourceIndexBuffer.Release();
        genVertBuffer.Release();
        genIndexBuffer.Release();

        return true; // No error
    }

}
