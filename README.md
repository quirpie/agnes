# Agnes

Compositor de fotos y video por nodos que corre en el navegador, inspirado en los COPs (Copernicus) de Houdini. Lleva el nombre de Agnès Varda.

Cada nodo produce una capa, y los **atributos** de una capa (luminancia, R, G, B o alfa) pueden conectarse a otras para controlar sus parámetros: máscaras, tamaño de desenfoque, desplazamiento, densidad de tramado…

## Uso

Es un solo archivo, `index.html`, sin dependencias ni compilación. Ábrelo en un navegador con WebGL2 (Chrome, Edge, Firefox o Safari 15+), o publícalo con GitHub Pages.

- Arrastra desde la salida ● de un nodo hasta la entrada de otro.
- Las entradas ámbar ■ reciben un atributo: eliges el canal y controla un parámetro.
- El ojo de cada nodo lo muestra en el visor.
- **Exportar**: foto (PNG/JPG) o video MP4 renderizado cuadro por cuadro.

## Nodos

| Categoría | Nodos |
|---|---|
| Fuentes | Imagen, Video, Ruido, Degradado |
| Filtros | Color, Desenfoque, Transformar, Desplazar, Tramado, Bordes |
| Atributos | Atributo (canal → máscara) |
| Combinar | Mezclar |
| Código | Código (GLSL por píxel) |

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

- WebGL2 con texturas de 16 bits flotantes cuando el equipo las soporta; evaluación perezosa y caché por nodo.
- El tramado por difusión de error (Atkinson, Floyd–Steinberg) se calcula en CPU sobre la cuadrícula reducida.
- La exportación de video usa WebCodecs (`VideoEncoder`) y un empaquetador MP4 propio, para que la duración y los cuadros sean exactos.
- El grafo se guarda en el `localStorage` del navegador; las fotos y videos cargados no se guardan.
