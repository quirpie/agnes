#effect Anaglifo 3D
#desc Fusiona el ojo izquierdo (rojo) y el derecho (cian) como el cine 3D clásico
#input A Ojo izquierdo
#input B Ojo derecho
#input C Profundidad scalar

#enum modo Color | Grises | Optimizado (Dubois)
#param separacion 6 -40 40
#color izquierda #ff0000
#color derecha #00ffff

// A = ojo izquierdo, B = ojo derecho. Si B no está conectada, el par se
// inventa desplazando A. Con un mapa en C (claro = cerca), el desplazamiento
// cambia por píxel y la imagen gana relieve.
float k = uHasC > 0.5 ? (@Cv - 0.5) * 2.0 : 1.0;
vec2 off = vec2(@separacion * k * 0.5 / @res.x, 0.0);
vec4 L = A(@uv + off);
vec4 R = uHasB > 0.5 ? B(@uv - off) : A(@uv - off);

vec3 col;
if (@modo == 1) {
  // Grises: menos rivalidad de color, más cómodo de ver
  col = luma(L.rgb) * @izquierda + luma(R.rgb) * @derecha;
} else if (@modo == 2) {
  // Matrices de Dubois para rojo/cian: menos "fantasmas"
  col = vec3(
    dot(L.rgb, vec3( 0.456,  0.500,  0.176)) + dot(R.rgb, vec3(-0.043, -0.088, -0.002)),
    dot(L.rgb, vec3(-0.040, -0.038, -0.016)) + dot(R.rgb, vec3( 0.378,  0.734, -0.018)),
    dot(L.rgb, vec3(-0.015, -0.021, -0.005)) + dot(R.rgb, vec3(-0.072, -0.113,  1.226)));
} else {
  // Color: cada ojo pasa por su filtro
  col = L.rgb * @izquierda + R.rgb * @derecha;
}
@out = vec4(clamp(col, 0.0, 1.0), max(L.a, R.a));
