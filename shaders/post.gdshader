shader_type canvas_item;

// Parameters
uniform vec4 color_stripe : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 color_gap : source_color = vec4(0.0, 0.0, 1.0, 0.2);
uniform float divisions : hint_range(1.0, 64.0) = 24.0;
uniform float stripe_bias : hint_range(1.0, 10.0) = 2.0;
uniform float speed : hint_range(0.0, 10.0) = 0.1;
uniform float angle : hint_range(0.0, 6.283) = 0.7854; // radians

uniform bool highlight = true;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

void fragment() {
    // Get UV in world space
    vec2 uv = SCREEN_UV;

    vec4 screen_color = texture(SCREEN_TEXTURE, uv);

    // Correct for aspect ratio
    float aspect = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
    uv = vec2(uv.x, uv.y * aspect);

    // Stripe math
    float w = cos(angle) * uv.x + sin(angle) * uv.y - speed * TIME;
    float stripe = floor(mod(w * divisions, stripe_bias));
    vec4 highlight_color = (stripe < 0.5) ? screen_color : color_stripe;

	COLOR = (highlight) ? highlight_color : screen_color;
}
