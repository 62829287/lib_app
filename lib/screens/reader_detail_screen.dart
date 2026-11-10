import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";

import "../repositories/reader_repository.dart";
import "../widgets/state_views.dart";

class ReaderDetailScreen extends StatefulWidget {
  const ReaderDetailScreen({super.key, required this.id});
  final int id;

  @override
  State<ReaderDetailScreen> createState() => _ReaderDetailScreenState();
}

class _ReaderDetailScreenState extends State<ReaderDetailScreen> {
  Future? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= context.read<ReaderRepository>().findById(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        final r = snap.data;
        if (r == null) return const EmptyView(message: "Читатель не найден");
        return ListView(
          children: [
            Text(r.fullName, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(r.email),
            Text(r.phone),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text("Читательский билет"),
                subtitle: Text(
                  "№ ${r.card.number}\nВыдан: ${r.card.issuedAt.toIso8601String().substring(0, 10)}\nДо: ${r.card.expiresAt.toIso8601String().substring(0, 10)}",
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => context.go("/readers/${r.id}/edit"),
              icon: const Icon(Icons.edit_outlined),
              label: const Text("Изменить"),
            ),
          ],
        );
      },
    );
  }
}