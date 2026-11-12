#version 320 es
// Liquid glass: a backdrop filter that frosts what is behind it, livens its
// colours, bends it at the shape's bevel like a thick lens (splitting the
// colours a little there), takes a thin tint and lights a specular rim. The
// shape is a rounded box with a radius per corner (a circle / stadium =
// radius -1: half the short side), optionally a bar with a round bump.
// Impeller only; MirrorSurface falls back to a plain blur elsewhere.

#include <flutter/runtime_effect.glsl>

// Filled by the engine for an ImageFilter shader.
uniform vec2 u_size;
uniform sampler2D u_texture;

// Corner radii in px: top-left, top-right, bottom-right, bottom-left.
uniform vec4 u_radii;
// Glass tint: rgb + how much of it (0..1).
uniform vec4 u_tint;
// Rim colour: rgb + strength (0..1).
uniform vec4 u_rim;
// Caps in px: x bevel width, y refraction, w frost radius; z dispersion
// (0..1). Each is also capped by u_scale × the shape's short half side.
uniform vec4 u_look;

// x: height of the box in px, centred in the region (0 = the whole region),
// y: radius of a round bump united with it at the centre (0 = none).
uniform vec2 u_bar;

// x: saturation (1 = as is), y: brightness lift (added).
uniform vec2 u_tone;

// Fractions of the shape's short half side: x bevel, y refraction, z frost.
uniform vec3 u_scale;

// x emboss (lit bevel brightens), y shade (far bevel darkens), z how much
// of the sharp bent copy shows at the rim, w how much the frost thins there.
uniform vec4 u_style;

out vec4 frag_color;

const vec2 LIGHT = vec2(-0.7071, -0.7071);

float corner(vec2 p, float tl, float tr, float br, float bl) {
  if (p.x > 0.0) {
    return p.y > 0.0 ? br : tr;
  }
  return p.y > 0.0 ? bl : tl;
}

// The box's half size: the region's, or a bar of u_bar.x height in it.
vec2 box_half(vec2 half_size) {
  return u_bar.x > 0.0 ? vec2(half_size.x, u_bar.x * 0.5) : half_size;
}

float sdf(vec2 p, vec2 half_size) {
  vec2 hs = box_half(half_size);
  float short_half = min(hs.x, hs.y);
  vec4 r = u_radii;
  if (r.x < 0.0) {
    r = vec4(short_half);
  }
  float rad = min(corner(p, r.x, r.y, r.z, r.w), short_half);
  vec2 q = abs(p) - hs + rad;
  float d = min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - rad;
  if (u_bar.y > 0.0) {
    d = min(d, length(p) - u_bar.y);
  }
  return d;
}

vec3 tap(vec2 at) {
  return texture(u_texture, clamp(at, vec2(0.5), u_size - 0.5) / u_size).rgb;
}

// Frost: a dense spiral of taps (a Vogel disc) weighted like a gaussian.
// Dense, so a thin line behind blurs into a haze instead of leaving ghost
// copies (a sparse ring of taps did).
// Each pixel turns the spiral by its own random angle, so what is left of
// the taps' pattern breaks into a fine grain, not a copy.
const int TAPS = 64;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 frosted(vec2 at, float radius) {
  if (radius < 0.5) {
    return tap(at);
  }
  float turn = hash(floor(at)) * 6.28318;
  vec3 c = vec3(0.0);
  float total = 0.0;
  for (int i = 0; i < TAPS; i++) {
    float k = (float(i) + 0.5) / float(TAPS);
    float r = sqrt(k);
    float a = float(i) * 2.39996 + turn;
    float w = exp(-r * r * 2.0);
    c += tap(at + vec2(cos(a), sin(a)) * r * radius) * w;
    total += w;
  }
  return c / total;
}

void main() {
  vec2 px = FlutterFragCoord().xy;
  vec2 half_size = u_size * 0.5;
  vec2 p = px - half_size;

  float d = sdf(p, half_size);

  // Outward normal from the distance field.
  vec2 e = vec2(1.0, 0.0);
  vec2 n = normalize(vec2(
    sdf(p + e.xy, half_size) - sdf(p - e.xy, half_size),
    sdf(p + e.yx, half_size) - sdf(p - e.yx, half_size)
  ) + 1e-5);

  // The bevel: 0 at the edge, 1 where the flat middle starts. A lens bends
  // hardest at its rim, so the bend falls off fast inwards.
  // Sizes follow the shape: a fraction of its short half side, capped.
  vec2 hs = box_half(half_size);
  float short_half = min(hs.x, hs.y);
  float bevel = max(min(u_look.x, short_half * u_scale.x), 1.0);
  float refraction = min(u_look.y, short_half * u_scale.y);
  float frost = min(u_look.w, short_half * u_scale.z);
  float t = clamp(-d / bevel, 0.0, 1.0);
  float edge = pow(1.0 - t, 2.4);
  float bend = refraction * edge;

  // Sample from further in: the rim shows a squeezed copy of what is
  // under the middle, the way a drop of water does.
  // Frosted in the middle; towards the rim the frost thins and the bent,
  // colour-split copy shows sharp, the way thick glass reads at its edge.
  vec2 at = px - n * bend;
  vec3 col = frosted(at, frost * (1.0 - u_style.w * edge));
  float split = bend * u_look.z;
  if (edge > 0.02) {
    vec3 sharp = vec3(
      tap(at - n * split).r,
      tap(at).g,
      tap(at + n * split).b
    );
    col = mix(col, sharp, edge * u_style.z);
  }

  // Livelier colour, a little lift, then the tint.
  float lum = dot(col, vec3(0.2126, 0.7152, 0.0722));
  col = mix(vec3(lum), col, u_tone.x) + u_tone.y;
  col = mix(col, u_tint.rgb, u_tint.a);

  // Light from the top-left: a soft sheen over the upper half...
  float facing = dot(n, LIGHT);
  float top = clamp(-p.y / hs.y, 0.0, 1.0);
  col += vec3(0.05) * top * top;

  // ...and the bevel lit like a raised edge: the side facing the light
  // brighter, the side away from it in shade, strongest at the rim. This is
  // what makes it look embossed rather than flat.
  float band = pow(1.0 - t, 1.6);
  if (facing > 0.0) {
    col += u_rim.rgb * u_rim.a * u_style.x * facing * band;
  } else {
    col *= 1.0 - u_style.y * (-facing) * band;
  }

  // ...and the specular line: bright where the edge faces the light or
  // straight away from it (two-sided, like glass), faint on the sides.
  float line = smoothstep(-3.2, -0.6, d) * (1.0 - smoothstep(-0.6, 0.6, d));
  float spec = 0.25 + 0.75 * pow(abs(facing), 1.4);
  if (facing < 0.0) {
    spec *= 0.45;
  }
  col += u_rim.rgb * u_rim.a * line * spec;

  frag_color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
