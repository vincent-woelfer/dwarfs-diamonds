shader_type canvas_item;

// Corners
uniform bool top_left = true;
uniform bool top_right = false;
uniform bool bottom_left = false;
uniform bool bottom_right = false;
// Sides
uniform bool left = true;
uniform bool right = false;
uniform bool top = false;
uniform bool bottom = true;

void fragment() {
    vec2 uv = UV;
    vec2 center = vec2(0.5, 0.5);
    vec2 offset = uv - center;

    float p_top    = max(0.0, offset.y * 2.0);
    float p_bottom = max(0.0, -offset.y * 2.0);
    float p_left   = max(0.0, -offset.x * 2.0);
    float p_right  = max(0.0, offset.x * 2.0);

    float p_top_left    = min(p_top, p_left);
    float p_top_right   = min(p_top, p_right);
    float p_bottom_left = min(p_bottom, p_left);
    float p_bottom_right = min(p_bottom, p_right);

    float alpha = 1.0;
    float fade_distance = 1.0;

    if (!top) {
        alpha = min(alpha, 1.0 - smoothstep(0.0, fade_distance, p_top));
    }
    if (!bottom) {
        alpha = min(alpha, 1.0 - smoothstep(0.0, fade_distance, p_bottom));
    }
    if (!left) {
        alpha = min(alpha, 1.0 - smoothstep(0.0, fade_distance, p_left));
    }
    if (!right) {
        alpha = min(alpha, 1.0 - smoothstep(0.0, fade_distance, p_right));
    }
    if (!top_left) {
        alpha = min(alpha, 1.0 - smoothstep(0.0, fade_distance, p_top_left));
    }
    if (!top_right) {
        alpha = min(alpha, 1.0 - smoothstep(0.0, fade_distance, p_top_right));
    }
    if (!bottom_left) {
        alpha = min(alpha, 1.0 - smoothstep(0.0, fade_distance, p_bottom_left));
    }
    if (!bottom_right) {
        alpha = min(alpha, 1.0 - smoothstep(0.0, fade_distance, p_bottom_right));
    }

    // Alpha = 1 -> fully black/shadow
    // Alpha = 0 -> fully transparent/no shadow
    alpha = 0.5;
    COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
