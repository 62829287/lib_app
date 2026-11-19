import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/pro_player.dart';
import '../models/pro_player_query.dart';
import '../models/team.dart';
import '../repositories/pro_player_repository.dart';
import '../repositories/team_repository.dart';
import '../state/catalog_notifier.dart';
import '../widgets/state_views.dart';

class TeamDetailScreen extends StatefulWidget {
  const TeamDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  Future<_DetailData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_DetailData> _load() async {
    final teams = context.read<TeamRepository>();
    final playersRepo = context.read<ProPlayerRepository>();
    final team = await teams.findById(widget.id);
    final players = await playersRepo.find(
      ProPlayerQuery(teamId: widget.id, size: 100),
    );
    return _DetailData(team: team, players: players.items);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogNotifier>();

    return FutureBuilder<_DetailData>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData && snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        final data = snap.data;
        final t = data?.team;
        if (t == null) return const EmptyView(message: 'Команда не найдена');
        final theme = Theme.of(context);

        return ListView(
          children: [
            Text(t.name, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            if (t.isDeleted)
              const Chip(
                avatar: Icon(Icons.delete_outline, size: 18),
                label: Text('Удалена (логически)'),
              ),
            const SizedBox(height: 16),
            _InfoRow(label: 'Тег', value: t.tag.isEmpty ? '—' : t.tag),
            _InfoRow(label: 'Регион', value: t.region.isEmpty ? '—' : t.region),
            _InfoRow(
              label: 'Описание',
              value: t.description.isEmpty ? 'Без описания' : t.description,
            ),
            const SizedBox(height: 24),
            Text('Про-игроки', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (data!.players.isEmpty)
              const Text('В составе пока нет игроков')
            else
              for (final p in data.players)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.nickname),
                  subtitle: Text(
                    '${catalog.teamName(p.teamId)} · ${p.country} · рейтинг ${p.rating}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/pros/${p.id}'),
                ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => context.go('/teams/${t.id}/edit'),
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
  const _DetailData({required this.team, required this.players});

  final Team? team;
  final List<ProPlayer> players;
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
        crossAxisAlignment: CrossAxisAlignment.start,
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