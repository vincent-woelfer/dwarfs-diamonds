shader_type canvas_item;
render_mode unshaded;

// Textures
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable;
uniform sampler2D STENCIL_TEXTURE : source_color, repeat_disable, filter_nearest;

uniform float zoom = 1.0; 

// Parameters
const vec4 marked_for_mining_stripe_color = vec4(1.0, 0.0, 0.0, 0.35);
const vec4 marked_for_mining_gap_color = vec4(1.0, 0.0, 0.0, 0.2);

const float divisions = 128.0;
const float stripe_bias = 1.75;
const float speed = 0.012;
const float angle = 0.7854; // radians

// STATIC COLORS
const vec4 mining_color = vec4(0.4, 0.18, 0.75, 0.8);
const vec4 highlight_color = vec4(1.0, 1.0, 0.0, 0.2);

const float is_solid_max_darken_factor = 0.5;
const float is_solid_flat_offset = 0.10;


////////////////////////////////////////////////////////////////////////////////////////
float sample_is_solid(vec2 uv) {
    vec4 stencil_color = texture(STENCIL_TEXTURE, uv);
    int stencil_r8 = int(round(stencil_color.r * 255.0));
    bool is_solid             = (stencil_r8 & (1 << 1)) != 0;

    // soild = dark = 0.0, not solid = bright = 1.0
    return is_solid ? 0.0 : 1.0;
}    

////////////////////////////////////////////////////////////////////////////////////////
void fragment() {
    // Get UV in world space - SCREEN_UV also works the same
    vec2 uv = UV;

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
    bool is_highlighted       = (stencil_r8 & (1 << 2)) != 0;

    // --- GREEN channel fields ---
    // Extract 3-bit field starting at bit 0, then normalize to [0.0, 1.0]
    const int bitmask_3bits = (1 << 3) - 1; // 0b00000111
    int mining_process_bits = (stencil_g8 >> 0) & bitmask_3bits;
    float mining_process = float(mining_process_bits) / 7.0;

    // --- BLUE channel fields ---
    // used for debugging

    // Correct UV for aspect ratio for strip generation only
    float aspect = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
    vec2 uv_stripes = vec2(uv.x, uv.y * aspect) / zoom;

    // Stripes for "marked for mining" effect
    float w = cos(angle) * uv_stripes.x + sin(angle) * uv_stripes.y - speed * TIME;
    float stripe = floor(mod(w * divisions, stripe_bias));
  
    ////////////////////////////////////////////////////////////////////////////////////////
    // Start with screen color
    COLOR = screen_color;

    // IS_SOLID -> darken
    if (is_solid) {   
        // ORIGINAL:
        // TODO removed when light_depth was added
        // COLOR.rgb *= is_solid_max_darken_factor;

        // float darkness_factor = blur_is_solid(uv, SCREEN_PIXEL_SIZE);
        // darkness_factor -= is_solid_flat_offset;
        // darkness_factor = clamp(darkness_factor, 0.0, 1.0);
        // darkness_factor = mix(is_solid_max_darken_factor, 1.0, darkness_factor);
        // COLOR.rgb *= darkness_factor;
    }

    // MINING PROGRESS
    if (mining_process > 0.0) {
        vec3 mining_overlay = mix(screen_color.rgb, mining_color.rgb, mining_color.a);
        COLOR.rgb = mix(COLOR.rgb, mining_overlay, mining_process);
    }

    // MARKED FOR MINING
    if (is_marked_for_mining) {
        // Choose stripe color
        vec4 marked_for_mining_color = (stripe >= 0.5) 
            ? mix(COLOR, marked_for_mining_stripe_color, marked_for_mining_stripe_color.a) 
            : mix(COLOR, marked_for_mining_gap_color, marked_for_mining_gap_color.a);

        COLOR = marked_for_mining_color;
    }

    // IS HIGHLIGHTED (when hovered over)
    if (is_highlighted) {
        COLOR = mix(COLOR, highlight_color, highlight_color.a);
    }

}



