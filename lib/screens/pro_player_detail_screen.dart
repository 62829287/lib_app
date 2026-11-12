import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/build.dart';
import '../models/build_query.dart';
import '../models/pro_player.dart';
import '../repositories/build_repository.dart';
import '../repositories/pro_player_repository.dart';
import '../widgets/state_views.dart';

class ProPlayerDetailScreen extends StatefulWidget {
  const ProPlayerDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<ProPlayerDetailScreen> createState() => _ProPlayerDetailScreenState();
}

class _ProPlayerDetailScreenState extends State<ProPlayerDetailScreen> {
  Future<_DetailData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_DetailData> _load() async {
    final players = context.read<ProPlayerRepository>();
    final buildsRepo = context.read<BuildRepository>();
    final player = await players.findById(widget.id);
    final builds = await buildsRepo.find(
      BuildQuery(proPlayerId: widget.id, size: 100),
    );
    return _DetailData(player: player, builds: builds.items);
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
        final p = data?.player;
        if (p == null) return const EmptyView(message: 'Про-игрок не найден');
        final builds = data!.builds;
        final theme = Theme.of(context);

        return ListView(
          children: [
            Text(p.nickname, style: theme.textTheme.headlineSmall),
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
            const SizedBox(height: 24),
            Text('Сборки', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (builds.isEmpty)
              const Text('Пока нет связанных сборок')
            else
              for (final build in builds)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(build.title),
                  subtitle: Text('${build.code} · патч ${build.patch}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/builds/${build.id}'),
                ),
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

class _DetailData {
  const _DetailData({required this.player, required this.builds});

  final ProPlayer? player;
  final List<Build> builds;
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
