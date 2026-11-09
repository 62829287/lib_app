import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";

import "../models/author.dart";
import "../models/book.dart";
import "../models/book_query.dart";
import "../repositories/author_repository.dart";
import "../repositories/book_repository.dart";
import "../widgets/state_views.dart";

class AuthorDetailScreen extends StatefulWidget {
  const AuthorDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<AuthorDetailScreen> createState() => _AuthorDetailScreenState();
}

class _AuthorDetailScreenState extends State<AuthorDetailScreen> {
  Future<_AuthorDetailData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_AuthorDetailData> _load() async {
    final authors = context.read<AuthorRepository>();
    final books = context.read<BookRepository>();
    final author = await authors.findById(widget.id);
    if (author == null) {
      return const _AuthorDetailData(author: null, books: []);
    }
    final page = await books.find(
      const BookQuery(size: 100, includeDeleted: true),
    );
    final related =
        page.items.where((b) => b.authorIds.contains(author.id)).toList();
    return _AuthorDetailData(author: author, books: related);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AuthorDetailData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (snapshot.hasError) {
          return ErrorView(
            message: "${snapshot.error}",
            onRetry: () => setState(() => _future = _load()),
          );
        }
        final data = snapshot.data!;
        final author = data.author;
        if (author == null) {
          return EmptyView(
            message: "Автор не найден",
            hint: "Идентификатор ${widget.id} отсутствует в каталоге.",
            action: FilledButton(
              onPressed: () => context.go("/authors"),
              child: const Text("К списку авторов"),
            ),
          );
        }

        final theme = Theme.of(context);
        return ListView(
          children: [
            Text(author.fullName, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            if (author.isDeleted)
              const Chip(
                avatar: Icon(Icons.delete_outline, size: 18),
                label: Text("Удалён (логически)"),
              ),
            const SizedBox(height: 16),
            _InfoRow(label: "Страна", value: author.country),
            _InfoRow(label: "Год рождения", value: "${author.birthYear}"),
            const SizedBox(height: 24),
            Text("Книги автора", style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (data.books.isEmpty)
              const Text("В каталоге пока нет книг этого автора.")
            else
              for (final book in data.books)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(book.title),
                  subtitle: Text("${book.year} · ${book.isbn}"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go("/books/${book.id}"),
                ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go("/authors"),
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

class _AuthorDetailData {
  const _AuthorDetailData({required this.author, required this.books});

  final Author? author;
  final List<Book> books;
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
          Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}