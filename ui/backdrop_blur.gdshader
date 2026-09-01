shader_type canvas_item;

// Blurs whatever has already been drawn behind this CanvasItem (i.e. any
// node with a lower effective z_index), using the screen backbuffer.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float blur_radius : hint_range(0.0, 32.0) = 8.0;

const int SAMPLES = 12;

void fragment() {
	vec4 sum = textureLod(screen_texture, SCREEN_UV, 0.0);
	float total_weight = 1.0;

	for (int i = 0; i < SAMPLES; i++) {
		float angle = (float(i) / float(SAMPLES)) * TAU;
		vec2 offset = vec2(cos(angle), sin(angle)) * blur_radius * SCREEN_PIXEL_SIZE;
		sum += textureLod(screen_texture, SCREEN_UV + offset, 0.0);
		total_weight += 1.0;
	}

	COLOR.rgb = (sum / total_weight).rgb;
	COLOR.a = 1.0;
}
