using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CharacterBase : ObjectBase
{
    static protected int AnimStandard = Animator.StringToHash("Standard Tree");
    static protected float StandardAnimReturnSpeed = 10.0f;

    protected MoveComponent m_MoveComponent;
    protected Animator m_Animator;

    protected override void Awake()
    {
        base.Awake();
        m_MoveComponent = GetComponent<MoveComponent>();
        m_Animator = GetComponent<Animator>();
    }

    public MoveComponent GetMoveComponent() { return m_MoveComponent; }

    public void SetMoveDirection(Vector2 _Dir)
    {
        if (!m_MoveComponent) return;

        m_MoveComponent.SetDirection(new Vector3(_Dir.x, 0, _Dir.y));
        m_Animator.SetFloat(AnimStandard, 1.0f);
    }

    protected override void Update()
    {
        base.Update();

        float deltaTime = Time.deltaTime;

        UpdateAimStandToWalk(deltaTime);
    }

    void UpdateAimStandToWalk(float _DeltaTime)
    {
        float value = m_Animator.GetFloat(AnimStandard);
        if (value > 0.0f)
        {
            value -= _DeltaTime * StandardAnimReturnSpeed;
            if (value < 0.0f)
                value = 0.0f;

            m_Animator.SetFloat(AnimStandard, value);
        }
    }
}
