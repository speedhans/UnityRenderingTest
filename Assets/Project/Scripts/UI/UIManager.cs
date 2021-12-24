using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UIManager : MonoBehaviour
{
    static GameObject _gameObject = null;
    static UIManager single = null;
    static public UIManager Instance
    {
        get
        {
            if (single == null)
            {
                _gameObject = new GameObject("UIManager");
                single = _gameObject.AddComponent<UIManager>();
                single.Initialize();
            }
            return single;
        }
    }

    void Initialize()
    {
        DontDestroyOnLoad(gameObject);
    }

    UITouchLayer m_UITouchLayer;

    public void SetTouchLayer(UITouchLayer _UITouchLayer) { m_UITouchLayer = _UITouchLayer; }
    public UITouchLayer GetTouchLayer() { return m_UITouchLayer; }
}
