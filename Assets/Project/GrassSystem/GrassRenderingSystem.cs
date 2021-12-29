﻿#define HIGHTMAP2

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEditor;
using UnityEngine;
using UnityEngine.TerrainUtils;

[ExecuteInEditMode]
public class GrassRenderingSystem : MonoBehaviour
{
    static GrassRenderingSystem _Instance;
    public static GrassRenderingSystem Instance
    {
        get
        {
            if (_Instance == null)
            {
                _Instance = FindObjectOfType<GrassRenderingSystem>();
            }

            return _Instance;
        }
    }

    [Header("-> Spawn Area 의 값이 Visible Distance 보다 높아야 원하는 거리만큼 렌더링이 가능합니다. \n-> Spawn Area 와 Visible Distance 의 값이 비슷할수록 성능이 올라갑니다.")]
    [Space(10)]
    [SerializeField] Texture2D m_GrassColorMap;
    [SerializeField] Material m_DrawMaterial;
    [SerializeField] ComputeShader m_CullingCS;
    [Min(2)]
    [SerializeField] float m_GrassSpawnAreaX;
    [Min(2)]
    [SerializeField] float m_GrassSpawnAreaY;
    [Range(0, 1000)]
    [SerializeField] int m_GrassCountX = 100;
    [Range(0, 1000)]
    [SerializeField] int m_GrassCountY = 100;
    [Range(0, 250)]
    [SerializeField] float m_VisibleDistance = 50.0f;
    //[SerializeField] bool m_TestGizmoOn;

    [SerializeField] Terrain m_Terrain;

    public Camera m_MainCamera;

    QuadTree m_QuadTree;
    RenderTexture m_EffectTexture;
    Texture2D m_EffectSourceTexture;

    List<Vector4> m_ObjectPosition = new List<Vector4>();
    int m_ObjectPositionSize = 0;
    List<Vector4> m_FirePosition = new List<Vector4>();

    Mesh m_MeshData;
    Bounds m_RenderBound;

    Transform m_TransformTarget;
    Vector3 m_BeforeTargetPosition;
    Vector3 m_BeforeTargetEuler;

    //float m_UpdateDistance = 0.5f;

    bool m_UpdateCellData = false;
    bool m_UpdateCullingData = false;

    ComputeBuffer m_PositionsBuffer;
    ComputeBuffer m_VisibleInstanceBuffer;
    ComputeBuffer m_ArgsBuffer;

    Vector3[] m_GrassLocalPositions;
    Vector2 m_Offset;

    public static RenderTexture CreateRenderTexture(FilterMode _FillterMode = FilterMode.Point)
    {
        RenderTexture texture = new RenderTexture(512, 512, 1, RenderTextureFormat.ARGB32);
        texture.filterMode = _FillterMode;
        texture.enableRandomWrite = true;
        texture.Create();

        return texture;
    }

    private void Awake()
    {
        _Instance = this;
        Initialize();
    }

    void Initialize()
    {
        m_MainCamera = Camera.main;

        GenerateGrass();

        m_UpdateCellData = false;
        m_UpdateCullingData = false;

        SetBufferToMaskTexture();

        m_TransformTarget = m_MainCamera.transform;

        if (m_EffectTexture)
            m_EffectTexture.Release();

        m_EffectTexture = CreateRenderTexture(FilterMode.Bilinear);
        m_EffectSourceTexture = new Texture2D(m_EffectTexture.width, m_EffectTexture.height, TextureFormat.ARGB32, false);

        for (int i = 0; i < 8; ++i)
            m_ObjectPosition.Add(Vector3.zero);
    }

    public void SetTargetTransform(Transform _Transform)
    {
        m_TransformTarget = _Transform;
    }

    void SetBufferToMaskTexture()
    {
        if (m_GrassColorMap == null) return;

        m_DrawMaterial.SetTexture("_ColorMapTexture", m_GrassColorMap);
        //m_DrawMaterial.SetTexture("_HeightMapTexture", m_GrassHeightMap);
        TerrainData terrain = m_Terrain.terrainData;
        if (terrain)
        {
            m_DrawMaterial.SetTexture("_HeightMapTexture", terrain.heightmapTexture);
            m_CullingCS.SetTexture(0, "_HeightMapTexture", terrain.heightmapTexture);
        }
        m_DrawMaterial.SetFloat("m_MapWidth", m_GrassColorMap.width);
        m_DrawMaterial.SetFloat("m_MapHeight", m_GrassColorMap.height);
        m_CullingCS.SetTexture(0, "_ColorMapTexture", m_GrassColorMap);
    }

    public void ReLoad()
    {
        Initialize();

        m_UpdateCellData = true;
        DrawGrass();
    }

    public void Refresh()
    {
#if UNITY_EDITOR
        //string path = AssetDatabase.GetAssetPath(m_GrassMap);
        //AssetDatabase.ImportAsset(path);

        if (!m_GrassColorMap)
        {
            Debug.Log("텍스쳐 소스 없음");
            return;
        }

        SetBufferToMaskTexture();

        SetBufferToDrawing();

        m_UpdateCellData = true;
        DrawGrass();
#endif
    }

    bool IsVaild()
    {
        if (m_GrassColorMap == null || m_CullingCS == null || m_TransformTarget == null ||
            m_ArgsBuffer == null || m_PositionsBuffer == null || m_VisibleInstanceBuffer == null) return false;

        return true;
    }

    private void FixedUpdate()
    {
        if (!IsVaild()) return;

        CheckPosition();
    }

    private void LateUpdate()
    {
        if (!IsVaild()) return;

        CheckRotation();
        DrawGrass();

        m_UpdateCellData = false;
        m_UpdateCullingData = false;
    }

    void CheckPosition()
    {
        Vector3 pos = new Vector3(CalRoundX(m_TransformTarget.position.x), 0.0f, CalRoundZ(m_TransformTarget.position.z));
        if (m_BeforeTargetPosition != pos)
        {
            m_UpdateCellData = true;
            m_BeforeTargetPosition = pos;
        }
        else m_UpdateCellData = false;
    }

    void CheckRotation()
    {
        if (m_BeforeTargetEuler != m_TransformTarget.eulerAngles)
        {
            m_UpdateCullingData = true;
            m_BeforeTargetEuler = m_TransformTarget.eulerAngles;
        }
        else m_UpdateCullingData = false;
    }

    void UpdateEffectTexture()
    {
        if (m_ObjectPosition.Count < 1 && m_FirePosition.Count < 1) return;

        for (int i = 0; i < m_ObjectPosition.Count; ++i)
        {
            Color color = m_EffectSourceTexture.GetPixel((int)m_ObjectPosition[i].x, (int)m_ObjectPosition[i].z);
            m_EffectSourceTexture.SetPixel((int)m_ObjectPosition[i].x, (int)m_ObjectPosition[i].z, new Color(color.r, color.g, color.b, 1.0f));
        }

        for (int i = 0; i < m_FirePosition.Count; ++i)
        {
            Color color = m_EffectSourceTexture.GetPixel((int)m_FirePosition[i].x, (int)m_FirePosition[i].z);
            m_EffectSourceTexture.SetPixel((int)m_FirePosition[i].x, (int)m_FirePosition[i].z, new Color(color.r, color.g, color.b, 1.0f));
        }

        m_EffectSourceTexture.Apply();
    }

    void GenerateGrass()
    {
        List<Vector3> tmpPos = new List<Vector3>();
        m_GrassLocalPositions = new Vector3[m_GrassCountX * m_GrassCountY];

        float spawnAreaHalfX = m_GrassSpawnAreaX * 0.5f;
        float spawnAreaHalfY = m_GrassSpawnAreaY * 0.5f;
        m_Offset.x = m_GrassSpawnAreaX / m_GrassCountX;
        m_Offset.y = m_GrassSpawnAreaY / m_GrassCountY;
        float startX = -spawnAreaHalfX;
        float startY = -spawnAreaHalfY;
        for (int x = 0; x < m_GrassCountX; ++x)
        {
            float posX = startX + (x * m_Offset.x);
            for (int y = 0; y < m_GrassCountY; ++y)
            {
                float posY = startY + (y * m_Offset.y);
                tmpPos.Add(new Vector3(posX, 0, posY));
            }
        }

        m_GrassLocalPositions = tmpPos.ToArray();

#if UNITY_EDITOR
        Debug.LogFormat("Grass Count: {0}   //   Vertex Count: {1}", m_GrassLocalPositions.Length, m_GrassLocalPositions.Length * GetGrassMeshCache().vertexCount);
#endif

        SetBufferToDrawing();
    }

    void SetBufferToDrawing()
    {
        if (m_PositionsBuffer != null) m_PositionsBuffer.Release();
        m_PositionsBuffer = new ComputeBuffer(m_GrassLocalPositions.Length, sizeof(float) * 3);
        m_PositionsBuffer.SetData(m_GrassLocalPositions);
        m_DrawMaterial.SetBuffer("_Positions", m_PositionsBuffer);

        if (m_VisibleInstanceBuffer != null) m_VisibleInstanceBuffer.Release();
        m_VisibleInstanceBuffer = new ComputeBuffer(m_GrassLocalPositions.Length, sizeof(uint), ComputeBufferType.Append);

        uint[] datas = new uint[] { 0, 0, 0, 0, 0 };
        datas[0] = GetGrassMeshCache().GetIndexCount(0);
        datas[1] = (uint)m_GrassLocalPositions.Length;
        if (m_ArgsBuffer != null) m_ArgsBuffer.Release();
        m_ArgsBuffer = new ComputeBuffer(1, sizeof(uint) * 5, ComputeBufferType.IndirectArguments);
        m_ArgsBuffer.SetData(datas);
    }

    void UpdateCulling()
    {
        if (m_VisibleInstanceBuffer == null) return;

        m_VisibleInstanceBuffer.SetCounterValue(0);

        Matrix4x4 v = m_MainCamera.worldToCameraMatrix;
        Matrix4x4 p = m_MainCamera.projectionMatrix;
        Matrix4x4 vp = p * v;

        Vector4 centerPos = GetCenterPosition();
        m_CullingCS.SetVector("_CenterPosition", centerPos);
        m_CullingCS.SetMatrix("_VPMatrix", vp);
        m_CullingCS.SetFloat("_MaxDrawDistance", m_VisibleDistance);
        m_CullingCS.SetBuffer(0, "_BasePositionDatas", m_PositionsBuffer);
        m_CullingCS.SetBuffer(0, "_VisibleInstancesID", m_VisibleInstanceBuffer);

        m_CullingCS.Dispatch(0, Mathf.Max(Mathf.CeilToInt(m_GrassLocalPositions.Length / 64), 1), 1, 1);

        m_DrawMaterial.SetVector("_CenterPosition", centerPos);
        m_DrawMaterial.SetBuffer("_VisibleIndex", m_VisibleInstanceBuffer);

        ComputeBuffer.CopyCount(m_VisibleInstanceBuffer, m_ArgsBuffer, sizeof(uint));
    }

    Vector4 GetCenterPosition()
    {
        if (m_TransformTarget == null) return Vector2.zero;

        Vector3 pos = m_TransformTarget.position;
        return new Vector4(CalRoundX(pos.x), 0.0f, CalRoundZ(pos.z), 1.0f);
    }
    
    float CalRoundX(float _Value)
    {
        return _Value == 0 ? 0 : ((int)(_Value / m_Offset.x)) * m_Offset.x;
    }

    float CalRoundZ(float _Value)
    {
        return _Value == 0 ? 0 : ((int)(_Value / m_Offset.y)) * m_Offset.y;
    }

    void DrawGrass()
    {
        if (m_UpdateCellData || m_UpdateCullingData)
        {
            UpdateCulling();
        }

        SetEffectData();

        // 바운딩 박스를 매 프레임 만들지 않으면 제대로 안그려짐 (왜 이래?)
        Bounds m_RenderBound = new Bounds();
        m_RenderBound.SetMinMax(new Vector3(-10000, 0, -10000), new Vector3(10000, 0, 10000));
        Graphics.DrawMeshInstancedIndirect(GetGrassMeshCache(), 0, m_DrawMaterial, m_RenderBound, m_ArgsBuffer);
    }

    void SetEffectData()
    {
        if (m_ObjectPosition.Count > 0)
        {
            m_DrawMaterial.SetVectorArray("_CollisionPositions", m_ObjectPosition);
            m_DrawMaterial.SetInt("_CollisionCount", m_ObjectPositionSize);
            m_ObjectPositionSize = 0;
        }
    }

    Mesh GetGrassMeshCache()
    {
        if (!m_MeshData)
        {
            m_MeshData = new Mesh();
            Vector3[] verts;
            int[] trinagles;
            if (false)
            {
                verts = new Vector3[3];
                verts[0] = new Vector3(-0.04f, 0);
                verts[1] = new Vector3(+0.04f, 0);
                verts[2] = new Vector3(0.0f, 0.3f);
                trinagles = new int[3] { 2, 1, 0, };
            }
            else
            {
                verts = new Vector3[5];
                verts[0] = new Vector3(-0.015f, 0);
                verts[1] = new Vector3(+0.015f, 0);
                verts[2] = new Vector3(+0.023f, 0.145f);
                verts[3] = new Vector3(-0.023f, 0.145f);
                verts[4] = new Vector3(0.0f, 0.25f);
                trinagles = new int[]
                {
                0,3,1,
                1,3,2,
                2,3,4
                };
            }
            m_MeshData.SetVertices(verts);
            m_MeshData.SetTriangles(trinagles, 0);
        }

        return m_MeshData;
    }


    public void SetObjectPosition(Vector3 _Position)
    {
        if (m_ObjectPositionSize >= 8) return;

        m_ObjectPosition[m_ObjectPositionSize++] = _Position;
    }

    public void SetFirePosition(Vector3 _Position)
    {
        m_FirePosition.Add(_Position);
    }
    //private void OnDrawGizmos()
    //{
    //    if (!m_TestGizmoOn) return;
    //    if (m_QuadTree == null || m_QuadTree.GetUnitList().Count < 1) return;

    //    Gizmos.color = Color.red;

    //    Gizmos.DrawWireSphere(transform.position, 20);
    //    List<QuadTree.QuadUnit> list = new List<QuadTree.QuadUnit>();
    //    m_QuadTree.SearchUnits(20, new Vector2(transform.position.x, transform.position.z), ref list);
    //    DrawQuad(list);
    //}

    //void DrawQuad(List<QuadTree.QuadUnit> _List)
    //{
    //    if (_List == null || _List.Count < 1) return;

    //    for (int i = 0; i < _List.Count; ++i)
    //    {
    //        Gizmos.DrawLine(new Vector3(_List[i].m_Rect.x - _List[i].m_Rect.width * 0.5f, 0, _List[i].m_Rect.y + _List[i].m_Rect.width * 0.5f),
    //            new Vector3(_List[i].m_Rect.x + _List[i].m_Rect.width * 0.5f, 0, _List[i].m_Rect.y + _List[i].m_Rect.width * 0.5f));

    //        Gizmos.DrawLine(new Vector3(_List[i].m_Rect.x - _List[i].m_Rect.width * 0.5f, 0, _List[i].m_Rect.y - _List[i].m_Rect.width * 0.5f),
    //          new Vector3(_List[i].m_Rect.x + _List[i].m_Rect.width * 0.5f, 0, _List[i].m_Rect.y - _List[i].m_Rect.width * 0.5f));

    //        Gizmos.DrawLine(new Vector3(_List[i].m_Rect.x - _List[i].m_Rect.width * 0.5f, 0, _List[i].m_Rect.y + _List[i].m_Rect.width * 0.5f),
    //          new Vector3(_List[i].m_Rect.x - _List[i].m_Rect.width * 0.5f, 0, _List[i].m_Rect.y - _List[i].m_Rect.width * 0.5f));

    //        Gizmos.DrawLine(new Vector3(_List[i].m_Rect.x + _List[i].m_Rect.width * 0.5f, 0, _List[i].m_Rect.y + _List[i].m_Rect.width * 0.5f),
    //          new Vector3(_List[i].m_Rect.x + _List[i].m_Rect.width * 0.5f, 0, _List[i].m_Rect.y - _List[i].m_Rect.width * 0.5f));

    //        //Gizmos.DrawCube(new Vector3(_List[i].m_Rect.x, 1, _List[i].m_Rect.y), new Vector3(_List[i].m_Rect.width, 0.1f, _List[i].m_Rect.height));
    //        DrawQuad(_List[i].GetUnitList());
    //    }
    //}
}
