using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShadowMaskViewTest : MonoBehaviour
{
    static GameObject _gameObject = null;
    static ShadowMaskViewTest single = null;
    static public ShadowMaskViewTest Instance
    {
        get
        {
            if (single == null)
            {
                single = FindObjectOfType<ShadowMaskViewTest>();
                if (single == null)
                {
                    _gameObject = new GameObject("ShadowMaskViewTest");
                    single = _gameObject.AddComponent<ShadowMaskViewTest>();
                }
            }
            return single;
        }
    }

    [SerializeField] UnityEngine.UI.RawImage m_Image;

    private void Update()
    {
        m_Image.texture = ShadowMaskManager.Instance.GetMaskTexture();
    }
}
