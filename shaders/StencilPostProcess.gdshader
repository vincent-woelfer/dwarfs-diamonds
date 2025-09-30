shader_type canvas_item;
render_mode blend_disabled, unshaded;

// Parameters
uniform vec4 stripe_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

uniform float divisions : hint_range(1.0, 256.0) = 128.0;
uniform float stripe_bias : hint_range(1.0, 10.0) = 1.75;
uniform float speed : hint_range(0.0, 10.0) = 0.025;
uniform float angle : hint_range(0.0, 6.283) = 0.7854; // radians

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable;
uniform sampler2D MASK_TEXTURE: repeat_disable, filter_nearest;

void fragment() {
    // Get UV in world space
    vec2 uv = SCREEN_UV;

    vec4 screen_color = texture(SCREEN_TEXTURE, uv);
    vec4 mask_color = texture(MASK_TEXTURE, uv);
    
    bool highlight = (mask_color.r > 0.5);

    // Correct for aspect ratio for stripes only
    float aspect = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
    uv = vec2(uv.x, uv.y * aspect);

    // Stripe math
    float w = cos(angle) * uv.x + sin(angle) * uv.y - speed * TIME;
    float stripe = floor(mod(w * divisions, stripe_bias));

    // Determine Colors
    vec4 highlight_color = (stripe >= 0.5) ? stripe_color : screen_color;
    vec4 background_color = (stripe >= 0.5) ? mix(screen_color, vec4(1,1,1,1), 0.5) : screen_color;

    if (highlight) {
        COLOR = highlight_color;
    } else {
        COLOR = background_color;
    }
    // COLOR = mix(screen_color, mask_color, 0.7);
}
