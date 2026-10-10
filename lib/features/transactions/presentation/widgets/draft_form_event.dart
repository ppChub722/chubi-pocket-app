part of 'draft_form.dart';

/// What [DraftForm]'s event mode needs about the project. A project row has
/// no wallet or category — it has a payer, a description, a note, tags and
/// splits between members, in the project's currency:
///
///   [TxHeroCard]: [ จ่าย | รับ ] · amount · คำอธิบาย (tap → pick one
///     used before, or type a new one) · date
///   [ จ่ายโดย 👤 ] · note · tags · หารกับสมาชิก
class DraftEvent {
  const DraftEvent({
    required this.members,
    required this.symbol,
    this.pastDescriptions = const [],
    this.tags = const [],
  });

  /// Current members — the payer and split choices.
  final List<ProjectMember> members;

  /// The project's currency symbol.
  final String symbol;

  /// Descriptions already used on this project, most used first.
  final List<String> pastDescriptions;

  /// Tags already used on this project, most used first.
  final List<String> tags;
}

class _EventForm extends StatelessWidget {
  const _EventForm({
    required this.controller,
    required this.event,
    required this.compact,
    required this.autofocus,
    required this.locked,
    required this.readOnly,
    required this.onPickDate,
  });

  final DraftFormController controller;
  final DraftEvent event;
  final bool compact;
  final bool autofocus;

  /// A saved row: its type and payer can't change (the API keeps them).
  final bool locked;
  final bool readOnly;
  final VoidCallback onPickDate;

  ProjectMember? _member(String? id) =>
      event.members.where((m) => m.id == id).firstOrNull;

  Future<void> _pickPayer(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final id = await showMemberPicker(
      context,
      title: controller.type == TransactionType.income
          ? l.projectTxReceivedBy
          : l.projectTxPaidBy,
      members: event.members,
      selected: controller.payerId,
    );
    if (id != null) controller.setPayer(id);
  }

  Future<void> _pickDescription(BuildContext context) async {
    final picked = await _showDescriptionPicker(
      context,
      current: controller.description.text,
      past: event.pastDescriptions,
    );
    if (picked != null) controller.description.text = picked;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        final isIncome = c.type == TransactionType.income;
        final form = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // The hero's "what for" line is the row's คำอธิบาย here.
            TxHeroCard(
              type: c.type,
              allowTransfer: false,
              onTypeChanged: locked ? null : c.setType,
              amount: c.amount,
              title: c.description,
              titleHint: l.projectTxDescriptionHint,
              onTitleTap: () => _pickDescription(context),
              dateLabel: _dayLabel(context, c.date),
              onPickDate: onPickDate,
              symbol: event.symbol,
              autofocus: autofocus,
              compact: compact,
            ),
            const SizedBox(height: AppSpacing.md),
            MemberPickCard(
              member: _member(c.payerId),
              label: isIncome ? l.projectTxReceivedBy : l.projectTxPaidBy,
              onTap: locked ? null : () => _pickPayer(context),
            ),
            const SizedBox(height: AppSpacing.md),
            _TextBlock(
              label: l.commonNote,
              controller: c.note,
              maxLength: TextLimits.note,
            ),
            const SizedBox(height: AppSpacing.md),
            _EventTags(controller: c, known: event.tags),
            const SizedBox(height: AppSpacing.md),
            _MemberSplits(
              controller: c,
              members: event.members,
              symbol: event.symbol,
              errorColor: scheme.error,
            ),
          ],
        );
        if (!readOnly) return form;
        return IgnorePointer(child: Opacity(opacity: 0.6, child: form));
      },
    );
  }
}

/// Tags of a project row: the project's tags as chips (tap to toggle) and
/// "+ แท็กใหม่" to start using a new one.
class _EventTags extends StatelessWidget {
  const _EventTags({required this.controller, required this.known});
  final DraftFormController controller;
  final List<String> known;

  Future<void> _addNew(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final text = TextEditingController();
    // The app's sheet + field, like the other pickers (was a raw dialog).
    final name = await showAppSheet<String>(
      context,
      title: l.projectTxAddTag,
      builder: (sheet) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: AppTextField(
          controller: text,
          autofocus: true,
          maxLength: 40,
          hint: l.projectTxTagHint,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.pop(sheet, v),
        ),
      ),
      // Builder: pop the sheet's route, not the caller's navigator.
      footer: Builder(
        builder: (sheet) => AppButton(
          label: l.commonSave,
          expand: true,
          onPressed: () => Navigator.pop(sheet, text.text),
        ),
      ),
    );
    text.dispose();
    final n = name?.trim() ?? '';
    if (n.isEmpty) return;
    final picked = controller.tagNames.any(
      (t) => t.toLowerCase() == n.toLowerCase(),
    );
    if (!picked) controller.toggleTagName(n);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // The project's tags plus any new ones on this row.
    final all = [
      ...known,
      for (final t in controller.tagNames)
        if (!known.any((k) => k.toLowerCase() == t.toLowerCase())) t,
    ];
    bool isOn(String t) =>
        controller.tagNames.any((x) => x.toLowerCase() == t.toLowerCase());
    final mine = context.watch<TagsCubit>().state.tags;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(AppIcons.tag, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Text(
              l.projectTxTags,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final t in all)
              TagChip(
                // Project tags are plain names — borrow the look of the
                // user's own tag of the same name, if any.
                tag:
                    mine
                        .where((m) => m.name.toLowerCase() == t.toLowerCase())
                        .firstOrNull ??
                    Tag(id: t, name: t),
                selected: isOn(t),
                onTap: () => controller.toggleTagName(t),
              ),
            ActionChip(
              avatar: const Icon(AppIcons.add, size: 16),
              label: Text(l.projectTxAddTag),
              onPressed: () => _addNew(context),
            ),
          ],
        ),
      ],
    );
  }
}

/// "หารกับ" for a project row: who owes the payer how much; the payer keeps
/// the rest. "หารเท่ากัน" fills everyone in.
class _MemberSplits extends StatelessWidget {
  const _MemberSplits({
    required this.controller,
    required this.members,
    required this.symbol,
    required this.errorColor,
  });

  final DraftFormController controller;
  final List<ProjectMember> members;
  final String symbol;
  final Color errorColor;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final c = controller;
    final others = members.where((m) => m.id != c.payerId).toList();
    if (others.isEmpty) return const SizedBox.shrink();
    final total = c.amountValue;
    final sum = c.memberSplitSum;
    final used = {for (final s in c.memberSplits) s.memberId};

    Future<void> pickMember(MemberSplitDraft s) async {
      final id = await showMemberPicker(
        context,
        title: l.projectTxSplitMember,
        members: others,
        selected: s.memberId,
      );
      if (id != null) c.setSplitMember(s, id);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(AppIcons.split, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(l.projectTxSplits, style: textTheme.labelLarge),
            ),
            if (total > 0)
              TextButton(
                onPressed: () =>
                    c.splitEqually([for (final m in members) m.id]),
                child: Text(l.projectTxSplitEqual),
              ),
          ],
        ),
        Text(l.projectTxSplitsHint, style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        for (final s in c.memberSplits)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final m = others.where((x) => x.id == s.memberId);
                      return PickerTile(
                        label: l.projectTxSplitMember,
                        value: m.firstOrNull?.displayName,
                        leading: m.isEmpty
                            ? const Icon(AppIcons.member)
                            : ProjectMemberAvatar(member: m.first, size: 24),
                        onTap: () => pickMember(s),
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 112,
                  child: TextField(
                    controller: s.amount,
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [ThousandsInputFormatter()],
                    decoration: InputDecoration(
                      hintText: '0',
                      prefixText: '$symbol ',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l.commonDelete,
                  icon: const Icon(AppIcons.clear, size: 18),
                  onPressed: () => c.removeMemberSplit(s),
                ),
              ],
            ),
          ),
        if (c.memberSplits.length < others.length)
          AddTile(
            label: l.projectTxAddSplit,
            variant: AddTileVariant.row,
            onTap: () => c.addMemberSplit(
              others.where((m) => !used.contains(m.id)).firstOrNull?.id,
            ),
          ),
        if (c.memberSplits.isNotEmpty && total > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              sum > total + 0.005
                  ? l.projectTxSplitsOver(
                      moneyString(context, sum, symbol: symbol),
                    )
                  : l.projectTxPayerKeeps(
                      moneyString(context, total - sum, symbol: symbol),
                    ),
              style: textTheme.bodySmall?.copyWith(
                color: sum > total + 0.005 ? errorColor : null,
              ),
            ),
          ),
      ],
    );
  }
}

/// คำอธิบาย: type a new one, or pick one used before in this project
/// (filtered as you type). Returns the text, or null when dismissed.
Future<String?> _showDescriptionPicker(
  BuildContext context, {
  required String current,
  required List<String> past,
}) {
  return showAppSheet<String>(
    context,
    title: AppLocalizations.of(context)!.projectTxDescriptionHint,
    // Same navigator as the quick create sheet it opens from.
    useRootNavigator: false,
    builder: (_) => _DescriptionPicker(current: current, past: past),
  );
}

class _DescriptionPicker extends StatefulWidget {
  const _DescriptionPicker({required this.current, required this.past});
  final String current;
  final List<String> past;

  @override
  State<_DescriptionPicker> createState() => _DescriptionPickerState();
}

class _DescriptionPickerState extends State<_DescriptionPicker> {
  late final _text = TextEditingController(text: widget.current);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final q = _text.text.trim();
    final lower = q.toLowerCase();
    final matches = widget.past
        .where((d) => lower.isEmpty || d.toLowerCase().contains(lower))
        .toList();
    final exact = widget.past.any((d) => d.toLowerCase() == lower);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: AppTextField(
              controller: _text,
              autofocus: true,
              hint: l.projectTxDescriptionHint,
              prefixIcon: AppIcons.note,
              maxLength: 200,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (v) => Navigator.pop(context, v.trim()),
            ),
          ),
          // Typed something new → use it as-is.
          if (q.isNotEmpty && !exact)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: AddTile(
                label: l.projectTxDescriptionUse(q),
                variant: AddTileVariant.row,
                onTap: () => Navigator.pop(context, q),
              ),
            ),
          if (matches.isNotEmpty) ...[
            SectionHeader(title: l.projectTxDescriptionPast),
            for (final d in matches)
              DetailRow(
                leading: const Icon(AppIcons.history),
                label: d,
                onTap: () => Navigator.pop(context, d),
              ),
          ],
        ],
      ),
    );
  }
}
