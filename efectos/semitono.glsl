#effect Semitono
#desc Puntos de imprenta según la luminancia
#input A Imagen

#param celda 10 4 40
#param angulo 45 0 90
#color tinta #111111
#color papel #f4efe4

float a = radians(@angulo);
mat2 R = mat2(cos(a), -sin(a), sin(a), cos(a));
vec2 p = R * @P;
vec2 id = floor(p / @celda);
vec2 f = fract(p / @celda) - 0.5;
vec2 centro = transpose(R) * ((id + 0.5) * @celda);
float l = luma(A(centro / @res).rgb);
float r = sqrt(1.0 - l) * 0.75;
float punto = 1.0 - smoothstep(r - 0.06, r + 0.06, length(f));
@out = vec4(mix(@papel, @tinta, punto), 1.0);
