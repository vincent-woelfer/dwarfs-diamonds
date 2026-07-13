shader_type canvas_item;

render_mode blend_mix, unshaded;

// #include "res://shaders/debug.gdshaderinc"

// ---------- uniforms ----------
group_uniforms GlobalParameters;	
uniform float total_penetration_distance : hint_range(0.0, 1.0) = 0.3;

// Colors go from lit_color -> fade_color -> unlit_color.
// fade_threshold [0,1] determines where the transition happens.
// Colors are set in Godot Code in Colors
uniform float fade_threshold : hint_range(0.0, 1.0) = 0.3;
uniform vec4 lit_color : source_color;
uniform vec4 fade_color : source_color;
uniform vec4 unlit_color : source_color;

// ---------- instance uniforms ----------
group_uniforms InstanceParameters;	
// 0  = fully lit, dont write anything
// 1  = apply fade based on neighbour_lit_bits
// 2+ = fully dark
instance uniform uint light_depth;

// Points in ORDER: 0 TL, 1 T, 2 TR, 3 R, 4 BR, 5 B, 6 BL, 7 L
// true = lit / apply fade | false = Shadow / no fade, black till border
instance uniform uint neighbour_lit_bits;

// UVs for poly points
instance uniform vec2 uvs_0;
instance uniform vec2 uvs_1;
instance uniform vec2 uvs_2;
instance uniform vec2 uvs_3;
instance uniform vec2 uvs_4;
instance uniform vec2 uvs_5;
instance uniform vec2 uvs_6;
instance uniform vec2 uvs_7;

// ------------------------------------------------------------------
// This t = distance from polygon edge/corner. 0 = on poly-edge, 1 = mid of polygon
float dir_fade(float dist) {
	float f = smoothstep(1.0 - total_penetration_distance, 1.0, 1.0 - dist);
	return clamp(1.0 - f, 0.0, 1.0);
}

bool get_neighbour_lit(int idx) {
	return bool((neighbour_lit_bits >> uint(idx)) & 1u);
}

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
	if (light_depth > 2u) {
		// Directly white unlit color
		COLOR = unlit_color;
	} else {

		vec2 uv = UV;
		float min_dist = 100.0;

		// Sides
		if (get_neighbour_lit(1)) min_dist = min(min_dist, two_seg_dist(uvs_0, uvs_1, uvs_2, uv));
		if (get_neighbour_lit(3)) min_dist = min(min_dist, two_seg_dist(uvs_2, uvs_3, uvs_4, uv));
		if (get_neighbour_lit(5)) min_dist = min(min_dist, two_seg_dist(uvs_4, uvs_5, uvs_6, uv));
		if (get_neighbour_lit(7)) min_dist = min(min_dist, two_seg_dist(uvs_6, uvs_7, uvs_0, uv));

		// Corners
		if (get_neighbour_lit(0)) min_dist = min(min_dist, corner_dist(uvs_0, uv));
		if (get_neighbour_lit(2)) min_dist = min(min_dist, corner_dist(uvs_2, uv));
		if (get_neighbour_lit(4)) min_dist = min(min_dist, corner_dist(uvs_4, uv));
		if (get_neighbour_lit(6)) min_dist = min(min_dist, corner_dist(uvs_6, uv));

		float color_progress_t = dir_fade(min_dist);

		// interpolate between lit_color (t=0) -> face_color(t=threshold) unlit_color (t=1)
		vec4 color;
		if (color_progress_t < fade_threshold) {
			color = mix(lit_color, fade_color, color_progress_t / fade_threshold);
		} else {
			color = mix(fade_color, unlit_color, (color_progress_t - fade_threshold) / (1.0 - fade_threshold));
		}

		// This is a modulate color because the shader is its own material applied on top of the cell color.
		// This overwrites the FINAL color of the shadow poly. Since alpha is present, this will still show the cell color + lightning underneath
		COLOR = color;
	}
}
