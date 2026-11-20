#effect Transición: barrido diagonal
#desc Para Secuencia: barrido en diagonal con borde brillante
#input A Saliente
#input B Entrante

// Secuencia controla @progreso (0 → solo A, 1 → solo B)
#param progreso 0.5 0 1
#param suavidad 0.08 0.01 0.5
#color borde #ffffff

float d = (@uv.x + @uv.y) * 0.5;
float e = @progreso * (1.0 + 2.0 * @suavidad) - @suavidad;
float m = smoothstep(e + @suavidad, e - @suavidad, d);
float brillo = 1.0 - abs(m * 2.0 - 1.0);
@out = mix(@A, @B, m);
@out.rgb += @borde * brillo * 0.6;
