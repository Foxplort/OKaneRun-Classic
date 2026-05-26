#ifdef GL_ES
precision mediump float;
#endif

extern number time;
extern bool noise = true;
extern bool vignette = true;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 34.45);
    return fract(p.x * p.y);
}

float get_noise(vec2 uv) {
    float t = mod(floor(time * 12.0), 256.0);
    return hash(uv + vec2(t, t * 0.37));
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = texture_coords - 0.5;
    float dist = length(uv);

    // COLOR SHIFT
    float shift = 0.0005 * dist; 
    float r = Texel(texture, texture_coords + vec2(shift, 0.0)).r;
    float g = Texel(texture, texture_coords).g;
    float b = Texel(texture, texture_coords - vec2(shift, 0.0)).b;
    vec4 texcolor = vec4(r, g, b, 1.0);

    // NOISE
    if (noise) {
        float noise = get_noise(screen_coords / love_ScreenSize.xy);
        float luminance = dot(texcolor.rgb, vec3(0.299, 0.587, 0.114));
        float noiseStrength = 0.02 * (1.0 - luminance * 0.5);
        texcolor.rgb += (noise - 0.5) * noiseStrength;
    }

    // VIGNETTE
    if (vignette) {
        float pulse = sin(time * 0.5) * 0.03;
        float vignette = smoothstep(0.9 + pulse, 0.4 + pulse, dist);
        texcolor.rgb *= vignette;
    }
    
    // CONTRAST
    texcolor.rgb *= 1.1;
    
    return texcolor * color;
}