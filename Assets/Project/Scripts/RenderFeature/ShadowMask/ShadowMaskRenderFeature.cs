using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ShadowMaskRenderFeature : ScriptableRendererFeature
{
	[System.Serializable]
	public struct MaskSetting
    {
		public RenderPassEvent m_Pass;
		public ComputeShader m_ComputeShader;
		[Range(0, 5)] public float m_BlurOffset;
		[Range(0, 4)] public int m_BlurPassCount;
	}

    public class ShadowMaskRenderFeaturePass : ScriptableRenderPass
    {
		MaskSetting m_Setting;
		RenderTexture m_RenderTexture;
		float m_BlurOffset;
		int m_BlurPassCount;

		int[] m_MainKernalSize = { 0, 0, 0};
		int[] m_BlurKernalSize = { 0, 0, 0 };

		public ShadowMaskRenderFeaturePass(MaskSetting InSetting)
		{
			this.renderPassEvent = InSetting.m_Pass;
			this.m_Setting = InSetting;
			this.m_BlurOffset = InSetting.m_BlurOffset * 0.001f;
			this.m_BlurPassCount = InSetting.m_BlurPassCount;
		}

		public void Setup()
		{
			if (m_RenderTexture)
            {
				m_RenderTexture.Release();
			}
			
			m_RenderTexture = new RenderTexture(Screen.width / 2, Screen.height / 2, 0, RenderTextureFormat.R8);//new RenderTexture(Screen.width / 2, Screen.height / 2, 0, RenderTextureFormat.R8);
			m_RenderTexture.enableRandomWrite = true;

#if UNITY_EDITOR
			Debug.LogFormat("Screen Size: {0}  ,  {1}", Screen.width, Screen.height);
			Debug.LogFormat("MaskBuffer Size: {0}  ,  {1}", m_RenderTexture.width, m_RenderTexture.height);
#endif

			ShadowMaskManager.Instance.SetMaskTexture(m_RenderTexture);

			uint mainKernelSizeX, mainKernelSizeY, mainKernelSizeZ;
			m_Setting.m_ComputeShader.GetKernelThreadGroupSizes(0, out mainKernelSizeX, out mainKernelSizeY, out mainKernelSizeZ);

			m_MainKernalSize[0] = (int)mainKernelSizeX;
			m_MainKernalSize[1] = (int)mainKernelSizeY;
			m_MainKernalSize[2] = (int)mainKernelSizeZ;

			uint blurKernelSizeX, blurKernelSizeY, blurKernelSizeZ;
			m_Setting.m_ComputeShader.GetKernelThreadGroupSizes(1, out blurKernelSizeX, out blurKernelSizeY, out blurKernelSizeZ);

			m_BlurKernalSize[0] = (int)blurKernelSizeX;
			m_BlurKernalSize[1] = (int)blurKernelSizeY;
			m_BlurKernalSize[2] = (int)blurKernelSizeZ;

#if UNITY_EDITOR
			int computePixelSizeX = m_RenderTexture.width / 2 / m_MainKernalSize[2];
			int computePixelSizeY = m_RenderTexture.height / 2 / m_MainKernalSize[2];

			Debug.LogFormat("MainKernel Size: {0} , {1} , {2}", 
				Mathf.Max(computePixelSizeX / m_MainKernalSize[0] + 1, 1), 
				Mathf.Max(computePixelSizeY / m_MainKernalSize[1] + 1, 1), 
				m_MainKernalSize[2]);
			Debug.LogFormat("BlurKernel Size: {0} , {1} , {2}", 

				Mathf.Max(m_RenderTexture.width / m_BlurKernalSize[2] / m_BlurKernalSize[0] + 1, 1),
				Mathf.Max(m_RenderTexture.height / m_BlurKernalSize[2] / m_BlurKernalSize[1] + 1, 1), 
				m_BlurKernalSize[2]);
#endif
		}

		public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
		{
			if (m_RenderTexture == null)
				return;

			int computePixelSizeX = m_RenderTexture.width / 2 / m_MainKernalSize[2];
			int computePixelSizeY = m_RenderTexture.height / 2 / m_MainKernalSize[2];

			m_Setting.m_ComputeShader.SetTexture(0, "_ShadowMaskTexture", m_RenderTexture);
			m_Setting.m_ComputeShader.SetFloats("_ShadowMaskTextureSize", new float[] { m_RenderTexture.width, m_RenderTexture.height });
			m_Setting.m_ComputeShader.SetFloats("_DevideValue", new float[] { computePixelSizeX, computePixelSizeY });
			m_Setting.m_ComputeShader.Dispatch(0, Mathf.Max(computePixelSizeX / m_MainKernalSize[0] + 1, 1), Mathf.Max(computePixelSizeY / m_MainKernalSize[1] + 1, 1), m_MainKernalSize[2]);

			if (m_BlurPassCount > 0)
			{
				m_Setting.m_ComputeShader.SetFloat("_BlurOffset", m_BlurOffset);
				m_Setting.m_ComputeShader.SetTexture(1, "_ShadowMaskTexture", m_RenderTexture);

				int blurThreadCountZ = m_BlurKernalSize[2];
				int blurThreadCountX = Mathf.Max(m_RenderTexture.width / blurThreadCountZ / m_BlurKernalSize[0] + 1, 1);
				int blurThreadCountY = Mathf.Max(m_RenderTexture.height / blurThreadCountZ / m_BlurKernalSize[1] + 1, 1);

				for (int i = 0; i < m_BlurPassCount; ++i)
				{
					m_Setting.m_ComputeShader.Dispatch(1, blurThreadCountX, blurThreadCountY, blurThreadCountZ);
				}
			}
            Shader.SetGlobalTexture("_ShadowMaskTexture", m_RenderTexture, RenderTextureSubElement.Color);
		}
	}

	public enum Target
	{
		CameraColor,
		TextureID,
		RenderTextureObject
	}

	public MaskSetting m_Setting;
	public ShadowMaskRenderFeaturePass m_RenderPass;

	public override void Create()
	{
		if (!this.isActive)
			return;

		m_RenderPass = new ShadowMaskRenderFeaturePass(m_Setting);
		m_RenderPass.Setup();
	}

	public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
	{
		if (m_Setting.m_ComputeShader == null)
		{
			Debug.LogWarningFormat("Missing Compute Shader");
			return;
		}

#if !UNITY_2021_2_OR_NEWER
		// AfterRenderingPostProcessing event is fixed in 2021.2+ so this workaround is no longer required

		if (settings.Event == RenderPassEvent.AfterRenderingPostProcessing) {
		} else if (settings.Event == RenderPassEvent.AfterRendering && renderingData.postProcessingEnabled) {
			// If event is AfterRendering, and src/dst is using CameraColor, switch to _AfterPostProcessTexture instead.
			if (settings.srcType == Target.CameraColor) {
				settings.srcType = Target.TextureID;
				settings.srcTextureId = "_AfterPostProcessTexture";
			}
			if (settings.dstType == Target.CameraColor) {
				settings.dstType = Target.TextureID;
				settings.dstTextureId = "_AfterPostProcessTexture";
			}
		} else {
			// If src/dst is using _AfterPostProcessTexture, switch back to CameraColor
			if (settings.srcType == Target.TextureID && settings.srcTextureId == "_AfterPostProcessTexture") {
				settings.srcType = Target.CameraColor;
				settings.srcTextureId = "";
			}
			if (settings.dstType == Target.TextureID && settings.dstTextureId == "_AfterPostProcessTexture") {
				settings.dstType = Target.CameraColor;
				settings.dstTextureId = "";
			}
		}
#endif
		renderer.EnqueuePass(m_RenderPass);
	}
}


//void OnRenderImage(RenderTexture src, RenderTexture dst) 
//{
//	Camera curruntCamera = Camera.main; 
//	Matrix4x4 matrixCameraToWorld = currentCamera.cameraToWorldMatrix; 
//	Matrix4x4 matrixProjectionInverse = GL.GetGPUProjectionMatrix(currentCamera.projectionMatrix, false).inverse; 
//	Matrix4x4 matrixHClipToWorld = matrixCameraToWorld * matrixProjectionInverse; 
//	Shader.SetGlobalMatrix("_MatrixHClipToWorld", matrixHClipToWorld); Graphics.Blit(src, dst, _material);
//}