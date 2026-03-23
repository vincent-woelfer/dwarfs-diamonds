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

// > 0.4 breaks visually on corners
uniform float fade_distance : hint_range(0.0, 0.4) = 0.25;

// UVs in ORDER: 0 TL, 1 T, 2 TR, 3 R, 4 BR, 5 B, 6 BL, 7 L
uniform vec2 uvs[8];

uniform vec4 shadow_color  : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 border_color  : source_color = vec4(0.5, 0.0, 0.0, 0.1);


// ------------------------------------------------------------------
// 1 = point directly at border, 0 = point at center
float dir_fade(float t, bool enabled) {
	if (!enabled) return 1.0;
	float f = smoothstep(1.0 - fade_distance, 1.0, t);
	return 1.0 - f;
}

void fragment() {
	vec2 uv = UV;
	vec2 center = vec2(0.5, 0.5);
	float alpha = 1.0;

	bool right_half = uv.x >= 0.5;
	bool bottom_half = uv.y >= 0.5;

    // Enabled: true = lit / apply fade | false = Shadow / no fade, black till border
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
		c_enabled  = top_left && !s0_enabled && !s1_enabled; // only enable corner if both sides are disabled

        // Sides
        // / center.x = 0.5 since this is the max-len of this side if ignoring UVs
        // 1 = point directly at border, 0 = point at center
		s0_t = (center.y - uv.y) / center.y;                    // top
		s1_t = (center.x - uv.x) / center.x;                    // left

        // Corner
		//float max_len = length(center - uvs[0]);
		//c_t  = length(uv - center) / max_len;                   // top_left

        // TODO
        c_t = 1.0 - length(uv - vec2(0.0, 0.0)) / 0.5; 

	} else if (right_half && !bottom_half) {
		// top‑right: top, right, top_right
		s0_enabled = top;
		s1_enabled = right;
		c_enabled  = top_right && !s0_enabled && !s1_enabled; // only enable corner if both sides are disabled

        // Sides
		s0_t = (center.y - uv.y) / center.y;                    // top
		s1_t = (uv.x - center.x) / (1.0 - center.x);            // right

        // Corner
        // float max_len = length(center - uvs[2]);
		// c_t  = length(uv - center) / max_len;                   // top_right
        c_t = 1.0 - length(uv - vec2(1.0, 0.0)) / 0.5; 

	} else if (right_half && bottom_half) {
		// bottom‑right: bot, right, bot_right
		s0_enabled = bot;
		s1_enabled = right;
		c_enabled  = bot_right && !s0_enabled && !s1_enabled; // only enable corner if both sides are disabled

        // Sides
		s0_t = (uv.y - center.y) / (1.0 - center.y);            // bot
		s1_t = (uv.x - center.x) / (1.0 - center.x);            // right

        // Corner
		// float max_len = length(center - uvs[4]);
		// c_t  = length(uv - center) / max_len;                   // bot_right
        c_t = 1.0 - length(uv - vec2(1.0, 1.0)) / 0.5; 
	} else {
		// bottom‑left: bot, left, bot_left
		s0_enabled = bot;
		s1_enabled = left;
		c_enabled  = bot_left && !s0_enabled && !s1_enabled; // only enable corner if both sides are disabled

        // Sides
		s0_t = (uv.y - center.y) / (1.0 - center.y);            // bot
		s1_t = (center.x - uv.x) / center.x;                    // left

        // Corner
		// float max_len = length(center - uvs[6]);
		// c_t  = length(uv - center) / max_len;                   // bot_left
        c_t = 1.0 - length(uv - vec2(0.0, 1.0)) / 0.5; 
	}

	s0_t = clamp(s0_t, 0.0, 1.0);
	s1_t = clamp(s1_t, 0.0, 1.0);
	c_t  = clamp(c_t, 0.0, 1.0);

	float f0 = dir_fade(s0_t, s0_enabled);
	float f1 = dir_fade(s1_t, s1_enabled);
	float fc = dir_fade(c_t,  c_enabled);

	alpha *= f0 * f1 * fc;

	// interpolate between shadow_color (alpha=1) and border_color (alpha=0.9) using previous alpha
	vec4 color = mix(border_color, shadow_color, alpha);

	COLOR = color;
}
