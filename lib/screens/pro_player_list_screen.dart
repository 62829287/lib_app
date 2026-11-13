import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/pro_player.dart';
import '../models/pro_player_query.dart';
import '../state/catalog_notifier.dart';
import '../state/load_status.dart';
import '../state/pro_player_list_notifier.dart';
import '../widgets/api_feedback.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/state_views.dart';

class ProPlayerListScreen extends StatefulWidget {
  const ProPlayerListScreen({super.key});

  @override
  State<ProPlayerListScreen> createState() => _ProPlayerListScreenState();
}

class _ProPlayerListScreenState extends State<ProPlayerListScreen> {
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

  void _syncFromUrl() {
    final uri = GoRouterState.of(context).uri;
    final key = uri.toString();
    if (key == _lastSynced) return;
    _lastSynced = key;

    final query = ProPlayerQuery.fromQueryParameters(uri.queryParameters);
    if (_searchController.text != query.search) {
      _searchController.text = query.search;
    }

    final notifier = context.read<ProPlayerListNotifier>();
    if (notifier.query.toQueryParameters().toString() !=
            query.toQueryParameters().toString() ||
        notifier.query.page != query.page ||
        notifier.query.size != query.size ||
        notifier.query.sortField != query.sortField ||
        notifier.query.sortAscending != query.sortAscending ||
        notifier.query.includeDeleted != query.includeDeleted ||
        notifier.status == LoadStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        notifier.applyQuery(query);
      });
    }
  }

  void _replaceQuery(ProPlayerQuery query) {
    final params = query.toQueryParameters();
    context.replace(
      Uri(path: '/pros', queryParameters: params.isEmpty ? null : params)
          .toString(),
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final current = ProPlayerQuery.fromQueryParameters(
        GoRouterState.of(context).uri.queryParameters,
      );
      _replaceQuery(current.copyWith(search: value));
    });
  }

  List<Widget> _rowActions(ProPlayer player, ProPlayerListNotifier n) {
    return [
      IconButton(
        tooltip: 'Открыть',
        icon: const Icon(Icons.open_in_new, size: 20),
        onPressed: () => context.go('/pros/${player.id}'),
      ),
      IconButton(
        tooltip: 'Изменить',
        icon: const Icon(Icons.edit_outlined, size: 20),
        onPressed: () => context.go('/pros/${player.id}/edit'),
      ),
      if (player.isDeleted)
        IconButton(
          tooltip: 'Восстановить',
          icon: const Icon(Icons.restore, size: 20),
          onPressed: () => n.restore(player.id),
        )
      else ...[
        IconButton(
          tooltip: 'В корзину',
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () => n.softDelete(player.id),
        ),
        IconButton(
          tooltip: 'Удалить навсегда',
          icon: const Icon(Icons.delete_forever_outlined, size: 20),
          onPressed: () async {
            final ok = await confirmAction(
              context,
              title: 'Удалить навсегда?',
              message:
                  'Игрок «${player.nickname}» будет стёрт без восстановления.',
              confirmLabel: 'Стереть',
            );
            if (ok && context.mounted) {
              await runApiAction(context, () => n.hardDelete(player.id));
            }
          },
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = context.watch<ProPlayerListNotifier>();
    final catalog = context.watch<CatalogNotifier>();
    final query = notifier.query;
    final useCards = useCardListOf(context);

    if (notifier.status == LoadStatus.success) {
      catalog.recoverIfNeeded();
    }

    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Про-игроки', style: theme.textTheme.headlineSmall),
            ),
            FilledButton.icon(
              onPressed: () => context.go('/pros/new'),
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
            hintText: 'Ник, имя или команда',
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
          children: [
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String?>(
                key: ValueKey('country-${query.country}'),
                initialValue: query.country,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Страна'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Все страны'),
                  ),
                  for (final c in catalog.countries)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (value) =>
                    _replaceQuery(query.copyWith(country: value)),
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
        if (notifier.hasSelection) _selectionBar(notifier),
        _buildBody(context, notifier, useCards),
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

  Widget _selectionBar(ProPlayerListNotifier n) {
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
                    message: 'Логическое удаление выбранных игроков')) {
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
                if (!context.mounted) return;
                await runApiAction(context, n.hardDeleteSelected);
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

  Widget _buildBody(
    BuildContext context,
    ProPlayerListNotifier notifier,
    bool useCards,
  ) {
    switch (notifier.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(
          message: notifier.error ?? '',
          onRetry: () {
            context.read<CatalogNotifier>().load();
            notifier.load();
          },
        );
      case LoadStatus.success:
        if (notifier.result.items.isEmpty) {
          return const EmptyView(message: 'Про-игроки не найдены');
        }
        if (useCards) {
          return Column(
            children: [
              for (final p in notifier.result.items)
                Card(
                  child: ListTile(
                    leading: Checkbox(
                      value: notifier.selected.contains(p.id),
                      onChanged: (_) => notifier.toggleSelection(p.id),
                    ),
                    title: Text(
                      p.nickname,
                      style: TextStyle(
                        decoration:
                            p.isDeleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text('${p.team} · ${p.country} · рейтинг ${p.rating}'),
                    onTap: () => context.go('/pros/${p.id}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        switch (value) {
                          case 'open':
                            context.go('/pros/${p.id}');
                          case 'soft':
                            await notifier.softDelete(p.id);
                          case 'hard':
                            if (await confirmAction(context,
                                title: 'Удалить навсегда?',
                                message: 'Игрок «${p.nickname}»',
                                confirmLabel: 'Стереть')) {
                              if (!context.mounted) return;
                              await runApiAction(
                                context,
                                () => notifier.hardDelete(p.id),
                              );
                            }
                          case 'restore':
                            await notifier.restore(p.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'open', child: Text('Открыть')),
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
        return EntityTable<ProPlayer>(
          columns: [
            TableColumnSpec(
              label: 'Ник',
              sortField: 'nickname',
              build: (p) => Text(
                p.nickname,
                style: TextStyle(
                  decoration:
                      p.isDeleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            TableColumnSpec(
              label: 'Имя',
              sortField: 'realName',
              build: (p) => Text(p.realName),
            ),
            TableColumnSpec(
              label: 'Команда',
              sortField: 'team',
              build: (p) => Text(p.team),
            ),
            TableColumnSpec(
              label: 'Рейтинг',
              sortField: 'rating',
              numeric: true,
              build: (p) => Text('${p.rating}'),
            ),
            TableColumnSpec(
              label: 'Страна',
              sortField: 'country',
              build: (p) => Text(p.country),
            ),
          ],
          items: notifier.result.items,
          idOf: (p) => p.id,
          selected: notifier.selected,
          onToggleSelect: notifier.toggleSelection,
          sortField: notifier.query.sortField,
          sortAscending: notifier.query.sortAscending,
          onSort: (field) => _replaceQuery(
            notifier.query.copyWith(
              sortField: field,
              sortAscending: notifier.query.sortField == field
                  ? !notifier.query.sortAscending
                  : true,
              page: 1,
            ),
          ),
          onRowTap: (p) => context.go('/pros/${p.id}'),
          actions: (p) => _rowActions(p, notifier),
        );
    }
  }
}
