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
// This t = distance from polygon edge/corner. 0 = on poly-edge, 1 = mid of polygon
float dir_fade(float dist, bool enabled) {
	if (!enabled) return 1.0;
	float f = smoothstep(1.0 - fade_distance, 1.0, 1.0 - dist);

	// This 1 - f is required because return value is alpha blend value
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
	
	// Determine quadrant
	bool right_half = cross2d(uvs[5] - uvs[1], uv - uvs[1]) <= 0.0;
	bool bottom_half = cross2d(uvs[3] - uvs[7], uv - uvs[7]) >= 0.0;

    // Enabled: true = lit / apply fade | false = Shadow / no fade, black till border
    // only enable corner if both sides are disabled
	bool s0_enabled;
	bool s1_enabled;
	bool c_enabled;

	// Distance from polygon edge/corner. 0 = on poly-edge, 1 = mid of polygon
	float s0_dist;
	float s1_dist;
	float c_dist;

	if (!right_half && !bottom_half) {
		// top‑left: top(1), left(7), top_left(0)
		s0_enabled = top;
		s1_enabled = left;
		c_enabled = top_left && !s0_enabled && !s1_enabled;

		
		// Inverse lerp t goes fro 0 at center/side-point to 1 at corner
		// Now perform original s_t calculation but use the projected point on the line to the corner as reference for t.
		// The formular ist (dist uv to border) / (max-dist = center to border)

		// TOP - 0 - 1 - 2
		float s0_proj_t_a = inv_lerp(uvs[0].x, uvs[1].x, uv.x);
		float s0_y_a = mix(uvs[0].y, uvs[1].y, s0_proj_t_a);
		float s0_dist_a = abs(s0_y_a - uv.y);

		// t = 0 at center, 1 at border
		float s0_proj_t_b = inv_lerp(uvs[1].x, uvs[2].x, uv.x);
		float s0_y_b = mix(uvs[1].y, uvs[2].y, s0_proj_t_b);
		float s0_dist_b = abs(s0_y_b - uv.y);

		s0_dist = min(s0_dist_a, s0_dist_b);

		// LEFT - 0 - 7 - 6
		// float s1_proj_t = inv_lerp(uvs[7].y, uvs[0].y, uv.y);
		// float s1_x = mix(uvs[7].x, uvs[0].x, s1_proj_t);
		// s1_dist = 1.0 - abs(s1_x - uv.x);

		float s1_proj_t_a = inv_lerp(uvs[0].y, uvs[7].y, uv.y);
		float s1_x_a = mix(uvs[0].x, uvs[7].x, s1_proj_t_a);
		float s1_dist_a = abs(s1_x_a - uv.x);

		// t = 0 at center, 1 at border
		float s1_proj_t_b = inv_lerp(uvs[7].y, uvs[6].y, uv.y);
		float s1_x_b = mix(uvs[7].x, uvs[6].x, s1_proj_t_b);
		float s1_dist_b =abs(s1_x_b - uv.x);

		s1_dist = min(s1_dist_a, s1_dist_b);
		

		// Corner is simply 1 - (dist to corner)
        c_dist = abs(length(uvs[0] - uv));      // top_left

	} else if (right_half && !bottom_half) {
		// top-right: top(1), right(3), corner TR(2)
		s0_enabled = top;
		s1_enabled = right;
		c_enabled  = top_right && !s0_enabled && !s1_enabled;

		float s0_proj_t = inv_lerp(uvs[1].x, uvs[2].x, uv.x);
		float s1_proj_t = inv_lerp(uvs[3].y, uvs[2].y, uv.y);

		// float s0_y = mix(uvs[1].y, uvs[2].y, s0_proj_t);
		// float s1_x = mix(uvs[3].x, uvs[2].x, s1_proj_t);

		// s0_dist = abs(s0_y - uv.y);
		// s1_dist = abs(s1_x - uv.x);

		vec2 s0_proj_point = mix(uvs[1], uvs[2], s0_proj_t);
		vec2 s1_proj_point = mix(uvs[3], uvs[2], s1_proj_t);
		s0_dist = abs(length(s0_proj_point - uv));
		s1_dist = abs(length(s1_proj_point - uv));

		c_dist  = abs(length(uvs[2] - uv));

	} else if (right_half && bottom_half) {
		// bottom-right: bot(5), right(3), corner BR(4)
		s0_enabled = bot;
		s1_enabled = right;
		c_enabled  = bot_right && !s0_enabled && !s1_enabled;

		float s0_proj_t = inv_lerp(uvs[5].x, uvs[4].x, uv.x);
		float s1_proj_t = inv_lerp(uvs[3].y, uvs[4].y, uv.y);

		// float s0_y = mix(uvs[5].y, uvs[4].y, s0_proj_t);
		// float s1_x = mix(uvs[3].x, uvs[4].x, s1_proj_t);

		// s0_dist = abs(s0_y - uv.y);
		// s1_dist = abs(s1_x - uv.x);

		vec2 s0_proj_point = mix(uvs[5], uvs[4], s0_proj_t);
		vec2 s1_proj_point = mix(uvs[3], uvs[4], s1_proj_t);
		s0_dist = abs(length(s0_proj_point - uv));
		s1_dist = abs(length(s1_proj_point - uv));

		c_dist  = abs(length(uvs[4] - uv));

	} else {
		// bottom-left: bot(5), left(7), corner BL(6)
		s0_enabled = bot;
		s1_enabled = left;
		c_enabled  = bot_left && !s0_enabled && !s1_enabled;

		float s0_proj_t = inv_lerp(uvs[5].x, uvs[6].x, uv.x);
		float s1_proj_t = inv_lerp(uvs[7].y, uvs[6].y, uv.y);

		// float s0_y = mix(uvs[5].y, uvs[6].y, s0_proj_t);
		// float s1_x = mix(uvs[7].x, uvs[6].x, s1_proj_t);

		// s0_dist = abs(s0_y - uv.y);
		// s1_dist = abs(s1_x - uv.x);
		vec2 s0_proj_point = mix(uvs[5], uvs[6], s0_proj_t);
		vec2 s1_proj_point = mix(uvs[7], uvs[6], s1_proj_t);
		s0_dist = abs(length(s0_proj_point - uv));
		s1_dist = abs(length(s1_proj_point - uv));



		c_dist  = abs(length(uvs[6] - uv));
	}

	s0_dist = clamp(s0_dist, 0.0, 1.0);
	s1_dist = clamp(s1_dist, 0.0, 1.0);
	c_dist  = clamp(c_dist, 0.0, 1.0);

	float f0 = dir_fade(s0_dist, s0_enabled);
	float f1 = dir_fade(s1_dist, s1_enabled);
	float fc = dir_fade(c_dist,  c_enabled);

	float alpha = 1.0 * f0 * f1 * fc;

	// interpolate between shadow_color (alpha=1) and border_color (alpha=0.9) using previous alpha
	vec4 color = mix(border_color, shadow_color, alpha);

	COLOR = color;
}
