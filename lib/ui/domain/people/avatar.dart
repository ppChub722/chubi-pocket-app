import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../atoms/corner_badge.dart';
import '../../atoms/server_image.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/avatar_metrics.dart';
import '../icons/color_token.dart';
import '../icons/icon_display.dart';
import '../icons/icon_type.dart';
import 'avatar_data.dart';

/// THE person picture (0.4.2 1b): draws the BE's `avatar` as it says —
/// a photo (Bearer-loaded through [ServerImageScope], cached by its URL; on
/// a load error the icon, then the initials), the icon maker's icon, or the
/// initials on colour 1. A photo gets its ring from `avatar.border` (thin /
/// thick / dashed). [badge] = a widget filling a corner disc (a brand logo).
class Avatar extends StatelessWidget {
  const Avatar(
    this.avatar, {
    this.size = AvatarMetrics.sizeMedium,
    this.badge,
    this.badgeColor,
    this.badgeEssential = false,
    super.key,
  });

  final AvatarData avatar;
  final double size;

  /// A corner badge's content (a brand logo image), clipped round.
  final Widget? badge;

  /// The badge disc behind a transparent [badge]; default the surface.
  final Color? badgeColor;

  /// Show the badge under 40 px too.
  final bool badgeEssential;

  @override
  Widget build(BuildContext context) {
    final face = switch (avatar.kind) {
      AvatarKind.photo when avatar.hasPhoto => _PhotoFace(
        avatar: avatar,
        size: size,
      ),
      _ => _fallback(avatar, size),
    };
    final badge = this.badge;
    if (badge == null) return SizedBox.square(dimension: size, child: face);
    return CornerBadge(
      size: size,
      glyph: badge,
      color: badgeColor,
      essential: badgeEssential,
      child: face,
    );
  }
}

/// The icon, else the initials (a photo's fallback chain).
Widget _fallback(AvatarData avatar, double size) => avatar.iconCode != null
    ? IconDisplay(
        type: IconType.userProfile,
        size: size,
        iconCode: avatar.iconCode,
      )
    : _InitialsFace(avatar: avatar, size: size);

class _InitialsFace extends StatelessWidget {
  const _InitialsFace({required this.avatar, required this.size});

  final AvatarData avatar;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>();
    final initials = avatar.initials;
    if (initials.isEmpty) {
      return _Disc(
        size: size,
        color: scheme.surfaceContainerHighest,
        child: Icon(
          Icons.person_outline,
          size: AvatarMetrics.glyph(size),
          color: scheme.onSurfaceVariant,
        ),
      );
    }
    final spec = avatar.colors.isEmpty ? '' : avatar.colors.first;
    final color = spec.isEmpty || palette == null
        ? _specColor(spec, scheme)
        : resolveColor(spec, palette);
    return _Disc(
      size: size,
      color: color,
      child: Text(
        initials,
        maxLines: 1,
        style: TextStyle(
          color: Colors.white,
          fontSize: AvatarMetrics.initials(size),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A colour spec read without the app palette (a bare theme in a test):
/// `#rrggbb`, else the scheme's primary.
Color _specColor(String spec, ColorScheme scheme) {
  final hex = spec.startsWith('#') ? spec.substring(1) : null;
  final v = hex == null ? null : int.tryParse(hex, radix: 16);
  return v == null ? scheme.primary : Color(0xFF000000 | v);
}

class _Disc extends StatelessWidget {
  const _Disc({required this.size, required this.color, required this.child});

  final double size;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: child,
  );
}

class _PhotoFace extends StatelessWidget {
  const _PhotoFace({required this.avatar, required this.size});

  final AvatarData avatar;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final picture = ClipOval(
      child: Image(
        image: ServerImageScope.providerOf(context, avatar.photoUrl!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        // While it loads: a plain disc (a cached picture paints at once).
        frameBuilder: (context, child, frame, sync) => frame == null && !sync
            ? _Disc(
                size: size,
                color: scheme.surfaceContainerHighest,
                child: const SizedBox.shrink(),
              )
            : child,
        errorBuilder: (_, _, _) => _fallback(avatar, size),
      ),
    );
    final border = avatar.border;
    if (border == null || border.isNone) return picture;
    final palette = Theme.of(context).extension<AppColors>();
    final spec = border.colors.isEmpty ? '' : border.colors.first;
    final color = spec.isEmpty
        ? scheme.outline
        : palette == null
        ? _specColor(spec, scheme)
        : resolveColor(spec, palette);
    return CustomPaint(
      foregroundPainter: _RingPainter(
        color: color,
        width: AvatarMetrics.frame(size, thick: border.style == 'thick'),
        dashed: border.style == 'dashed',
      ),
      child: picture,
    );
  }
}

/// The ring inside the picture's edge; dashed = short arcs round it.
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.color,
    required this.width,
    required this.dashed,
  });

  final Color color;
  final double width;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final rect = Offset.zero & size;
    final ring = rect.deflate(width / 2);
    if (!dashed) {
      canvas.drawOval(ring, paint);
      return;
    }
    final r = ring.shortestSide / 2;
    final dash = math.max(width * 2.5, 3.0);
    final count = math.max(6, (2 * math.pi * r / (dash * 1.8)).floor());
    final sweep = 2 * math.pi / count;
    for (var i = 0; i < count; i++) {
      canvas.drawArc(ring, i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.color != color || old.width != width || old.dashed != dashed;
}
