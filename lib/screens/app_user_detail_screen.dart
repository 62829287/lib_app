import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../repositories/app_user_repository.dart';
import '../widgets/state_views.dart';

class AppUserDetailScreen extends StatefulWidget {
  const AppUserDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<AppUserDetailScreen> createState() => _AppUserDetailScreenState();
}

class _AppUserDetailScreenState extends State<AppUserDetailScreen> {
  Future? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= context.read<AppUserRepository>().findById(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        final u = snap.data;
        if (u == null) return const EmptyView(message: 'Пользователь не найден');
        return ListView(
          children: [
            Text(u.nickname, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(u.email),
            Text('Регион: ${u.region}'),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text('Steam-профиль'),
                subtitle: Text(
                  '${u.steam.nickname}\n${u.steam.url}\nРейтинг: ${u.steam.rating}',
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => context.go('/users/${u.id}/edit'),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Изменить'),
            ),
          ],
        );
      },
    );
  }
}
