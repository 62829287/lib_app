import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/list_query.dart';
import '../models/publisher.dart';
import '../repositories/book_repository.dart';
import '../state/load_status.dart';
import '../state/publisher_list_notifier.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/state_views.dart';

class PublisherListScreen extends StatefulWidget {
  const PublisherListScreen({super.key});

  @override
  State<PublisherListScreen> createState() => _PublisherListScreenState();
}

class _PublisherListScreenState extends State<PublisherListScreen> {
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
    context.read<PublisherListNotifier>().applyQuery(q);
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
      Uri(
        path: '/publishers',
        queryParameters: params.isEmpty ? null : params,
      ).toString(),
    );
  }

  Future<bool> _ensureCanDelete(int id) async {
    final count = await context.read<BookRepository>().countByPublisher(id);
    if (count == 0) return true;
    if (!mounted) return false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удаление невозможно'),
        content: Text(
          'На издательство ссылаются $count книг(и). Сначала отвяжите или удалите эти книги.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
    return false;
  }

  Future<void> _deleteSelected({required bool soft}) async {
    final notifier = context.read<PublisherListNotifier>();
    final ids = soft
        ? notifier.selectedItems
            .where((e) => !e.isDeleted)
            .map((e) => e.id)
            .toList()
        : notifier.selected.toList();

    for (final id in ids) {
      if (!await _ensureCanDelete(id)) return;
    }

    if (!mounted) return;
    final ok = soft
        ? await confirmAction(
            context,
            title: 'В корзину?',
            message: 'Логическое удаление',
          )
        : await confirmAction(
            context,
            title: 'Удалить навсегда?',
            message: 'Физическое удаление',
            confirmLabel: 'Стереть',
          );
    if (!ok) return;
    if (soft) {
      await notifier.softDeleteSelected();
    } else {
      await notifier.hardDeleteSelected();
    }
  }

  Future<void> _softDeleteOne(Publisher publisher, PublisherListNotifier n) async {
    if (!await _ensureCanDelete(publisher.id)) return;
    await n.softDelete(publisher.id);
  }

  Future<void> _hardDeleteOne(Publisher publisher, PublisherListNotifier n) async {
    if (!await _ensureCanDelete(publisher.id)) return;
    if (!mounted) return;
    final ok = await confirmAction(
      context,
      title: 'Удалить навсегда?',
      message: 'Издательство «${publisher.name}» будет стёрто без восстановления.',
      confirmLabel: 'Стереть',
    );
    if (ok) await n.hardDelete(publisher.id);
  }

  List<Widget> _rowActions(Publisher publisher, PublisherListNotifier n) {
    return [
      IconButton(
        tooltip: 'Открыть',
        icon: const Icon(Icons.open_in_new, size: 20),
        onPressed: () => context.go('/publishers/${publisher.id}'),
      ),
      IconButton(
        tooltip: 'Изменить',
        icon: const Icon(Icons.edit_outlined, size: 20),
        onPressed: () => context.go('/publishers/${publisher.id}/edit'),
      ),
      if (publisher.isDeleted)
        IconButton(
          tooltip: 'Восстановить',
          icon: const Icon(Icons.restore, size: 20),
          onPressed: () => n.restore(publisher.id),
        )
      else ...[
        IconButton(
          tooltip: 'В корзину',
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () => _softDeleteOne(publisher, n),
        ),
        IconButton(
          tooltip: 'Удалить навсегда',
          icon: const Icon(Icons.delete_forever_outlined, size: 20),
          onPressed: () => _hardDeleteOne(publisher, n),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<PublisherListNotifier>();
    final q = n.query;
    final cards = useCardListOf(context);

    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Издательства',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            FilledButton.icon(
              onPressed: () => context.go('/publishers/new'),
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          decoration: const InputDecoration(
            hintText: 'Название, город или страна',
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
        if (n.hasSelection)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Выбрано: ${n.selected.length}'),
                if (n.selectionHasActive)
                  FilledButton.tonalIcon(
                    onPressed: () => _deleteSelected(soft: true),
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
                  onPressed: () => _deleteSelected(soft: false),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Удалить навсегда'),
                ),
                TextButton(
                  onPressed: n.clearSelection,
                  child: const Text('Снять выделение'),
                ),
              ],
            ),
          ),
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

  Widget _body(PublisherListNotifier n, bool cards) {
    switch (n.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(message: n.error ?? '', onRetry: n.load);
      case LoadStatus.success:
        if (n.result.items.isEmpty) {
          return const EmptyView(message: 'Издательства не найдены');
        }
        if (cards) {
          return Column(
            children: [
              for (final p in n.result.items)
                Card(
                  child: ListTile(
                    leading: Checkbox(
                      value: n.selected.contains(p.id),
                      onChanged: (_) => n.toggleSelection(p.id),
                    ),
                    title: Text(
                      p.name,
                      style: TextStyle(
                        decoration:
                            p.isDeleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text('${p.city}, ${p.country}'),
                    onTap: () => context.go('/publishers/${p.id}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        switch (value) {
                          case 'open':
                            context.go('/publishers/${p.id}');
                          case 'edit':
                            context.go('/publishers/${p.id}/edit');
                          case 'soft':
                            await _softDeleteOne(p, n);
                          case 'hard':
                            await _hardDeleteOne(p, n);
                          case 'restore':
                            await n.restore(p.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'open', child: Text('Открыть')),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Изменить'),
                        ),
                        if (p.isDeleted)
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
        return EntityTable<Publisher>(
          columns: [
            TableColumnSpec(
              label: 'Название',
              sortField: 'name',
              build: (p) => Text(
                p.name,
                style: TextStyle(
                  decoration:
                      p.isDeleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            TableColumnSpec(
              label: 'Город',
              sortField: 'city',
              build: (p) => Text(p.city),
            ),
            TableColumnSpec(
              label: 'Страна',
              sortField: 'country',
              build: (p) => Text(p.country),
            ),
          ],
          items: n.result.items,
          idOf: (p) => p.id,
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
          onRowTap: (p) => context.go('/publishers/${p.id}'),
          actions: (p) => _rowActions(p, n),
        );
    }
  }
}
