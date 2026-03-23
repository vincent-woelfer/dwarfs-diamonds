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
float dir_fade(float dist) {
	float f = smoothstep(1.0 - fade_distance, 1.0, 1.0 - dist);

	// This 1 - f is required because return value is alpha blend value
	return 1.0 - f;
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
	float min_dist = 100.0;

	// Sides
	if (top) min_dist = min(min_dist, two_seg_dist(uvs[0], uvs[1], uvs[2], uv));
	if (right) min_dist = min(min_dist, two_seg_dist(uvs[2], uvs[3], uvs[4], uv));
	if (bot) min_dist = min(min_dist, two_seg_dist(uvs[4], uvs[5], uvs[6], uv));
	if (left) min_dist = min(min_dist, two_seg_dist(uvs[6], uvs[7], uvs[0], uv));

	// Corners
	if (top_left) min_dist = min(min_dist, corner_dist(uvs[0], uv));
	if (top_right) min_dist = min(min_dist, corner_dist(uvs[2], uv));
	if (bot_right) min_dist = min(min_dist, corner_dist(uvs[4], uv));
	if (bot_left) min_dist = min(min_dist, corner_dist(uvs[6], uv));

	float alpha = dir_fade(min_dist);

	// interpolate between shadow_color (alpha=1) and border_color (alpha=0.9) using previous alpha
	vec4 color = mix(border_color, shadow_color, alpha);

	COLOR = color;
}
