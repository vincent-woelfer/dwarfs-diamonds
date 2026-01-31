shader_type canvas_item;

uniform sampler2D bg_texture : source_color, filter_nearest;


uniform float zoom = 1.0; 

const float tex_scale = 2.0;

void fragment() {

    // Correct UV for aspect ratio for strip generation only
	// vec2 uv_base = SCREEN_UV;
    // float aspect = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
    // vec2 uv_corrected = vec2(uv_base.x, uv_base.y * aspect) / zoom;
	

	// vec2 uv_final = uv_corrected * tex_scale;
	vec2 uv_final = SCREEN_UV;

	vec4 color_multiplier = texture(bg_texture, uv_final * tex_scale);

	COLOR *= color_multiplier;
}

