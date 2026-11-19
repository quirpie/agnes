#effect Pixelado
#desc Bloques cuadrados de tamaño ajustable
#input A Imagen

#param bloque 12 2 64

vec2 cell = vec2(@bloque) / @res;
vec2 uv = (floor(@uv / cell) + 0.5) * cell;
@out = A(uv);
