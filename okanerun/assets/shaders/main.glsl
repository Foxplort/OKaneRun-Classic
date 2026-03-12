extern number time;
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 texcolor = Texel(texture, texture_coords);
    
    vec2 uv = texture_coords - 0.5;
    float dist = length(uv);
    float vignette = smoothstep(0.95, 0.4, dist);
    
    texcolor.rgb *= vignette;
    texcolor.rgb *= 1.1;
    
    return texcolor * color;
}