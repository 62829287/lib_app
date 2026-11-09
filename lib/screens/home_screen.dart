import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text('Библиотека', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('Книги'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/books'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: const Text('Авторы'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/authors'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
