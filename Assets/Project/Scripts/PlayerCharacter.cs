using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerCharacter : CharacterBase
{
    protected override void Start()
    {
        base.Start();

        GameManager.Instance.m_MyCharacter = this;
    }

    protected override void Update()
    {
        base.Update();

    }
}
