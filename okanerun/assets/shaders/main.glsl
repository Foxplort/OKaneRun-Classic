extern number time;

float get_noise(vec2 uv) {
    float t = floor(time * 12.0);
    return fract(sin(dot(uv + t, vec2(12.9898, 78.233))) * 43758.5453);
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
    float noise = get_noise(texture_coords);
    float luminance = dot(texcolor.rgb, vec3(0.299, 0.587, 0.114));
    float noiseStrength = 0.02 * (1.0 - luminance * 0.5);
    texcolor.rgb += (noise - 0.5) * noiseStrength;

    // VIGNETTE
    float pulse = sin(time * 0.5) * 0.03;
    float vignette = smoothstep(0.9 + pulse, 0.4 + pulse, dist);
    texcolor.rgb *= vignette;
    
    // CONTRAST
    texcolor.rgb *= 1.1;
    
    return texcolor * color;
}