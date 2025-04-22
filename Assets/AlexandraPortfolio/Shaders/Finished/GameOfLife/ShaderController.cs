using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.UI;

public class ShaderController : MonoBehaviour
{

    public ComputeShader CelluarAutomatShader;
    public ComputeShader PreTextureShader;
    public ComputeShader PaintShader;

    private RenderTexture Result;
    private RenderTexture PreResult;

    //public RawImage RawResult;
    public Material ResultMat;

    [Space]public bool isAlive = true;
    public bool isPaint = false;
    float BrushPosX;
    float BrushPosY;
    public float Radius = 5;

    private float gameFieldSize = 256;
    private int streamsCount = 16;

    [Space] public float fps = 10;
    private float elapsedTime = 0;
    public float repeatPeriod = 10f;
    private float elapsedSeconds = 0;

    // Start is called before the first frame update
    void Start()
    {
        Result = new RenderTexture((int)gameFieldSize, (int)gameFieldSize, 32);
        Result.enableRandomWrite = true;
        Result.Create();
        ResultMat.mainTexture = Result;

        PreResult = new RenderTexture((int)gameFieldSize, (int)gameFieldSize, 32);
        PreResult.enableRandomWrite = true;
        PreResult.Create();

        CelluarAutomatShader.SetTexture(0, "PreResult", PreResult);
        CelluarAutomatShader.SetTexture(0, "Result", Result);
        CelluarAutomatShader.SetFloat("gameFieldSize", gameFieldSize);
        CelluarAutomatShader.SetFloat("streamsCount", streamsCount);

        //PreTextureShader.SetTexture(0, "PreResult", PreResult);
        //PreTextureShader.SetTexture(0, "Result", Result);

        PaintShader.SetTexture(0, "Result", Result);
        PaintShader.SetTexture(0, "PreResult", PreResult);
        PaintShader.SetBool("isPaint", isPaint);
        PaintShader.SetBool("isAlive", isAlive);
        PaintShader.SetFloat("gameFieldSize", gameFieldSize);
        PaintShader.SetFloat("streamsCount", streamsCount);
        PaintShader.SetFloat("Radius", Radius);
        PaintShader.SetFloat("BrushPosX", Input.mousePosition.x);
        PaintShader.SetFloat("BrushPosY", Input.mousePosition.y);

        PaintShader.Dispatch(0, Result.width / streamsCount, Result.height / streamsCount, 1);
    }

    private void Awake()
    {
        //Application.targetFrameRate = TargetFPS;
    }

    // Update is called once per frame
    void Update()
    {
        /*if (Application.targetFrameRate != TargetFPS)
            Application.targetFrameRate = TargetFPS;
        if (Input.GetMouseButton(0))
        {
            isPaint = true;
        }
        if (Input.GetMouseButtonUp(0))
        {
            isPaint = false;
        }
        if (Input.GetMouseButton(1))
        {
            isAlive = !isAlive;
        }*/

        elapsedTime += Time.fixedDeltaTime;
        elapsedSeconds += Time.fixedDeltaTime;
        if (elapsedTime >= (1f / fps))
        {
            elapsedTime = 0;
            CustOnRenderImage();
        }
        if (elapsedSeconds >= repeatPeriod)
        {
            elapsedSeconds = 0;
            //Recreate
            Debug.Log("Recreate");
            PaintShader.Dispatch(0, Result.width / streamsCount, Result.height / streamsCount, 1);
        }

        /*CustOnRenderImage();
        BrushUpdate();*/
    }

    private void OnRenderObject()
    {
        /*if (Application.targetFrameRate != TargetFPS)
            Application.targetFrameRate = TargetFPS;
        if (Input.GetMouseButton(0))
        {
            isPaint = true;
        }
        if (Input.GetMouseButtonUp(0))
        {
            isPaint = false;
        }
        if (Input.GetMouseButton(1))
        {
            isAlive = !isAlive;
        }*/
        //CustOnRenderImage();
    }

    /*private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        CelluarAutomatShader.Dispatch(0, Result.width / 8, Result.height / 8, 1);
        //PreTextureShader.Dispatch(0, PreResult.width / 8, PreResult.height / 8, 1);

        //Paint dots
        PaintShader.SetBool("isPaint", isPaint);
        PaintShader.SetBool("isAlive", isAlive);
        PaintShader.SetFloat("Radius", Radius);
        PaintShader.SetFloat("BrushPosX", Input.mousePosition.x);
        PaintShader.SetFloat("BrushPosY", Input.mousePosition.y);
        PaintShader.Dispatch(0, Result.width /8, Result.height / 8, 1);

        Graphics.Blit(Result, destination);

        Debug.Log("Render");
    }*/

    private void CustOnRenderImage()
    {
        CelluarAutomatShader.Dispatch(0, Result.width / streamsCount, Result.height / streamsCount, 1);
        //PreTextureShader.Dispatch(0, PreResult.width / 8, PreResult.height / 8, 1);

        //BrushUpdate();

        //Debug.Log("RenderCust");
    }
    private void BrushUpdate()
    {
        //Paint dots
        PaintShader.SetBool("isPaint", isPaint);
        PaintShader.SetBool("isAlive", isAlive);
        PaintShader.SetFloat("Radius", Radius);
        PaintShader.SetFloat("BrushPosX", Mathf.Round(Input.mousePosition.x / 2));
        PaintShader.SetFloat("BrushPosY", Mathf.Round(Input.mousePosition.y / 2));
        PaintShader.Dispatch(0, Result.width / streamsCount, Result.height / streamsCount, 1);
    }
}
