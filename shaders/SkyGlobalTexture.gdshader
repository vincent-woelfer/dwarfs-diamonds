shader_type canvas_item;
render_mode unshaded;

uniform sampler2D bg_texture : source_color, repeat_enable;

// Smaller number -> larger texture on screen
const vec2 tex_scale = vec2(0.0004, 0.00065);

varying vec2 world_pos;

// Scroll offset to animate the sky texture, changed by script every frame
global uniform vec2 sky_scroll_offset = vec2(0.0, 0.0);

global uniform float sky_sunlight_energy = 1.0;

global uniform vec4 sky_color = vec4(1.0, 1.0, 1.0, 1.0);

void vertex() {
	// Pass through vertex shader
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 uv_final = (world_pos * tex_scale) + sky_scroll_offset;
	vec4 color_multiplier = texture(bg_texture, uv_final);

	// Apply sky texture only where alpha is above a threshold.
	// Sky background is static color, texture has clouds with alpha mask
	if (color_multiplier.a > 0.1) {
		COLOR *= color_multiplier;
	}

	// Apply global sky color (which is set based on sunlight color and energy)
	COLOR *= sky_color;

	// Apply sunlight energy to the sky color
	// COLOR.rgb *= sky_sunlight_energy;

	
}

