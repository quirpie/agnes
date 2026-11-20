#effect Blanco y negro intenso
#desc Alto contraste con filtro de color, curva en S, claridad y grano
#input A Imagen

#enum filtro Neutro | Rojo | Naranja | Amarillo | Verde | Azul
#enum estilo Fotográfico | Gráfico (umbral)
#param contraste 1.8 0.3 4
#param negros 0.06 0 0.5
#param blancos 0.94 0.5 1
#param claridad 0.6 0 2
#param radio 6 1 24
#param umbral 0.5 0 1
#param suavidad 0.04 0 0.3
#param grano 0.05 0 0.3

// Mezcla de canales como un filtro frente al lente
// (Rojo oscurece cielos y azules; Verde aclara follaje; Azul aclara cielos)
float gris(vec3 c) {
  vec3 W[6] = vec3[6](
    vec3(0.2126, 0.7152, 0.0722),   // Neutro
    vec3(0.90, 0.10, 0.00),         // Rojo
    vec3(0.70, 0.30, 0.00),         // Naranja
    vec3(0.50, 0.45, 0.05),         // Amarillo
    vec3(0.20, 0.70, 0.10),         // Verde
    vec3(0.10, 0.20, 0.70));        // Azul
  return dot(c, W[@filtro]);
}

// Curva en S normalizada: 0 → 0, 1 → 1, más dura con k mayor
float curvaS(float x, float k) {
  float a = 1.0 / (1.0 + exp(k * 0.5));
  float b = 1.0 / (1.0 + exp(-k * 0.5));
  return (1.0 / (1.0 + exp(-k * (x - 0.5))) - a) / (b - a);
}

float g = gris(@A.rgb);

// Claridad: compara con el promedio de un anillo de 12 muestras
vec2 px = @radio / @res;
float prom = 0.0;
for (int i = 0; i < 12; i++) {
  float ang = float(i) * 0.5236;
  float r = (i % 2 == 0) ? 1.0 : 0.5;
  prom += gris(A(@uv + vec2(cos(ang), sin(ang)) * px * r).rgb);
}
prom /= 12.0;
g += @claridad * (g - prom);

// Puntos de negro y blanco, luego la curva
g = clamp((g - @negros) / max(@blancos - @negros, 0.001), 0.0, 1.0);
if (@estilo == 1) {
  g = smoothstep(@umbral - @suavidad, @umbral + @suavidad, g);
} else {
  g = curvaS(g, 4.0 * @contraste);
}

// Grano de película, más visible en los medios tonos
float n = hash13(vec3(@P, floor(@time * 24.0))) - 0.5;
g += n * @grano * (0.3 + 2.8 * g * (1.0 - g));

@out = vec4(vec3(clamp(g, 0.0, 1.0)), @A.a);
