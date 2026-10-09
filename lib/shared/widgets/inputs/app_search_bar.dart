import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Full-width search field used at the top of list pages. Shows a clear
/// (×) button once there's text. Owns a controller if none is passed.
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    required this.onChanged,
    this.controller,
    this.hint,
    this.autofocus = false,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.xs,
      AppSpacing.lg,
      AppSpacing.xs,
    ),
    super.key,
  });

  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  /// Defaults to the localized "Search".
  final String? hint;
  final bool autofocus;
  final EdgeInsetsGeometry padding;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  TextEditingController? _own;
  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (context, value, _) => TextField(
          controller: _controller,
          autofocus: widget.autofocus,
          textInputAction: TextInputAction.search,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hint ?? AppLocalizations.of(context)!.commonSearch,
            prefixIcon: const Icon(AppIcons.search),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).deleteButtonTooltip,
                    icon: const Icon(AppIcons.close),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged('');
                    },
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      ),
    );
  }
}
