shader_type canvas_item;

uniform sampler2D bg_texture : source_color, filter_nearest, repeat_enable;

const float tex_scale = 0.005;

varying vec2 world_pos;

void vertex() {
	// Pass through vertex shader
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 uv_final = world_pos * tex_scale;

	vec4 color_multiplier = texture(bg_texture, uv_final);

	COLOR *= color_multiplier;
}

