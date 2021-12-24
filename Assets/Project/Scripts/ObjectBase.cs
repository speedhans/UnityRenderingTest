using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ObjectBase : MonoBehaviour
{
    List<ActionBase> m_ActionList;

    protected virtual void Awake() { }

    protected virtual void Start() { }

    protected virtual void Update() { }

    T CreateAction<T>(T _Action) where T : ActionBase
    {
        for (int i = 0; i < m_ActionList.Count; ++i)
        {
            if (m_ActionList[i].GetType() == _Action.GetType())
            {
                return null;
            }
        }

        m_ActionList.Add(_Action);
        _Action.CreateEvent();
        return _Action;
    }

    public void ReleaseAction(System.Type _Class)
    {
        for (int i = 0; i < m_ActionList.Count; ++i)
        {
            if (m_ActionList[i].GetType() == _Class)
            {
                m_ActionList[i].ReleaseEvent();
                m_ActionList.RemoveAt(i);
                return;
            }
        }
    }
}
