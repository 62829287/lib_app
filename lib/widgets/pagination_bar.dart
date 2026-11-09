import 'package:flutter/material.dart';

import '../models/page_result.dart';

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.result,
    required this.pageSize,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final PageResult<dynamic> result;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  static const pageSizes = [10, 25, 50];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(
          'Всего: ${result.total}',
          style: theme.textTheme.bodyMedium,
        ),
        Text(
          'Стр. ${result.page} из ${result.totalPages}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        IconButton(
          tooltip: 'Первая страница',
          onPressed: result.hasPrevious ? () => onPageChanged(1) : null,
          icon: const Icon(Icons.first_page),
        ),
        IconButton(
          tooltip: 'Предыдущая',
          onPressed: result.hasPrevious
              ? () => onPageChanged(result.page - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          tooltip: 'Следующая',
          onPressed:
              result.hasNext ? () => onPageChanged(result.page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
        IconButton(
          tooltip: 'Последняя страница',
          onPressed: result.hasNext
              ? () => onPageChanged(result.totalPages)
              : null,
          icon: const Icon(Icons.last_page),
        ),
        const SizedBox(width: 8),
        Text('На странице:', style: theme.textTheme.bodyMedium),
        DropdownButton<int>(
          value: pageSize,
          items: [
            for (final size in pageSizes)
              DropdownMenuItem(value: size, child: Text('$size')),
          ],
          onChanged: (value) {
            if (value != null) onPageSizeChanged(value);
          },
        ),
      ],
    );
  }
}
