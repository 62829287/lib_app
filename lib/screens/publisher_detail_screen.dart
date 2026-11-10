import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";

import "../repositories/book_repository.dart";
import "../repositories/publisher_repository.dart";
import "../widgets/state_views.dart";

class PublisherDetailScreen extends StatefulWidget {
  const PublisherDetailScreen({super.key, required this.id});
  final int id;

  @override
  State<PublisherDetailScreen> createState() => _PublisherDetailScreenState();
}

class _PublisherDetailScreenState extends State<PublisherDetailScreen> {
  Future? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= () async {
      final publishers = context.read<PublisherRepository>();
      final books = context.read<BookRepository>();
      final p = await publishers.findById(widget.id);
      final count = await books.countByPublisher(widget.id);
      return (publisher: p, books: count);
    }();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const LoadingView();
        final data = snap.data as dynamic;
        final p = data.publisher;
        if (p == null) return const EmptyView(message: "Издательство не найдено");
        return ListView(
          children: [
            Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text("${p.city}, ${p.country}"),
            Text("Связанных книг: ${data.books}"),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => context.go("/publishers/${p.id}/edit"),
              icon: const Icon(Icons.edit_outlined),
              label: const Text("Изменить"),
            ),
          ],
        );
      },
    );
  }
}