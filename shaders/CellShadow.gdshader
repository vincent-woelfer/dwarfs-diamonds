shader_type canvas_item;

#include "res://shaders/debug.gdshaderinc"

uniform bool top_left     = true;
uniform bool top          = true;
uniform bool top_right    = true;
uniform bool right        = false;
uniform bool bot_right    = false;
uniform bool bot          = false;
uniform bool bot_left     = false;
uniform bool left         = false;

uniform float fade_distance : hint_range(0.0, 1.0) = 0.3;

// 0 TL, 1 T, 2 TR, 3 R, 4 BR, 5 B, 6 BL, 7 L
// uniform vec2 uvs[8];

void fragment() {
	// vec2 center = vec2(0.5, 0.5);
	// float center_dist = distance(UV, center);
	
	// float min_side_dist = 1.0;
	
	// // Sides
	// if (left) min_side_dist = min(min_side_dist, UV.x);
	// if (right) min_side_dist = min(min_side_dist, 1.0 - UV.x);
	// if (top) min_side_dist = min(min_side_dist, UV.y);
	// if (bot) min_side_dist = min(min_side_dist, 1.0 - UV.y);
		
	// Corners
	// if (top_left) min_side_dist = min(min_side_dist, min(UV.x, UV.y));
	// if (top_right) min_side_dist = min(min_side_dist, min(1.0 - UV.x, UV.y));
	// if (bot_left) min_side_dist = min(min_side_dist, min(UV.x, 1.0 - UV.y));
	// if (bot_right) min_side_dist = min(min_side_dist, min(1.0 - UV.x, 1.0 - UV.y));
	
	// float fade = 1.0 - smoothstep(0.0, fade_distance, min_side_dist);
	// float alpha = 1.0 - center_dist;
	// alpha = mix(alpha, fade, step(fade_distance, min_side_dist));
	
	// COLOR.a = alpha;
	// COLOR.rgb = vec3(1.0, 0.0, 0.5);
    //COLOR.a = 1.0 - min_side_dist;

	COLOR.rgb = vec3(UV.x, UV.y, sin(TIME*3.0) * 0.5 + 0.5);

	Debug dbg = debug_construct(UV);
	dbgFloat(dbg, TIME);
	debug_finish(COLOR.rgb, dbg);
}
