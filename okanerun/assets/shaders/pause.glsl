#ifdef GL_ES
precision mediump float;
#endif

extern number levels;   // number of grayscale steps (e.g. 4, 6, 8)
extern number strength; // 0..1 blend between original and mono

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
    vec4 px = Texel(tex, tc) * color;

    // Luminance (perceptually correct)
    number gray = dot(px.rgb, vec3(0.299, 0.587, 0.114));

    // Posterize
    gray = floor(gray * levels) / (levels - 1.0);

    vec3 mono = vec3(gray);

    px.rgb = mix(px.rgb, mono, strength);
    return px;
}
