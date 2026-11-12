import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../repositories/role_repository.dart';
import '../widgets/state_views.dart';

class RoleDetailScreen extends StatefulWidget {
  const RoleDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<RoleDetailScreen> createState() => _RoleDetailScreenState();
}

class _RoleDetailScreenState extends State<RoleDetailScreen> {
  Future? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= context.read<RoleRepository>().findById(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData && snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        final r = snap.data;
        if (r == null) return const EmptyView(message: 'Роль не найдена');
        return ListView(
          children: [
            Text(r.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(r.description.isEmpty ? 'Без описания' : r.description),
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
