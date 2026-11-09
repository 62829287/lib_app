import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";

import "../models/author.dart";
import "../models/book.dart";
import "../repositories/author_repository.dart";
import "../repositories/book_repository.dart";
import "../state/catalog_notifier.dart";
import "../widgets/state_views.dart";

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Future<Book?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= context.read<BookRepository>().findById(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogNotifier>();

    return FutureBuilder<Book?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (snapshot.hasError) {
          return ErrorView(
            message: "${snapshot.error}",
            onRetry: () => setState(() {
              _future = context.read<BookRepository>().findById(widget.id);
            }),
          );
        }
        final book = snapshot.data;
        if (book == null) {
          return EmptyView(
            message: "Книга не найдена",
            hint: "Идентификатор ${widget.id} отсутствует в каталоге.",
            action: FilledButton(
              onPressed: () => context.go("/books"),
              child: const Text("К списку книг"),
            ),
          );
        }

        final theme = Theme.of(context);
        return ListView(
          children: [
            Text(book.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            if (book.isDeleted)
              const Chip(
                avatar: Icon(Icons.delete_outline, size: 18),
                label: Text("Удалена (логически)"),
              ),
            const SizedBox(height: 16),
            _InfoRow(label: "ISBN", value: book.isbn),
            _InfoRow(label: "Год", value: "${book.year}"),
            _InfoRow(label: "Страниц", value: "${book.pages}"),
            _InfoRow(
              label: "Издательство",
              value: catalog.publisherName(book.publisherId),
            ),
            _InfoRow(
              label: "Жанры",
              value: book.genreIds.map(catalog.genreName).join(", "),
            ),
            _InfoRow(
              label: "Экземпляры",
              value: "${book.copiesAvailable} / ${book.copiesTotal}",
            ),
            const SizedBox(height: 24),
            Text("Авторы", style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _AuthorsBlock(authorIds: book.authorIds),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go("/books"),
                icon: const Icon(Icons.arrow_back),
                label: const Text("К списку"),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AuthorsBlock extends StatelessWidget {
  const _AuthorsBlock({required this.authorIds});

  final List<int> authorIds;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AuthorRepository>();
    return FutureBuilder<List<Author?>>(
      future: Future.wait(authorIds.map(repo.findById)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          );
        }
        final authors = snapshot.data!.whereType<Author>().toList();
        if (authors.isEmpty) {
          return const Text("Авторы не указаны");
        }
        return Column(
          children: [
            for (final author in authors)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(author.fullName),
                subtitle: Text(author.country),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go("/authors/${author.id}"),
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