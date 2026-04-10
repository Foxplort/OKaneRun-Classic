#ifdef GL_ES
precision mediump float;
#endif

extern float progress;
extern Image ditherTex; // We will send a 4x4 image here

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 screen_coords) {
    // Wrap the coordinates so the 4x4 texture repeats across the screen
    // We use screen_coords / 4.0 because the texture is 4x4 pixels
    float limit = Texel(ditherTex, screen_coords / 4.0).r;
    
    return (progress > limit) ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(0.0);
}