import 'package:flutter/material.dart';

class HeroCaption extends StatelessWidget {
  const HeroCaption(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

class HeroNote extends StatelessWidget {
  const HeroNote({
    required this.child,
    this.alignment = AlignmentDirectional.centerStart,
    this.onTap,
    super.key,
  });

  final Widget child;
  final AlignmentGeometry alignment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = DefaultTextStyle.merge(
      style: Theme.of(context).textTheme.bodySmall,
      child: child,
    );
    return Align(
      alignment: alignment,
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}
