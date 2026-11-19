#effect Bordes neón
#desc Contornos Sobel brillantes sobre la imagen oscurecida
#input A Imagen

#color neon #00f0ff
#param fuerza 3 0 10
#param fondo 0.25 0 1

vec2 px = 1.0 / @res;
float tl = luma(A(@uv + px * vec2(-1.0,  1.0)).rgb);
float t  = luma(A(@uv + px * vec2( 0.0,  1.0)).rgb);
float tr = luma(A(@uv + px * vec2( 1.0,  1.0)).rgb);
float l  = luma(A(@uv + px * vec2(-1.0,  0.0)).rgb);
float r  = luma(A(@uv + px * vec2( 1.0,  0.0)).rgb);
float bl = luma(A(@uv + px * vec2(-1.0, -1.0)).rgb);
float b  = luma(A(@uv + px * vec2( 0.0, -1.0)).rgb);
float br = luma(A(@uv + px * vec2( 1.0, -1.0)).rgb);
float gx = tr + 2.0 * r + br - tl - 2.0 * l - bl;
float gy = tl + 2.0 * t + tr - bl - 2.0 * b - br;
float e = clamp(length(vec2(gx, gy)) * @fuerza, 0.0, 1.0);
@out.rgb = @A.rgb * @fondo + @neon * e;
