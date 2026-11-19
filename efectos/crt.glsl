#effect Pantalla CRT
#desc Curvatura de barril y líneas de barrido
#input A Imagen

#param curva 0.12 0 0.4
#param lineas 0.35 0 1

vec2 c = @uv * 2.0 - 1.0;
c *= 1.0 + @curva * dot(c, c) * 0.5;
vec2 uv = c * 0.5 + 0.5;
if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
  @out = vec4(0.0, 0.0, 0.0, 1.0);
} else {
  vec4 col = A(uv);
  float s = 0.5 + 0.5 * sin(uv.y * @res.y * 3.14159);
  col.rgb *= 1.0 - @lineas * (1.0 - s);
  @out = col;
}
