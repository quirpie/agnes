# Guía para crear efectos en Agnes

> Esta guía está escrita para modelos de lenguaje (LLMs) que generan efectos para Agnes, aunque también sirve para personas. Todo el código que aparece aquí se compiló y se probó en Agnes.

Agnes es un compositor de foto y video por nodos que corre en el navegador con WebGL2 (`index.html`, un solo archivo). Hay dos formas de crear un efecto:

1. **Un efecto importable** (recomendado). Es código del nodo Código (GLSL con atributos `@`) con un encabezado de nombre, descripción y entradas. El usuario lo importa en **Efectos** (archivo o texto pegado), queda guardado en su navegador y aparece en **+ Nodo → Mis efectos** como un nodo más. No hay que tocar el código fuente. Secciones 0 a 9.
2. **Un nodo nativo nuevo en `index.html`**, para efectos de varios pases o con procesamiento en CPU. Sección 10.

Si te piden «un efecto» sin más detalle, entrega un efecto importable.

---

## 0. Formato de respuesta esperado

Cuando entregues un efecto, incluye:

1. **Un solo bloque de código** que empiece con el encabezado de efecto (sección 0.1), seguido de las líneas `#param` y `#color`, y después el código.
2. **Qué conectar:** qué nodo va a cada entrada.
3. **Qué hace cada parámetro**, en una línea por parámetro.
4. **Cómo instalarlo:** «En Agnes, toca **Efectos**, pega el código y toca **Importar código pegado**. Luego agrégalo desde **+ Nodo → Mis efectos**». Si el usuario prefiere archivo, sugiere guardarlo como `nombre.glsl`.

No envuelvas el código en `void main()` ni declares `uniform`: Agnes lo hace por ti (sección 1.1).

### 0.1 Encabezado de efecto

```glsl
#effect Nombre visible               // obligatorio en la práctica; máx. 60 caracteres
#desc Qué hace, en una línea         // opcional; aparece en el menú
#input A Imagen                      // una línea por entrada que use el efecto
#input C Máscara scalar              // «scalar» = entrada de atributo (■ ámbar)
```

- `#input` acepta solo las letras `A`, `B` y `C`; el resto de la línea es la etiqueta del puerto.
- Si agregas `scalar` al final, la entrada se muestra como atributo: el usuario elige un canal (luminancia, R, G, B o alfa) y **sin conectar vale 1** (blanco). Lee el valor elegido con `@Av`, `@Bv` o `@Cv` (sección 1.2).
- Si no escribes ningún `#input`, Agnes deduce las entradas de las que el código usa (`@A`, `A(...)`, etc.). Un efecto que no usa ninguna es un **generador** (sin entradas), como un ruido o un plasma.
- Importar un efecto con el mismo `#effect` que uno instalado lo **actualiza** (sin distinguir mayúsculas), y todos los nodos que lo usan se actualizan con él.
- El encabezado no estorba en un nodo Código: allí esas líneas se ignoran.

Ejemplo completo:

```glsl
#effect Duotono
#desc Sombras y luces con dos colores
#input A Imagen
#color sombra #1a0b3d
#color luz #ffb36b
#param contraste 1.2 0 3

float l = luma(@A.rgb);
l = clamp((l - 0.5) * @contraste + 0.5, 0.0, 1.0);
@out.rgb = mix(@sombra, @luz, l);
```

### 0.2 Formatos de archivo

| Formato | Contenido |
|---|---|
| `.glsl`, `.frag`, `.txt` | Un efecto: el código con su encabezado. Si falta `#effect`, el nombre sale del archivo. |
| `.json` (uno) | `{"agnes":"effect","version":1,"name":"…","desc":"…","code":"…"}` |
| `.json` (varios) | `{"agnes":"effects","version":1,"effects":[{"name":"…","desc":"…","code":"…"}, …]}` o directamente un arreglo. |

En JSON, `name` y `desc` son opcionales si el `code` ya trae `#effect` y `#desc`; si vienen, mandan sobre el encabezado. Al pegar texto, Agnes extrae el primer bloque de código entre ```` ``` ````, así que el usuario puede pegar tu respuesta completa.

Agnes compila cada efecto antes de guardarlo: si tiene errores, no lo importa y muestra el mensaje con su número de línea. El código es solo GLSL y corre en la GPU, nunca como JavaScript, así que importar efectos de otras personas no da acceso a nada del navegador.

La carpeta [`efectos/`](../efectos) del repositorio tiene ejemplos listos para importar, incluido `todos.agnes.json` con todos juntos.

---

## 1. El nodo Código: contrato exacto

### 1.1 Qué hace Agnes con tu código

Tu texto se procesa así:

1. Las líneas `#param` y `#color` se quitan (quedan en blanco para que los números de línea coincidan) y se convierten en controles y `uniform`. Las de encabezado (`#effect`, `#desc`, `#input`) también se quitan.
2. Las **definiciones de función** y las líneas `#define` que estén fuera de cualquier bloque `{}` se mueven al ámbito global, antes de `main()` (sección 1.5).
3. Cada `@nombre` se reemplaza por el identificador GLSL correspondiente (tabla 1.2).
4. El resto se inserta dentro de `main()`:

```glsl
#version 300 es
precision highp float;
precision highp int;
// ... cabecera con uniforms y funciones (sección 1.4) ...
uniform float u_shift;            // generado por cada #param
uniform vec3  u_tint;             // generado por cada #color
vec4 _A, _B, _C, _out;            // globales: también se ven desde tus funciones
// <<< TUS FUNCIONES Y #define, cada uno con #line para conservar su número de línea >>>
void main(){
  _A = texture(iA, vUv); _B = texture(iB, vUv); _C = texture(iC, vUv);
  _out = _A;
  #line 1
  // <<< EL RESTO DE TU CÓDIGO VA AQUÍ >>>
  outColor = _out;
}
```

Consecuencias:

- Todo lo que no sea una función ni un `#define` es el **cuerpo de `main()`**: sentencias que se ejecutan en orden.
- Puedes **definir funciones auxiliares** en cualquier parte del snippet (sección 1.5).
- `@out` **empieza igual a `@A`**. Si no lo tocas, el nodo deja pasar la entrada A.
- Los números de línea de los errores corresponden a las líneas de tu snippet.

### 1.2 Atributos `@`

| Atributo | Se convierte en | Tipo | Significado |
|---|---|---|---|
| `@A` `@B` `@C` | `_A` `_B` `_C` | `vec4` | Color RGBA de cada entrada en el píxel actual. Una entrada sin conectar vale `vec4(0.0)`. |
| `@Av` `@Bv` `@Cv` | `pick(_A,uChA)` … | `float` | Valor del canal elegido en el panel para esa entrada (con `#input … scalar`). En entradas normales es la luminancia. |
| `@out` | `_out` | `vec4` | Resultado del píxel. Empieza igual a `@A`. |
| `@uv` | `vUv` | `vec2` | Coordenada normalizada 0–1. **(0,0) es la esquina inferior izquierda.** |
| `@P` | `gl_FragCoord.xy` | `vec2` | Coordenada en píxeles (centro del píxel: 0.5, 1.5, …). |
| `@res` | `uRes` | `vec2` | Resolución del lienzo en píxeles (por ejemplo 960×540). |
| `@time` | `uTime` | `float` | Segundos desde 0. **Si aparece `@time` en el texto, el nodo se recalcula en cada cuadro.** |
| `@nombre` | `u_nombre` | `float`, `vec3` o `int` | Cualquier otro nombre: el parámetro declarado con `#param`, `#color` o `#enum`. Si no lo declaraste, da `'u_nombre' : undeclared identifier`. |

### 1.3 Directivas de parámetros

```glsl
#param nombre valor_inicial mínimo máximo    // deslizador → @nombre (float)
#color nombre #rrggbb                        // selector de color → @nombre (vec3, 0–1)
#enum nombre Opción 1 | Opción 2 | Opción 3  // lista desplegable → @nombre (int: 0, 1, 2…)
```

Reglas estrictas (se leen con una expresión regular, no con un analizador):

- Una directiva por línea, al inicio de la línea.
- `nombre`: letras, dígitos y `_`, sin espacios.
- Los números van en decimal simple: `0.5`, `-2`, `.25`. **No uses** notación científica (`1e-3`) ni signo `+`.
- `#color` exige **6 dígitos hexadecimales** (`#ff8800`, no `#f80`).
- `#enum` separa las opciones con `|` (pueden tener espacios). La primera es la inicial. `@nombre` es un `int`: compáralo con enteros, `if (@modo == 1)`. Úsalo para modos, en lugar de un `#param` que haya que redondear.
- Los `#param` siempre son `float`. Si necesitas un entero, conviértelo: `int n = int(@pasos);`.
- Si cambias el valor inicial en el código, el control se reinicia a ese valor.

### 1.4 Funciones y uniforms disponibles

Además de las funciones nativas de GLSL ES 3.00 (`mix`, `smoothstep`, `fract`, `texture`, `atan`, …), la cabecera de Agnes trae:

| Firma | Qué hace |
|---|---|
| `vec4 A(vec2 uv)`, `B(uv)`, `C(uv)` | Lee la entrada A, B o C en otra posición (filtrado bilineal, bordes extendidos). |
| `float luma(vec3 c)` | Luminancia (Rec. 709). |
| `float pick(vec4 c, int ch)` | Extrae un canal: 0 luminancia, 1 R, 2 G, 3 B, 4 alfa. |
| `vec3 rgb2hsv(vec3 c)`, `vec3 hsv2rgb(vec3 c)` | Conversión de espacio de color; el tono va de 0 a 1. |
| `float hash13(vec3 p)` | Número pseudoaleatorio 0–1 a partir de un `vec3`. |
| `float noise(vec2 p)`, `float noise(vec3 p)` | Ruido de valor suave, 0–1. |
| `float fbm(vec3 p, int octavas)`, `float fbm(vec2 p)` | Ruido fractal 0–1 (la versión `vec2` usa 5 octavas). |

Uniforms que también puedes usar directamente, sin `@`:

| Uniform | Tipo | Significado |
|---|---|---|
| `uHasA` `uHasB` `uHasC` | `float` | 1.0 si la entrada está conectada, 0.0 si no. |
| `iA` `iB` `iC` | `sampler2D` | Las texturas de entrada, por si necesitas `textureSize` o `texelFetch`. |

### 1.5 Funciones auxiliares

Escribe funciones GLSL normales en el snippet. Agnes las detecta y las mueve fuera de `main()`:

```glsl
#param fuerza 3 0 10

// Luminancia de A desplazada (dx, dy) píxeles
float L(float dx, float dy) {
  return luma(A(@uv + vec2(dx, dy) / @res).rgb);
}

float gx = L(1.0, 0.0) - L(-1.0, 0.0);
float gy = L(0.0, 1.0) - L(0.0, -1.0);
@out.rgb = vec3(length(vec2(gx, gy)) * @fuerza);
```

Reglas:

- Una función se reconoce cuando la línea empieza (fuera de cualquier `{}`) con un tipo de retorno (`void`, `float`, `int`, `bool`, `vec2`–`vec4`, `ivec*`, `bvec*`, `mat2`–`mat4`), un nombre y `(`. La firma puede ocupar varias líneas.
- **Dentro de las funciones valen todos los `@`**: `@A`, `@uv`, `@res`, `@time`, `@Av` y tus parámetros. Una función `void` incluso puede modificar `@out`.
- Desde el cuerpo puedes llamar a una función definida más abajo. Pero **una función que llama a otra necesita que la otra esté definida antes** (o declarada con un prototipo como `float g(float x);`), como en cualquier GLSL.
- No pongas a tus funciones los nombres de la cabecera (`A`, `B`, `C`, `luma`, `pick`, `noise`, `fbm`, `hash13`, `vnoise`, `rgb2hsv`, `hsv2rgb`). Sí puedes **sobrecargarlas** con otra firma.
- Las variables declaradas en el cuerpo **no** son visibles dentro de las funciones: pásalas como argumento.
- Los `#define` fuera de bloques también se mueven al inicio, así que sirven dentro de las funciones.
- Los errores dentro de una función muestran la línea correcta del snippet.

### 1.6 Convenciones de imagen

- Todas las capas tienen el tamaño del lienzo (`@res`). Las entradas ya llegan ajustadas a ese tamaño.
- Los colores van de 0 a 1. Internamente las capas son de 16 bits flotantes (cuando el equipo lo permite), así que valores por encima de 1 sobreviven entre nodos; el visor y la exportación recortan a 0–1 al final.
- El alfa importa: el nodo Mezclar en modo «Sobre» lo usa, y el PNG exportado lo conserva. Si tu efecto genera una imagen opaca, deja `@out.a = 1.0`.
- `@uv` **no es cuadrado**: en un lienzo de 16:9, un círculo `length(@uv - 0.5) < r` sale ovalado. Para coordenadas cuadradas, multiplica x por la proporción:

```glsl
vec2 p = @uv - 0.5;
p.x *= @res.x / @res.y;   // ahora length(p) mide igual en x y en y
```

- Un píxel en unidades de `uv` es `1.0 / @res`.
- Leer fuera de 0–1 devuelve el color del borde (los bordes se extienden). Si quieres negro fuera de la imagen, compruébalo tú.

---

## 2. Reglas de GLSL ES 3.00 que más fallan

GLSL ES es estricto. Estas son las causas de error más comunes:

1. **No hay conversión automática entre `int` y `float`.** Escribe `2.0`, no `2`. Convierte con `float(i)` e `int(x)`.
2. **Una función debe estar definida antes que otra función que la llame** (sección 1.5).
3. **Los tamaños de vector deben coincidir:** `vec3 c = @A;` falla; usa `@A.rgb`.
4. **Cada sentencia termina en `;`.**
5. Los bucles con límite variable están permitidos en ES 3.00, pero cada iteración cuesta en el teléfono (sección 4).
6. Los nombres que empiezan con `gl_` están reservados. No declares variables llamadas `A`, `B`, `C`, `iA`, `vUv`, `uRes`, `uTime` ni con prefijo `u_` o `_`, porque chocan con la cabecera.

---

## 3. Plantilla

```glsl
// Nombre del efecto: qué hace en una línea
#param cantidad 0.5 0 1
#color tinte #ffffff

vec4 src = @A;
vec3 col = src.rgb;

// ... transformar col ...

@out = vec4(mix(src.rgb, col * @tinte, @cantidad), src.a);
```

---

## 4. Límites y rendimiento

- **Un solo pase.** Cada píxel se calcula de forma independiente y solo puede leer las entradas A, B y C, no el resultado de otros píxeles de este mismo nodo. Para efectos de varios pases (por ejemplo, desenfoque separable o bloom), **encadena varios nodos Código** o escribe un nodo nativo (sección 10).
- **Sin memoria entre cuadros.** No hay acceso al cuadro anterior; la animación sale solo de `@time`.
- **`@time` es el tiempo del nodo, no siempre el del proyecto.** Si el efecto está después de un nodo Recortar o Velocidad, `@time` es el instante que esos nodos le piden (por ejemplo, va hacia atrás en reversa).
- **Máximo 3 entradas** (A, B, C).
- **Rendimiento:** el código corre una vez por píxel en cada cuadro (unos 500 000 píxeles a 960×540, casi 1 millón a 1280×720). En un teléfono de gama media, procura no pasar de unas **32 lecturas de textura** por píxel. Los bucles de 64 o más lecturas se notan.
- `@time` en cualquier parte del texto, incluso en un comentario, hace que el nodo se recalcule en cada cuadro. Si el efecto no se anima, no lo menciones.

---

## 5. Recetas

Cada receta se pega tal cual en un nodo Código, con la imagen o el video conectado a la entrada A, salvo que se diga otra cosa.

### 5.1 Duotono
```glsl
// Duotono: sombras y luces con dos colores
#color sombra #1a0b3d
#color luz #ffb36b
#param contraste 1.2 0 3

float l = luma(@A.rgb);
l = clamp((l - 0.5) * @contraste + 0.5, 0.0, 1.0);
@out.rgb = mix(@sombra, @luz, l);
```

### 5.2 Viñeta con grano animado
Usa `hash13` con el cuadro como tercera coordenada para que el grano cambie 24 veces por segundo.
```glsl
// Viñeta + grano animado
#param grano 0.08 0 0.5
#param vig 1.2 0 3

vec2 d = @uv - 0.5;
d.x *= @res.x / @res.y;
float n = hash13(vec3(@P, floor(@time * 24.0))) - 0.5;
@out.rgb += n * @grano;
@out.rgb *= 1.0 - @vig * dot(d, d);
```

### 5.3 Pixelado
Muestrea A en el centro de cada bloque.
```glsl
// Pixelado en bloques cuadrados
#param bloque 12 2 64

vec2 cell = vec2(@bloque) / @res;
vec2 uv = (floor(@uv / cell) + 0.5) * cell;
@out = A(uv);
```

### 5.4 Semitono
Cuadrícula girada; el radio de cada punto depende de la luminancia en su centro.
```glsl
// Semitono: puntos cuyo radio sigue la luminancia
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
```

### 5.5 Pantalla CRT
Curvatura de barril y líneas de barrido; negro fuera de la pantalla curva.
```glsl
// Líneas de barrido CRT con curvatura
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
```

### 5.6 Ondas animadas
```glsl
// Ondas animadas que deforman la imagen
#param amp 0.01 0 0.05
#param freq 18 1 80
#param vel 2 0 10

vec2 uv = @uv;
uv.x += sin(uv.y * @freq + @time * @vel) * @amp;
uv.y += cos(uv.x * @freq * 0.7 + @time * @vel) * @amp;
@out = A(uv);
```

### 5.7 Caleidoscopio
Coordenadas polares con corrección de proporción.
```glsl
// Caleidoscopio de N segmentos
#param segmentos 6 2 16
#param giro 0 0 6.2832

vec2 p = @uv - 0.5;
p.x *= @res.x / @res.y;
float r = length(p);
float a = atan(p.y, p.x) + @giro;
float seg = 6.28318 / floor(@segmentos);
a = abs(mod(a, seg) - seg * 0.5);
p = vec2(cos(a), sin(a)) * r;
p.x /= @res.x / @res.y;
@out = A(p + 0.5);
```

### 5.8 Mezcla con máscara (usa A, B y C)
Conecta dos imágenes a A y B, y una máscara (por ejemplo un Ruido o un Degradado) a C. Si C no está conectada, `uHasC` vale 0 y se muestra A. La versión importable en `efectos/mezcla-mascara.glsl` declara C como `scalar` y usa `@Cv`.
```glsl
// Mezcla A y B usando la luminancia de C como máscara
#param suavidad 0.1 0 0.5
#param umbral 0.5 0 1

float m = luma(@C.rgb);
m = smoothstep(@umbral - @suavidad, @umbral + @suavidad, m);
@out = mix(@A, @B, m * uHasC);
```

### 5.9 Bordes neón
Operador de Sobel con una función auxiliar `L()` que lee la luminancia desplazada.
```glsl
// Bordes tipo neón (Sobel) sobre la imagen oscurecida
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
```

### 5.10 Desenfoque radial
Bucle de 24 lecturas hacia un centro ajustable.
```glsl
// Desenfoque radial (zoom) con bucle
#param fuerza 0.15 0 0.5
#param cx 0.5 0 1
#param cy 0.5 0 1

vec2 c = vec2(@cx, @cy);
vec4 acc = vec4(0.0);
for (int i = 0; i < 24; i++) {
  float k = float(i) / 23.0;
  acc += A(mix(@uv, c, k * @fuerza));
}
@out = acc / 24.0;
```

---

## 6. Efectos que reaccionan al sonido

El nodo **Audio** (Fuentes) carga un archivo de audio, o el audio de un video, y lo analiza en cada cuadro. Hay dos formas de usarlo.

### 6.1 Desde código: el audio como capa

Conecta el nodo Audio a una entrada del efecto. Con la capa en modo **Valores** (por defecto), todos los píxeles valen lo mismo:

| Canal | Valor (0–1) |
|---|---|
| `r` | Volumen general |
| `g` | Graves (20–250 Hz) |
| `b` | Agudos (2–12 kHz) |
| `a` | Siempre 1 |

Como la capa es uniforme, basta leer el píxel actual: `@B.g` son los graves. Declara la entrada con `#input B Audio` para que el puerto tenga nombre. Los **medios** (250–2000 Hz) no están en la capa: para usarlos, conecta el parámetro con el control por audio (6.2).

```glsl
#effect Pulso
#desc Zoom y brillo que laten con los graves del audio
#input A Imagen
#input B Audio
#param zoom 0.08 0 0.3
#param brillo 0.6 0 2
#color destello #ffd9a0

float graves = @B.g;
vec2 c = @uv - 0.5;
vec4 col = A(0.5 + c / (1.0 + @zoom * graves));
col.rgb += @destello * @brillo * graves * graves;
@out = vec4(col.rgb, col.a);
```

Consejos:

- Elevar al cuadrado (`graves * graves`) acentúa los golpes y aplana el ruido de fondo.
- El nodo Audio tiene **Ganancia** (sube todo), **Umbral** (lo que queda por debajo vale 0) y **Suavizado** (respuesta más lenta y menos nerviosa). Dile al usuario cuál ajustar si el efecto se mueve poco o demasiado.
- Las otras capas del nodo Audio son **Espectro** (barras: x = frecuencia en escala logarítmica, de 30 Hz a 16 kHz) y **Onda** (forma de onda): en una entrada de código, `B(vec2(x, 0.5))` lee la columna `x`, pero ten en cuenta que esas capas dibujan barras o una línea, no un valor por columna en todos los píxeles.

### 6.2 Sin código: control por audio de cualquier parámetro

Junto a cada deslizador de número hay un botón ♪. Al activarlo, el parámetro queda así:

```
valor = valor del deslizador + cantidad × señal
```

donde la señal es el volumen, los graves, los medios o los agudos (0–1) del nodo Audio elegido. El resultado se limita al rango del parámetro, y la cantidad puede ser negativa. Funciona con los parámetros de los nodos nativos, de los nodos Código y de los efectos importados (los `#param`). Un cable punteado verde une el nodo Audio con cada nodo que controla.

Si un efecto expone un `#param` con un rango razonable, el usuario puede animarlo con audio o con fotogramas clave (botón ◆) sin cambiar tu código. Por eso conviene que los parámetros principales sean `#param` y no constantes.

### 6.3 Sincronía y exportación

El análisis se calcula a partir del audio decodificado y del tiempo, no en vivo: el video exportado queda sincronizado cuadro por cuadro y lleva el audio del nodo Audio (AAC u Opus, según el navegador). En la vista previa, el análisis sigue lo que se está escuchando.

---

## 6.4 Transiciones para Secuencia

Un efecto puede servir como transición del nodo Secuencia si declara un parámetro **`progreso`**. Secuencia lo controla durante la transición, de 0 (solo el clip saliente) a 1 (solo el entrante), y conecta el clip saliente a **A** y el entrante a **B**. Aparece en Secuencia → Transición → «Efecto de Mis efectos».

```glsl
#effect Transición: barrido diagonal
#desc Para Secuencia: barrido en diagonal con borde brillante
#input A Saliente
#input B Entrante

#param progreso 0.5 0 1
#param suavidad 0.08 0.01 0.5
#color borde #ffffff

float d = (@uv.x + @uv.y) * 0.5;
float e = @progreso * (1.0 + 2.0 * @suavidad) - @suavidad;
float m = smoothstep(e + @suavidad, e - @suavidad, d);
float brillo = 1.0 - abs(m * 2.0 - 1.0);
@out = mix(@A, @B, m);
@out.rgb += @borde * brillo * 0.6;
```

Reglas:

- Con `@progreso = 0` el resultado debe ser exactamente `@A`, y con `1` exactamente `@B`; si no, se nota un salto al empezar o terminar la transición.
- Pon el nombre con el prefijo «Transición:» para que se distinga en el menú.
- El valor inicial de `#param progreso` solo sirve para previsualizar el efecto en un nodo suelto; dentro de Secuencia lo controla ella.

---

## 7. Combinar con otros nodos

A veces es mejor armar un grafo que escribir código. Estos son los nodos nativos:

| Nodo | Entradas (■ = atributo escalar) | Qué hace |
|---|---|---|
| Imagen | — | Carga una foto. |
| Audio | — | Analiza un audio: capa con volumen, graves y agudos; espectro u onda. |
| Recortar | Clip | Muestra el tramo entrada–salida del clip a partir del segundo «Empieza en»; fuera del rango, transparente, congelado o en bucle. |
| Velocidad | Clip | Cambia la velocidad (negativa = reversa, 0 = congelado) desde un instante dado. |
| Secuencia | Clip 1…8 | Une clips en orden con transición (corte, fundido, fundido a negro, cortinilla, deslizar, zoom, disolución o un efecto con `@progreso`). Une también el audio de los clips. |
| Texto | — | Texto con fuente, contorno, sombra y animación de escritura, sobre fondo transparente (combínalo con Mezclar). |
| Video | — | Carga un video (sin audio). |
| Ruido | — | Ruido fractal, gris, color o vector; animable. |
| Degradado | — | Lineal o radial entre dos colores. |
| Color | Entrada, ■ Máscara | Brillo, contraste, saturación, tono, gamma. |
| Gradación | Entrada, ■ Máscara | Exposición, temperatura, matiz, contraste, color de sombras/medios/luces, saturación, vibración, desvanecido y preajustes. |
| Desenfoque | Entrada, ■ Mapa tamaño | Desenfoque gaussiano; el mapa controla el radio por píxel. |
| Transformar | Entrada | Mover, escalar, rotar; bordes vacíos, repetidos o en espejo. |
| Desplazar | Entrada, ■ Campo | Deforma según el gradiente de un canal o un vector RG. |
| Tramado | Entrada, ■ Máscara | Dithering en puntos (Atkinson, Floyd–Steinberg, Bayer, ruido azul). |
| Bordes | Entrada | Sobel en escala de grises. |
| Atributo | ■ Fuente | Convierte un canal en máscara, con rango, suavizado e inversión. |
| Mezclar | Frente, Fondo, ■ Máscara | Sobre, Suma, Multiplicar, Pantalla, Diferencia, Superponer. |
| Código | A, B, C | Tu snippet. |

Una entrada ■ toma **un canal** (luminancia, R, G, B o alfa, a elegir en el panel) de la capa conectada y lo usa para controlar un parámetro por píxel. Un patrón típico es Ruido → Atributo → ■ Máscara de otro nodo.

---

## 8. Errores comunes

Los mensajes son los que da Chrome (con ANGLE); otros navegadores los redactan distinto. «Línea N» se refiere a tu snippet.

| Mensaje | Causa | Solución |
|---|---|---|
| `cannot convert from 'const int' to 'highp float'` | Literal entero donde va un float (`float x = 1;`) | Escribe `1.0`. |
| `cannot convert from 'const int' to 'highp 3-component vector of float'` | `@out.rgb *= 2;` | `@out.rgb *= 2.0;` |
| `wrong operand types - no operation '*' exists … 'highp float' and … 'highp int'` | Mezclar `float` e `int` en una operación | `x * float(i)` |
| `'u_nombre' : undeclared identifier` | Usaste `@nombre` sin declarar `#param`, `#color` o `#enum` (o hay un error de escritura en la directiva) | Agrega la directiva y revisa el formato (sección 1.3). |
| `'f' : no matching overloaded function found` | Llamaste a una función con tipos de argumento que no coinciden (por ejemplo `f(1)` cuando espera `float`), o una función llama a otra definida más abajo | Revisa los tipos (`f(1.0)`) o mueve la función llamada arriba. |
| `'luma' : function already has a body` | Definiste una función con el mismo nombre y firma que una de la cabecera (o la definiste dos veces) | Cámbiale el nombre. |
| `dimension mismatch` | Asignaste un `vec4` a un `vec3` (o al revés) | Usa `.rgb`, `.xy`, o construye `vec4(c, 1.0)`. |
| `'_out' : syntax error` (o el siguiente identificador) | Falta `;` al final de la línea anterior | Agrega el `;`. |

Cuando el código no compila, Agnes muestra el error debajo del editor y el visor sigue con la última versión válida.

---

## 9. Lista de verificación antes de entregar

- [ ] Todos los literales que deben ser float tienen punto decimal (`1.0`, `0.5`).
- [ ] Si una función llama a otra, la llamada está definida antes. Ninguna función se llama como las de la cabecera.
- [ ] Cada `@nombre` tiene su `#param`, `#color` o `#enum`, con números en decimal simple y colores de 6 dígitos.
- [ ] Los rangos de `#param` son útiles: el mínimo y el máximo dan resultados razonables.
- [ ] Si usas distancias o círculos, corregiste la proporción con `@res.x / @res.y`.
- [ ] `@out.a` tiene sentido (normalmente `@A.a` o `1.0`).
- [ ] Menos de ~32 lecturas de textura por píxel.
- [ ] Solo mencionas `@time` si el efecto se anima.
- [ ] El código empieza con `#effect` y `#desc`, y tiene un `#input` por cada entrada que usa (con `scalar` si es una máscara o atributo).
- [ ] Indicaste qué conectar a cada entrada y cómo importarlo.

---

## 10. Avanzado: agregar un nodo nativo a `index.html`

Usa esta vía solo si el efecto necesita varios pases, texturas intermedias, procesamiento en CPU o una interfaz propia. Todo está en `index.html`.

### 10.1 Definición en `DEFS`

```js
miEfecto:{
  name:'Mi efecto',            // nombre visible
  cat:'flt',                   // src | flt | attr | mix | code (categoría del menú y color)
  desc:'descripción corta',    // texto gris en el menú
  inputs:[                     // hasta 3; se mapean en orden a iA, iB, iC
    {k:'in',label:'Entrada'},                                  // kind 'rgba' por defecto
    {k:'mask',label:'Máscara',kind:'scalar',white:true}        // ■ atributo; sin conectar vale 1
  ],
  params:[
    {k:'amount',t:'float',label:'Cantidad',v:.5,min:0,max:1},
    {k:'steps',t:'int',label:'Pasos',v:4,min:1,max:16},
    {k:'mode',t:'enum',label:'Modo',opts:['Uno','Dos'],v:0},
    {k:'invert',t:'bool',label:'Invertir',v:false},
    {k:'tint',t:'color',label:'Tinte',v:'#ffffff'}
  ],
  fs:FS.miEfecto,              // shader de un pase (sección 10.2), o bien:
  // run:runMiEfecto,          // función propia para varios pases (sección 10.3)
  // td:n=>n.p.speed>0,        // true si depende del tiempo aunque sus entradas no
},
```

Tipos de parámetro y su uniform automático (`u_` + clave):

| `t` | Control | Uniform |
|---|---|---|
| `float` | deslizador | `float` |
| `int` | deslizador entero | `int` |
| `enum` | lista (`opts`) | `int` (índice) |
| `bool` | casilla | `float` (0.0 o 1.0) |
| `color` | selector | `vec3` |
| `file` | botón de archivo | — (lo maneja `run`) |

### 10.2 Shader de un pase

Se define como `FS_HEAD + cuerpo`. La cabecera ya trae todo lo de la sección 1.4, además de `vUv`, `outColor`, `uRes`, `uTime`, `uChA` a `uChC` (canal elegido para cada entrada ■) y `uHasA` a `uHasC`.

```js
FS.miEfecto=FS_HEAD+`uniform float u_amount;uniform vec3 u_tint;
void main(){
  vec4 c=A(vUv);
  float m=pick(texture(iB,vUv),uChB);        // atributo ■ de la 2.ª entrada
  outColor=vec4(mix(c.rgb,c.rgb*u_tint,u_amount*m),c.a);
}`;
```

Sin `run`, Agnes usa `runGeneric`: enlaza las entradas, sube los parámetros y dibuja un pase en la capa del nodo.

### 10.3 Varios pases con `run`

`run(n, ins, d)` recibe el nodo, las texturas de entrada ya evaluadas (`null` si no están conectadas) y la definición. Debe dejar el resultado en `n._out` (creado por Agnes, del tamaño del lienzo). Funciones útiles:

- `pass(fs, target, fn)`: dibuja un pase en `target` (`{tex, fb, w?, h?}`); en `fn(P)` se enlazan las texturas y uniforms.
- `makeTarget()`: textura intermedia del tamaño del lienzo (16 bits flotantes cuando se puede). `makeTarget8(w, h)`: RGBA de 8 bits del tamaño que indiques.
- `bindTex(P, nombre, unidad, tex)`, `set1f`, `set1i`, `set2f`, `set3f`, `setParams(P, d.params, n.p)`, `bindInputs(P, n, ins, d)`.
- Guarda las texturas auxiliares en el nodo (`n._tmp`, etc.) y libéralas en `dispose()`.

Ejemplo real, el desenfoque separable de dos pases:

```js
function runBlur(n,ins){
  if(!n._tmp)n._tmp=makeTarget();
  const map=ins[1]||WHITE,ch=n.ch.map||0;
  pass(FS.blur,n._tmp,P=>{bindTex(P,'iA',0,ins[0]||BLACK);bindTex(P,'iB',1,map);set1i(P,'uChB',ch);set2f(P,'uDir',1,0);set1f(P,'u_size',n.p.size);});
  pass(FS.blur,n._out,P=>{bindTex(P,'iA',0,n._tmp.tex);bindTex(P,'iB',1,map);set1i(P,'uChB',ch);set2f(P,'uDir',0,1);set1f(P,'u_size',n.p.size);});
}
```

El nodo Tramado (`runDither`) es el ejemplo de procesamiento en CPU: reduce la imagen con un pase, la lee con `readPixels`, aplica la difusión de error en JavaScript y sube el resultado como textura.

### 10.4 Lo que Agnes hace por ti

- **Caché:** un nodo solo se recalcula si cambian sus parámetros, sus entradas o, si depende del tiempo, el cuadro.
- **Interfaz:** el panel de parámetros, los puertos y el menú se generan a partir de `DEFS`.
- **Guardado:** los parámetros se guardan solos en el navegador.
- **Exportación:** foto y video funcionan con cualquier nodo sin código extra.

Para probar, abre `index.html` en Chrome; los errores de compilación de los shaders nativos aparecen en la consola.
