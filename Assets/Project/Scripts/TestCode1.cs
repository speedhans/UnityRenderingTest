using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestCode1 : MonoBehaviour
{
    public float m_Value;

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Q))
        {
            Debug.Log("Log10 = " + Mathf.Log10(m_Value));
        }

        if (Input.GetKeyDown(KeyCode.Q))
        {
            Debug.Log("Log = " + Mathf.Log(m_Value));
        }
    }
}
