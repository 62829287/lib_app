import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
  Future? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= () async {
      final heroes = context.read<HeroRepository>();
      final builds = context.read<BuildRepository>();
      final h = await heroes.findById(widget.id);
      final count = await builds.countByHero(widget.id);
      return (hero: h, builds: count);
    }();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const LoadingView();
        final data = snap.data as dynamic;
        final h = data.hero;
        if (h == null) return const EmptyView(message: 'Герой не найден');
        return ListView(
          children: [
            Text(h.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Атрибут: ${h.primaryAttribute}'),
            Text('Тип атаки: ${h.attackType}'),
            Text('Связанных сборок: ${data.builds}'),
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
