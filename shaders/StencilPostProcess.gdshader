shader_type canvas_item;
render_mode blend_disabled, unshaded;

// Textures
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable;
uniform sampler2D STENCIL_TEXTURE : source_color, repeat_disable, filter_nearest;

// Parameters
const vec4 highlight_stripe_color = vec4(1.0, 0.0, 0.0, 0.8);
const vec4 highlight_gap_color = vec4(1.0, 0.0, 0.0, 0.2);

uniform float divisions : hint_range(1.0, 256.0) = 128.0;
uniform float stripe_bias : hint_range(1.0, 10.0) = 1.75;
uniform float speed : hint_range(0.0, 10.0) = 0.015;
uniform float angle : hint_range(0.0, 6.283) = 0.7854; // radians


// Mining = 54, 15, 90
const vec4 mining_color = vec4(0.211, 0.058, 0.352, 0.8);


////////////////////////////////////////////////////////////////////////////////////////
void fragment() {
    // Get UV in world space
    vec2 uv = SCREEN_UV;  // UV also works

    // Sample Textures with correct UV
    vec4 screen_color = texture(SCREEN_TEXTURE, uv);
    vec4 stencil_color = texture(STENCIL_TEXTURE, uv);

    // Convert normalized color to 8-bit integer channels
    int stencil_r8 = int(round(stencil_color.r * 255.0));
    int stencil_g8 = int(round(stencil_color.g * 255.0));
    int stencil_b8 = int(round(stencil_color.b * 255.0));

    // --- RED channel flags ---
    bool highlight = (stencil_r8 & (1 << 0)) != 0;
    bool is_solid  = (stencil_r8 & (1 << 1)) != 0;

    // --- GREEN channel fields ---
    // Extract 3-bit field starting at bit 0, then normalize to [0.0, 1.0]
    int mining_process_bits = (stencil_g8 >> 0) & 7;
    float mining_process = float(mining_process_bits) / 7.0;


    // Correct UV for aspect ratio for strip generation only
    float aspect = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
    vec2 uv_stripes = vec2(uv.x, uv.y * aspect);

    // Stripe math
    float w = cos(angle) * uv_stripes.x + sin(angle) * uv_stripes.y - speed * TIME;
    float stripe = floor(mod(w * divisions, stripe_bias));
  

    COLOR = screen_color;

    // SOLID
    if (is_solid) {
        float darken_factor = 0.8;
        COLOR.rgb *= darken_factor;
    }

    // MINING
    if (mining_process > 0.0) {
        vec3 mining_overlay = mix(screen_color.rgb, mining_color.rgb, mining_color.a);
        COLOR.rgb = mix(COLOR.rgb, mining_overlay, mining_process);
    }

    // HIGHLIGHT
    if (highlight) {
        // Choose stripe color
        vec4 highlight_color = (stripe >= 0.5) 
            ? mix(COLOR, highlight_stripe_color, highlight_stripe_color.a) 
            : mix(COLOR, highlight_gap_color, highlight_gap_color.a);

        COLOR = highlight_color;
    }

    


}


