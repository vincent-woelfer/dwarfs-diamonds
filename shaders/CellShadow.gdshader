shader_type canvas_item;

#include "res://shaders/debug.gdshaderinc"

// ---------- uniforms ----------
// true = lit / apply fade | false = Shadow / no fade, black till border
uniform bool top_left     = false;
uniform bool top          = false;
uniform bool top_right    = false;
uniform bool right        = false;
uniform bool bot_right    = false;
uniform bool bot          = false;
uniform bool bot_left     = false;
uniform bool left         = false;

// 
uniform float fade_distance : hint_range(0.0, 1.0) = 0.4;

// UVs in ORDER: 0 TL, 1 T, 2 TR, 3 R, 4 BR, 5 B, 6 BL, 7 L
uniform vec2 uvs[8];

uniform vec4 shadow_color  : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 border_color  : source_color = vec4(0.0, 0.0, 0.0, 0.3);


// ------------------------------------------------------------------
// 1 = point directly at border, 0 = point at center
float dir_fade(float t, bool enabled) {
	if (!enabled) return 1.0;
	float f = smoothstep(1.0 - fade_distance, 1.0, t);
	return 1.0 - f;
}

float inv_lerp(float from, float to, float value){
	float t = (value - from) / (to - from);
	// t = clamp(t, 0.0, 1.0);
	return t;
}

float cross2d(vec2 a, vec2 b) {
	return a.x * b.y - a.y * b.x;
}

void fragment() {
	vec2 uv = UV;
	
	// We want uniform shadow depth, NOT scaled by actual distance edge to center
	float max_dist = 0.5; 

	// Determine quadrant
	bool right_half = cross2d(uvs[5] - uvs[1], uv - uvs[1]) <= 0.0;
	bool bottom_half = cross2d(uvs[3] - uvs[7], uv - uvs[7]) >= 0.0;

    // Enabled: true = lit / apply fade | false = Shadow / no fade, black till border
    // only enable corner if both sides are disabled
	bool s0_enabled;
	bool s1_enabled;
	bool c_enabled;
	float s0_t;
	float s1_t;
	float c_t;

	if (!right_half && !bottom_half) {
		// top‑left: top(1), left(7), top_left(0)
		s0_enabled = top;
		s1_enabled = left;
		c_enabled = top_left && !s0_enabled && !s1_enabled;

		// t = 0 at center, 1 at border
		// Inverse lerp t goes fro 0 at center/side-point to 1 at corner
		float s0_proj_t = inv_lerp(uvs[1].x, uvs[0].x, uv.x);               // top
		float s1_proj_t = inv_lerp(uvs[7].y, uvs[0].y, uv.y);               // left

		float s0_y = mix(uvs[1].y, uvs[0].y, s0_proj_t);               // top
		float s1_x = mix(uvs[7].x, uvs[0].x, s1_proj_t);               // left

		// No perform original s_t calculation but use the projected point on the line to the corner as reference for t.
		// The formular ist (dist uv to border) / (max-dist = center to border)
		s0_t = 1.0 - abs((s0_y - uv.y) / max_dist);               // top
		s1_t = 1.0 - abs((s1_x - uv.x) / max_dist);               // left

		// Corner is simply 1 - (dist to corner) / (max dist = center to corner)
        c_t = 1.0 - abs(length(uvs[0] - uv) / max_dist);      // top_left

	} else if (right_half && !bottom_half) {
		// top-right: top(1), right(3), corner TR(2)
		s0_enabled = top;
		s1_enabled = right;
		c_enabled  = top_right && !s0_enabled && !s1_enabled;

		float s0_proj_t = inv_lerp(uvs[1].x, uvs[2].x, uv.x);
		float s1_proj_t = inv_lerp(uvs[3].y, uvs[2].y, uv.y);

		float s0_y = mix(uvs[1].y, uvs[2].y, s0_proj_t);
		float s1_x = mix(uvs[3].x, uvs[2].x, s1_proj_t);

		s0_t = 1.0 - abs((s0_y - uv.y) / max_dist);
		s1_t = 1.0 - abs((s1_x - uv.x) / max_dist);
		c_t  = 1.0 - abs(length(uvs[2] - uv) / max_dist);

	} else if (right_half && bottom_half) {
		// bottom-right: bot(5), right(3), corner BR(4)
		s0_enabled = bot;
		s1_enabled = right;
		c_enabled  = bot_right && !s0_enabled && !s1_enabled;

		float s0_proj_t = inv_lerp(uvs[5].x, uvs[4].x, uv.x);
		float s1_proj_t = inv_lerp(uvs[3].y, uvs[4].y, uv.y);

		float s0_y = mix(uvs[5].y, uvs[4].y, s0_proj_t);
		float s1_x = mix(uvs[3].x, uvs[4].x, s1_proj_t);

		s0_t = 1.0 - abs((s0_y - uv.y) / max_dist);
		s1_t = 1.0 - abs((s1_x - uv.x) / max_dist);
		c_t  = 1.0 - abs(length(uvs[4] - uv) / max_dist);

	} else {
		// bottom-left: bot(5), left(7), corner BL(6)
		s0_enabled = bot;
		s1_enabled = left;
		c_enabled  = bot_left && !s0_enabled && !s1_enabled;

		float s0_proj_t = inv_lerp(uvs[5].x, uvs[6].x, uv.x);
		float s1_proj_t = inv_lerp(uvs[7].y, uvs[6].y, uv.y);

		float s0_y = mix(uvs[5].y, uvs[6].y, s0_proj_t);
		float s1_x = mix(uvs[7].x, uvs[6].x, s1_proj_t);

		s0_t = 1.0 - abs((s0_y - uv.y) / max_dist);
		s1_t = 1.0 - abs((s1_x - uv.x) / max_dist);
		c_t  = 1.0 - abs(length(uvs[6] - uv) / max_dist);
	}

	s0_t = clamp(s0_t, 0.0, 1.0);
	s1_t = clamp(s1_t, 0.0, 1.0);
	c_t  = clamp(c_t, 0.0, 1.0);

	float f0 = dir_fade(s0_t, s0_enabled);
	float f1 = dir_fade(s1_t, s1_enabled);
	float fc = dir_fade(c_t,  c_enabled);

	float alpha = 1.0 * f0 * f1 * fc;

	// interpolate between shadow_color (alpha=1) and border_color (alpha=0.9) using previous alpha
	vec4 color = mix(border_color, shadow_color, alpha);

	COLOR = color;
}
