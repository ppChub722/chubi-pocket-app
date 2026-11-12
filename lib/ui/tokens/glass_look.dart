import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// The glass's look ([MirrorSurface]): the app uses ONE set everywhere
/// ([AppGlass.standard]), so the top bar's chips and pill and the bottom bar
/// read as the same glass.
///
/// Two kinds: [useShader] true = Apple-style liquid glass (the
/// `liquid_glass.frag` lens: bent, colour-split, embossed edge); false =
/// Samsung One UI-style soft glass (a plain backdrop blur, livelier colours,
/// a milky tint, a thin border; far cheaper to draw).
///
/// Shader sizes scale with the shape: each is a fraction × the shape's
/// short half side, capped at a max (logical px), so a 40 px chip and the
/// 64 px bar look alike and the frost never reads past a chip's own edge.
@immutable
class GlassLook {
  const GlassLook({
    this.useShader = true,
    this.blur = 14,
    this.sheenDark = 0.06,
    this.sheenLight = 0.2,
    this.frostFraction = 0.45,
    this.frostMax = 14,
    this.bevelFraction = 0.6,
    this.bevelMax = 16,
    this.refractionFraction = 0.55,
    this.refractionMax = 18,
    this.dispersion = 0.08,
    this.tintDark = 0.5,
    this.tintLight = 0.4,
    this.tintSelected = 0.55,
    this.saturation = 1.35,
    this.liftDark = 0.03,
    this.liftLight = 0.05,
    this.emboss = 0.22,
    this.shade = 0.28,
    this.rimSharp = 0.3,
    this.rimFrostThin = 0.35,
    this.rimWidth = 1.2,
    this.rimLitDark = 0.6,
    this.rimLitLight = 1,
    this.rimFarDark = 0.16,
    this.rimFarLight = 0.8,
    this.shadowDark = 0.35,
    this.shadowLight = 0.16,
  });

  /// true: the liquid lens shader (Impeller only; elsewhere it draws as if
  /// false). false: a plain backdrop blur.
  final bool useShader;

  /// Without the shader: the backdrop blur sigma (logical px).
  final double blur;

  /// Without the shader: a soft light over the top of the glass (opacity of
  /// white at the top edge, fading to none by the middle).
  final double sheenDark;
  final double sheenLight;

  /// Shader: frost radius, how soft what is behind gets.
  final double frostFraction;
  final double frostMax;

  /// Shader: the bevel, the band along the edge that bends and catches light.
  final double bevelFraction;
  final double bevelMax;

  /// Shader: how far the backdrop bends at the very edge.
  final double refractionFraction;
  final double refractionMax;

  /// Shader: colour split at the bent edge (0 = none).
  final double dispersion;

  /// How much of the tint colour covers the backdrop (0..1), per theme; a
  /// selected chip (primaryContainer) takes [tintSelected] so it reads.
  final double tintDark;
  final double tintLight;
  final double tintSelected;

  /// The backdrop's colours livened (1 = as is), and lifted a little.
  final double saturation;
  final double liftDark;
  final double liftLight;

  /// Shader: the raised edge, the bevel facing the light (top-left)
  /// brightens by [emboss], the side away from it darkens by [shade].
  final double emboss;
  final double shade;

  /// Shader: at the rim, how much of the bent copy shows sharp (0..1), and
  /// how much thinner the frost gets there (0..1).
  final double rimSharp;
  final double rimFrostThin;

  /// The border drawn all round (width 0 = none): its width, its lit
  /// corner's opacity (white)
  /// and the far sides' opacity (white in dark, outlineVariant in light).
  final double rimWidth;
  final double rimLitDark;
  final double rimLitLight;
  final double rimFarDark;
  final double rimFarLight;

  /// The shadow outside the shape (opacity of the theme's shadow colour).
  final double shadowDark;
  final double shadowLight;

  double frostFor(double shortHalf) =>
      math.min(frostMax, shortHalf * frostFraction);

  /// The same look with no blur / frost (a perf probe).
  GlassLook withoutFrost() => GlassLook(
    useShader: useShader,
    blur: 0,
    sheenDark: sheenDark,
    sheenLight: sheenLight,
    frostFraction: 0,
    frostMax: 0,
    bevelFraction: bevelFraction,
    bevelMax: bevelMax,
    refractionFraction: refractionFraction,
    refractionMax: refractionMax,
    dispersion: dispersion,
    tintDark: tintDark,
    tintLight: tintLight,
    tintSelected: tintSelected,
    saturation: saturation,
    liftDark: liftDark,
    liftLight: liftLight,
    emboss: emboss,
    shade: shade,
    rimSharp: rimSharp,
    rimFrostThin: rimFrostThin,
    rimWidth: rimWidth,
    rimLitDark: rimLitDark,
    rimLitLight: rimLitLight,
    rimFarDark: rimFarDark,
    rimFarLight: rimFarLight,
    shadowDark: shadowDark,
    shadowLight: shadowLight,
  );
}

abstract final class AppGlass {
  /// The app's one glass (owner 2026-11-12: the same everywhere, Samsung
  /// style).
  static const standard = soft;

  /// Samsung One UI-style: a soft blur, a light milky tint, a light on the
  /// top, no border. No lens.
  static const soft = GlassLook(
    useShader: false,
    // Light enough to still read as glass, not frosted plastic (owner
    // 2026-11-12: 18, then 10, was too blurred).
    blur: 6,
    sheenDark: 0.06,
    sheenLight: 0.22,
    tintDark: 0.32,
    tintLight: 0.45,
    tintSelected: 0.6,
    // 1 / 0: no colour step, so the glass is one blur pass (perf, owner
    // 2026-11-12: the app felt slow).
    saturation: 1,
    liftDark: 0,
    liftLight: 0,
    // No border: the blur's edge and the shadow outline it (owner
    // 2026-11-12).
    rimWidth: 0,
    rimLitDark: 0.32,
    rimLitLight: 0.9,
    rimFarDark: 0.1,
    rimFarLight: 0.6,
    shadowDark: 0.3,
    shadowLight: 0.12,
  );

  /// Apple-style liquid glass (the lens shader), kept to switch back to.
  static const liquid = GlassLook();
}
