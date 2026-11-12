import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../tokens/glass_look.dart';

/// Glass of any [shape], drawn by [look] (the app's one glass,
/// [AppGlass.standard]).
///
/// A soft look ([GlassLook.useShader] false, Samsung style): the backdrop
/// blurred, its colours livened, a milky tint and a light on top. A liquid
/// look (Apple style) where Impeller runs: the `shaders/liquid_glass.frag`
/// lens, the backdrop bent at the bevel (colours split a little) with a
/// raised, lit edge; it draws as the soft kind elsewhere (web, Skia). Both
/// get a border all round and a shadow that falls only OUTSIDE the shape.
///
/// It only shows when something is behind it (the top bar's pages scroll
/// under it). The ink (InkWell) belongs INSIDE [child] under its own
/// transparent Material, so the splash paints above the glass.
class MirrorSurface extends StatefulWidget {
  const MirrorSurface({
    required this.shape,
    required this.child,
    this.look = AppGlass.standard,
    this.tint,
    this.rim,
    this.elevated = true,
    this.bar,
    super.key,
  });

  /// The outline: [CircleBorder], [StadiumBorder], a
  /// [RoundedRectangleBorder] (`IconShape.radius` fits; its corners may
  /// differ); any other [ShapeBorder] draws as a stadium in the shader
  /// unless [bar] says otherwise.
  final ShapeBorder shape;
  final Widget child;

  final GlassLook look;

  /// The glass colour (default surfaceContainerHigh). A selected state passes
  /// primaryContainer, which covers [GlassLook.tintSelected] of it.
  final Color? tint;

  /// The rim's bright colour (default white); a selected state passes the
  /// primary.
  final Color? rim;

  final bool elevated;

  /// For a shape that is not a rounded box: the bar + round bump the shader
  /// should draw (the clip still comes from [shape]).
  final GlassBar? bar;

  @override
  State<MirrorSurface> createState() => _MirrorSurfaceState();
}

/// A bar of [height] centred in the surface, its four corners [cornerRadius]
/// round, with a round bump of [bumpRadius] united at the centre (the bottom
/// bar's shape). Lengths in logical px.
class GlassBar {
  const GlassBar({
    required this.height,
    required this.cornerRadius,
    this.bumpRadius = 0,
  });

  final double height;
  final double cornerRadius;
  final double bumpRadius;
}

class _MirrorSurfaceState extends State<MirrorSurface> {
  static ui.FragmentProgram? _program;
  static Future<void>? _loading;

  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _loadIfNeeded();
  }

  @override
  void didUpdateWidget(MirrorSurface old) {
    super.didUpdateWidget(old);
    _loadIfNeeded();
  }

  void _loadIfNeeded() {
    if (widget.look.useShader &&
        ui.ImageFilter.isShaderFilterSupported &&
        _program == null) {
      (_loading ??= _load()).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  /// The soft look's colour step: [s] saturation, [lift] (0..1) added.
  static ui.ColorFilter _livelier(double s, double lift) {
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final o = lift * 255;
    return ui.ColorFilter.matrix([
      lr * (1 - s) + s, lg * (1 - s), lb * (1 - s), 0, o, //
      lr * (1 - s), lg * (1 - s) + s, lb * (1 - s), 0, o,
      lr * (1 - s), lg * (1 - s), lb * (1 - s) + s, 0, o,
      0, 0, 0, 1, 0,
    ]);
  }

  /// A failed load leaves [_program] null: the fallback blur stays.
  static Future<void> _load() async {
    try {
      _program = await ui.FragmentProgram.fromAsset(
        'shaders/liquid_glass.frag',
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  static List<double> _radiiOf(ShapeBorder shape) {
    if (shape is RoundedRectangleBorder) {
      final r = shape.borderRadius.resolve(TextDirection.ltr);
      return [r.topLeft.x, r.topRight.x, r.bottomRight.x, r.bottomLeft.x];
    }
    return const [-1, -1, -1, -1];
  }

  Color _rimLit(bool dark) =>
      widget.rim ??
      Colors.white.withValues(
        alpha: dark ? widget.look.rimLitDark : widget.look.rimLitLight,
      );

  double _tintAlpha(bool dark) => widget.tint != null
      ? widget.look.tintSelected
      : (dark ? widget.look.tintDark : widget.look.tintLight);

  ui.ImageFilter? _glassFilter(BuildContext context, ColorScheme scheme) {
    final program = _program;
    final look = widget.look;
    if (!look.useShader ||
        program == null ||
        !ui.ImageFilter.isShaderFilterSupported) {
      return null;
    }
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final dark = scheme.brightness == Brightness.dark;
    final tint = widget.tint ?? scheme.surfaceContainerHigh;
    final rim = _rimLit(dark);
    final bar = widget.bar;
    final radii = bar == null
        ? _radiiOf(widget.shape)
        : List.filled(4, bar.cornerRadius);

    _shader?.dispose();
    final s = _shader = program.fragmentShader();
    // 0,1 = u_size, filled by the engine. The order below is the shader's
    // uniform order.
    final floats = <double>[
      for (final r in radii) r < 0 ? -1 : r * dpr, // u_radii
      tint.r, tint.g, tint.b, _tintAlpha(dark), // u_tint
      rim.r, rim.g, rim.b, rim.a, // u_rim
      look.bevelMax * dpr, // u_look
      look.refractionMax * dpr,
      look.dispersion,
      look.frostMax * dpr,
      (bar?.height ?? 0) * dpr, // u_bar
      (bar?.bumpRadius ?? 0) * dpr,
      look.saturation, dark ? look.liftDark : look.liftLight, // u_tone
      look.bevelFraction, // u_scale
      look.refractionFraction,
      look.frostFraction,
      look.emboss, look.shade, look.rimSharp, look.rimFrostThin, // u_style
    ];
    for (var i = 0; i < floats.length; i++) {
      s.setFloat(2 + i, floats[i]);
    }
    // The shader frosts by itself: a blur run before it would leave the lens
    // nothing sharp to bend (it then reads as a plain blur).
    return ui.ImageFilter.shader(s);
  }

  @override
  Widget build(BuildContext context) {
    final look = widget.look;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final shape = widget.shape;
    final glassFilter = _glassFilter(context, scheme);

    final Widget glass;
    if (const bool.fromEnvironment('NO_GLASS')) {
      // Temporary fps probe: --dart-define=NO_GLASS=true (a flat tint, no
      // backdrop filter at all).
      glass = ColoredBox(
        color: (widget.tint ?? scheme.surfaceContainerHigh).withValues(
          alpha: 0.85,
        ),
        child: widget.child,
      );
    } else if (glassFilter != null) {
      glass = BackdropFilter.grouped(filter: glassFilter, child: widget.child);
    } else {
      // Soft glass: blur what is behind (livened only when the look asks:
      // the colour step is one more full pass), then a milky tint and a
      // light over the top.
      final base = widget.tint ?? scheme.surfaceContainerHigh;
      final lift = dark ? look.liftDark : look.liftLight;
      final livelier = look.saturation == 1 && lift == 0
          ? null
          : _livelier(look.saturation, lift);
      final blur = look.blur > 0
          ? ui.ImageFilter.blur(sigmaX: look.blur, sigmaY: look.blur)
          : null;
      final sheen = Colors.white.withValues(
        alpha: dark ? look.sheenDark : look.sheenLight,
      );
      final filter = blur != null && livelier != null
          ? ui.ImageFilter.compose(outer: livelier, inner: blur)
          : blur ?? livelier ?? ui.ImageFilter.blur();
      // Grouped: the top bar's glass and the bottom bar's share one read of
      // the screen behind them (a [BackdropGroup] in the shell) instead of
      // each taking its own.
      glass = BackdropFilter.grouped(
        filter: filter,
        child: ColoredBox(
          color: base.withValues(alpha: _tintAlpha(dark)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [sheen, sheen.withValues(alpha: 0)],
              ),
            ),
            child: widget.child,
          ),
        ),
      );
    }

    return CustomPaint(
      painter: widget.elevated
          ? _ShadowPainter(
              shape: shape,
              color: scheme.shadow.withValues(
                alpha: dark ? look.shadowDark : look.shadowLight,
              ),
            )
          : null,
      // A border all the way round, brightest on the lit corner (the
      // shader's specular line sits just inside it).
      // (A 0 width stroke would draw a hairline, so none at all.)
      foregroundPainter: look.rimWidth <= 0
          ? null
          : _RimPainter(
              shape: shape,
              width: look.rimWidth,
              lit: _rimLit(dark),
              far: dark
                  ? Colors.white.withValues(alpha: look.rimFarDark)
                  : scheme.outlineVariant.withValues(alpha: look.rimFarLight),
            ),
      child: _clip(shape, glass),
    );
  }

  /// The cheapest clip that fits: a circle, a rounded rect; a path only for
  /// any other shape (the bottom bar's bar + bump).
  static Widget _clip(ShapeBorder shape, Widget child) => switch (shape) {
    CircleBorder() => ClipOval(child: child),
    StadiumBorder() => ClipRRect(
      borderRadius: BorderRadius.circular(9999),
      child: child,
    ),
    RoundedRectangleBorder(:final borderRadius) => ClipRRect(
      borderRadius: borderRadius,
      child: child,
    ),
    _ => ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: child,
    ),
  };
}

/// A soft shadow outside the shape only.
class _ShadowPainter extends CustomPainter {
  const _ShadowPainter({required this.shape, required this.color});

  final ShapeBorder shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inside = shape.getOuterPath(rect);
    // Even-odd: the big rect minus the shape, without a boolean path op
    // (Path.combine is slow, and this paints with every repaint).
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(40))
      ..addPath(inside, Offset.zero);
    canvas.save();
    canvas.clipPath(outside);
    canvas.drawPath(
      inside.shift(const Offset(0, 2)),
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShadowPainter old) =>
      old.shape != shape || old.color != color;
}

/// The border: bright at the top-left (and a little at the bottom-right),
/// faint on the far sides.
class _RimPainter extends CustomPainter {
  const _RimPainter({
    required this.shape,
    required this.width,
    required this.lit,
    required this.far,
  });

  final ShapeBorder shape;
  final double width;
  final Color lit;
  final Color far;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    canvas.drawPath(
      shape.getOuterPath(rect),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            lit,
            far,
            far,
            lit.withValues(alpha: lit.a * 0.7),
          ],
          stops: const [0, 0.35, 0.65, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RimPainter old) =>
      old.shape != shape ||
      old.width != width ||
      old.lit != lit ||
      old.far != far;
}

/// Turns the round buttons under it into glass (the top bar's chips).
class MirrorScope extends InheritedWidget {
  const MirrorScope({required super.child, super.key});

  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<MirrorScope>() != null;

  @override
  bool updateShouldNotify(MirrorScope old) => false;
}
