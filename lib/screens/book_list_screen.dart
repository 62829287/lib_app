import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../state/book_list_notifier.dart';
import '../state/catalog_notifier.dart';
import '../state/load_status.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/state_views.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final _searchController = TextEditingController();
  final _yearFromController = TextEditingController();
  final _yearToController = TextEditingController();
  Timer? _debounce;
  String _lastSynced = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFromUrl();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _yearFromController.dispose();
    _yearToController.dispose();
    super.dispose();
  }

  BookQuery _queryFromUrl() {
    return BookQuery.fromQueryParameters(
      GoRouterState.of(context).uri.queryParameters,
    );
  }

  void _syncFromUrl() {
    final uri = GoRouterState.of(context).uri;
    final key = uri.toString();
    if (key == _lastSynced) return;
    _lastSynced = key;

    final query = BookQuery.fromQueryParameters(uri.queryParameters);
    if (_searchController.text != query.search) {
      _searchController.text = query.search;
    }
    final yearFromText = query.yearFrom?.toString() ?? '';
    if (_yearFromController.text != yearFromText) {
      _yearFromController.text = yearFromText;
    }
    final yearToText = query.yearTo?.toString() ?? '';
    if (_yearToController.text != yearToText) {
      _yearToController.text = yearToText;
    }

    final notifier = context.read<BookListNotifier>();
    final current = notifier.query.toQueryParameters().toString();
    final next = query.toQueryParameters().toString();
    if (current != next ||
        notifier.query.page != query.page ||
        notifier.query.size != query.size ||
        notifier.query.sortField != query.sortField ||
        notifier.query.sortAscending != query.sortAscending ||
        notifier.query.includeDeleted != query.includeDeleted ||
        notifier.status == LoadStatus.idle) {
      notifier.applyQuery(query);
    }
  }

  void _replaceQuery(BookQuery query) {
    final params = query.toQueryParameters();
    final uri = Uri(
      path: '/books',
      queryParameters: params.isEmpty ? null : params,
    );
    context.replace(uri.toString());
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final current = _queryFromUrl();
      _replaceQuery(current.copyWith(search: value));
    });
  }

  void _scheduleYearApply() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final current = _queryFromUrl();
      _replaceQuery(
        current.copyWith(
          yearFrom: _yearFromController.text.isEmpty
              ? null
              : int.tryParse(_yearFromController.text),
          yearTo: _yearToController.text.isEmpty
              ? null
              : int.tryParse(_yearToController.text),
        ),
      );
    });
  }

  Future<void> _confirmSoftDeleteSelected(BookListNotifier notifier) async {
    final count =
        notifier.selectedItems.where((b) => !b.isDeleted).length;
    final ok = await confirmAction(
      context,
      title: 'В корзину?',
      message: 'Логически удалить выбранные книги: $count.',
    );
    if (ok) await notifier.softDeleteSelected();
  }

  Future<void> _confirmHardDeleteSelected(BookListNotifier notifier) async {
    final ok = await confirmAction(
      context,
      title: 'Удалить навсегда?',
      message:
          'Физически стереть ${notifier.selected.length} кн. без восстановления.',
      confirmLabel: 'Стереть',
    );
    if (ok) await notifier.hardDeleteSelected();
  }

  Future<void> _confirmRestoreSelected(BookListNotifier notifier) async {
    final count = notifier.selectedItems.where((b) => b.isDeleted).length;
    final ok = await confirmAction(
      context,
      title: 'Восстановить?',
      message: 'Вернуть из корзины выбранные книги: $count.',
      confirmLabel: 'Восстановить',
    );
    if (ok) await notifier.restoreSelected();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = context.watch<BookListNotifier>();
    final catalog = context.watch<CatalogNotifier>();
    final query = notifier.query;
    final useCards = useCardListOf(context);

    return ListView(
      children: [
        Text('Книги', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Название или ISBN',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Очистить',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      _replaceQuery(query.copyWith(search: ''));
                    },
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<int?>(
                key: ValueKey('genre-${query.genreId}'),
                initialValue: query.genreId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Жанр'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Все жанры', overflow: TextOverflow.ellipsis),
                  ),
                  for (final g in catalog.genres)
                    DropdownMenuItem(
                      value: g.id,
                      child: Text(g.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) =>
                    _replaceQuery(query.copyWith(genreId: value)),
              ),
            ),
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<int?>(
                key: ValueKey('publisher-${query.publisherId}'),
                initialValue: query.publisherId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Издательство'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      'Все издательства',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  for (final p in catalog.publishers)
                    DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) =>
                    _replaceQuery(query.copyWith(publisherId: value)),
              ),
            ),
            SizedBox(
              width: 110,
              child: TextField(
                controller: _yearFromController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Год от'),
                onChanged: (_) => _scheduleYearApply(),
              ),
            ),
            SizedBox(
              width: 110,
              child: TextField(
                controller: _yearToController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Год до'),
                onChanged: (_) => _scheduleYearApply(),
              ),
            ),
            FilterChip(
              label: const Text('Удалённые'),
              selected: query.includeDeleted,
              onSelected: (value) =>
                  _replaceQuery(query.copyWith(includeDeleted: value)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (notifier.hasSelection)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Выбрано: ${notifier.selected.length}'),
                if (notifier.selectionHasActive)
                  FilledButton.tonalIcon(
                    onPressed: () => _confirmSoftDeleteSelected(notifier),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('В корзину'),
                  ),
                if (notifier.selectionHasDeleted)
                  FilledButton.tonalIcon(
                    onPressed: () => _confirmRestoreSelected(notifier),
                    icon: const Icon(Icons.restore),
                    label: const Text('Восстановить'),
                  ),
                FilledButton.icon(
                  onPressed: () => _confirmHardDeleteSelected(notifier),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Удалить навсегда'),
                ),
                TextButton(
                  onPressed: notifier.clearSelection,
                  child: const Text('Снять выделение'),
                ),
              ],
            ),
          ),
        _buildBody(context, notifier, catalog, useCards),
        const SizedBox(height: 16),
        if (notifier.status == LoadStatus.success)
          PaginationBar(
            result: notifier.result,
            pageSize: query.size,
            onPageChanged: (page) =>
                _replaceQuery(query.copyWith(page: page)),
            onPageSizeChanged: (size) =>
                _replaceQuery(query.copyWith(size: size, page: 1)),
          ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    BookListNotifier notifier,
    CatalogNotifier catalog,
    bool useCards,
  ) {
    switch (notifier.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(
          message: notifier.error ?? 'Неизвестная ошибка',
          onRetry: notifier.load,
        );
      case LoadStatus.success:
        if (notifier.result.items.isEmpty) {
          return const EmptyView(
            message: 'Под фильтр ничего не подошло',
            hint: 'Измените поиск или сбросьте фильтры.',
          );
        }
        if (useCards) {
          return Column(
            children: [
              for (final book in notifier.result.items) ...[
                _BookCard(
                  book: book,
                  publisherName: catalog.publisherName(book.publisherId),
                  selected: notifier.selected.contains(book.id),
                  onToggle: () => notifier.toggleSelection(book.id),
                  onOpen: () => context.go('/books/${book.id}'),
                  onSoftDelete: () => notifier.softDelete(book.id),
                  onHardDelete: () async {
                    final ok = await confirmAction(
                      context,
                      title: 'Удалить навсегда?',
                      message: 'Книга «${book.title}» будет стёрта без восстановления.',
                      confirmLabel: 'Стереть',
                    );
                    if (ok) await notifier.hardDelete(book.id);
                  },
                  onRestore: () => notifier.restore(book.id),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        }
        return EntityTable<Book>(
          columns: [
            TableColumnSpec(
              label: 'Название',
              sortField: 'title',
              build: (b) => Text(
                b.title,
                style: TextStyle(
                  decoration:
                      b.isDeleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            TableColumnSpec(
              label: 'ISBN',
              sortField: 'isbn',
              build: (b) => Text(b.isbn),
            ),
            TableColumnSpec(
              label: 'Год',
              sortField: 'year',
              numeric: true,
              build: (b) => Text('${b.year}'),
            ),
            TableColumnSpec(
              label: 'Стр.',
              sortField: 'pages',
              numeric: true,
              build: (b) => Text('${b.pages}'),
            ),
            TableColumnSpec(
              label: 'Издательство',
              build: (b) => Text(catalog.publisherName(b.publisherId)),
            ),
          ],
          items: notifier.result.items,
          idOf: (b) => b.id,
          selected: notifier.selected,
          onToggleSelect: notifier.toggleSelection,
          sortField: notifier.query.sortField,
          sortAscending: notifier.query.sortAscending,
          onSort: (field) {
            final ascending = notifier.query.sortField == field
                ? !notifier.query.sortAscending
                : true;
            _replaceQuery(
              notifier.query.copyWith(
                sortField: field,
                sortAscending: ascending,
                page: 1,
              ),
            );
          },
          onRowTap: (book) => context.go('/books/${book.id}'),
          actions: (book) => [
            IconButton(
              tooltip: 'Открыть',
              icon: const Icon(Icons.open_in_new, size: 20),
              onPressed: () => context.go('/books/${book.id}'),
            ),
            if (book.isDeleted)
              IconButton(
                tooltip: 'Восстановить',
                icon: const Icon(Icons.restore, size: 20),
                onPressed: () => notifier.restore(book.id),
              )
            else ...[
              IconButton(
                tooltip: 'В корзину',
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => notifier.softDelete(book.id),
              ),
              IconButton(
                tooltip: 'Удалить навсегда',
                icon: const Icon(Icons.delete_forever_outlined, size: 20),
                onPressed: () async {
                  final ok = await confirmAction(
                    context,
                    title: 'Удалить навсегда?',
                    message:
                        'Книга «${book.title}» будет стёрта без восстановления.',
                    confirmLabel: 'Стереть',
                  );
                  if (ok) await notifier.hardDelete(book.id);
                },
              ),
            ],
          ],
        );
    }
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.publisherName,
    required this.selected,
    required this.onToggle,
    required this.onOpen,
    required this.onSoftDelete,
    required this.onHardDelete,
    required this.onRestore,
  });

  final Book book;
  final String publisherName;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final VoidCallback onSoftDelete;
  final VoidCallback onHardDelete;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Checkbox(value: selected, onChanged: (_) => onToggle()),
        title: Text(
          book.title,
          style: TextStyle(
            decoration: book.isDeleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text('${book.year} · $publisherName · ${book.isbn}'),
        onTap: onOpen,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'open':
                onOpen();
              case 'soft':
                onSoftDelete();
              case 'hard':
                onHardDelete();
              case 'restore':
                onRestore();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'open', child: Text('Открыть')),
            if (book.isDeleted)
              const PopupMenuItem(
                value: 'restore',
                child: Text('Восстановить'),
              )
            else ...[
              const PopupMenuItem(
                value: 'soft',
                child: Text('В корзину'),
              ),
              const PopupMenuItem(
                value: 'hard',
                child: Text('Удалить навсегда'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
