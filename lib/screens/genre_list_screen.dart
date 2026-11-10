import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/genre.dart';
import '../models/list_query.dart';
import '../state/genre_list_notifier.dart';
import '../state/load_status.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/state_views.dart';

class GenreListScreen extends StatefulWidget {
  const GenreListScreen({super.key});

  @override
  State<GenreListScreen> createState() => _GenreListScreenState();
}

class _GenreListScreenState extends State<GenreListScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _last = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    if (uri.toString() == _last) return;
    _last = uri.toString();
    final q = ListQuery.fromQueryParameters(uri.queryParameters);
    if (_search.text != q.search) _search.text = q.search;
    context.read<GenreListNotifier>().applyQuery(q);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _replace(ListQuery q) {
    final params = q.toQueryParameters();
    context.replace(
      Uri(path: '/genres', queryParameters: params.isEmpty ? null : params)
          .toString(),
    );
  }

  Future<void> _hardDeleteOne(Genre genre, GenreListNotifier n) async {
    final ok = await confirmAction(
      context,
      title: 'Удалить навсегда?',
      message: 'Жанр «${genre.name}» будет стёрт без восстановления.',
      confirmLabel: 'Стереть',
    );
    if (ok) await n.hardDelete(genre.id);
  }

  List<Widget> _rowActions(Genre genre, GenreListNotifier n) {
    return [
      IconButton(
        tooltip: 'Открыть',
        icon: const Icon(Icons.open_in_new, size: 20),
        onPressed: () => context.go('/genres/${genre.id}'),
      ),
      IconButton(
        tooltip: 'Изменить',
        icon: const Icon(Icons.edit_outlined, size: 20),
        onPressed: () => context.go('/genres/${genre.id}/edit'),
      ),
      if (genre.isDeleted)
        IconButton(
          tooltip: 'Восстановить',
          icon: const Icon(Icons.restore, size: 20),
          onPressed: () => n.restore(genre.id),
        )
      else ...[
        IconButton(
          tooltip: 'В корзину',
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () => n.softDelete(genre.id),
        ),
        IconButton(
          tooltip: 'Удалить навсегда',
          icon: const Icon(Icons.delete_forever_outlined, size: 20),
          onPressed: () => _hardDeleteOne(genre, n),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<GenreListNotifier>();
    final q = n.query;
    final cards = useCardListOf(context);

    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Жанры', style: Theme.of(context).textTheme.headlineSmall),
            ),
            FilledButton.icon(
              onPressed: () => context.go('/genres/new'),
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          decoration: const InputDecoration(
            hintText: 'Название или описание',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 350), () {
              _replace(q.copyWith(search: v));
            });
          },
        ),
        const SizedBox(height: 8),
        FilterChip(
          label: const Text('Удалённые'),
          selected: q.includeDeleted,
          onSelected: (v) => _replace(q.copyWith(includeDeleted: v)),
        ),
        const SizedBox(height: 12),
        if (n.hasSelection) _selectionBar(n),
        _body(n, cards),
        if (n.status == LoadStatus.success)
          PaginationBar(
            result: n.result,
            pageSize: q.size,
            onPageChanged: (p) => _replace(q.copyWith(page: p)),
            onPageSizeChanged: (s) => _replace(q.copyWith(size: s, page: 1)),
          ),
      ],
    );
  }

  Widget _selectionBar(GenreListNotifier n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Выбрано: ${n.selected.length}'),
          if (n.selectionHasActive)
            FilledButton.tonalIcon(
              onPressed: () async {
                if (await confirmAction(context,
                    title: 'В корзину?',
                    message: 'Логическое удаление выбранных жанров')) {
                  await n.softDeleteSelected();
                }
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('В корзину'),
            ),
          if (n.selectionHasDeleted)
            FilledButton.tonalIcon(
              onPressed: n.restoreSelected,
              icon: const Icon(Icons.restore),
              label: const Text('Восстановить'),
            ),
          FilledButton.icon(
            onPressed: () async {
              if (await confirmAction(context,
                  title: 'Удалить навсегда?',
                  message: 'Физическое удаление',
                  confirmLabel: 'Стереть')) {
                await n.hardDeleteSelected();
              }
            },
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Удалить навсегда'),
          ),
          TextButton(
            onPressed: n.clearSelection,
            child: const Text('Снять выделение'),
          ),
        ],
      ),
    );
  }

  Widget _body(GenreListNotifier n, bool cards) {
    switch (n.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(message: n.error ?? '', onRetry: n.load);
      case LoadStatus.success:
        if (n.result.items.isEmpty) {
          return const EmptyView(message: 'Жанры не найдены');
        }
        if (cards) {
          return Column(
            children: [
              for (final g in n.result.items)
                Card(
                  child: ListTile(
                    leading: Checkbox(
                      value: n.selected.contains(g.id),
                      onChanged: (_) => n.toggleSelection(g.id),
                    ),
                    title: Text(
                      g.name,
                      style: TextStyle(
                        decoration:
                            g.isDeleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(g.description),
                    onTap: () => context.go('/genres/${g.id}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        switch (value) {
                          case 'open':
                            context.go('/genres/${g.id}');
                          case 'edit':
                            context.go('/genres/${g.id}/edit');
                          case 'soft':
                            await n.softDelete(g.id);
                          case 'hard':
                            await _hardDeleteOne(g, n);
                          case 'restore':
                            await n.restore(g.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'open', child: Text('Открыть')),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Изменить'),
                        ),
                        if (g.isDeleted)
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
                ),
            ],
          );
        }
        return EntityTable<Genre>(
          columns: [
            TableColumnSpec(
              label: 'Название',
              sortField: 'name',
              build: (g) => Text(
                g.name,
                style: TextStyle(
                  decoration:
                      g.isDeleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            TableColumnSpec(
              label: 'Описание',
              sortField: 'description',
              build: (g) => Text(g.description),
            ),
          ],
          items: n.result.items,
          idOf: (g) => g.id,
          selected: n.selected,
          onToggleSelect: n.toggleSelection,
          sortField: n.query.sortField,
          sortAscending: n.query.sortAscending,
          onSort: (f) => _replace(
            n.query.copyWith(
              sortField: f,
              sortAscending:
                  n.query.sortField == f ? !n.query.sortAscending : true,
              page: 1,
            ),
          ),
          onRowTap: (g) => context.go('/genres/${g.id}'),
          actions: (g) => _rowActions(g, n),
        );
    }
  }
}
