using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Rotator : MonoBehaviour
{
    [SerializeField] float m_Speed = 5.0f;

    Transform m_Transform;

    private void Awake()
    {
        m_Transform = transform;
    }

    // Update is called once per frame
    void Update()
    {
        Vector3 rot = m_Transform.eulerAngles;
        rot.z += Time.deltaTime * m_Speed;

        if (rot.z > 360.0f)
            rot.z -= 360.0f;
        else if (rot.z < 0.0f)
            rot.z += 360.0f;

        m_Transform.rotation = Quaternion.Euler(rot);
    }
}
