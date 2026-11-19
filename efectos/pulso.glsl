#effect Pulso
#desc Zoom y brillo que laten con los graves del audio
#input A Imagen
#input B Audio

#param zoom 0.08 0 0.3
#param brillo 0.6 0 2
#color destello #ffd9a0

// Conecta un nodo Audio (capa «Valores») a la entrada B:
// @B.r = volumen, @B.g = graves, @B.b = agudos
float graves = @B.g;
vec2 c = @uv - 0.5;
vec4 col = A(0.5 + c / (1.0 + @zoom * graves));
col.rgb += @destello * @brillo * graves * graves;
@out = vec4(col.rgb, col.a);
