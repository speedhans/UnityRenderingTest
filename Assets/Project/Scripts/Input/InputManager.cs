using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InputManager : MonoBehaviour
{
    static GameObject _gameObject = null;
    static InputManager single = null;
    static public InputManager Instance
    {
        get
        {
            if (single == null)
            {
                _gameObject = new GameObject("InputManager");
                single = _gameObject.AddComponent<InputManager>();
                single.Initialize();
            }
            return single;
        }
    }

    void Initialize()
    {
        DontDestroyOnLoad(gameObject);
    }
}
