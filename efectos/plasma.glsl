#effect Plasma
#desc Generador animado de color, sin entradas

#param escala 3 0.5 12
#param vel 0.6 0 3

vec2 p = (@uv - 0.5) * vec2(@res.x / @res.y, 1.0) * @escala;
float t = @time * @vel;
float v = sin(p.x + t) + sin(p.y * 1.3 - t) + sin(length(p) * 1.7 + t * 1.4);
v += fbm(vec3(p * 0.6, t * 0.3), 4) * 2.0;
vec3 col = hsv2rgb(vec3(fract(v * 0.15 + t * 0.05), 0.75, 0.95));
@out = vec4(col, 1.0);
