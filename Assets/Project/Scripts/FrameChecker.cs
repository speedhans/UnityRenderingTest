using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FrameChecker : MonoBehaviour
{
	float deltaTime = 0.0f;

	float Timer = 0.0f;
	int perFrame = 0;
	float perFrame2 = 0.0f;

	void Update()
	{
		deltaTime += (Time.unscaledDeltaTime - deltaTime) * 0.1f;

		Timer += Time.deltaTime;
		perFrame++;
	}

	void OnGUI()
	{
		int w = Screen.width, h = Screen.height;

		GUIStyle style = new GUIStyle();

		Rect rect = new Rect(0, 0, w, h * 2 / 100);
		style.alignment = TextAnchor.UpperLeft;
		style.fontSize = h * 2 / 100;
		style.normal.textColor = new Color(1.0f, 0.0f, 0.0f, 1.0f);
		float msec = deltaTime * 1000.0f;
		float fps = 1.0f / deltaTime;

		if (Timer >= 5)
        {
			Timer = 0.0f;
			perFrame2 = perFrame / 5;
			perFrame = 0;
		}

		string text = string.Format("{0:0.0} ms ({1:0.} fps)  /  5sc ({2:0.} fps)", msec, fps, perFrame2);
		GUI.Label(rect, text, style);
	}
}
