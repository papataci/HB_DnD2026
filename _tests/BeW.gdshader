shader_type canvas_item;

// uniform does not change during the lifetime of the shader
uniform float grayscaleMulti = 1.0;
uniform float grayscaleOffset = 0.0;

void fragment() {

	float grayscale = (COLOR.r + COLOR.g + COLOR.b) / 3.0 * grayscaleMulti + grayscaleOffset;

	COLOR = vec4(grayscale, grayscale, grayscale, COLOR.a);

}
