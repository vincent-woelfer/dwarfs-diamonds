shader_type canvas_item;

#include "res://shaders/debug.gdshaderinc"

// ---------- uniforms ----------
uniform bool top_left     = true;
uniform bool top          = true;
uniform bool top_right    = false;
uniform bool right        = true;
uniform bool bot_right    = false;
uniform bool bot          = true;
uniform bool bot_left     = false;
uniform bool left         = true;

uniform float fade_distance : hint_range(0.0, 1.0) = 0.3;

// UVs in ORDER: 0 TL, 1 T, 2 TR, 3 R, 4 BR, 5 B, 6 BL, 7 L
uniform vec2 uvs[8];

// ------------------------------------------------------------------
// outward normal for edge a->b (points outside the polygon)
vec2 outward_normal(vec2 a, vec2 b, vec2 center) {
    vec2 ab = b - a;
	// left‑hand normal
    vec2 n = vec2(-ab.y, ab.x);
    // if n points toward the centre, flip it
    return dot(center - a, n) > 0.0 ? -n : n;
}

// signed distance to edge a->b (positive = outside)
float signed_distance_to_edge(vec2 p, vec2 a, vec2 b, vec2 center) {
    vec2 n = outward_normal(a, b, center);
    return dot(p - a, n);
}

// distance to a corner point
float distance_to_corner(vec2 p, vec2 c) {
    return length(p - c);
}

// ------------------------------------------------------------------
void fragment() {
	Debug dbg = debug_construct(UV);

	vec2 uv = UV;
    vec2 center = vec2(0.5, 0.5);
    float alpha = 1.0;

    // ----- Sides -----
    if (!top) {
        float d = signed_distance_to_edge(uv, uvs[0], uvs[2], center); // top edge TL‑TR
        if (d > 0.0) {
            float fade = smoothstep(0.0, fade_distance, d);
            alpha *= (1.0 - fade);
        }

		dbgFloat(dbg, d);
    }
    if (!bot) {
        float d = signed_distance_to_edge(uv, uvs[6], uvs[4], center); // bot edge BL‑BR
        if (d > 0.0) {
            float fade = smoothstep(0.0, fade_distance, d);
            alpha *= (1.0 - fade);
        }
    }
    if (!left) {
        float d = signed_distance_to_edge(uv, uvs[0], uvs[6], center); // left edge TL‑BL
        if (d > 0.0) {
            float fade = smoothstep(0.0, fade_distance, d);
            alpha *= (1.0 - fade);
        }
    }
    if (!right) {
        float d = signed_distance_to_edge(uv, uvs[2], uvs[4], center); // right edge TR‑BR
        if (d > 0.0) {
            float fade = smoothstep(0.0, fade_distance, d);
            alpha *= (1.0 - fade);
        }
    }

    // ----- Corners -----
    // if (!top_left) {
    //     float d = distance_to_corner(uv, uvs[0]); // TL corner
    //     if (d > 0.0) {
    //         float fade = smoothstep(0.0, fade_distance, d);
    //         alpha *= (1.0 - fade);
    //     }
    // }
    // if (!top_right) {
    //     float d = distance_to_corner(uv, uvs[2]); // TR corner
    //     if (d > 0.0) {
    //         float fade = smoothstep(0.0, fade_distance, d);
    //         alpha *= (1.0 - fade);
    //     }
    // }
    // if (!bot_left) {
    //     float d = distance_to_corner(uv, uvs[6]); // BL corner
    //     if (d > 0.0) {
    //         float fade = smoothstep(0.0, fade_distance, d);
    //         alpha *= (1.0 - fade);
    //     }
    // }
    // if (!bot_right) {
    //     float d = distance_to_corner(uv, uvs[4]); // BR corner
    //     if (d > 0.0) {
    //         float fade = smoothstep(0.0, fade_distance, d);
    //         alpha *= (1.0 - fade);
    //     }
    // }

    // ----- Output -----	
    COLOR = vec4(0.0, 0.0, 0.0, alpha);

	// Debug dbg = debug_construct(UV);
	// dbgFloat(dbg, UV.x);
	debug_finish(COLOR.rgb, dbg);
}
