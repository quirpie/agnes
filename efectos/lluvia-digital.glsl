#effect Lluvia digital
#desc Cascada de glifos estilo Matrix que dibuja la imagen de entrada
#input A Imagen

#param tamano 14 6 48
#param velocidad 1 0 4
#param estela 0.35 0.05 1
#param gotas 2 1 3
#param fondo 0.3 0 1
#param cambio 3 0 12
#param contraste 1.3 0.3 4
#param brillo 1.3 0 3
#enum color Verde clásico | Colores de la imagen
#color tinta #3dff6e
#color cabeza #e2ffe9

// Glifo procedural: cuadrícula de 3×5 trazos dentro de la celda.
// f = posición dentro de la celda (0–1), id = qué glifo
float glifo(vec2 f, float id) {
  vec2 g = (f - vec2(0.14, 0.08)) / vec2(0.72, 0.84);
  if (g.x < 0.0 || g.x > 1.0 || g.y < 0.0 || g.y > 1.0) return 0.0;
  vec2 q = floor(g * vec2(3.0, 5.0));
  if (hash13(vec3(id, 5.0, 1.0)) > 0.5) q.x = min(q.x, 2.0 - q.x);  // la mitad, simétricos
  float on = step(0.45, hash13(vec3(q, id)));
  vec2 c = fract(g * vec2(3.0, 5.0)) - 0.5;
  return on * (1.0 - smoothstep(0.38, 0.5, max(abs(c.x), abs(c.y))));
}

vec2 cell = vec2(@tamano * 0.7, @tamano);   // celdas más altas que anchas
vec2 id = floor(@P / cell);
vec2 f = fract(@P / cell);
vec2 cuv = (id + 0.5) * cell / @res;        // centro de la celda (0–1)
float filas = @res.y / cell.y;

// Gotas de esta columna: cabeza que baja celda por celda y estela encima
float tr = 0.0, cab = 0.0;
float vcol = 0.5 + hash13(vec3(id.x, 1.0, 2.0));
for (int k = 0; k < 3; k++) {
  if (float(k) >= @gotas) break;
  float off = hash13(vec3(id.x, float(k), 3.0));
  float y = (1.0 + @estela) - fract(off + @time * @velocidad * vcol * 0.15) * (1.0 + 2.0 * @estela);
  y = floor(y * filas) / filas;
  float d = cuv.y - y;                       // distancia por encima de la cabeza
  if (d >= 0.0 && d < @estela) tr = max(tr, 1.0 - d / @estela);
  cab = max(cab, 1.0 - step(0.5 / filas, abs(d)));
}

// Glifo que cambia con el tiempo, cada celda a su ritmo
float ritmo = @cambio * (0.4 + hash13(vec3(id, 9.0)));
float gid = hash13(vec3(id, floor(@time * ritmo + hash13(vec3(id, 4.0))))) * 1000.0;
float g = glifo(f, gid);

// La imagen decide cuánto brilla cada glifo
vec3 src = A(cuv).rgb;
float lum = uHasA > 0.5 ? pow(clamp(luma(src), 0.0, 1.0), @contraste) : 1.0;
vec3 tinte = (@color == 1 && uHasA > 0.5) ? src / max(max(src.r, max(src.g, src.b)), 0.001) : @tinta;
// Sin imagen: lluvia clásica (solo las estelas)
float inten = uHasA > 0.5 ? lum * (@fondo + (1.0 - @fondo) * tr) : tr;

vec3 col = g * (tinte * inten * @brillo + @cabeza * cab * (0.15 + 0.85 * lum));
@out = vec4(clamp(col, 0.0, 1.0), 1.0);
