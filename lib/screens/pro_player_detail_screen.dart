import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../repositories/pro_player_repository.dart';
import '../widgets/state_views.dart';

class ProPlayerDetailScreen extends StatefulWidget {
  const ProPlayerDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<ProPlayerDetailScreen> createState() => _ProPlayerDetailScreenState();
}

class _ProPlayerDetailScreenState extends State<ProPlayerDetailScreen> {
  Future? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= context.read<ProPlayerRepository>().findById(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData && snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        final p = snap.data;
        if (p == null) return const EmptyView(message: 'Про-игрок не найден');
        return ListView(
          children: [
            Text(p.nickname, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            if (p.isDeleted)
              const Chip(
                avatar: Icon(Icons.delete_outline, size: 18),
                label: Text('Удалён (логически)'),
              ),
            const SizedBox(height: 16),
            _InfoRow(label: 'Имя', value: p.realName),
            _InfoRow(label: 'Команда', value: p.team),
            _InfoRow(label: 'Рейтинг', value: '${p.rating}'),
            _InfoRow(label: 'Страна', value: p.country),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => context.go('/pros/${p.id}/edit'),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Изменить'),
            ),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
