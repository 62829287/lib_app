import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/build.dart';
import '../models/build_query.dart';
import '../models/dota_hero.dart';
import '../repositories/build_repository.dart';
import '../repositories/hero_repository.dart';
import '../widgets/state_views.dart';

class HeroDetailScreen extends StatefulWidget {
  const HeroDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<HeroDetailScreen> createState() => _HeroDetailScreenState();
}

class _HeroDetailScreenState extends State<HeroDetailScreen> {
  Future<_DetailData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_DetailData> _load() async {
    final heroes = context.read<HeroRepository>();
    final buildsRepo = context.read<BuildRepository>();
    final hero = await heroes.findById(widget.id);
    final builds = await buildsRepo.find(
      BuildQuery(heroId: widget.id, size: 100),
    );
    return _DetailData(hero: hero, builds: builds.items);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DetailData>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const LoadingView();
        final data = snap.data!;
        final h = data.hero;
        if (h == null) return const EmptyView(message: 'Герой не найден');
        final theme = Theme.of(context);

        return ListView(
          children: [
            Text(h.name, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Атрибут: ${h.primaryAttribute}'),
            Text('Тип атаки: ${h.attackType}'),
            Text('Связанных сборок: ${data.builds.length}'),
            const SizedBox(height: 24),
            Text('Сборки', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (data.builds.isEmpty)
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
              onPressed: () => context.go('/heroes/${h.id}/edit'),
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
  const _DetailData({required this.hero, required this.builds});

  final DotaHero? hero;
  final List<Build> builds;
}
