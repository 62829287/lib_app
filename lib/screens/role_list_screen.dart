import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/list_query.dart';
import '../models/role.dart';
import '../state/auth_notifier.dart';
import '../state/catalog_notifier.dart';
import '../state/load_status.dart';
import '../state/role_list_notifier.dart';
import '../widgets/api_feedback.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/state_views.dart';

class RoleListScreen extends StatefulWidget {
  const RoleListScreen({super.key});

  @override
  State<RoleListScreen> createState() => _RoleListScreenState();
}

class _RoleListScreenState extends State<RoleListScreen> {
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
    final notifier = context.read<RoleListNotifier>();
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
      Uri(
        path: '/roles',
        queryParameters: params.isEmpty ? null : params,
      ).toString(),
    );
  }

  Future<void> _hardDeleteOne(Role role, RoleListNotifier n) async {
    final ok = await confirmAction(
      context,
      title: 'Удалить навсегда?',
      message: 'Роль «${role.name}» будет стёрта без восстановления.',
      confirmLabel: 'Стереть',
    );
    if (ok && mounted) {
      await runApiAction(context, () => n.hardDelete(role.id));
    }
  }

  List<Widget> _rowActions(
    Role role,
    RoleListNotifier n, {
    required bool canEdit,
    required bool canHard,
  }) {
    return [
      IconButton(
        tooltip: 'Открыть',
        icon: const Icon(Icons.open_in_new, size: 20),
        onPressed: () => context.go('/roles/${role.id}'),
      ),
      if (canEdit)
        IconButton(
          tooltip: 'Изменить',
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: () => context.go('/roles/${role.id}/edit'),
        ),
      if (canEdit && role.isDeleted)
        IconButton(
          tooltip: 'Восстановить',
          icon: const Icon(Icons.restore, size: 20),
          onPressed: () => n.restore(role.id),
        )
      else if (canEdit) ...[
        IconButton(
          tooltip: 'В корзину',
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () => n.softDelete(role.id),
        ),
        if (canHard)
          IconButton(
            tooltip: 'Удалить навсегда',
            icon: const Icon(Icons.delete_forever_outlined, size: 20),
            onPressed: () => _hardDeleteOne(role, n),
          ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<RoleListNotifier>();
    final auth = context.watch<AuthNotifier>();
    final canEdit = auth.canEditCatalog();
    final canHard = auth.canHardDelete();
    final q = n.query;
    final cards = useCardListOf(context);

    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Роли',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            if (canEdit)
              FilledButton.icon(
                onPressed: () => context.go('/roles/new'),
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
        if (canEdit) ...[
          const SizedBox(height: 8),
          FilterChip(
            label: const Text('В архиве'),
            selected: q.includeDeleted,
            onSelected: (v) => _replace(q.copyWith(includeDeleted: v)),
          ),
        ],
        const SizedBox(height: 12),
        if (canEdit && n.hasSelection) _selectionBar(n, canHard: canHard),
        _body(n, cards, canEdit: canEdit, canHard: canHard),
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

  Widget _selectionBar(RoleListNotifier n, {required bool canHard}) {
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
                if (await confirmAction(
                  context,
                  title: 'В корзину?',
                  message: 'Логическое удаление выбранных ролей',
                )) {
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
          if (canHard)
            FilledButton.icon(
              onPressed: () async {
                final ok = await confirmAction(
                  context,
                  title: 'Удалить навсегда?',
                  message: 'Физическое удаление',
                  confirmLabel: 'Стереть',
                );
                if (!ok || !mounted) return;
                await runApiAction(context, n.hardDeleteSelected);
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

  Widget _body(
    RoleListNotifier n,
    bool cards, {
    required bool canEdit,
    required bool canHard,
  }) {
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
          return const EmptyView(message: 'Роли не найдены');
        }
        if (cards) {
          return Column(
            children: [
              for (final r in n.result.items)
                Card(
                  child: ListTile(
                    leading: Checkbox(
                      value: n.selected.contains(r.id),
                      onChanged: (_) => n.toggleSelection(r.id),
                    ),
                    title: Text(
                      r.name,
                      style: TextStyle(
                        decoration: r.isDeleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(r.description),
                    onTap: () => context.go('/roles/${r.id}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        switch (value) {
                          case 'open':
                            context.go('/roles/${r.id}');
                          case 'edit':
                            context.go('/roles/${r.id}/edit');
                          case 'soft':
                            await n.softDelete(r.id);
                          case 'hard':
                            await _hardDeleteOne(r, n);
                          case 'restore':
                            await n.restore(r.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'open',
                          child: Text('Открыть'),
                        ),
                        if (canEdit)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Изменить'),
                          ),
                        if (canEdit && r.isDeleted)
                          const PopupMenuItem(
                            value: 'restore',
                            child: Text('Восстановить'),
                          )
                        else if (canEdit) ...[
                          const PopupMenuItem(
                            value: 'soft',
                            child: Text('В корзину'),
                          ),
                          if (canHard)
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
        return EntityTable<Role>(
          columns: [
            TableColumnSpec(
              label: 'Название',
              sortField: 'name',
              build: (r) => Text(
                r.name,
                style: TextStyle(
                  decoration: r.isDeleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            TableColumnSpec(
              label: 'Описание',
              sortField: 'description',
              build: (r) => Text(r.description),
            ),
          ],
          items: n.result.items,
          idOf: (r) => r.id,
          selected: canEdit ? n.selected : {},
          onToggleSelect: canEdit ? n.toggleSelection : null,
          sortField: n.query.sortField,
          sortAscending: n.query.sortAscending,
          onSort: (f) => _replace(
            n.query.copyWith(
              sortField: f,
              sortAscending: n.query.sortField == f
                  ? !n.query.sortAscending
                  : true,
              page: 1,
            ),
          ),
          onRowTap: (r) => context.go('/roles/${r.id}'),
          actions: (r) => _rowActions(r, n, canEdit: canEdit, canHard: canHard),
        );
    }
  }
}
