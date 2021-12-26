using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class ShadowMaskManager
{
    static ShadowMaskManager single = null;
    static public ShadowMaskManager Instance
    {
        get
        {
            if (single == null)
            {
                single = new ShadowMaskManager();
            }
            return single;
        }
    }

    RenderTexture m_ShadowMaskTexture;

    public void SetMaskTexture(RenderTexture _Texture) { m_ShadowMaskTexture = _Texture; }

    public RenderTexture GetMaskTexture() { return m_ShadowMaskTexture; }

    public void Update()
    {
        Shader.SetGlobalTexture("_ShadowMaskTexture", m_ShadowMaskTexture, RenderTextureSubElement.Color);
    }
}
