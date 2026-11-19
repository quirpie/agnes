#effect Desenfoque radial
#desc Zoom borroso hacia un centro ajustable
#input A Imagen

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
