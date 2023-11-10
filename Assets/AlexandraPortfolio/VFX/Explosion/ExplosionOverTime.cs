using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.VFX;

public class ExplosionOverTime : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    public VisualEffect visualEffectGraph; // Reference to the Visual Effect Graph component
    public float eventInterval = 1.0f; // Number of seconds between events

    private float timer = 0f;

    void Update()
    {
        // Update the timer with the time passed since the last frame
        timer += Time.deltaTime;

        // Check if the timer has reached the specified interval
        if (timer >= eventInterval)
        {
            // Send an event from the Visual Effect Graph
            visualEffectGraph.SendEvent("OnPlay"); // Replace "YourEventName" with the actual event name from your Visual Effect Graph

            // Reset the timer
            timer = 0f;
        }
    }
}
