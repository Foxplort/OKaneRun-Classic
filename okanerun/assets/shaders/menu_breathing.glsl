#ifdef GL_ES
precision mediump float;
#endif

extern float time;
extern float b_intensity;
extern float b_speed;
extern float b_ysize;
extern float s_speed;
extern float s_intensity;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Create a waving effect for the "alive" feel
    float wave = sin(texture_coords.y * b_ysize + time * b_speed) * b_intensity;

    // RGB Split / Ghosting
    float split = sin(time * s_speed) * s_intensity;
    float r = Texel(texture, vec2(texture_coords.x + split + wave, texture_coords.y)).r;
    float g = Texel(texture, vec2(texture_coords.x + wave, texture_coords.y)).g;
    float b = Texel(texture, vec2(texture_coords.x - split + wave, texture_coords.y)).b;
    float a = Texel(texture, vec2(texture_coords.x + wave, texture_coords.y)).a;

    // Dim the alpha slightly to make it look ethereal
    return vec4(r, g, b, a) * color;
}