import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/auth_notifier.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final items = <(String, String, IconData)>[
      ('Сборки', '/builds', Icons.construction_outlined),
      if (auth.canBrowsePros())
        ('Про-игроки', '/pros', Icons.sports_esports_outlined),
      if (auth.canBrowseReferenceData()) ...[
        ('Роли', '/roles', Icons.category_outlined),
        ('Герои', '/heroes', Icons.shield_outlined),
      ],
      if (auth.canManageUsers()) ...[
        ('Учётные записи', '/accounts', Icons.manage_accounts_outlined),
        ('Пользователи', '/users', Icons.person_outline),
      ],
    ];

    return ListView(
      children: [
        Text('Dota Builds', style: Theme.of(context).textTheme.headlineSmall),
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
