shader_type canvas_item;
render_mode unshaded;

uniform float world_seed = 123456.0;
uniform vec2 world_center = vec2(0.0);
uniform vec2 world_extent = vec2(1400.0);
uniform vec2 world_size = vec2(1024.0);

uniform float macro_frequency = 0.0004;
uniform float temperature_frequency = 0.0007;
uniform float humidity_frequency = 0.0009;
uniform float warp_frequency = 0.0012;
uniform float warp_strength = 150.0;
uniform float border_detail_frequency = 0.0025;
uniform float border_detail_strength = 0.18;

uniform float void_threshold = 0.60;
uniform float cold_temperature = 0.34;
uniform float hot_temperature = 0.68;
uniform float green_humidity = 0.45;

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

vec2 get_sample_position(vec2 world_position) {
    float warp_x = fbm(world_position, warp_frequency, world_seed + 101.0);
    float warp_y = fbm(world_position, warp_frequency, world_seed + 202.0);
    return world_position + (vec2(warp_x, warp_y) - vec2(0.5)) * warp_strength;
}

vec4 sample_environment(vec2 world_position) {
    vec2 sample_position = get_sample_position(world_position);

    float macro = fbm(sample_position, macro_frequency, world_seed + 303.0);
    float temperature = fbm(sample_position, temperature_frequency, world_seed + 404.0);
    float humidity = fbm(sample_position, humidity_frequency, world_seed + 505.0);
    float detail = fbm(sample_position, border_detail_frequency, world_seed + 606.0) - 0.5;

    temperature = clamp(temperature + detail * border_detail_strength, 0.0, 1.0);
    humidity = clamp(humidity + detail * border_detail_strength * 0.5, 0.0, 1.0);
    macro = smoothstep(0.30, 0.70, macro);

    float biome_code = 0.0;
    if (macro >= void_threshold) {
        if (temperature < cold_temperature) {
            biome_code = 1.0;
        } else if (temperature > hot_temperature) {
            biome_code = 2.0;
        } else {
            biome_code = 3.0;
        }
    }

    return vec4(macro, temperature, humidity, biome_code / 3.0);
}

void fragment() {
    vec2 world_position = world_center + (UV - vec2(0.5)) * world_extent;
    COLOR = sample_environment(world_position);
}
