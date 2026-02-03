shader_type canvas_item;

uniform sampler2D bg_texture : source_color, filter_nearest, repeat_enable;

// Smaller number -> larger texture on screen
const vec2 tex_scale = vec2(0.0004, 0.00065);

varying vec2 world_pos;

// Scroll offset to animate the sky texture, changed by script every frame
global uniform vec2 sky_scroll_offset = vec2(0.0, 0.0);

void vertex() {
	// Pass through vertex shader
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 uv_final = (world_pos * tex_scale) + sky_scroll_offset;
	vec4 color_multiplier = texture(bg_texture, uv_final);

	if (color_multiplier.a > 0.5) {
		COLOR *= color_multiplier;
	}

	
}

