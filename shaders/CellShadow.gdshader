shader_type canvas_item;

// ---------- uniforms ----------
// false -> fade out to light, true -> keep fully opaque/black
uniform bool top_left     = false;
uniform bool top          = false;
uniform bool top_right    = false;
uniform bool right        = true;
uniform bool bot_right    = true;
uniform bool bot          = true;
uniform bool bot_left     = true;
uniform bool left         = true;

uniform float fade_distance = 0.5;   // fade length outside enabled edges/corners

// UVs of the eight points – fill from GDScript in the order shown above
uniform vec2 uvs[8];   // 0 TL, 1 T, 2 TR, 3 R, 4 BR, 5 B, 6 BL, 7 L

// -------------------------------------------------
vec2 compute_center() {
    vec2 c = vec2(0.0);
    for (int i = 0; i < 8; i++) c += uvs[i];
    return c / 8.0;
}

// outward normal for edge a->b (points outside the polygon)
vec2 outward_normal(vec2 a, vec2 b, vec2 center) {
    vec2  ab  = b - a;
    vec2  n   = vec2(-ab.y, ab.x);          // left‑hand normal
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

// -------------------------------------------------
void fragment() {
    vec2 uv   = UV;               // incoming fragment UV
    vec2 cen  = compute_center(); // polygon centre in UV space
    float alpha = 1.0;            // start with full opacity

    // ----- Sides -----
    if (!top) {
        float d = signed_distance_to_edge(uv, uvs[0], uvs[2], cen); // top edge TL‑TR
        if (d > 0.0) {
            float fade = smoothstep(0.0, fade_distance, d);
            alpha *= (1.0 - fade);
        }
    }
    if (!bot) {
        float d = signed_distance_to_edge(uv, uvs[6], uvs[4], cen); // bot edge BL‑BR
        if (d > 0.0) {
            float fade = smoothstep(0.0, fade_distance, d);
            alpha *= (1.0 - fade);
        }
    }
    if (!left) {
        float d = signed_distance_to_edge(uv, uvs[0], uvs[6], cen); // left edge TL‑BL
        if (d > 0.0) {
            float fade = smoothstep(0.0, fade_distance, d);
            alpha *= (1.0 - fade);
        }
    }
    if (!right) {
        float d = signed_distance_to_edge(uv, uvs[2], uvs[4], cen); // right edge TR‑BR
        if (d > 0.0) {
            float fade = smoothstep(0.0, fade_distance, d);
            alpha *= (1.0 - fade);
        }
    }

    // ----- Corners -----
    if (!top_left) {
        float d = distance_to_corner(uv, uvs[0]); // TL corner
        if (d > 0.0) {
            float fade = smoothstep(0.0, fade_distance, d);
            alpha *= (1.0 - fade);
        }
    }
    if (!top_right) {
        float d = distance_to_corner(uv, uvs[2]); // TR corner
        if (d > 0.0) {
            float fade = smoothstep(0.0, fade_distance, d);
            alpha *= (1.0 - fade);
        }
    }
    if (!bot_left) {
        float d = distance_to_corner(uv, uvs[6]); // BL corner
        if (d > 0.0) {
            float fade = smoothstep(0.0, fade_distance, d);
            alpha *= (1.0 - fade);
        }
    }
    if (!bot_right) {
        float d = distance_to_corner(uv, uvs[4]); // BR corner
        if (d > 0.0) {
            float fade = smoothstep(0.0, fade_distance, d);
            alpha *= (1.0 - fade);
        }
    }

    // ----- Output -----
    COLOR = vec4(0.0, 0.0, 0.0, alpha); // black shadow; change RGB for tint
}
