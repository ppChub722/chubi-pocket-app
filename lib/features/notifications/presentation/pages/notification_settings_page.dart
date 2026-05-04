import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/notifications_repository.dart';
import '../cubit/notification_settings_cubit.dart';

/// `/notifications/settings` — per-user notification preferences. Spec
/// §13.1, §13.4.7.
class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => NotificationSettingsCubit(
        repository: ctx.read<NotificationsRepository>(),
      )..load(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification settings')),
      body: BlocConsumer<NotificationSettingsCubit, SettingsState>(
        listenWhen: (a, b) => a.errorMessage != b.errorMessage,
        listener: (ctx, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (ctx, state) {
          if (state.settings == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = state.settings!;
          return ListView(
            children: [
              SwitchListTile(
                title: const Text('Auto-notify linked split contacts'),
                subtitle: const Text(
                  'When you split a bill with a linked contact, send them a notification.',
                ),
                value: s.autoNotifyLinkedSplitContacts,
                onChanged: (v) => ctx
                    .read<NotificationSettingsCubit>()
                    .update(autoNotifyLinkedSplitContacts: v),
              ),
              SwitchListTile(
                title:
                    const Text('Auto-add to debt on split notification'),
                subtitle: const Text(
                  'When someone splits a bill with you, automatically track it as a debt.',
                ),
                value: s.autoAddToPersonalDebtOnSplitNotification,
                onChanged: (v) => ctx
                    .read<NotificationSettingsCubit>()
                    .update(autoAddToPersonalDebtOnSplitNotification: v),
              ),
              SwitchListTile(
                title: const Text('Auto-record received payment'),
                subtitle: const Text(
                  'When someone says they paid you, automatically create your receipt.',
                ),
                value: s.autoRecordReceivedPayment,
                onChanged: (v) => ctx
                    .read<NotificationSettingsCubit>()
                    .update(autoRecordReceivedPayment: v),
              ),
              SwitchListTile(
                title: const Text('Auto-resolve own project transactions'),
                subtitle: const Text(
                  'When you save a project transaction you are involved in, skip the resolve modal.',
                ),
                value: s.autoResolveOwnInProjects,
                onChanged: (v) => ctx
                    .read<NotificationSettingsCubit>()
                    .update(autoResolveOwnInProjects: v),
              ),
              if (state.status == SettingsStatus.saving)
                const LinearProgressIndicator(),
            ],
          );
        },
      ),
    );
  }
}
