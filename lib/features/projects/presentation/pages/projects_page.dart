import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../domain/project.dart';
import '../cubit/projects_cubit.dart';

/// `/projects` — list of projects the user owns or is a member of.
class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectsCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New project',
            onPressed: () => context.push('/projects/new'),
          ),
        ],
      ),
      body: BlocConsumer<ProjectsCubit, ProjectsState>(
        listenWhen: (a, b) => a.errorMessage != b.errorMessage,
        listener: (ctx, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(ctx)
                .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (ctx, state) {
          if (state.status == ProjectsStatus.loading &&
              state.projects.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'active', label: Text('Active')),
                    ButtonSegment(
                        value: 'completed', label: Text('Completed')),
                    ButtonSegment(
                        value: 'archived', label: Text('Archived')),
                    ButtonSegment(value: 'all', label: Text('All')),
                  ],
                  selected: {state.statusFilter},
                  onSelectionChanged: (v) =>
                      ctx.read<ProjectsCubit>().load(statusFilter: v.first),
                ),
              ),
              Expanded(
                child: state.projects.isEmpty
                    ? const Center(child: Text('No projects'))
                    : RefreshIndicator(
                        onRefresh: () => ctx.read<ProjectsCubit>().load(),
                        child: ListView.separated(
                          itemCount: state.projects.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) =>
                              _ProjectRow(project: state.projects[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconDisplay(
        type: IconType.project,
        size: 40,
        iconCode: project.iconCode,
      ),
      title: Text(project.name),
      subtitle: Text(
          '${project.membersCount} member${project.membersCount == 1 ? '' : 's'} · ${project.status.wire}'),
      trailing: project.isLocked ? const Icon(Icons.lock_outline) : null,
      onTap: () async {
        await context.push('/projects/${project.id}');
        if (context.mounted) {
          context.read<ProjectsCubit>().load();
        }
      },
    );
  }
}
