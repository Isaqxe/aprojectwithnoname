shader_type canvas_item;

uniform float world_seed = 123456.0;
uniform vec2 world_origin = vec2(0.0);
uniform float world_scale = 512.0;
uniform float macro_frequency = 0.0004;
uniform float temperature_frequency = 0.0007;
uniform float humidity_frequency = 0.0009;
uniform float warp_frequency = 0.0012;
uniform float border_detail_frequency = 0.0025;
uniform float void_threshold = 0.60;
uniform float cold_temperature = 0.34;
uniform float hot_temperature = 0.68;
uniform float green_humidity = 0.45;
uniform float warp_strength = 150.0;
uniform float border_detail_strength = 0.18;

const vec3 VOID_COLOR = vec3(0.42, 0.42, 0.42);
const vec3 COLD_COLOR = vec3(0.48, 0.72, 0.95);
const vec3 GREEN_COLOR = vec3(0.42, 0.82, 0.46);
const vec3 HOT_COLOR = vec3(0.95, 0.55, 0.28);

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32 + world_seed);
    return fract(p.x * p.y);
}

float value_noise(vec2 p, float seed_offset) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i + seed_offset);
    float b = hash21(i + vec2(1.0, 0.0) + seed_offset);
    float c = hash21(i + vec2(0.0, 1.0) + seed_offset);
    float d = hash21(i + vec2(1.0, 1.0) + seed_offset);
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p, float frequency, float seed_offset) {
    float value = 0.0;
    float amplitude = 0.5;
    float total = 0.0;
    for (int octave = 0; octave < 4; octave++) {
        value += value_noise(p * frequency, seed_offset + float(octave) * 17.0) * amplitude;
        total += amplitude;
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value / total;
}

void fragment() {
    vec2 world_position = world_origin + UV * world_scale;
    vec2 warp = vec2(
        fbm(world_position, warp_frequency, 101.0) - 0.5,
        fbm(world_position, warp_frequency, 202.0) - 0.5
    ) * warp_strength;
    vec2 p = world_position + warp;

    float macro = fbm(p, macro_frequency, 303.0);
    float temperature = fbm(p, temperature_frequency, 404.0);
    float humidity = fbm(p, humidity_frequency, 505.0);
    float detail = fbm(p, border_detail_frequency, 606.0) - 0.5;
    temperature += detail * border_detail_strength;
    humidity += detail * border_detail_strength * 0.5;

    if (macro < void_threshold) {
        COLOR = vec4(VOID_COLOR, 1.0);
    } else if (temperature < cold_temperature) {
        COLOR = vec4(COLD_COLOR, 1.0);
    } else if (temperature > hot_temperature) {
        COLOR = vec4(HOT_COLOR, 1.0);
    } else if (humidity >= green_humidity) {
        COLOR = vec4(GREEN_COLOR, 1.0);
    } else {
        COLOR = vec4(GREEN_COLOR * 0.96, 1.0);
    }
}
