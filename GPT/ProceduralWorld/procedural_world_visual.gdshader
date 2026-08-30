shader_type canvas_item;
render_mode unshaded;

uniform sampler2D environment_map;
uniform vec2 world_center = vec2(0.0);
uniform vec2 world_extent = vec2(1400.0);

uniform float void_threshold = 0.60;
uniform float cold_temperature = 0.34;
uniform float hot_temperature = 0.68;
uniform float green_humidity = 0.45;
uniform float edge_softness = 0.24;
uniform float edge_detail_frequency = 0.0018;
uniform float edge_detail_strength = 0.018;
uniform float surface_large_frequency = 0.0014;
uniform float surface_medium_frequency = 0.0040;
uniform float surface_small_frequency = 0.012;
uniform float surface_variation_strength = 0.035;

const vec3 VOID_COLOR = vec3(0.18, 0.19, 0.22);
const vec3 COLD_COLOR = vec3(0.42, 0.68, 0.92);
const vec3 GREEN_COLOR = vec3(0.30, 0.72, 0.38);
const vec3 HOT_COLOR = vec3(0.92, 0.48, 0.20);

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 local = fract(p);
	local = local * local * (3.0 - 2.0 * local);
	float a = hash21(cell);
	float b = hash21(cell + vec2(1.0, 0.0));
	float c = hash21(cell + vec2(0.0, 1.0));
	float d = hash21(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}

float fbm(vec2 p) {
	float result = 0.0;
	float amplitude = 0.5;
	float normalization = 0.0;
	for (int octave = 0; octave < 4; octave++) {
		result += value_noise(p) * amplitude;
		normalization += amplitude;
		p *= 2.0;
		amplitude *= 0.5;
	}
	return result / normalization;
}

void fragment() {
	vec4 environment = texture(environment_map, UV);
	float macro = environment.r;
	float temperature = environment.g;
	float humidity = environment.b;

	float land_factor = smoothstep(void_threshold - edge_softness, void_threshold + edge_softness, macro);

	float cold_factor = smoothstep(cold_temperature + 0.05, cold_temperature - 0.05, temperature);
	float hot_factor = smoothstep(hot_temperature - 0.05, hot_temperature + 0.05, temperature);
	float green_factor = smoothstep(0.12, green_humidity, humidity);

	vec3 climate_color = mix(GREEN_COLOR * 0.72, GREEN_COLOR, green_factor);
	climate_color = mix(climate_color, COLD_COLOR, cold_factor);
	climate_color = mix(climate_color, HOT_COLOR, hot_factor);

	vec3 color = mix(VOID_COLOR, climate_color, land_factor);

	vec2 world_position = world_center + (UV - vec2(0.5)) * world_extent;
	float large_surface = fbm(world_position * surface_large_frequency) - 0.5;
	float medium_surface = fbm(world_position * surface_medium_frequency) - 0.5;
	float small_surface = fbm(world_position * surface_small_frequency) - 0.5;
	float surface_variation = large_surface * 0.55 + medium_surface * 0.30 + small_surface * 0.15;
	color += surface_variation * surface_variation_strength * (0.25 + 0.75 * land_factor);

	float edge_noise = fbm(world_position * edge_detail_frequency) - 0.5;
	float edge_band = 1.0 - smoothstep(0.0, edge_softness * 1.5, abs(macro - void_threshold));
	color += edge_noise * edge_detail_strength * edge_band;

	COLOR = vec4(clamp(color, vec3(0.0), vec3(1.0)), 1.0);
}
