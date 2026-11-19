#effect Duotono
#desc Sombras y luces con dos colores
#input A Imagen

#color sombra #1a0b3d
#color luz #ffb36b
#param contraste 1.2 0 3

float l = luma(@A.rgb);
l = clamp((l - 0.5) * @contraste + 0.5, 0.0, 1.0);
@out.rgb = mix(@sombra, @luz, l);
