#effect Caleidoscopio
#desc Simetría radial de N segmentos
#input A Imagen

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
