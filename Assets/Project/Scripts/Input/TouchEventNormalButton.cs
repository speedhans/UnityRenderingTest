using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.Events;

public class TouchEventNormalButton : CustomTouchEvent
{
    [SerializeField]
    UnityEvent m_ButtonAction;

    public override void OnPointerDown(PointerEventData eventData)
    {
        base.OnPointerDown(eventData);

        m_ButtonAction?.Invoke();
    }
}
