import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/build.dart';
import '../models/build_query.dart';
import '../models/role.dart';
import '../repositories/build_repository.dart';
import '../repositories/role_repository.dart';
import '../widgets/state_views.dart';

class RoleDetailScreen extends StatefulWidget {
  const RoleDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<RoleDetailScreen> createState() => _RoleDetailScreenState();
}

class _RoleDetailScreenState extends State<RoleDetailScreen> {
  Future<_DetailData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_DetailData> _load() async {
    final roles = context.read<RoleRepository>();
    final buildsRepo = context.read<BuildRepository>();
    final role = await roles.findById(widget.id);
    final builds = await buildsRepo.find(
      BuildQuery(roleId: widget.id, size: 100),
    );
    return _DetailData(role: role, builds: builds.items);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DetailData>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData && snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        final data = snap.data;
        final r = data?.role;
        if (r == null) return const EmptyView(message: 'Роль не найдена');
        final theme = Theme.of(context);

        return ListView(
          children: [
            Text(r.name, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(r.description.isEmpty ? 'Без описания' : r.description),
            const SizedBox(height: 24),
            Text('Сборки', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (data!.builds.isEmpty)
              const Text('Пока нет связанных сборок')
            else
              for (final build in data.builds)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(build.title),
                  subtitle: Text('${build.code} · патч ${build.patch}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/builds/${build.id}'),
                ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => context.go('/roles/${r.id}/edit'),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Изменить'),
            ),
          ],
        );
      },
    );
  }
}

class _DetailData {
  const _DetailData({required this.role, required this.builds});

  final Role? role;
  final List<Build> builds;
}
