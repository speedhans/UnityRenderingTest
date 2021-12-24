using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CustomMath
{
    static public float CorrectionDegree(float _Value)
    {
        float fixedvalue = _Value;
        if (fixedvalue > 360.0f)
            fixedvalue -= 360.0f;
        else if (fixedvalue < 0.0f)
            fixedvalue += 360.0f;

        return fixedvalue;
    }

    static public Vector3 MultiplyVector3(Vector3 _Src1, Vector3 _Src2)
    {
        Vector3 res = Vector3.zero;
        res.x = _Src1.x * _Src2.x;
        res.y = _Src1.y * _Src2.y;
        res.z = _Src1.z * _Src2.z;

        return res;
    }

    static public Vector3 DivideVector3(Vector3 _Src1, Vector3 _Src2)
    {
        Vector3 res = Vector3.zero;
        res.x = _Src1.x / _Src2.x;
        res.y = _Src1.y / _Src2.y;
        res.z = _Src1.z / _Src2.z;

        return res;
    }

    static public Vector3 CalculateGlobalScale(Matrix4x4 _worldToLocalMatrix, Vector3 _TargetScale)
    {
        _worldToLocalMatrix.SetColumn(0, new Vector4(_worldToLocalMatrix.GetColumn(0).magnitude, 1f));
        _worldToLocalMatrix.SetColumn(1, new Vector4(0f, _worldToLocalMatrix.GetColumn(1).magnitude));
        _worldToLocalMatrix.SetColumn(2, new Vector4(0f, 0f, _worldToLocalMatrix.GetColumn(2).magnitude));
        _worldToLocalMatrix.SetColumn(3, new Vector4(0f, 0f, 0f, 1f));
        return _worldToLocalMatrix.MultiplyPoint(_TargetScale);
    }
}
