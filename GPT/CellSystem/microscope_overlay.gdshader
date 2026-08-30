shader_type canvas_item;

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float lens_distance = length(centered * vec2(1.0, 1.08));
	float vignette = smoothstep(0.36, 0.72, lens_distance);
	float alpha = clamp(vignette * 0.42, 0.0, 0.45);
	COLOR = vec4(0.0, 0.02, 0.015, alpha);
}
