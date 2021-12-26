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
    }

    public class ShadowMaskRenderFeaturePass : ScriptableRenderPass
    {
		MaskSetting m_Setting;
		RenderTexture m_RenderTexture;

		public ShadowMaskRenderFeaturePass(MaskSetting InSetting)
		{
			this.renderPassEvent = InSetting.m_Pass;
			this.m_Setting = InSetting;
		}

		public void Setup()
		{
			if (m_RenderTexture)
            {
				m_RenderTexture.Release();
			}
			
			m_RenderTexture = new RenderTexture(Screen.width / 2, Screen.height / 2, 0, RenderTextureFormat.R8);//new RenderTexture(Screen.width / 2, Screen.height / 2, 0, RenderTextureFormat.R8);
			m_RenderTexture.enableRandomWrite = true;

			Debug.LogFormat("Screen Size: {0}  ,  {1}", Screen.width, Screen.height);
			Debug.LogFormat("MaskBuffer Size: {0}  ,  {1}", m_RenderTexture.width, m_RenderTexture.height);

			ShadowMaskManager.Instance.SetMaskTexture(m_RenderTexture);
		}

		public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
		{
			if (m_RenderTexture == null)
				return;

			m_Setting.m_ComputeShader.SetTexture(0, "_MaskTexture", m_RenderTexture);
			m_Setting.m_ComputeShader.SetFloats("_TextureSize", new float[] { m_RenderTexture.width, m_RenderTexture.height });
			m_Setting.m_ComputeShader.Dispatch(0, m_RenderTexture.width / 32, m_RenderTexture.height / 32, 1);

			m_Setting.m_ComputeShader.SetTexture(1, "_MaskTexture", m_RenderTexture);
			m_Setting.m_ComputeShader.Dispatch(1, m_RenderTexture.width / 4 / 32, m_RenderTexture.height / 4 / 32, 1);
			
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