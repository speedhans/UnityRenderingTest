using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ObjectMoveCos : MonoBehaviour
{
    [SerializeField] float m_Power = 1;

    Transform m_Transform;

    Vector3 m_OriginPos;

    private void Awake()
    {
        m_Transform = transform;
        m_OriginPos = m_Transform.position;
    }

    private void FixedUpdate()
    {
        Vector3 pos = m_OriginPos;

        pos.x += Mathf.Sin(Time.time) * m_Power;
        pos.z += Mathf.Cos(Time.time) * m_Power;

        m_Transform.position = pos;
    }
}
