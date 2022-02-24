using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class TimeOfDayLight : MonoBehaviour
{
    [SerializeField] Light m_SunLight;
    [SerializeField] Light m_MoonLight;

    Material m_SkyBoxMat;

    float m_SunExposure = 1.3f;
    float m_MoonExposure = 0.07f;

    bool m_IsAfternoon;

    private void Awake()
    {
        m_SkyBoxMat = RenderSettings.skybox;

        m_IsAfternoon = m_SunLight.enabled;
    }

    // Update is called once per frame
    void Update()
    {
        if (-m_SunLight.transform.forward.y > 0)
        {
            if (!m_IsAfternoon)
            {
                m_SunLight.enabled = true;
                m_MoonLight.enabled = false;
                m_IsAfternoon = true;

                m_SkyBoxMat.SetFloat("_Exposure", m_SunExposure);
            }
        }
        else
        {
            if (m_IsAfternoon)
            {
                m_SunLight.enabled = false;
                m_MoonLight.enabled = true;
                m_IsAfternoon = false;

                m_SkyBoxMat.SetFloat("_Exposure", m_MoonExposure);
            }
        }
    }
}
