import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/build.dart';
import '../models/pro_player.dart';
import '../repositories/build_repository.dart';
import '../repositories/pro_player_repository.dart';
import '../state/catalog_notifier.dart';
import '../widgets/state_views.dart';

class BuildDetailScreen extends StatefulWidget {
  const BuildDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<BuildDetailScreen> createState() => _BuildDetailScreenState();
}

class _BuildDetailScreenState extends State<BuildDetailScreen> {
  Future<Build?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= context.read<BuildRepository>().findById(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogNotifier>();

    return FutureBuilder<Build?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (snapshot.hasError) {
          return ErrorView(
            message: '${snapshot.error}',
            onRetry: () => setState(() {
              _future = context.read<BuildRepository>().findById(widget.id);
            }),
          );
        }
        final build = snapshot.data;
        if (build == null) {
          return EmptyView(
            message: 'Сборка не найдена',
            hint: 'Идентификатор ${widget.id} отсутствует в каталоге.',
            action: FilledButton(
              onPressed: () => context.go('/builds'),
              child: const Text('К списку сборок'),
            ),
          );
        }

        final theme = Theme.of(context);
        return ListView(
          children: [
            Text(build.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            if (build.isDeleted)
              const Chip(
                avatar: Icon(Icons.delete_outline, size: 18),
                label: Text('Удалена (логически)'),
              ),
            const SizedBox(height: 16),
            _InfoRow(label: 'Код', value: build.code),
            _InfoRow(label: 'Патч', value: build.patch),
            _InfoRow(label: 'Сложность', value: '${build.difficulty}'),
            _InfoRow(
              label: 'Герой',
              value: catalog.heroName(build.heroId),
            ),
            _InfoRow(
              label: 'Роли',
              value: build.roleIds.map(catalog.roleName).join(', '),
            ),
            _InfoRow(
              label: 'Статистика',
              value: '${build.wins} побед из ${build.picks} пиков',
            ),
            const SizedBox(height: 24),
            Text('Про-игроки', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _ProPlayersBlock(proPlayerIds: build.proPlayerIds),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => context.go('/builds/${build.id}/edit'),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Изменить'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go('/builds'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('К списку'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProPlayersBlock extends StatelessWidget {
  const _ProPlayersBlock({required this.proPlayerIds});

  final List<int> proPlayerIds;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ProPlayerRepository>();
    return FutureBuilder<List<ProPlayer?>>(
      future: Future.wait(proPlayerIds.map(repo.findById)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          );
        }
        final players = snapshot.data!.whereType<ProPlayer>().toList();
        if (players.isEmpty) {
          return const Text('Про-игроки не указаны');
        }
        return Column(
          children: [
            for (final player in players)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(player.nickname),
                subtitle: Text('${player.team} · ${player.country}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/pros/${player.id}'),
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
          Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
