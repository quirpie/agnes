# Agnes

Compositor de fotos y video por nodos que corre en el navegador, inspirado en los COPs (Copernicus) de Houdini. Lleva el nombre de Agnès Varda.

Cada nodo produce una capa, y los **atributos** de una capa (luminancia, R, G, B o alfa) pueden conectarse a otras para controlar sus parámetros: máscaras, tamaño de desenfoque, desplazamiento, densidad de tramado…

## Uso

Es un solo archivo, `index.html`, sin dependencias ni compilación. Ábrelo en un navegador con WebGL2 (Chrome, Edge, Firefox o Safari 15+), o publícalo con GitHub Pages.

- Arrastra desde la salida ● de un nodo hasta la entrada de otro.
- Las entradas ámbar ■ reciben un atributo: eliges el canal y controla un parámetro.
- El ojo de cada nodo lo muestra en el visor.
- **Edición**: Secuencia une hasta 8 clips en orden, con transiciones integradas o cualquier efecto con `@progreso`. El audio de cada video sigue sus recortes, velocidad (también en reversa) y transiciones, en la vista previa y en el MP4.
- **Editor de la Secuencia**: al seleccionar una Secuencia aparece su línea de tiempo, con los clips como bloques con miniaturas y forma de onda. Arrastra los bordes para recortar, arrastra el bloque para reordenar, divide en el cabezal, mueve, quita o abre el nodo de cada clip. Los recortes se guardan en la propia Secuencia y funcionan con cualquier clip.
- **Línea de tiempo**: barra con cabezal, avance cuadro por cuadro (← →), duración del proyecto y repetición.
- **Exportar**: foto (PNG/JPG) o video MP4 renderizado cuadro por cuadro.
- **Audio**: el nodo Audio analiza un archivo de audio (o el audio de un video). Su capa lleva volumen, graves y agudos, y el botón ♪ junto a cualquier parámetro lo hace reaccionar al sonido. El video exportado incluye el audio.
- **Efectos**: importa efectos (archivos `.glsl`/`.json` o código pegado), que se guardan en el navegador y aparecen en **+ Nodo → Mis efectos**. Un nodo Código también se puede guardar como efecto. Hay ejemplos en [`efectos/`](efectos).

## Nodos

| Categoría | Nodos |
|---|---|
| Fuentes | Imagen, Video, Audio, Texto, Ruido, Degradado |
| Tiempo | Recortar (entrada, salida, posición), Velocidad (lenta, rápida, reversa), Secuencia (une clips con transiciones y su audio) |
| Filtros | Color, Gradación, Desenfoque, Transformar, Desplazar, Tramado, Bordes |
| Atributos | Atributo (canal → máscara) |
| Combinar | Mezclar |
| Código | Código (GLSL por píxel) |
| Mis efectos | Los efectos importados o guardados por el usuario |

## Crear efectos

La guía completa para crear efectos, pensada también para que la usen otros LLMs, está en [`docs/guia-efectos.md`](docs/guia-efectos.md): contrato del nodo Código, funciones disponibles, reglas de GLSL ES, recetas probadas, errores comunes y cómo agregar nodos nativos.

## Nodo Código

GLSL que se ejecuta en cada píxel, con atributos al estilo VEX:

```glsl
#param shift 0.012 0 0.05     // crea un deslizador → @shift
#color tint #ffe0b0           // crea un selector de color → @tint

vec2 d = @uv - 0.5;
@out.r = A(@uv + d * @shift).r;
@out.b = A(@uv - d * @shift).b;
@out.rgb *= mix(vec3(1.0), @tint, 0.4);
```

`@A @B @C` color de cada entrada · `A(uv)` lee la entrada en otra posición · `@uv` `@P` `@res` `@time` · `@out` resultado.
Funciones: `luma`, `noise`, `fbm(vec3 p, int oct)`, `rgb2hsv`, `hsv2rgb`.

## Detalles técnicos

- WebGL2 con texturas de 16 bits flotantes cuando el equipo las soporta; evaluación perezosa con caché por nodo y por instante. El tiempo es un argumento de la evaluación: los nodos de tiempo piden su entrada en otro instante, y cada video se adelanta al cuadro que el grafo necesita.
- El tramado por difusión de error (Atkinson, Floyd–Steinberg) se calcula en CPU sobre la cuadrícula reducida.
- La exportación de video usa WebCodecs (`VideoEncoder` y `AudioEncoder`) y un empaquetador MP4 propio, para que la duración y los cuadros sean exactos. El audio va en AAC, u Opus si el navegador no codifica AAC.
- El análisis de audio (FFT de 2048 muestras con ventana de Hann) se calcula sobre el audio decodificado en función del tiempo, así que la exportación cuadro por cuadro queda sincronizada.
- El grafo y la biblioteca de efectos se guardan en el `localStorage` del navegador (`agnes-graph-v1` y `agnes-effects-v1`); las fotos y videos cargados no se guardan. Un grafo guarda también una copia del código de cada efecto que usa: si el efecto se borra de la biblioteca, sus nodos pasan a ser nodos Código y siguen funcionando.
