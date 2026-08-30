shader_type canvas_item;

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float lens_distance = length(centered * vec2(1.0, 1.12));
	float vignette = smoothstep(0.34, 0.72, lens_distance);
	float scanline = 0.5 + 0.5 * sin(UV.y * 900.0);
	float alpha = clamp(vignette * 0.48 + scanline * 0.018, 0.0, 0.55);
	COLOR = vec4(0.0, 0.025, 0.018, alpha);
}
