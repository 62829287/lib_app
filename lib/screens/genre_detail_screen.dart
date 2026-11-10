import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";

import "../repositories/genre_repository.dart";
import "../widgets/state_views.dart";

class GenreDetailScreen extends StatefulWidget {
  const GenreDetailScreen({super.key, required this.id});
  final int id;

  @override
  State<GenreDetailScreen> createState() => _GenreDetailScreenState();
}

class _GenreDetailScreenState extends State<GenreDetailScreen> {
  Future? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= context.read<GenreRepository>().findById(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData && snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        final g = snap.data;
        if (g == null) return const EmptyView(message: "Жанр не найден");
        return ListView(
          children: [
            Text(g.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(g.description.isEmpty ? "Без описания" : g.description),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => context.go("/genres/${g.id}/edit"),
              icon: const Icon(Icons.edit_outlined),
              label: const Text("Изменить"),
            ),
          ],
        );
      },
    );
  }
}