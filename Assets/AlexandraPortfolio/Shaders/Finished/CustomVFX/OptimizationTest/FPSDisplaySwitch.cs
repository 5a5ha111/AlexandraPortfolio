using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;

public class FPSDisplaySwitch : MonoBehaviour
{
    // Start is called before the first frame update
    public TextMeshProUGUI fpsText; // Reference to the TextMeshProUGUI object
    public TextMeshProUGUI ActiveText; // Reference to the TextMeshProUGUI object
    public GameObject object1;      // Reference to the first GameObject
    public GameObject object2;      // Reference to the second GameObject

    private float deltaTime = 0.0f;

    void Update()
    {
        // Calculate the deltaTime for FPS calculation
        deltaTime += (Time.deltaTime - deltaTime) * 0.1f;

        // Calculate FPS
        float fps = 1.0f / deltaTime;

        // Update the TextMeshPro text to display the FPS
        fpsText.text = string.Format("FPS: {0:0.}", fps);

        // Check for spacebar press to toggle objects
        if (Input.GetKeyDown(KeyCode.Space))
        {
            ToggleObjects();
        }
    }

    bool ToggleObjects()
    {
        // Toggle the active states of the two objects

        if (object1.activeSelf)
        {
            object1.SetActive(false);
            object2.SetActive(true);
            ActiveText.text = object2.name;
            return true;
        }
        if (object2.activeSelf)
        {
            object1.SetActive(true);
            object2.SetActive(false);
            ActiveText.text = object1.name;
            return true;
        }

        return true;

    }
}
