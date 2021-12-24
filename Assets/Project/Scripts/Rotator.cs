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
        rot.y += Time.deltaTime * m_Speed;

        if (rot.y > 360.0f)
            rot.y -= 360.0f;
        else if (rot.y < 0.0f)
            rot.y += 360.0f;

        m_Transform.rotation = Quaternion.Euler(rot);
    }
}
