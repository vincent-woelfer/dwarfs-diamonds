shader_type canvas_item;
render_mode blend_disabled, unshaded;

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

const vec4 selection_color = vec4(1.0, 1.0, 0.0, 0.2);

// for debugging
const vec4 walkable_color = vec4(0.0, 0.0, 1.0, 0.05);


const float is_solid_max_darken_factor = 0.15;
const float is_solid_blur_radius = 350.0;
const float is_solid_flat_offset = 0.05;


////////////////////////////////////////////////////////////////////////////////////////
float sample_is_solid(vec2 uv) {
    vec4 stencil_color = texture(STENCIL_TEXTURE, uv);
    int stencil_r8 = int(round(stencil_color.r * 255.0));
    bool is_solid             = (stencil_r8 & (1 << 1)) != 0;

    // soild = dark = 0.0, not solid = bright = 1.0
    return is_solid ? 0.0 : 1.0;
}


// HORIZONTAL GAUSSIAN BLUR
float blur_is_solid_horizontal(vec2 uv, vec2 screen_pixel_size) {
    float sigma = is_solid_blur_radius * 0.25; // controls blur softness
    int radius = int(ceil(sigma * 2.0)); // how many pixels out to sample

    float sum = 0.0;
    float weight_sum = 0.0;

    for (int i = -radius; i <= radius; i++) {
        float w = exp(-0.5 * pow(float(i) / sigma, 2.0)); // Gaussian weight
        vec2 offset = vec2(screen_pixel_size.x * float(i) * zoom, 0.0);
        sum += sample_is_solid(uv + offset) * w;
        weight_sum += w;
    }

    return sum / weight_sum;
}

// VERTICAL GAUSSIAN BLUR
float blur_is_solid_vertical(vec2 uv, vec2 screen_pixel_size) {
    float sigma = is_solid_blur_radius * 0.25;
    int radius = int(ceil(sigma * 2.0));

    float sum = 0.0;
    float weight_sum = 0.0;

    for (int i = -radius; i <= radius; i++) {
        float w = exp(-0.5 * pow(float(i) / sigma, 2.0));
        vec2 offset = vec2(0.0, screen_pixel_size.y * float(i) * zoom);
        sum += sample_is_solid(uv + offset) * w;
        weight_sum += w;
    }

    return sum / weight_sum;
}

float blur_is_solid(vec2 uv, vec2 screen_pixel_size) {
    float horiz = blur_is_solid_horizontal(uv, screen_pixel_size);
    float vert = blur_is_solid_vertical(uv, screen_pixel_size);
    float blurred = (horiz + vert) * 0.5;
    return blurred;
}
    


// float blur_is_solid(vec2 uv, vec2 screen_pixel_size) {
//     vec2 halfpixel = screen_pixel_size / 2.0;
//     float z = is_solid_blur_radius * zoom;
	
//     float sum = 0.0;
//     sum += sample_is_solid(uv + vec2(-halfpixel.x * 2.0, 0.0) * z);
//     sum += sample_is_solid(uv + vec2(-halfpixel.x,  halfpixel.y) * z) * 2.0;
//     sum += sample_is_solid(uv + vec2(0.0,          halfpixel.y * 2.0) * z);
//     sum += sample_is_solid(uv + vec2(halfpixel.x,  halfpixel.y) * z) * 2.0;
//     sum += sample_is_solid(uv + vec2(halfpixel.x * 2.0, 0.0) * z);
//     sum += sample_is_solid(uv + vec2(halfpixel.x, -halfpixel.y) * z) * 2.0;
//     sum += sample_is_solid(uv + vec2(0.0,         -halfpixel.y * 2.0) * z);
//     sum += sample_is_solid(uv + vec2(-halfpixel.x, -halfpixel.y) * z) * 2.0;

// 	return sum / 12.0;
// }

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

    // Stripes for "marked for mining" effect
    float w = cos(angle) * uv_stripes.x + sin(angle) * uv_stripes.y - speed * TIME;
    float stripe = floor(mod(w * divisions, stripe_bias));
  
    ////////////////////////////////////////////////////////////////////////////////////////
    // Start with screen color
    COLOR = screen_color;

    // SOLID -> darken
    if (is_solid) {   
        // ORIGINAL:
        // COLOR.rgb *= is_solid_max_darken_factor;

        float darkness_factor = blur_is_solid(uv, SCREEN_PIXEL_SIZE);
        darkness_factor -= is_solid_flat_offset;
        darkness_factor = clamp(darkness_factor, 0.0, 1.0);
        
        darkness_factor = mix(is_solid_max_darken_factor, 1.0, darkness_factor);

        COLOR.rgb *= darkness_factor;

    }

    // MINING
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

    // IS SELECTED (highlighted when hovered over)
    if (is_selected) {
        COLOR = mix(COLOR, selection_color, selection_color.a);
    }

    // WALKABLE (for debugging)
    // if (is_walkable) {
    //     COLOR = mix(COLOR, walkable_color, walkable_color.a);
    // }

    // DONT OVERWRITE IF ONE CHANNEL IS AT 100%
    if (screen_color.r >= 1.0 || screen_color.g >= 1.0 || screen_color.b >= 1.0) {
        COLOR = screen_color;
    }


}



