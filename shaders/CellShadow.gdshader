shader_type canvas_item;

#include "res://shaders/debug.gdshaderinc"

// ---------- uniforms ----------
// true = Shadow, false = With light fade-out
uniform bool top_left     = false;
uniform bool top          = false;
uniform bool top_right    = false;
uniform bool right        = false;
uniform bool bot_right    = false;
uniform bool bot          = false;
uniform bool bot_left     = false;
uniform bool left         = false;

uniform float fade_distance : hint_range(0.0, 1.0) = 0.3;

// UVs in ORDER: 0 TL, 1 T, 2 TR, 3 R, 4 BR, 5 B, 6 BL, 7 L
uniform vec2 uvs[8];

// ------------------------------------------------------------------
// radial fade helper: center→1, border→0, based on scalar t in [0,1]
float dir_fade(float t, bool enabled) {
	if (enabled) return 1.0;
	float f = smoothstep(1.0 - fade_distance, 1.0, t);
	return 1.0 - f;
}

void fragment() {
	vec2 uv = UV;
	vec2 center = vec2(0.5, 0.5);
	vec2 d = uv - center;
	float alpha = 1.0;

	bool right_half = uv.x >= 0.5;
	bool bottom_half = uv.y >= 0.5;

	bool s0_enabled;
	bool s1_enabled;
	bool c_enabled;
	float s0_t;
	float s1_t;
	float c_t;

	if (!right_half && !bottom_half) {
		// top‑left: top, left, top_left
		s0_enabled = top;
		s1_enabled = left;
		c_enabled  = top_left;

		s0_t = (center.y - uv.y) / center.y;                    // top
		s1_t = (center.x - uv.x) / center.x;                    // left
		float max_len = length(center - uvs[0]);
		c_t  = length(uv - center) / max_len;                   // top_left
	} else if (right_half && !bottom_half) {
		// top‑right: top, right, top_right
		s0_enabled = top;
		s1_enabled = right;
		c_enabled  = top_right;

		s0_t = (center.y - uv.y) / center.y;                    // top
		s1_t = (uv.x - center.x) / (1.0 - center.x);            // right
		float max_len = length(center - uvs[2]);
		c_t  = length(uv - center) / max_len;                   // top_right
	} else if (right_half && bottom_half) {
		// bottom‑right: bot, right, bot_right
		s0_enabled = bot;
		s1_enabled = right;
		c_enabled  = bot_right;

		s0_t = (uv.y - center.y) / (1.0 - center.y);            // bot
		s1_t = (uv.x - center.x) / (1.0 - center.x);            // right
		float max_len = length(center - uvs[4]);
		c_t  = length(uv - center) / max_len;                   // bot_right
	} else {
		// bottom‑left: bot, left, bot_left
		s0_enabled = bot;
		s1_enabled = left;
		c_enabled  = bot_left;

		s0_t = (uv.y - center.y) / (1.0 - center.y);            // bot
		s1_t = (center.x - uv.x) / center.x;                    // left
		float max_len = length(center - uvs[6]);
		c_t  = length(uv - center) / max_len;                   // bot_left
	}

	s0_t = clamp(s0_t, 0.0, 1.0);
	s1_t = clamp(s1_t, 0.0, 1.0);
	c_t  = clamp(c_t, 0.0, 1.0);

	float f0 = dir_fade(s0_t, s0_enabled);
	float f1 = dir_fade(s1_t, s1_enabled);
	float fc = dir_fade(c_t,  c_enabled);

	alpha *= f0 * f1 * fc;

	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
