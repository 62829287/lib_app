import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatefulWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;
  final ValueChanged<T>? onRowTap;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
    this.onRowTap,
  });

  @override
  State<EntityTable<T>> createState() => _EntityTableState<T>();
}

class _EntityTableState<T> extends State<EntityTable<T>> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showSelect = widget.onToggleSelect != null;
    final showActions = widget.actions != null;

    return Scrollbar(
      controller: _scroll,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.sizeOf(context).width > 600
                ? MediaQuery.sizeOf(context).width - 280
                : (showActions ? 980 : 720),
          ),
          child: DataTable(
            showCheckboxColumn: showSelect,
            headingRowColor: WidgetStatePropertyAll(
              theme.dataTableTheme.headingRowColor?.resolve({}) ??
                  const Color(0xFFF2F4F7),
            ),
            columns: [
              for (final column in widget.columns)
                DataColumn(
                  numeric: column.numeric,
                  onSort: column.sortField == null || widget.onSort == null
                      ? null
                      : (columnIndex, ascending) =>
                          widget.onSort!(column.sortField!),
                  label: _SortHeader(
                    label: column.label,
                    active: widget.sortField == column.sortField,
                    ascending: widget.sortAscending,
                    sortable:
                        column.sortField != null && widget.onSort != null,
                  ),
                ),
              if (showActions)
                const DataColumn(label: Text('Действия')),
            ],
            rows: [
              for (final item in widget.items)
                DataRow(
                  selected: widget.selected.contains(widget.idOf(item)),
                  onSelectChanged: showSelect
                      ? (_) => widget.onToggleSelect!(widget.idOf(item))
                      : (widget.onRowTap == null
                          ? null
                          : (_) => widget.onRowTap!(item)),
                  cells: [
                    for (final column in widget.columns)
                      DataCell(column.build(item)),
                    if (showActions)
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: widget.actions!(item),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortHeader extends StatelessWidget {
  const _SortHeader({
    required this.label,
    required this.active,
    required this.ascending,
    required this.sortable,
  });

  final String label;
  final bool active;
  final bool ascending;
  final bool sortable;

  @override
  Widget build(BuildContext context) {
    if (!sortable) return Text(label);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(width: 4),
        Icon(
          active
              ? (ascending ? Icons.arrow_upward : Icons.arrow_downward)
              : Icons.unfold_more,
          size: 16,
          color: active
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}
