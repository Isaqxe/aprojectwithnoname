shader_type canvas_item;
render_mode unshaded;

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

float hash21(vec2 p, float seed_offset) {
    p += vec2(seed_offset * 0.0137, seed_offset * 0.0211);
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float value_noise(vec2 p, float seed_offset) {
    vec2 cell = floor(p);
    vec2 local = fract(p);
    local = local * local * (3.0 - 2.0 * local);

    float a = hash21(cell, seed_offset);
    float b = hash21(cell + vec2(1.0, 0.0), seed_offset);
    float c = hash21(cell + vec2(0.0, 1.0), seed_offset);
    float d = hash21(cell + vec2(1.0, 1.0), seed_offset);

    return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}

float fbm(vec2 p, float frequency, float seed_offset) {
    float result = 0.0;
    float amplitude = 0.5;
    float normalization = 0.0;
    vec2 sample_position = p * frequency;

    for (int octave = 0; octave < 4; octave++) {
        result += value_noise(sample_position, seed_offset + float(octave) * 19.37) * amplitude;
        normalization += amplitude;
        sample_position *= 2.0;
        amplitude *= 0.5;
    }

    return result / normalization;
}

void fragment() {
    vec2 world_position = world_origin + UV * world_scale;

    vec2 warp = vec2(
        fbm(world_position, warp_frequency, world_seed + 101.0),
        fbm(world_position, warp_frequency, world_seed + 202.0)
    );
    vec2 sample_position = world_position + (warp - vec2(0.5)) * warp_strength;

    float macro = fbm(sample_position, macro_frequency, world_seed + 303.0);
    float temperature = fbm(sample_position, temperature_frequency, world_seed + 404.0);
    float humidity = fbm(sample_position, humidity_frequency, world_seed + 505.0);
    float detail = fbm(sample_position, border_detail_frequency, world_seed + 606.0) - 0.5;

    temperature = clamp(temperature + detail * border_detail_strength, 0.0, 1.0);
    humidity = clamp(humidity + detail * border_detail_strength * 0.5, 0.0, 1.0);

    // Increase contrast so the macro noise actually crosses the biome threshold.
    macro = smoothstep(0.30, 0.70, macro);

    vec3 biome_color = VOID_COLOR;

    if (macro >= void_threshold) {
        if (temperature < cold_temperature) {
            biome_color = COLD_COLOR;
        } else if (temperature > hot_temperature) {
            biome_color = HOT_COLOR;
        } else if (humidity >= green_humidity) {
            biome_color = GREEN_COLOR;
        } else {
            biome_color = mix(GREEN_COLOR * 0.90, GREEN_COLOR, humidity / max(green_humidity, 0.001));
        }
    }

    COLOR = vec4(biome_color, 1.0);
}
