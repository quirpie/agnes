#effect Ondas
#desc Deformación ondulante animada
#input A Imagen

#param amp 0.01 0 0.05
#param freq 18 1 80
#param vel 2 0 10

vec2 uv = @uv;
uv.x += sin(uv.y * @freq + @time * @vel) * @amp;
uv.y += cos(uv.x * @freq * 0.7 + @time * @vel) * @amp;
@out = A(uv);
