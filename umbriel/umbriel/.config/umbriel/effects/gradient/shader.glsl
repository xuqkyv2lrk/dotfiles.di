// Catppuccin Mocha mauve (the main accent) and green (the STRAT0S logo)
const vec3 MAUVE = vec3(0.796, 0.651, 0.969);
const vec3 GREEN = vec3(0.651, 0.890, 0.631);
const float PERIOD_S = 3.0;

vec4 border(vec2 uv) {
  float ring = umbriel_sample(uv).a;
  float angle = radians(45.0) + umbriel_time * 6.2831853 / PERIOD_S;
  float t = clamp(dot(uv - 0.5, vec2(cos(angle), sin(angle))) + 0.5, 0.0, 1.0);
  return vec4(mix(MAUVE, GREEN, smoothstep(0.4, 1.0, t)) * ring, ring);
}
