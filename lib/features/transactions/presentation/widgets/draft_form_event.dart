part of 'draft_form.dart';

class DraftEvent {
  const DraftEvent({
    required this.members,
    required this.symbol,
    this.pastDescriptions = const [],
    this.tags = const [],
  });

  final List<ProjectMember> members;

  final String symbol;

  final List<String> pastDescriptions;

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
    this.heroKey,
  });

  final DraftFormController controller;
  final DraftEvent event;
  final bool compact;
  final bool autofocus;

  /// A saved row: its type and payer can't change (the API keeps them).
  final bool locked;
  final bool readOnly;
  final VoidCallback onPickDate;

  final GlobalKey? heroKey;

  ProjectMember? _member(String? id) =>
      event.members.where((m) => m.id == id).firstOrNull;

  Future<void> _pickPayer(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final m = await EventMemberPicker.one(
      context,
      title: controller.type == TransactionType.income
          ? l.projectTxReceivedBy
          : l.projectTxPaidBy,
      members: event.members,
      selectedId: controller.payerId,
    );
    if (m != null) controller.setPayer(m.id);
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
            TransactionHeroCard(
              key: heroKey,
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
              errorText: c.payerMissing && c.payerId == null
                  ? l.projectTxPayerRequired
                  : null,
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

class _EventTags extends StatelessWidget {
  const _EventTags({required this.controller, required this.known});
  final DraftFormController controller;
  final List<String> known;

  Future<void> _addNew(BuildContext context) async {
    final n = await askNewTagName(context, maxLength: 40);
    if (n == null) return;
    final picked = controller.tagNames.any(
      (t) => t.toLowerCase() == n.toLowerCase(),
    );
    if (!picked) controller.toggleTagName(n);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final all = [
      ...known,
      for (final t in controller.tagNames)
        if (!known.any((k) => k.toLowerCase() == t.toLowerCase())) t,
    ];
    bool isOn(String t) =>
        controller.tagNames.any((x) => x.toLowerCase() == t.toLowerCase());
    final mine = context.watch<TagsCubit>().state.tags;
    return SectionCard(
      title: l.projectTxTags,
      leading: const AppIcon(AppIcons.tag, size: AppIconSize.sm),
      dividers: false,
      first: true,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final t in all)
                tagAppChip(
                  context,
                  mine
                          .where((m) => m.name.toLowerCase() == t.toLowerCase())
                          .firstOrNull ??
                      Tag(id: t, name: t),
                  selected: isOn(t),
                  onTap: () => controller.toggleTagName(t),
                ),
              AppChip(
                icon: AppIcons.add,
                label: l.projectTxAddTag,
                onTap: () => _addNew(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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
      final m = await EventMemberPicker.one(
        context,
        title: l.projectTxSplitMember,
        members: others,
        selectedId: s.memberId,
      );
      if (m != null) c.setSplitMember(s, m.id);
    }

    return SectionCard(
      title: l.projectTxSplits,
      description: l.projectTxSplitsHint,
      leading: const AppIcon(AppIcons.split, size: AppIconSize.sm),
      trailing: total > 0
          ? AppButton(
              variant: AppButtonVariant.text,
              onPressed: () => c.splitEqually([for (final m in members) m.id]),
              label: l.projectTxSplitEqual,
            )
          : null,
      first: true,
      children: [
        for (final s in c.memberSplits)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final m = others.where((x) => x.id == s.memberId);
                      return DetailRow.pick(
                        label: l.projectTxSplitMember,
                        value: m.firstOrNull?.displayName,
                        emptyText: l.quickEventNone,
                        leading: m.isEmpty
                            ? const AppIcon(AppIcons.member)
                            : memberAvatar(m.first, size: 24),
                        onTap: () => pickMember(s),
                        horizontalInset: 0,
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 112,
                  child: AppInput(
                    controller: s.amount,
                    type: AppInputType.amount,
                    currencySymbol: symbol,
                    dense: true,
                    hint: '0',
                  ),
                ),
                AppIconButton.clear(
                  tooltip: l.commonDelete,
                  iconSize: AppIconSize.md,
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
            padding: const EdgeInsets.all(AppSpacing.md),
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

Future<String?> _showDescriptionPicker(
  BuildContext context, {
  required String current,
  required List<String> past,
}) {
  final l = AppLocalizations.of(context)!;
  return showDescriptionPickerSheet(
    context,
    current: current,
    suggestions: past,
    labels: DescriptionPickerLabels(
      title: l.projectTxDescriptionHint,
      hint: l.projectTxDescriptionHint,
      pastHeading: l.projectTxDescriptionPast,
      useLabel: l.projectTxDescriptionUse,
    ),
    useRootNavigator: false,
  );
}
