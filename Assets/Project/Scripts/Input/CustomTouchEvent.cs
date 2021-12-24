using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;

[RequireComponent(typeof(UnityEngine.UI.Image))]
public class CustomTouchEvent : MonoBehaviour, IPointerEnterHandler, IPointerExitHandler, IPointerDownHandler, IPointerUpHandler, 
    IDragHandler, IBeginDragHandler, IEndDragHandler
{
    protected Vector2 m_EnterPoint;
    protected Vector2 m_DownPoint;
    protected Vector2 m_LastDragPoint;
    protected bool m_Pressed = false;

    public bool IsTouch() { return m_Pressed; }
    public Vector2 GetEnterPoint() { return m_EnterPoint; }
    public Vector2 GetDownPoint() { return m_DownPoint; }

    public virtual void OnPointerDown(PointerEventData eventData) // Click down
    {
        m_DownPoint = eventData.position;
        m_LastDragPoint = m_DownPoint;
        m_Pressed = true;
    }

    public virtual void OnPointerUp(PointerEventData eventData) // Click up
    {
        m_Pressed = false;
    }

    public virtual void OnPointerEnter(PointerEventData eventData)
    {
        m_EnterPoint = eventData.position;
    }

    public virtual void OnPointerExit(PointerEventData eventData)
    {
    }

    public virtual void OnDrag(PointerEventData eventData)
    {
        m_LastDragPoint = eventData.position;
    }

    public virtual void OnBeginDrag(PointerEventData eventData)
    {
        m_LastDragPoint = eventData.position;
    }

    public virtual void OnEndDrag(PointerEventData eventData)
    {
        m_LastDragPoint = eventData.position;
    }
}
