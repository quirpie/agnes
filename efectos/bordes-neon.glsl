#effect Bordes neón
#desc Contornos Sobel brillantes sobre la imagen oscurecida
#input A Imagen

#color neon #00f0ff
#param fuerza 3 0 10
#param fondo 0.25 0 1

// Luminancia de A desplazada (dx, dy) píxeles
float L(float dx, float dy) {
  return luma(A(@uv + vec2(dx, dy) / @res).rgb);
}

float gx = L(1.0, 1.0) + 2.0 * L(1.0, 0.0) + L(1.0, -1.0)
         - L(-1.0, 1.0) - 2.0 * L(-1.0, 0.0) - L(-1.0, -1.0);
float gy = L(-1.0, 1.0) + 2.0 * L(0.0, 1.0) + L(1.0, 1.0)
         - L(-1.0, -1.0) - 2.0 * L(0.0, -1.0) - L(1.0, -1.0);
float e = clamp(length(vec2(gx, gy)) * @fuerza, 0.0, 1.0);
@out.rgb = @A.rgb * @fondo + @neon * e;
