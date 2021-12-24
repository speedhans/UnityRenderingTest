using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ActionBase
{
    public virtual void Update(float _DeltaTime)
    {

    }

    public virtual void CreateEvent() { }
    public virtual void ReleaseEvent() { }
    public virtual void EnterEvent() { }
    public virtual void ExitEvent() { }
}
