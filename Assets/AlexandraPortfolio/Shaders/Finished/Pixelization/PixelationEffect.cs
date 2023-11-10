using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;

public class PixelationEffect : MonoBehaviour
{
    public float PixelationMin = 50;
    public float PixelationMax = 250;
    public float PixelationTarget = 50;
    public float PixelationCurrent = 250;
    public float PixelationSpeed = 0.5f;

    private Material pixelMat;
    Renderer rend;
    private const string pixelationPropertie = "_Pixelation";
    private const string shaderName = "PixeletionShader";

    // Start is called before the first frame update
    void Start()
    {
        pixelMat = GetComponent<Renderer>().material;
    }

    // Update is called once per frame
    void Update()
    {
        if (PixelationCurrent != PixelationTarget)
        {
            PixelationCurrent = math.lerp(PixelationCurrent, PixelationTarget, PixelationSpeed * Time.deltaTime);
        }
        pixelMat.SetFloat(pixelationPropertie, PixelationCurrent);
        if (math.round(PixelationCurrent) == PixelationTarget)
        {
            if (PixelationTarget == PixelationMin) { PixelationTarget = PixelationMax; }
            else if (PixelationTarget == PixelationMax) { PixelationTarget = PixelationMin; }
        }
    }
}
