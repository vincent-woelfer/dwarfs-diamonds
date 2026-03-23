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

float cross2d(vec2 a, vec2 b) {
	return a.x * b.y - a.y * b.x;
}

// ------------------------------------------------------------------
float seg_dist(vec2 a, vec2 b, vec2 p) {
	vec2 ab = b - a;
	vec2 ap = p - a;
	float t = clamp(dot(ap, ab) / dot(ab, ab), 0.0, 1.0);
	return length(ap - ab * t);
}

float two_seg_dist(vec2 a, vec2 b, vec2 c, vec2 p) {
	return min(seg_dist(a, b, p), seg_dist(b, c, p));
}

float corner_dist(vec2 corner, vec2 p) {
	return length(corner - p);
}


// ------------------------------------------------------------------
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

		s0_dist = two_seg_dist(uvs[0], uvs[1], uvs[2], uv);  // top edge
		s1_dist = two_seg_dist(uvs[0], uvs[7], uvs[6], uv);  // left edge
        c_dist = corner_dist(uvs[0], uv);

	} else if (right_half && !bottom_half) {
		// top-right: top(1), right(3), corner TR(2)
		s0_enabled = top;
		s1_enabled = right;
		c_enabled  = top_right && !s0_enabled && !s1_enabled;

		s0_dist = two_seg_dist(uvs[2], uvs[1], uvs[0], uv);  // top edge
		s1_dist = two_seg_dist(uvs[2], uvs[3], uvs[4], uv);  // right edge
		c_dist = corner_dist(uvs[2], uv);

	} else if (right_half && bottom_half) {
		// bottom-right: bot(5), right(3), corner BR(4)
		s0_enabled = bot;
		s1_enabled = right;
		c_enabled  = bot_right && !s0_enabled && !s1_enabled;

		s0_dist = two_seg_dist(uvs[4], uvs[5], uvs[6], uv);  // bot edge
		s1_dist = two_seg_dist(uvs[4], uvs[3], uvs[2], uv);  // right edge
		c_dist = corner_dist(uvs[4], uv);

	} else {
		// bottom-left: bot(5), left(7), corner BL(6)
		s0_enabled = bot;
		s1_enabled = left;
		c_enabled  = bot_left && !s0_enabled && !s1_enabled;

		s0_dist = two_seg_dist(uvs[6], uvs[5], uvs[4], uv);  // bot edge
		s1_dist = two_seg_dist(uvs[6], uvs[7], uvs[0], uv);  // left edge
		c_dist = corner_dist(uvs[6], uv);
	}

	// s0_dist = clamp(s0_dist, 0.0, 1.0);
	// s1_dist = clamp(s1_dist, 0.0, 1.0);
	// c_dist  = clamp(c_dist, 0.0, 1.0);

	float f0 = dir_fade(s0_dist, s0_enabled);
	float f1 = dir_fade(s1_dist, s1_enabled);
	float fc = dir_fade(c_dist,  c_enabled);

	float alpha = 1.0 * f0 * f1 * fc;

	// interpolate between shadow_color (alpha=1) and border_color (alpha=0.9) using previous alpha
	vec4 color = mix(border_color, shadow_color, alpha);

	COLOR = color;
}
