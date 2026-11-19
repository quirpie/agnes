#effect Mezcla con máscara
#desc Funde A y B según un atributo de C
#input A Imagen 1
#input B Imagen 2
#input C Máscara scalar

#param suavidad 0.1 0 0.5
#param umbral 0.5 0 1

// @Cv = canal elegido de C (luminancia por defecto); sin conectar vale 1
float m = smoothstep(@umbral - @suavidad, @umbral + @suavidad, @Cv);
@out = mix(@A, @B, m);
