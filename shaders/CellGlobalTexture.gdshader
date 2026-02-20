shader_type canvas_item;

uniform sampler2D bg_texture_main : source_color, filter_nearest, repeat_enable;
uniform sampler2D bg_texture_alt : source_color, filter_nearest, repeat_enable;

uniform sampler2D noise_tex : source_color, filter_nearest, repeat_enable;

const float tex_scale = 0.005;
const float tex_scale_noise = 0.004;

varying vec2 world_pos;

void vertex() {
	// Pass through vertex shader
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 uv_final = world_pos * tex_scale;
	vec2 uv_noise = world_pos * tex_scale_noise;

	vec4 tex_main = texture(bg_texture_main, uv_final);
	vec4 tex_alt = texture(bg_texture_alt, uv_final);

	float noise_value = texture(noise_tex, uv_noise).r;  // 0-1 blend factor
	float bias_strength = 0.2; // Adjust this for sharper or softer transitions, should be 0 - 10. 0 -> clear cut
	// float blend_value = pow(abs(noise_value - 0.5) * 2.0, bias_strength) * sign(noise_value - 0.5) + 0.5;
	float blend_value = smoothstep(0.0, 1.0, noise_value);  // Bias low to high

	vec4 multiplier = mix(tex_main, tex_alt, 1.0 - blend_value);

	COLOR *= multiplier;
}

