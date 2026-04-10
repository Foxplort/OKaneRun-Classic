#ifdef GL_ES
precision mediump float;
#endif

extern float time;
extern float intensity; // How much it shakes/glitches

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Create a waving effect for the "alive" feel
    float wave = sin(texture_coords.y * 10.0 + time * 2.0) * 0.002;
    
    // Random horizontal jumps (Glitch)
    float split = sin(time * 20.0) * intensity;
    if (sin(time * 50.0) > 0.95) { // Occasional big jump
        split *= 5.0;
    }

    // RGB Split / Ghosting
    float r = Texel(texture, vec2(texture_coords.x + split + wave, texture_coords.y)).r;
    float g = Texel(texture, vec2(texture_coords.x + wave, texture_coords.y)).g;
    float b = Texel(texture, vec2(texture_coords.x - split + wave, texture_coords.y)).b;
    float a = Texel(texture, vec2(texture_coords.x + wave, texture_coords.y)).a;

    // Dim the alpha slightly to make it look ethereal
    return vec4(r, g, b, a) * color;
}