import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/main_bottom_nav.dart';
import '../../../../app/shell/more_menu_sheet.dart';
import '../../../transactions/presentation/pages/transaction_form_page.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../domain/tag.dart';
import '../cubit/tags_cubit.dart';
import '../widgets/tag_chip.dart';

/// Tags management.
///
/// **Browse mode only** — tags are flat (no hierarchy), so there's no
/// reorder mode equivalent to categories. Sort is server-driven by
/// `usage_count DESC, name ASC` (spec §3.9).
///
/// Interactions:
/// - **Tap** chip → edit form
/// - **Long-press** chip → delete confirm dialog (hard-deletes per spec
///   §4.11 — junction rows in `transaction_tags` cascade)
/// - **`+`** in app bar → new tag
class TagsPage extends StatefulWidget {
  const TagsPage({super.key});

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TagsCubit>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l.commonBack,
          onPressed: () => context.pop(),
        ),
        title: Text(l.tagsTitle),
        actions: [
          IconButton(
            tooltip: l.tagsAddNew,
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/tags/new'),
          ),
        ],
      ),
      body: BlocBuilder<TagsCubit, TagsState>(
        builder: (context, state) {
          final isLoading = state.status == TagsStatus.loading &&
              state.tags.isEmpty;
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final sorted = state.tags;
          if (sorted.isEmpty) {
            return EmptyView(
              icon: Icons.sell_outlined,
              title: l.tagsEmptyTitle,
              message: l.tagsEmptyMessage,
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              96,
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final tag in sorted)
                  TagChip(
                    key: ValueKey(tag.id),
                    tag: tag,
                    onTap: () => context.push('/tags/${tag.id}/edit'),
                    onLongPress: () => _confirmDelete(context, tag, l),
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: MainBottomNav(
        currentIndex: -1,
        onTabSelected: (i) {
          switch (i) {
            case 0:
              context.go('/');
            case 1:
              context.go('/transactions');
            case 2:
              context.go('/accounts');
          }
        },
        onAddPressed: () => showTransactionFormSheet(context),
        onMorePressed: () => MoreMenuSheet.show(context),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l.navAddTransaction,
        onPressed: () => showTransactionFormSheet(context),
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, Tag tag, AppLocalizations l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.tagDeleteConfirmTitle),
        content: Text(l.tagDeleteConfirmBody),
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
            child: Text(l.tagDeleteConfirmAction),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<TagsCubit>().remove(tag.id);
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

}
