import "dart:async";

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";

import "../core/breakpoints.dart";
import "../models/author.dart";
import "../models/author_query.dart";
import "../state/author_list_notifier.dart";
import "../state/catalog_notifier.dart";
import "../state/load_status.dart";
import "../widgets/confirm_dialog.dart";
import "../widgets/entity_table.dart";
import "../widgets/pagination_bar.dart";
import "../widgets/state_views.dart";

class AuthorListScreen extends StatefulWidget {
  const AuthorListScreen({super.key});

  @override
  State<AuthorListScreen> createState() => _AuthorListScreenState();
}

class _AuthorListScreenState extends State<AuthorListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _lastSynced = "";

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

  AuthorQuery _queryFromUrl() {
    return AuthorQuery.fromQueryParameters(
      GoRouterState.of(context).uri.queryParameters,
    );
  }

  void _syncFromUrl() {
    final uri = GoRouterState.of(context).uri;
    final key = uri.toString();
    if (key == _lastSynced) return;
    _lastSynced = key;

    final query = AuthorQuery.fromQueryParameters(uri.queryParameters);
    if (_searchController.text != query.search) {
      _searchController.text = query.search;
    }

    final notifier = context.read<AuthorListNotifier>();
    if (notifier.query.toQueryParameters().toString() !=
            query.toQueryParameters().toString() ||
        notifier.query.page != query.page ||
        notifier.query.size != query.size ||
        notifier.query.sortField != query.sortField ||
        notifier.query.sortAscending != query.sortAscending ||
        notifier.query.includeDeleted != query.includeDeleted ||
        notifier.status == LoadStatus.idle) {
      notifier.applyQuery(query);
    }
  }

  void _replaceQuery(AuthorQuery query) {
    final params = query.toQueryParameters();
    final uri = Uri(
      path: "/authors",
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

  Future<void> _confirmSoftDeleteSelected(AuthorListNotifier notifier) async {
    final count =
        notifier.selectedItems.where((a) => !a.isDeleted).length;
    final ok = await confirmAction(
      context,
      title: "В корзину?",
      message: "Логически удалить выбранных авторов: $count.",
    );
    if (ok) await notifier.softDeleteSelected();
  }

  Future<void> _confirmHardDeleteSelected(AuthorListNotifier notifier) async {
    final ok = await confirmAction(
      context,
      title: "Удалить навсегда?",
      message:
          "Физически стереть ${notifier.selected.length} авт. без восстановления.",
      confirmLabel: "Стереть",
    );
    if (ok) await notifier.hardDeleteSelected();
  }

  Future<void> _confirmRestoreSelected(AuthorListNotifier notifier) async {
    final count = notifier.selectedItems.where((a) => a.isDeleted).length;
    final ok = await confirmAction(
      context,
      title: "Восстановить?",
      message: "Вернуть из корзины выбранных авторов: $count.",
      confirmLabel: "Восстановить",
    );
    if (ok) await notifier.restoreSelected();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = context.watch<AuthorListNotifier>();
    final catalog = context.watch<CatalogNotifier>();
    final query = notifier.query;
    final useCards = useCardListOf(context);

    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Text("Авторы", style: theme.textTheme.headlineSmall),
            ),
            FilledButton.icon(
              onPressed: () => context.go("/authors/new"),
              icon: const Icon(Icons.add),
              label: const Text("Добавить"),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: "Фамилия или страна",
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: "Очистить",
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      _replaceQuery(query.copyWith(search: ""));
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
              width: 220,
              child: DropdownButtonFormField<String?>(
                key: ValueKey('country-${query.country}'),
                initialValue: query.country,
                isExpanded: true,
                decoration: const InputDecoration(labelText: "Страна"),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text("Все страны"),
                  ),
                  for (final c in catalog.countries)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (value) =>
                    _replaceQuery(query.copyWith(country: value)),
              ),
            ),
            FilterChip(
              label: const Text("Удалённые"),
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
                Text("Выбрано: ${notifier.selected.length}"),
                if (notifier.selectionHasActive)
                  FilledButton.tonalIcon(
                    onPressed: () => _confirmSoftDeleteSelected(notifier),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text("В корзину"),
                  ),
                if (notifier.selectionHasDeleted)
                  FilledButton.tonalIcon(
                    onPressed: () => _confirmRestoreSelected(notifier),
                    icon: const Icon(Icons.restore),
                    label: const Text("Восстановить"),
                  ),
                FilledButton.icon(
                  onPressed: () => _confirmHardDeleteSelected(notifier),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text("Удалить навсегда"),
                ),
                TextButton(
                  onPressed: notifier.clearSelection,
                  child: const Text("Снять выделение"),
                ),
              ],
            ),
          ),
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

  Widget _buildBody(
    BuildContext context,
    AuthorListNotifier notifier,
    bool useCards,
  ) {
    switch (notifier.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(
          message: notifier.error ?? "Неизвестная ошибка",
          onRetry: notifier.load,
        );
      case LoadStatus.success:
        if (notifier.result.items.isEmpty) {
          return const EmptyView(
            message: "Авторы не найдены",
            hint: "Измените строку поиска или фильтр страны.",
          );
        }
        if (useCards) {
          return Column(
            children: [
              for (final author in notifier.result.items) ...[
                _AuthorCard(
                  author: author,
                  selected: notifier.selected.contains(author.id),
                  onToggle: () => notifier.toggleSelection(author.id),
                  onOpen: () => context.go("/authors/${author.id}"),
                  onSoftDelete: () => notifier.softDelete(author.id),
                  onHardDelete: () async {
                    final ok = await confirmAction(
                      context,
                      title: "Удалить навсегда?",
                      message:
                          "Автор «${author.fullName}» будет стёрт без восстановления.",
                      confirmLabel: "Стереть",
                    );
                    if (ok) await notifier.hardDelete(author.id);
                  },
                  onRestore: () => notifier.restore(author.id),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        }
        return EntityTable<Author>(
          columns: [
            TableColumnSpec(
              label: "Фамилия",
              sortField: "lastName",
              build: (a) => Text(
                a.lastName,
                style: TextStyle(
                  decoration:
                      a.isDeleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            TableColumnSpec(
              label: "Имя",
              sortField: "firstName",
              build: (a) => Text(a.firstName),
            ),
            TableColumnSpec(
              label: "Страна",
              sortField: "country",
              build: (a) => Text(a.country),
            ),
            TableColumnSpec(
              label: "Год рожд.",
              sortField: "birthYear",
              numeric: true,
              build: (a) => Text("${a.birthYear}"),
            ),
          ],
          items: notifier.result.items,
          idOf: (a) => a.id,
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
          onRowTap: (author) => context.go("/authors/${author.id}"),
          actions: (author) => [
            IconButton(
              tooltip: "Открыть",
              icon: const Icon(Icons.open_in_new, size: 20),
              onPressed: () => context.go("/authors/${author.id}"),
            ),
            IconButton(
              tooltip: "Изменить",
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => context.go("/authors/${author.id}/edit"),
            ),
            if (author.isDeleted)
              IconButton(
                tooltip: "Восстановить",
                icon: const Icon(Icons.restore, size: 20),
                onPressed: () => notifier.restore(author.id),
              )
            else ...[
              IconButton(
                tooltip: "В корзину",
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => notifier.softDelete(author.id),
              ),
              IconButton(
                tooltip: "Удалить навсегда",
                icon: const Icon(Icons.delete_forever_outlined, size: 20),
                onPressed: () async {
                  final ok = await confirmAction(
                    context,
                    title: "Удалить навсегда?",
                    message:
                        "Автор «${author.fullName}» будет стёрт без восстановления.",
                    confirmLabel: "Стереть",
                  );
                  if (ok) await notifier.hardDelete(author.id);
                },
              ),
            ],
          ],
        );
    }
  }
}

class _AuthorCard extends StatelessWidget {
  const _AuthorCard({
    required this.author,
    required this.selected,
    required this.onToggle,
    required this.onOpen,
    required this.onSoftDelete,
    required this.onHardDelete,
    required this.onRestore,
  });

  final Author author;
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
          author.fullName,
          style: TextStyle(
            decoration: author.isDeleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text("${author.country} · ${author.birthYear}"),
        onTap: onOpen,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case "open":
                onOpen();
              case "soft":
                onSoftDelete();
              case "hard":
                onHardDelete();
              case "restore":
                onRestore();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: "open", child: Text("Открыть")),
            if (author.isDeleted)
              const PopupMenuItem(
                value: "restore",
                child: Text("Восстановить"),
              )
            else ...[
              const PopupMenuItem(value: "soft", child: Text("В корзину")),
              const PopupMenuItem(
                value: "hard",
                child: Text("Удалить навсегда"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}