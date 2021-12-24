using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameManager : MonoBehaviour
{
    static GameObject _gameObject = null;
    static GameManager single = null;
    static public GameManager Instance
    {
        get
        {
            if (single == null)
            {
                single = FindObjectOfType<GameManager>();
                if (single == null)
                {
                    _gameObject = new GameObject("GameManager");
                    single = _gameObject.AddComponent<GameManager>();
                }
                single.Initialize();
            }
            return single;
        }
    }

    void Initialize()
    {
        DontDestroyOnLoad(gameObject);

#if UNITY_EDITOR

#else
        Application.targetFrameRate = 45;
#endif
    }

    public PlayerCharacter m_MyCharacter;

    public float Value;
    public Vector2 Min;
    public Vector2 Max;

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Alpha1))
        {
            Debug.Log("Remap: " + Remap(Value, Min, Max));
        }

    }

    float Remap(float In, Vector2 InMinMax, Vector2 OutMinMax)
    {
        return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
    }
}
