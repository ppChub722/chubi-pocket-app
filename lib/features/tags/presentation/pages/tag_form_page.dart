import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/icon_maker/icon_maker_sheet.dart';
import '../../../../shared/icon_maker/icon_registry.dart';
import '../../domain/tag.dart';
import '../cubit/tags_cubit.dart';
import '../widgets/tag_chip.dart';

/// Create / edit a tag — full-page route at `/tags/new` and `/tags/:id/edit`.
class TagFormPage extends StatefulWidget {
  const TagFormPage({this.editingId, super.key});

  final String? editingId;

  bool get isEdit => editingId != null;

  @override
  State<TagFormPage> createState() => _TagFormPageState();
}

class _TagFormPageState extends State<TagFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  IconCode? _iconCode;

  Tag? _initial;

  @override
  void initState() {
    super.initState();
    if (widget.editingId != null) {
      final existing = context.read<TagsCubit>().byId(widget.editingId!);
      if (existing != null) {
        _initial = existing;
        _nameController.text = existing.name;
        _iconCode = existing.iconCode;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _dirty {
    if (_initial == null) {
      return _nameController.text.isNotEmpty || _iconCode != null;
    }
    final i = _initial!;
    return _nameController.text != i.name || _iconCode != i.iconCode;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmDiscard(context, l);
        if (ok && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEdit ? l.tagFormTitleEdit : l.tagFormTitleNew),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.huge,
            ),
            children: [
              _SectionLabel(text: l.tagFormPreviewLabel),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TagChip(
                  tag: _previewTag(),
                  onIconTap: () => _openIconMaker(context, l),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameController,
                maxLength: 50,
                decoration: InputDecoration(labelText: l.tagFormNameLabel),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final name = v?.trim() ?? '';
                  if (name.isEmpty) return l.tagFormNameRequired;
                  if (name.length > 50) return l.tagFormNameTooLong;
                  final cubit = context.read<TagsCubit>();
                  if (cubit.nameExists(name, excludeId: _initial?.id)) {
                    return l.tagFormNameDuplicate;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l.tagFormSave),
            ),
          ),
        ),
      ),
    );
  }

  Tag _previewTag() {
    return Tag(
      id: _initial?.id ?? 'preview',
      name: _nameController.text,
      iconCode: _iconCode,
      usageCount: _initial?.usageCount ?? 0,
    );
  }

  Future<void> _openIconMaker(BuildContext context, AppLocalizations l) async {
    final result = await showIconMakerSheet(
      context: context,
      iconIds: IconRegistry.tagIconIds,
      style: IconMakerStyle.iconColor,
      initial: _iconCode,
      iconSectionLabel: l.tagFormIconLabel,
      colorSectionLabel: l.tagFormColorLabel,
      previewBuilder: (iconCode) => Align(
        alignment: Alignment.centerLeft,
        child: TagChip(tag: _previewTag().copyWith(iconCode: iconCode)),
      ),
    );
    if (!mounted || result == null) return;
    if (result is IconMakerSelected) {
      setState(() => _iconCode = result.iconCode);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cubit = context.read<TagsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (widget.isEdit) {
        await cubit.update(_initial!.copyWith(
          name: _nameController.text.trim(),
          iconCode: _iconCode,
        ));
      } else {
        await cubit.add(Tag(
          id: 'draft',
          name: _nameController.text.trim(),
          iconCode: _iconCode,
        ));
      }
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    context.pop();
  }

  Future<bool> _confirmDiscard(
      BuildContext context, AppLocalizations l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.tagFormDiscardTitle),
        content: Text(l.tagFormDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l.commonRemove),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 0.5,
          ),
    );
  }
}
