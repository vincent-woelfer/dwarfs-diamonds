shader_type canvas_item;

uniform sampler2D bg_texture_main : source_color, filter_nearest, repeat_enable;
uniform sampler2D bg_texture_alt : source_color, filter_nearest, repeat_enable;

uniform sampler2D noise_tex : source_color, filter_nearest, repeat_enable;

const float tex_scale = 0.005;
const float tex_scale_noise = 0.001;

varying vec2 world_pos;

void vertex() {
	// Compute world_pos and pass to fragment shader
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float ease_inout(float x, float c) {
	if (x < 0.5) {
		return pow(x * 2.0, -c) * 0.5;
	} else {
		return (1.0 - pow(1.0 - (x - 0.5) * 2.0, -c)) * 0.5 + 0.5;
	}
}

void fragment() {
	vec2 uv_final = world_pos * tex_scale;
	vec2 uv_noise = world_pos * tex_scale_noise;

	vec4 tex_main = texture(bg_texture_main, uv_final);
	vec4 tex_alt = texture(bg_texture_alt, uv_final);

	float noise_value = texture(noise_tex, uv_noise).r;  // 0-1 blend factor
	float blend_value = ease_inout(noise_value, -4.0);

	vec4 multiplier = mix(tex_main, tex_alt, blend_value);

	COLOR *= multiplier;
}



