using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UnityChanGenerator : MonoBehaviour
{
    [SerializeField] GameObject m_Object;
    [SerializeField] int m_SpawnCount = 20;

    float m_Timer;


    private void Update()
    {
        if (m_SpawnCount < 1)
            return;

        m_Timer += Time.deltaTime;

        if (m_Timer > 0.001f)
        {
            Instantiate(m_Object, transform.position + new Vector3(Random.Range(-8, 8), 0, Random.Range(-8, 8)), Quaternion.identity);
            m_SpawnCount--;
        }
    }
}
