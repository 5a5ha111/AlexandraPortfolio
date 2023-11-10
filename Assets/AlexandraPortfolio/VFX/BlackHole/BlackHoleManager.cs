using System.Collections;
using System.Collections.Generic;
using System.Net.NetworkInformation;
using System.Timers;
using UnityEngine;
using UnityEngine.Serialization;
using UnityEngine.VFX;

public class BlackHoleManager : MonoBehaviour
{

    [SerializeField] private VisualEffect blackHole;
    [SerializeField] private List<VisualEffect> Numbers;

    [Space][SerializeField] private bool StartProp = false;
    private bool started = false;

    private int timeBackCount;
    //private Timer timer = new Timer();
    private MyTimer myTimer = new MyTimer();

    private const string blackHoleStart = "OnPlay";
    private const string blackHoleEnd = "OnBlackHoleEnd";

    private const string numbersStart = "OnPlay";
    private const string numbersEnd = "OnEnd";

    // Start is called before the first frame update
    void Start()
    {
        timeBackCount = Numbers.Count -1;
        //timer.Interval = 1000;
        //timer.Elapsed += Timer_Elapsed;
        
        myTimer.Time = 1;
        myTimer.Elapsed += MyTimer_Elapsed;
    }

    private void MyTimer_Elapsed()
    {
        HideNumber(timeBackCount);
        timeBackCount -= 1;
        if (timeBackCount < 0)
        {
            ShowBlackHole();
        }
        else
        {
            ShowNumber(timeBackCount);
            myTimer.Time = 1;
        }
    }

    /*private void Timer_Elapsed(object sender, ElapsedEventArgs e)
    {
        Debug.Log("Elapsed!!");
        HideNumber(timeBackCount);
        timeBackCount -= 1;
        if (timeBackCount < 0)
        {
            ShowBlackHole();
        }
        else
        {
            ShowNumber(timeBackCount);
            timer.Start();
        }
    }*/

    // Update is called once per frame
    void Update()
    {
        if (StartProp && !started)
        {
            started = true;
            ShowNumber(timeBackCount);
            myTimer.Time = 1;
        }
        if (!StartProp && started)
        {
            started = false;
            HideBlackHole();
            HideNumber(timeBackCount);
            timeBackCount = Numbers.Count - 1;

        }
        if (started && timeBackCount >= 0) 
        {
            myTimer.Update(Time.smoothDeltaTime);
        }
    }

    private void ShowBlackHole()
    {
        blackHole.SendEvent(blackHoleStart);
        blackHole.gameObject.SetActive(true);
    }
    private void HideBlackHole()
    {
        blackHole.SendEvent(blackHoleEnd);
        //blackHole.gameObject.SetActive(false);
    }
    private void ShowNumber(int id)
    {
        if (id >= 0 && id <= Numbers.Count)
        {
            Numbers[id].gameObject.SetActive(true);
            Numbers[id].SendEvent(numbersStart);
        }
    }
    private void HideNumber(int id)
    {
        if (id >= 0 && id <= Numbers.Count)
        {
            Numbers[id].SendEvent(numbersEnd);
        }
    }

    struct MyTimer
    {
        public float Time;
        public delegate void Elapsedd();
        public event Elapsedd Elapsed;

        public void Update(float dt)
        {
            //Debug.Log("dt = " + dt);
            Time -= dt;
            if (Time <= 0)
            {
                Elapsed();
            }
        }
    }


}
