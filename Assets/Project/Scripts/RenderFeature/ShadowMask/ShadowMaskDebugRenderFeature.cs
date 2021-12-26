using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ShadowMaskDebugRenderFeature : ScriptableRendererFeature
{

	public class ShadowMaskDebugRenderPass : ScriptableRenderPass
	{

		public Material DebugMaterial = null;
		public FilterMode filterMode { get; set; }

		private BlitSettings settings;

		private RenderTargetIdentifier source { get; set; }
		private RenderTargetIdentifier destination { get; set; }

		RenderTargetHandle m_TemporaryColorTexture;
		RenderTargetHandle m_DestinationTexture;
		string m_ProfilerTag;

		public ShadowMaskDebugRenderPass(RenderPassEvent renderPassEvent, BlitSettings settings, string tag)
		{
			this.renderPassEvent = renderPassEvent;
			this.settings = settings;
			DebugMaterial = settings.DebugMaterial;
			m_ProfilerTag = tag;
			m_TemporaryColorTexture.Init("_TemporaryColorTexture");
		}

		public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
		{
			CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
			RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;
			opaqueDesc.depthBufferBits = 0;

			// Set Source / Destination
			// note : Seems this has to be done in here rather than in AddRenderPasses to work correctly in 2021.2+
			var renderer = renderingData.cameraData.renderer;
			source = renderer.cameraColorTarget;
			destination = renderer.cameraColorTarget;

			//DebugMaterial.SetTexture("_ShadowMaskTexture", ShadowMaskManager.Instance.GetMaskTexture());

			Blit(cmd, source, destination, DebugMaterial);

			context.ExecuteCommandBuffer(cmd);
			CommandBufferPool.Release(cmd);
		}
	}

	[System.Serializable]
	public class BlitSettings
	{
		public RenderPassEvent Event = RenderPassEvent.AfterRenderingOpaques;

		public Material DebugMaterial = null;
		public bool overrideGraphicsFormat = false;
		public UnityEngine.Experimental.Rendering.GraphicsFormat graphicsFormat;
	}

	public enum Target
	{
		CameraColor,
		TextureID,
		RenderTextureObject
	}

	public BlitSettings settings = new BlitSettings();
	public ShadowMaskDebugRenderPass blitPass;

	public override void Create()
	{
		var passIndex = settings.DebugMaterial != null ? settings.DebugMaterial.passCount - 1 : 1;
		blitPass = new ShadowMaskDebugRenderPass(settings.Event, settings, name);

#if !UNITY_2021_2_OR_NEWER
		if (settings.Event == RenderPassEvent.AfterRenderingPostProcessing) {
			Debug.LogWarning("Note that the \"After Rendering Post Processing\"'s Color target doesn't seem to work? (or might work, but doesn't contain the post processing) :( -- Use \"After Rendering\" instead!");
		}
#endif

		if (settings.graphicsFormat == UnityEngine.Experimental.Rendering.GraphicsFormat.None)
		{
			settings.graphicsFormat = SystemInfo.GetGraphicsFormat(UnityEngine.Experimental.Rendering.DefaultFormat.LDR);
		}
	}

	public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
	{
		if (settings.DebugMaterial == null)
		{
			Debug.LogWarningFormat("Missing Blit Material. {0} blit pass will not execute. Check for missing reference in the assigned renderer.", GetType().Name);
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

		renderer.EnqueuePass(blitPass);
	}
}