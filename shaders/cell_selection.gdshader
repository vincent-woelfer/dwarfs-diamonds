shader_type canvas_item;

// Parameters
uniform vec4 color_gap : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 color_stripe : source_color;
uniform float divisions : hint_range(1.0, 64.0) = 8.0;
uniform float stripe_bias : hint_range(1.0, 10.0) = 2.0;
uniform float speed : hint_range(0.0, 10.0) = 0.1;
uniform float angle : hint_range(0.0, 6.283) = 0.7854; // radians

uniform bool highlight = false;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

// Varyings
varying vec2 world_pos;
varying vec4 vert_color;

// Kein fragcoord da das screen-based ist. Wir wollen world-bases coords

void vertex()
{
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0, 1.0)).xy;
    vert_color = COLOR;
}

void fragment() {
    vec2 uv = world_pos * vec2(0.01);

    vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);

    // vec4 vert_color = vec4(0.0, 0.0, 0.0, 1.0);

	// Stripe math
	float w = cos(angle) * uv.x + sin(angle) * uv.y - speed * TIME;
	float stripe = floor(mod(w * divisions, stripe_bias));
    vec4 highlight_color = (stripe < 0.5) ? color_gap : color_stripe;
	COLOR = (highlight) ? highlight_color : screen_color;
}


