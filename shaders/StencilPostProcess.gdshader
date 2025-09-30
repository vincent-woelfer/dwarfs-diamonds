shader_type canvas_item;
render_mode blend_disabled, unshaded;

// Parameters
uniform vec4 highlight_stripe_color : source_color = vec4(1.0, 0.0, 0.0, 0.8);
uniform vec4 highlight_gap_color : source_color = vec4(1.0, 0.0, 0.0, 0.2);

uniform float divisions : hint_range(1.0, 256.0) = 128.0;
uniform float stripe_bias : hint_range(1.0, 10.0) = 1.75;
uniform float speed : hint_range(0.0, 10.0) = 0.02;
uniform float angle : hint_range(0.0, 6.283) = 0.7854; // radians

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable;
uniform sampler2D STENCIL_TEXTURE: repeat_disable, filter_nearest;

void fragment() {
    // Get UV in world space
    vec2 uv = SCREEN_UV;  // UV also works

    // Sample Textures with correct UV
    vec4 screen_color = texture(SCREEN_TEXTURE, uv);
    vec4 stencil_color = texture(STENCIL_TEXTURE, uv);
    
    bool highlight = (stencil_color.r > 0.5);

    // Correct UV for aspect ratio for strip generation only
    float aspect = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
    vec2 uv_stripes = vec2(uv.x, uv.y * aspect);

    // Stripe math
    float w = cos(angle) * uv_stripes.x + sin(angle) * uv_stripes.y - speed * TIME;
    float stripe = floor(mod(w * divisions, stripe_bias));

    // Choose stripe color
    vec4 highlight_color = (stripe >= 0.5) 
        ? mix(screen_color, highlight_stripe_color, highlight_stripe_color.a) 
        : mix(screen_color, highlight_gap_color, highlight_gap_color.a);

    COLOR = highlight ? highlight_color : screen_color;
}
