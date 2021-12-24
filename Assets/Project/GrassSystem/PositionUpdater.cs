using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PositionUpdater : MonoBehaviour
{
    // Update is called once per frame
    void Update()
    {
        GrassRenderingSystem.Instance.SetObjectPosition(transform.position);
    }
}
