shader_type canvas_item;
render_mode blend_disabled, unshaded;

// Textures
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable;
uniform sampler2D STENCIL_TEXTURE : source_color, repeat_disable, filter_nearest;

uniform float zoom = 1.0; 

// Parameters
const vec4 marked_for_mining_stripe_color = vec4(1.0, 0.0, 0.0, 0.5);
const vec4 marked_for_mining_gap_color = vec4(1.0, 0.0, 0.0, 0.1);

uniform float divisions : hint_range(1.0, 256.0) = 128.0;
uniform float stripe_bias : hint_range(1.0, 10.0) = 1.75;
uniform float speed : hint_range(0.0, 10.0) = 0.015;
uniform float angle : hint_range(0.0, 6.283) = 0.7854; // radians


// STATIC COLORS
const vec4 mining_color = vec4(0.4, 0.18, 0.75, 0.8);

const vec4 selection_color = vec4(1.0, 1.0, 0.0, 0.2);

// for debugging
const vec4 walkable_color = vec4(0.0, 0.0, 1.0, 0.05);


const float is_solid_darken_factor = 0.35;

////////////////////////////////////////////////////////////////////////////////////////
void fragment() {
    // Get UV in world space
    vec2 uv = UV;  // SCREEN_UV also works the same

    // Sample Textures with correct UV
    vec4 screen_color = texture(SCREEN_TEXTURE, uv);
    vec4 stencil_color = texture(STENCIL_TEXTURE, uv);

    // Convert normalized color to 8-bit integer channels
    int stencil_r8 = int(round(stencil_color.r * 255.0));
    int stencil_g8 = int(round(stencil_color.g * 255.0));
    int stencil_b8 = int(round(stencil_color.b * 255.0));

    // --- RED channel flags ---
    bool is_marked_for_mining = (stencil_r8 & (1 << 0)) != 0;
    bool is_solid             = (stencil_r8 & (1 << 1)) != 0;
    bool is_selected          = (stencil_r8 & (1 << 2)) != 0;

    // --- GREEN channel fields ---
    // Extract 3-bit field starting at bit 0, then normalize to [0.0, 1.0]
    const int bitmask_3bits = (1 << 3) - 1; // 0b00000111
    int mining_process_bits = (stencil_g8 >> 0) & bitmask_3bits;
    float mining_process = float(mining_process_bits) / 7.0;

    // --- BLUE channel fields ---
    // used for debugging
    bool is_walkable    = (stencil_b8 & (1 << 6)) != 0;

    // Correct UV for aspect ratio for strip generation only
    float aspect = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
    vec2 uv_stripes = vec2(uv.x, uv.y * aspect) / zoom;

    // Stripe math
    float w = cos(angle) * uv_stripes.x + sin(angle) * uv_stripes.y - speed * TIME;
    float stripe = floor(mod(w * divisions, stripe_bias));
  

    COLOR = screen_color;

    // SOLID
    if (is_solid) {        
        COLOR.rgb *= is_solid_darken_factor;
    }

    // MINING
    if (mining_process > 0.0) {
        vec3 mining_overlay = mix(screen_color.rgb, mining_color.rgb, mining_color.a);
        COLOR.rgb = mix(COLOR.rgb, mining_overlay, mining_process);
    }

    // marked_for_mining
    if (is_marked_for_mining) {
        // Choose stripe color
        vec4 marked_for_mining_color = (stripe >= 0.5) 
            ? mix(COLOR, marked_for_mining_stripe_color, marked_for_mining_stripe_color.a) 
            : mix(COLOR, marked_for_mining_gap_color, marked_for_mining_gap_color.a);

        COLOR = marked_for_mining_color;
    }

    if (is_selected) {
        COLOR = mix(COLOR, selection_color, selection_color.a);
    }

    // WALKABLE (for debugging)
    if (is_walkable) {
        COLOR = mix(COLOR, walkable_color, walkable_color.a);
    }

    


}


