#effect Grano y viñeta
#desc Grano animado de película con viñeta
#input A Imagen

#param grano 0.08 0 0.5
#param vig 1.2 0 3

vec2 d = @uv - 0.5;
d.x *= @res.x / @res.y;
float n = hash13(vec3(@P, floor(@time * 24.0))) - 0.5;
@out.rgb += n * @grano;
@out.rgb *= 1.0 - @vig * dot(d, d);
