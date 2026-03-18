shader_type canvas_item;

#include "debug.gdshaderinc"

instance uniform bool top_left     = true;
instance uniform bool top          = true;
instance uniform bool top_right    = true;
instance uniform bool right        = false;
instance uniform bool bot_right    = false;
instance uniform bool bot          = false;
instance uniform bool bot_left     = false;
instance uniform bool left         = false;

uniform float fade_distance : hint_range(0.0, 1.0) = 0.3;

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
	COLOR.rgb = vec3(1.0, 0.0, 0.5);
    //COLOR.a = 1.0 - min_side_dist;

	Debug dbg = debug_construct(SCREEN_UV);
	dbgFloat(dbg, 0.5);
	debug_finish(COLOR.rgb, dbg);
}
