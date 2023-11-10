using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MaskedObject : MonoBehaviour
{
    [ExecuteInEditMode]
    void Start()
    {
        GetComponent<MeshRenderer>().sharedMaterial.renderQueue = 3002;
    }

    
}
