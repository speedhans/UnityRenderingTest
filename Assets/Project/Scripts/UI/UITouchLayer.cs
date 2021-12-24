using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;

public class UITouchLayer : MonoBehaviour, IDragHandler
{
    System.Action<Vector2> m_DrageCallback;

    private void Awake()
    {
        UIManager.Instance.SetTouchLayer(this);
    }

    public void OnDrag(PointerEventData eventData)
    {
        m_DrageCallback?.Invoke(eventData.delta);
    }

    public void AddDrageCallback(System.Action<Vector2> _CallbackFuntion)
    {
        m_DrageCallback -= _CallbackFuntion;
        m_DrageCallback += _CallbackFuntion;
    }
}
