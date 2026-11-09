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

class EntityTable<T> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showSelect = onToggleSelect != null;
    final showActions = actions != null;

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.sizeOf(context).width > 600
                ? MediaQuery.sizeOf(context).width - 320
                : 720,
          ),
          child: DataTable(
            showCheckboxColumn: showSelect,
            headingRowColor: WidgetStatePropertyAll(
              theme.dataTableTheme.headingRowColor?.resolve({}) ??
                  const Color(0xFFF2F4F7),
            ),
            columns: [
              for (final column in columns)
                DataColumn(
                  numeric: column.numeric,
                  onSort: column.sortField == null || onSort == null
                      ? null
                      : (columnIndex, ascending) =>
                          onSort!(column.sortField!),
                  label: _SortHeader(
                    label: column.label,
                    active: sortField == column.sortField,
                    ascending: sortAscending,
                    sortable: column.sortField != null && onSort != null,
                  ),
                ),
              if (showActions)
                const DataColumn(label: Text('Действия')),
            ],
            rows: [
              for (final item in items)
                DataRow(
                  selected: selected.contains(idOf(item)),
                  onSelectChanged: showSelect
                      ? (_) => onToggleSelect!(idOf(item))
                      : (onRowTap == null ? null : (_) => onRowTap!(item)),
                  cells: [
                    for (final column in columns) DataCell(column.build(item)),
                    if (showActions)
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions!(item),
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
