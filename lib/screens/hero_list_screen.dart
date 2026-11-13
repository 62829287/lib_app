import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/dota_hero.dart';
import '../models/list_query.dart';
import '../state/catalog_notifier.dart';
import '../state/hero_list_notifier.dart';
import '../state/load_status.dart';
import '../widgets/api_feedback.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/state_views.dart';

class HeroListScreen extends StatefulWidget {
  const HeroListScreen({super.key});

  @override
  State<HeroListScreen> createState() => _HeroListScreenState();
}

class _HeroListScreenState extends State<HeroListScreen> {
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
    final notifier = context.read<HeroListNotifier>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      notifier.applyQuery(q);
    });
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
      Uri(path: '/heroes', queryParameters: params.isEmpty ? null : params)
          .toString(),
    );
  }

  Future<void> _deleteSelected({required bool soft}) async {
    final notifier = context.read<HeroListNotifier>();
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
    if (!mounted) return;
    if (soft) {
      await notifier.softDeleteSelected();
    } else {
      await runApiAction(context, notifier.hardDeleteSelected);
    }
  }

  Future<void> _softDeleteOne(DotaHero hero, HeroListNotifier n) async {
    await n.softDelete(hero.id);
  }

  Future<void> _hardDeleteOne(DotaHero hero, HeroListNotifier n) async {
    final ok = await confirmAction(
      context,
      title: 'Удалить навсегда?',
      message: 'Герой «${hero.name}» будет стёрт без восстановления.',
      confirmLabel: 'Стереть',
    );
    if (ok && mounted) {
      await runApiAction(context, () => n.hardDelete(hero.id));
    }
  }

  List<Widget> _rowActions(DotaHero hero, HeroListNotifier n) {
    return [
      IconButton(
        tooltip: 'Открыть',
        icon: const Icon(Icons.open_in_new, size: 20),
        onPressed: () => context.go('/heroes/${hero.id}'),
      ),
      IconButton(
        tooltip: 'Изменить',
        icon: const Icon(Icons.edit_outlined, size: 20),
        onPressed: () => context.go('/heroes/${hero.id}/edit'),
      ),
      if (hero.isDeleted)
        IconButton(
          tooltip: 'Восстановить',
          icon: const Icon(Icons.restore, size: 20),
          onPressed: () => n.restore(hero.id),
        )
      else ...[
        IconButton(
          tooltip: 'В корзину',
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () => _softDeleteOne(hero, n),
        ),
        IconButton(
          tooltip: 'Удалить навсегда',
          icon: const Icon(Icons.delete_forever_outlined, size: 20),
          onPressed: () => _hardDeleteOne(hero, n),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<HeroListNotifier>();
    final q = n.query;
    final cards = useCardListOf(context);

    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Герои', style: Theme.of(context).textTheme.headlineSmall),
            ),
            FilledButton.icon(
              onPressed: () => context.go('/heroes/new'),
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          decoration: const InputDecoration(
            hintText: 'Имя или тип атаки',
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
          label: const Text('В архиве'),
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

  Widget _body(HeroListNotifier n, bool cards) {
    switch (n.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(
          message: n.error ?? '',
          onRetry: () {
            context.read<CatalogNotifier>().load();
            n.load();
          },
        );
      case LoadStatus.success:
        if (n.result.items.isEmpty) {
          return const EmptyView(message: 'Герои не найдены');
        }
        if (cards) {
          return Column(
            children: [
              for (final h in n.result.items)
                Card(
                  child: ListTile(
                    leading: Checkbox(
                      value: n.selected.contains(h.id),
                      onChanged: (_) => n.toggleSelection(h.id),
                    ),
                    title: Text(
                      h.name,
                      style: TextStyle(
                        decoration:
                            h.isDeleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text('${h.primaryAttribute} · ${h.attackType}'),
                    onTap: () => context.go('/heroes/${h.id}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        switch (value) {
                          case 'open':
                            context.go('/heroes/${h.id}');
                          case 'edit':
                            context.go('/heroes/${h.id}/edit');
                          case 'soft':
                            await _softDeleteOne(h, n);
                          case 'hard':
                            await _hardDeleteOne(h, n);
                          case 'restore':
                            await n.restore(h.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'open', child: Text('Открыть')),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Изменить'),
                        ),
                        if (h.isDeleted)
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
        return EntityTable<DotaHero>(
          columns: [
            TableColumnSpec(
              label: 'Имя',
              sortField: 'name',
              build: (h) => Text(
                h.name,
                style: TextStyle(
                  decoration:
                      h.isDeleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            TableColumnSpec(
              label: 'Атрибут',
              sortField: 'primaryAttribute',
              build: (h) => Text(h.primaryAttribute),
            ),
            TableColumnSpec(
              label: 'Атака',
              sortField: 'attackType',
              build: (h) => Text(h.attackType),
            ),
          ],
          items: n.result.items,
          idOf: (h) => h.id,
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
          onRowTap: (h) => context.go('/heroes/${h.id}'),
          actions: (h) => _rowActions(h, n),
        );
    }
  }
}
