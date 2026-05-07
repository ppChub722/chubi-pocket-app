import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_maker_sheet.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../domain/saving_goal.dart';
import '../../domain/saving_goal_status.dart';
import '../cubit/saving_goals_cubit.dart';

/// Create / edit a saving goal — `/saving-goals/new` and
/// `/saving-goals/:id/edit`.
///
/// **Spec quirks** baked in:
/// - `linked_account_id` is NOT editable (spec §3.4) — the picker is
///   disabled in edit mode.
/// - `allocation_pct` is optional on create — leaving it blank lets the
///   server suggest a default proportional to other active goals on the
///   linked account.
/// - Per `phase1c/overview.md` IconMaker decision, we reuse
///   [IconType.account] for the picker; a dedicated `IconType.savingGoal`
///   pack lands in Phase 2 polish.
class SavingGoalFormPage extends StatefulWidget {
  const SavingGoalFormPage({this.editingId, super.key});

  final String? editingId;

  bool get isEdit => editingId != null;

  @override
  State<SavingGoalFormPage> createState() => _SavingGoalFormPageState();
}

class _SavingGoalFormPageState extends State<SavingGoalFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _allocationController = TextEditingController();
  final _noteController = TextEditingController();

  String? _linkedAccountId;
  DateTime? _deadline;
  IconCode? _iconCode;
  SavingGoal? _initial;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      final existing =
          context.read<SavingGoalsCubit>().byId(widget.editingId!);
      if (existing != null) {
        _initial = existing;
        _nameController.text = existing.name;
        _targetController.text = existing.targetAmount.toString();
        _allocationController.text = existing.allocationPct.toString();
        _noteController.text = existing.note ?? '';
        _linkedAccountId = existing.linkedAccountId;
        _iconCode = existing.iconCode;
        if (existing.deadline != null) {
          _deadline = DateTime.tryParse(existing.deadline!);
        }
      }
    }
    // Make sure the account picker has options to show — the user could
    // deep-link to /saving-goals/new without ever visiting /accounts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccountsCubit>().loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _allocationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (widget.isEdit && _initial == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.savingGoalFormTitleEdit)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              l.savingGoalDetailNotFoundMessage,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit
            ? l.savingGoalFormTitleEdit
            : l.savingGoalFormTitle),
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
            _IconPickerTile(
              iconCode: _iconCode,
              label: l.savingGoalFormIconLabel,
              onTap: () => _openIconMaker(context, l),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _nameController,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: l.savingGoalFormNameLabel,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l.savingGoalFormNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _AccountPicker(
              selectedId: _linkedAccountId,
              enabled: !widget.isEdit,
              onChanged: (id) => setState(() => _linkedAccountId = id),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _targetController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: l.savingGoalFormTargetLabel,
                prefixText: '฿ ',
              ),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return l.savingGoalFormTargetInvalid;
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _allocationController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: l.savingGoalFormAllocationLabel,
                helperText: l.savingGoalFormAllocationHelper,
                helperMaxLines: 2,
                suffixText: '%',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return null; // optional
                final n = double.tryParse(v);
                if (n == null || n <= 0 || n > 100) {
                  return l.savingGoalFormAllocationInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _DeadlineTile(
              deadline: _deadline,
              onPick: (d) => setState(() => _deadline = d),
              onClear: () => setState(() => _deadline = null),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _noteController,
              maxLength: 200,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l.savingGoalFormNoteLabel,
              ),
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
            child: Text(widget.isEdit
                ? l.savingGoalFormSaveEdit
                : l.savingGoalFormSave),
          ),
        ),
      ),
    );
  }

  Future<void> _openIconMaker(BuildContext context, AppLocalizations l) async {
    final result = await showIconMakerSheet(
      context: context,
      type: IconType.account,
      initial: _iconCode,
      iconSectionLabel: l.savingGoalFormIconLabel,
    );
    if (!mounted || result == null) return;
    if (result is IconMakerSelected) {
      setState(() => _iconCode = result.iconCode);
    } else if (result is IconMakerRemoved) {
      setState(() => _iconCode = null);
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_linkedAccountId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.savingGoalFormAccountRequired)));
      return;
    }
    final cubit = context.read<SavingGoalsCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final note = _noteController.text.trim();
    final allocText = _allocationController.text.trim();
    final allocation = allocText.isEmpty ? 0.0 : double.parse(allocText);
    final deadline = _deadline == null ? null : _isoDate(_deadline!);

    try {
      if (widget.isEdit) {
        final updated = SavingGoal(
          id: _initial!.id,
          name: _nameController.text.trim(),
          targetAmount: double.parse(_targetController.text.trim()),
          linkedAccountId: _initial!.linkedAccountId,
          allocationPct:
              allocation > 0 ? allocation : _initial!.allocationPct,
          currency: _initial!.currency,
          status: _initial!.status,
          deadline: deadline,
          iconCode: _iconCode,
          note: note.isEmpty ? null : note,
        );
        await cubit.update(updated);
      } else {
        final draft = SavingGoal(
          id: 'draft',
          name: _nameController.text.trim(),
          targetAmount: double.parse(_targetController.text.trim()),
          linkedAccountId: _linkedAccountId!,
          allocationPct: allocation,
          currency: 'THB',
          status: SavingGoalStatus.active,
          deadline: deadline,
          iconCode: _iconCode,
          note: note.isEmpty ? null : note,
        );
        await cubit.add(draft);
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

  String _isoDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}

class _IconPickerTile extends StatelessWidget {
  const _IconPickerTile({
    required this.iconCode,
    required this.label,
    required this.onTap,
  });

  final IconCode? iconCode;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            IconDisplay(
              type: IconType.account,
              size: 48,
              iconCode: iconCode,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _AccountPicker extends StatelessWidget {
  const _AccountPicker({
    required this.selectedId,
    required this.enabled,
    required this.onChanged,
  });

  final String? selectedId;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, state) {
        final accounts = state.accounts;
        return DropdownButtonFormField<String>(
          initialValue: selectedId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l.savingGoalFormLinkedAccountLabel,
            helperText: enabled
                ? l.savingGoalFormLinkedAccountHelper
                : l.savingGoalFormLinkedAccountLockedHelper,
            helperMaxLines: 2,
          ),
          onChanged: enabled ? onChanged : null,
          items: [
            for (final Account a in accounts)
              DropdownMenuItem<String>(
                value: a.id,
                child: Text(a.name),
              ),
          ],
        );
      },
    );
  }
}

class _DeadlineTile extends StatelessWidget {
  const _DeadlineTile({
    required this.deadline,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? deadline;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final hasDeadline = deadline != null;
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: deadline ?? now.add(const Duration(days: 90)),
          firstDate: now,
          lastDate: DateTime(now.year + 20),
        );
        if (picked != null) onPick(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(Icons.event_outlined, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.savingGoalFormDeadlineLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    hasDeadline
                        ? _format(deadline!)
                        : l.savingGoalFormDeadlinePlaceholder,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            if (hasDeadline)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: onClear,
              ),
          ],
        ),
      ),
    );
  }

  String _format(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}
