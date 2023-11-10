using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.VFX;


// Literally, its simple as possible
public class SlashScript : MonoBehaviour
{

    public VisualEffect VFX_Slash;

    private Animator animator;
    [SerializeField] private float animationTime = 1.5f;
    [SerializeField] private float vfxTime = 0.5f;
    private bool vfx_Play = false;
    private float cc = 0f;
    private const string slashTrigger = "SlashTrigger";
    // Start is called before the first frame update
    void Start()
    {
        animator = GetComponent<Animator>();
    }

    // Update is called once per frame
    void Update()
    {
        if (cc >= animationTime)
        {
            cc = 0f;
            animator.SetTrigger(slashTrigger);
            vfx_Play = false;
        }
        if (cc >= vfxTime && !vfx_Play)
        {
            VFX_Slash.Play();
            vfx_Play = true;
        }
        cc += Time.deltaTime;
    }


}
