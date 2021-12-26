using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Cinemachine;

public class CameraManager : MonoBehaviour
{
    [SerializeField] CinemachineBrain m_BrainCamera;
    [SerializeField] CinemachineVirtualCamera m_CurrentVirtualCamera;
    CinemachineTransposer m_CurrentCinemachineTransposer;

    [SerializeField] float m_Pitch; // X
    [SerializeField] float m_Yaw;   // Y
    [SerializeField] float m_Distance;

    private void Awake()
    {
        Cinemachine.CinemachineCore.CameraUpdatedEvent.AddListener(CameraUpdate);
        SetVirtualCamera(m_CurrentVirtualCamera);
    }

    private void Start()
    {
        UIManager.Instance.GetTouchLayer().AddDrageCallback(TouchEvent);

        TouchEvent(new Vector2(0, 0.00001f));
    }

    void CameraUpdate(CinemachineBrain _Brain)
    {

    }

    public void SetBrainCamera(CinemachineBrain _Brain) { m_BrainCamera = _Brain; }
    public CinemachineBrain GetBrainCamera() { return m_BrainCamera; }
    public void SetVirtualCamera(CinemachineVirtualCamera _Camera) 
    {
        m_CurrentVirtualCamera = _Camera;
        m_CurrentCinemachineTransposer = m_CurrentVirtualCamera.GetCinemachineComponent<CinemachineTransposer>();
    }
    public CinemachineVirtualCamera GetVirtualCamera() { return m_CurrentVirtualCamera; }

    void TouchEvent(Vector2 _Dir)
    {
        if (_Dir == Vector2.zero) return;
        _Dir = _Dir.normalized;
        m_CurrentCinemachineTransposer.m_FollowOffset = Quaternion.Euler(ClampPitch(m_Pitch), ClampYaw(m_Yaw += (_Dir.x * 5.0f)), 0.0f) * Vector3.back * m_Distance;
    }

    float ClampPitch(float _Value)
    {
        return Mathf.Clamp(_Value, -15.0f, 45.0f);
    }

    float ClampYaw(float _Value)
    {
        if (_Value > 360.0f)
            return _Value -= 360.0f;
        else if (_Value < 0.0f)
            return _Value += 360.0f;
        return _Value;
    }
}
