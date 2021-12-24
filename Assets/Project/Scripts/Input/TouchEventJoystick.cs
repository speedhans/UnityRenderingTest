using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;

public class TouchEventJoystick : CustomTouchEvent
{
    [SerializeField]
    RectTransform m_JoystickOrigin;
    [SerializeField]
    RectTransform m_JoystickPointer;

    Vector2 m_PointerDownPoint;

    private void FixedUpdate()
    {
        if (IsTouch())
            DragEvent(m_LastDragPoint);
    }

    public override void OnPointerDown(PointerEventData eventData)
    {
        base.OnPointerDown(eventData);

        m_JoystickOrigin.gameObject.SetActive(true);
        m_JoystickPointer.gameObject.SetActive(true);
        m_PointerDownPoint = eventData.position;
        m_JoystickOrigin.position = new Vector3(m_PointerDownPoint.x, m_PointerDownPoint.y, 0.0f);
        m_JoystickPointer.position = new Vector3(m_PointerDownPoint.x, m_PointerDownPoint.y, 0.0f);
    }

    public override void OnPointerUp(PointerEventData eventData)
    {
        base.OnPointerUp(eventData);

        m_JoystickOrigin.gameObject.SetActive(false);
        m_JoystickPointer.gameObject.SetActive(false);
    }

    void DragEvent(Vector2 _Point)
    {
        Vector2 dir = (_Point - m_PointerDownPoint).normalized;

        m_JoystickPointer.position = _Point;

        if (GameManager.Instance.m_MyCharacter)
        {
            GameManager.Instance.m_MyCharacter.SetMoveDirection(dir);
        }
    }
}
