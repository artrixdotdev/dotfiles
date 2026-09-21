float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);

  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));

  vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

const mat2 FBM_MAT = mat2(1.6, 1.2, -1.2, 1.6);

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;

  for (int i = 0; i < 6; i++) {
    v += a * noise(p);
    p = FBM_MAT * p;
    a *= 0.5;
  }

  return v;
}

float fbmFast(vec2 p) {
  float v = 0.0;
  float a = 0.5;

  for (int i = 0; i < 4; i++) {
    v += a * noise(p);
    p = FBM_MAT * p;
    a *= 0.5;
  }

  return v;
}

float pattern(vec2 p, float t, out vec2 q, out vec2 r) {
  q = vec2(
    fbm(p + vec2(0.0, 0.0) + t * 0.02),
    fbm(p + vec2(5.2, 1.3) - t * 0.015)
  );

  r = vec2(
    fbm(p + 4.0 * q + vec2(1.7, 9.2) + t * 0.012),
    fbm(p + 4.0 * q + vec2(8.3, 2.8) - t * 0.01)
  );

  vec2 s = vec2(
    fbmFast(p + 4.0 * r + vec2(3.1, 7.7) + t * 0.008),
    fbmFast(p + 4.0 * r + vec2(6.5, 4.1) - t * 0.006)
  );

  vec2 u = vec2(
    fbmFast(p + 4.0 * s + vec2(9.8, 0.3) + t * 0.005),
    fbmFast(p + 4.0 * s + vec2(2.4, 8.6) - t * 0.004)
  );

  return fbmFast(p + 4.0 * u);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / iResolution.xy;
  vec2 p = uv - 0.5;
  p.x *= iResolution.x / iResolution.y;

  float t = iTime * 0.15;

  vec2 q1, r1, q2, r2, q3, r3;

  float v1 = pattern(p * 2.0, t, q1, r1);
  float v2 = pattern(p * 4.0 + 10.0, t * 0.8, q2, r2);
  float v3 = pattern(p * 8.0 + 20.0, t * 0.6, q3, r3);

  float v = v1 * 0.58 + v2 * 0.30 + v3 * 0.12;
  v -= 0.5;

  float yBias = (uv.y - 0.45) * 0.8;

  float plumes = 0.0;
  for (float i = 0.0; i < 5.0; i++) {
    float freq = 2.0 + i * 1.5;
    float amp = 0.12 / (1.0 + i * 0.5);
    float phase = hash(vec2(i, 0.0)) * 6.2831853;
    float cx = sin(freq * 0.7 + phase) * 0.3;
    float px = p.x - cx;
    float column = exp(-px * px * freq * freq * 0.5);
    plumes += column * amp;
  }

  v += yBias - plumes * (1.0 - uv.y);

  float detail = 0.0;
  detail += (fbmFast(r1 * 8.0) - 0.5) * 0.08;
  detail += (fbmFast(r2 * 8.0) - 0.5) * 0.04;
  detail += (fbmFast(q1 * 12.0 + r2 * 6.0) - 0.5) * 0.02;
  v += detail;

  float distFromInterface = abs(v);
  float nearInterface = smoothstep(0.15, 0.0, distFromInterface);

  float spiral = sin(v * 25.0 + fbmFast(p * 5.0 + r1 * 3.0) * 6.0) * 0.07;
  spiral += sin(v * 48.0 + fbmFast(p * 8.0 + q2 * 2.5) * 7.0) * 0.02;
  v += spiral * nearInterface;

  float fluid = smoothstep(-0.008, 0.008, v);
  float grayEdge = 1.0 - smoothstep(0.0, 0.025, abs(v));

  vec3 color = mix(vec3(0.0), vec3(1.0), fluid);

  float grayVal = mix(0.15, 0.85, fluid);
  color = mix(color, vec3(grayVal), grayEdge * 0.25);

  fragColor = vec4(color, 1.0);
}

void main() {
  mainImage(gl_FragColor, gl_FragCoord.xy);
}
