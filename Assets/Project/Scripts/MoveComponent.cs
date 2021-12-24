using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MoveComponent : MonoBehaviour
{
    CharacterBase m_CharacterBase;
    Transform m_Transform;

    [SerializeField] float m_Speed = 1.0f;
    [SerializeField] float m_RotatePerSpeed = 300.0f;

    private void Awake()
    {
        m_Transform = this.transform;
        m_CharacterBase = GetComponent<CharacterBase>();
    }

    public void SetSpeed(float _Speed)
    {
        m_Speed = _Speed;
    }

    public void SetDirection(Vector3 _Dir)
    {
        if (_Dir == Vector3.zero) return;

        Quaternion camRot = Camera.main.transform.rotation;
        Vector3 fixedDir = camRot * _Dir;
        fixedDir.y = 0.0f;

        CalTransform(Time.deltaTime, fixedDir);
    }

    void CalTransform(float _DeltaTime, Vector3 _Direction)
    {
        Vector3 dir = _Direction;
        Vector3 dirnormal = dir.normalized;

        Vector3 Euler = m_Transform.rotation.eulerAngles;
        Euler.x = 0.0f;
        Euler.z = 0.0f;
        if (m_RotatePerSpeed > 0)
        {
            float addrotY = _DeltaTime * m_RotatePerSpeed;
            float dot = Vector3.Dot(m_Transform.right, dirnormal);
            Vector3 dirRot = Quaternion.LookRotation(dirnormal).eulerAngles;
            if (Mathf.Abs(dirRot.y - Euler.y) > addrotY)
            {
                if (dot < 0.0f)
                    Euler.y -= addrotY;
                else
                    Euler.y += addrotY;
            }
            else
            {
                Euler.y = dirRot.y;
            }

            Euler.y = CustomMath.CorrectionDegree(Euler.y);
        }
        float speed = _DeltaTime * m_Speed;
        m_Transform.SetPositionAndRotation(m_Transform.position + dirnormal * speed, Quaternion.Euler(Euler));
    }
}
