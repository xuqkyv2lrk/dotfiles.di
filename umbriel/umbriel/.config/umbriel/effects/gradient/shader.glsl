// Catppuccin Mocha mauve (the main accent) and blue
// hex values are sRGB; the compositor blends in linear light
const vec3 MAUVE = pow(vec3(0.796, 0.651, 0.969), vec3(2.2));
const vec3 BLUE = pow(vec3(0.537, 0.706, 0.980), vec3(2.2));
const float PERIOD_S = 3.0;

vec4 border(vec2 uv) {
  float ring = umbriel_sample(uv).a;
  float angle = radians(45.0) + umbriel_time * 6.2831853 / PERIOD_S;
  float t = clamp(dot(uv - 0.5, vec2(cos(angle), sin(angle))) + 0.5, 0.0, 1.0);
  return vec4(mix(MAUVE, BLUE, smoothstep(0.4, 1.0, t)) * ring, ring);
}
