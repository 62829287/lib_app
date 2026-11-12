import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/build.dart';
import '../models/build_query.dart';
import '../state/build_list_notifier.dart';
import '../state/catalog_notifier.dart';
import '../state/load_status.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/state_views.dart';

class BuildListScreen extends StatefulWidget {
  const BuildListScreen({super.key});

  @override
  State<BuildListScreen> createState() => _BuildListScreenState();
}

class _BuildListScreenState extends State<BuildListScreen> {
  final _searchController = TextEditingController();
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
    super.dispose();
  }

  BuildQuery _queryFromUrl() {
    return BuildQuery.fromQueryParameters(
      GoRouterState.of(context).uri.queryParameters,
    );
  }

  void _syncFromUrl() {
    final uri = GoRouterState.of(context).uri;
    final key = uri.toString();
    if (key == _lastSynced) return;
    _lastSynced = key;

    final query = BuildQuery.fromQueryParameters(uri.queryParameters);
    if (_searchController.text != query.search) {
      _searchController.text = query.search;
    }

    final notifier = context.read<BuildListNotifier>();
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

  void _replaceQuery(BuildQuery query) {
    final params = query.toQueryParameters();
    final uri = Uri(
      path: '/builds',
      queryParameters: params.isEmpty ? null : params,
    );
    context.replace(uri.toString());
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _replaceQuery(_queryFromUrl().copyWith(search: value));
    });
  }

  int? _difficultyFilter(BuildQuery q) {
    if (q.difficultyFrom != null &&
        q.difficultyFrom == q.difficultyTo) {
      return q.difficultyFrom;
    }
    return null;
  }

  Future<void> _confirmSoftDeleteSelected(BuildListNotifier notifier) async {
    final count =
        notifier.selectedItems.where((b) => !b.isDeleted).length;
    final ok = await confirmAction(
      context,
      title: 'В корзину?',
      message: 'Логически удалить выбранные сборки: $count.',
    );
    if (ok) await notifier.softDeleteSelected();
  }

  Future<void> _confirmHardDeleteSelected(BuildListNotifier notifier) async {
    final ok = await confirmAction(
      context,
      title: 'Удалить навсегда?',
      message:
          'Физически стереть ${notifier.selected.length} сбор. без восстановления.',
      confirmLabel: 'Стереть',
    );
    if (ok) await notifier.hardDeleteSelected();
  }

  Future<void> _confirmRestoreSelected(BuildListNotifier notifier) async {
    final count = notifier.selectedItems.where((b) => b.isDeleted).length;
    final ok = await confirmAction(
      context,
      title: 'Восстановить?',
      message: 'Вернуть из корзины выбранные сборки: $count.',
      confirmLabel: 'Восстановить',
    );
    if (ok) await notifier.restoreSelected();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = context.watch<BuildListNotifier>();
    final catalog = context.watch<CatalogNotifier>();
    final query = notifier.query;
    final useCards = useCardListOf(context);
    final difficulty = _difficultyFilter(query);

    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Сборки', style: theme.textTheme.headlineSmall),
            ),
            FilledButton.icon(
              onPressed: () => context.go('/builds/new'),
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Название или код',
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
                key: ValueKey('role-${query.roleId}'),
                initialValue: query.roleId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Роль'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Все роли', overflow: TextOverflow.ellipsis),
                  ),
                  for (final r in catalog.roles)
                    DropdownMenuItem(
                      value: r.id,
                      child: Text(r.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) =>
                    _replaceQuery(query.copyWith(roleId: value)),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<int?>(
                key: ValueKey('hero-${query.heroId}'),
                initialValue: query.heroId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Герой'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Все герои', overflow: TextOverflow.ellipsis),
                  ),
                  for (final h in catalog.heroes)
                    DropdownMenuItem(
                      value: h.id,
                      child: Text(h.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) =>
                    _replaceQuery(query.copyWith(heroId: value)),
              ),
            ),
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<int?>(
                key: ValueKey('difficulty-$difficulty'),
                initialValue: difficulty,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Сложность'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Любая'),
                  ),
                  for (var d = 1; d <= 5; d++)
                    DropdownMenuItem(value: d, child: Text('$d')),
                ],
                onChanged: (value) => _replaceQuery(
                  query.copyWith(
                    difficultyFrom: value,
                    difficultyTo: value,
                  ),
                ),
              ),
            ),
            FilterChip(
              label: const Text('В архиве'),
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
    BuildListNotifier notifier,
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
              for (final build in notifier.result.items) ...[
                _BuildCard(
                  item: build,
                  heroName: catalog.heroName(build.heroId),
                  selected: notifier.selected.contains(build.id),
                  onToggle: () => notifier.toggleSelection(build.id),
                  onOpen: () => context.go('/builds/${build.id}'),
                  onSoftDelete: () => notifier.softDelete(build.id),
                  onHardDelete: () async {
                    final ok = await confirmAction(
                      context,
                      title: 'Удалить навсегда?',
                      message:
                          'Сборка «${build.title}» будет стёрта без восстановления.',
                      confirmLabel: 'Стереть',
                    );
                    if (ok) await notifier.hardDelete(build.id);
                  },
                  onRestore: () => notifier.restore(build.id),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        }
        return EntityTable<Build>(
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
              label: 'Код',
              sortField: 'code',
              build: (b) => Text(b.code),
            ),
            TableColumnSpec(
              label: 'Патч',
              sortField: 'patch',
              build: (b) => Text(b.patch),
            ),
            TableColumnSpec(
              label: 'Сложн.',
              sortField: 'difficulty',
              numeric: true,
              build: (b) => Text('${b.difficulty}'),
            ),
            TableColumnSpec(
              label: 'Герой',
              build: (b) => Text(catalog.heroName(b.heroId)),
            ),
            TableColumnSpec(
              label: 'Победы',
              sortField: 'wins',
              numeric: true,
              build: (b) => Text('${b.wins}/${b.picks}'),
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
          onRowTap: (build) => context.go('/builds/${build.id}'),
          actions: (build) => [
            IconButton(
              tooltip: 'Открыть',
              icon: const Icon(Icons.open_in_new, size: 20),
              onPressed: () => context.go('/builds/${build.id}'),
            ),
            IconButton(
              tooltip: 'Изменить',
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => context.go('/builds/${build.id}/edit'),
            ),
            if (build.isDeleted)
              IconButton(
                tooltip: 'Восстановить',
                icon: const Icon(Icons.restore, size: 20),
                onPressed: () => notifier.restore(build.id),
              )
            else ...[
              IconButton(
                tooltip: 'В корзину',
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => notifier.softDelete(build.id),
              ),
              IconButton(
                tooltip: 'Удалить навсегда',
                icon: const Icon(Icons.delete_forever_outlined, size: 20),
                onPressed: () async {
                  final ok = await confirmAction(
                    context,
                    title: 'Удалить навсегда?',
                    message:
                        'Сборка «${build.title}» будет стёрта без восстановления.',
                    confirmLabel: 'Стереть',
                  );
                  if (ok) await notifier.hardDelete(build.id);
                },
              ),
            ],
          ],
        );
    }
  }
}

class _BuildCard extends StatelessWidget {
  const _BuildCard({
    required this.item,
    required this.heroName,
    required this.selected,
    required this.onToggle,
    required this.onOpen,
    required this.onSoftDelete,
    required this.onHardDelete,
    required this.onRestore,
  });

  final Build item;
  final String heroName;
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
          item.title,
          style: TextStyle(
            decoration: item.isDeleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${item.patch} · $heroName · ${item.wins}/${item.picks} · ${item.code}',
        ),
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
            if (item.isDeleted)
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
