import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Книги', '/books', Icons.menu_book_outlined),
      ('Авторы', '/authors', Icons.people_outline),
      ('Жанры', '/genres', Icons.category_outlined),
      ('Издательства', '/publishers', Icons.business_outlined),
      ('Читатели', '/readers', Icons.badge_outlined),
    ];

    return ListView(
      children: [
        Text('Библиотека', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                ListTile(
                  leading: Icon(items[i].$3),
                  title: Text(items[i].$1),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(items[i].$2),
                ),
                if (i != items.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
