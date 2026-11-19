#effect VHS
#desc Líneas de barrido, color corrido, tracking y ruido de cinta VHS
#input A Imagen

#param lineas 0.35 0 1
#param grosor 2 1 6
#param sangrado 8 0 24
#param desfase 3 -12 12
#param temblor 1.5 0 8
#param tracking 0.6 0 1
#param cabeza 1 0 1
#param ruido 0.08 0 0.4
#param saturacion 0.85 0 1.5

// YIQ: el espacio de color de la TV analógica (Y = brillo, I/Q = color)
vec3 rgb2yiq(vec3 c) {
  return mat3(0.299, 0.596, 0.211,
              0.587, -0.274, -0.523,
              0.114, -0.322, 0.312) * c;
}
vec3 yiq2rgb(vec3 c) {
  return mat3(1.0, 1.0, 1.0,
              0.956, -0.272, -1.106,
              0.621, -0.647, 1.703) * c;
}

float px = 1.0 / @res.x;
float linea = floor(@P.y / @grosor);
float cuadro = floor(@time * 30.0);

// Temblor por línea + ondulación lenta de la cinta (en píxeles)
float dx = (hash13(vec3(linea, cuadro, 3.1)) - 0.5) * @temblor;
dx += sin(@uv.y * 40.0 + @time * 3.0) * @temblor * 0.4;

// Banda de tracking que sube rodando
float pos = fract(@time * 0.12);
float banda = (1.0 - smoothstep(0.0, 0.035, abs(@uv.y - pos))) * @tracking;
dx += banda * (hash13(vec3(linea, cuadro, 7.7)) - 0.3) * 40.0;

// Ruido de cambio de cabeza en el borde inferior
float cab = smoothstep(0.035, 0.0, @uv.y) * @cabeza;
dx += cab * 25.0 * (1.0 + hash13(vec3(linea, cuadro, 9.0)));

vec2 uv = @uv + vec2(dx * px, 0.0);

// Brillo nítido; color desenfocado y corrido en horizontal
float Y = rgb2yiq(A(uv).rgb).x;
vec2 IQ = vec2(0.0);
for (int i = 0; i < 8; i++) {
  float o = (float(i) / 7.0 - 0.5) * @sangrado + @desfase;
  IQ += rgb2yiq(A(uv + vec2(o * px, 0.0)).rgb).yz;
}
IQ = IQ / 8.0 * @saturacion;
vec3 col = yiq2rgb(vec3(Y, IQ));

// Líneas de barrido
float sl = 0.5 + 0.5 * cos(@P.y / @grosor * 6.28318);
col *= 1.0 - @lineas * (1.0 - sl);

// Ruido de señal, nieve en la banda de tracking y en la franja inferior
col += (hash13(vec3(@P, cuadro)) - 0.5) * @ruido;
col += banda * hash13(vec3(floor(@P.x * 0.5), linea, cuadro)) * 0.35;
col += cab * hash13(vec3(@P, cuadro + 1.0)) * 0.3;

@out = vec4(clamp(col, 0.0, 1.0), 1.0);
