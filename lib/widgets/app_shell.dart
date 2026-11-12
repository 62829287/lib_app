import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/breakpoints.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const List<_Section> _sections = [
    _Section('Обзор', '/', Icons.home_outlined),
    _Section('Сборки', '/builds', Icons.construction_outlined),
    _Section('Про-игроки', '/pros', Icons.sports_esports_outlined),
    _Section('Роли', '/roles', Icons.category_outlined),
    _Section('Герои', '/heroes', Icons.shield_outlined),
    _Section('Пользователи', '/users', Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final compact = layoutSizeOf(context) == LayoutSize.compact;
    final location = GoRouterState.of(context).uri.path;
    final selected = _sectionIndex(location);

    if (compact) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dota Builds')),
        drawer: NavigationDrawer(
          selectedIndex: selected,
          onDestinationSelected: (index) {
            Navigator.of(context).pop();
            context.go(_sections[index].path);
          },
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 24, 16, 16),
              child: Text('Меню'),
            ),
            for (final section in _sections)
              NavigationDrawerDestination(
                icon: Icon(section.icon),
                label: Text(section.title),
              ),
          ],
        ),
        body: _Content(child: child),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selected,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (index) =>
                context.go(_sections[index].path),
            destinations: [
              for (final section in _sections)
                NavigationRailDestination(
                  icon: Icon(section.icon),
                  label: Text(section.title),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _Content(child: child)),
        ],
      ),
    );
  }

  static int _sectionIndex(String location) {
    for (var i = _sections.length - 1; i >= 0; i--) {
      final path = _sections[i].path;
      if (path == '/') continue;
      if (location == path || location.startsWith('$path/')) return i;
    }
    return 0;
  }
}

class _Section {
  const _Section(this.title, this.path, this.icon);

  final String title;
  final String path;
  final IconData icon;
}

class _Content extends StatelessWidget {
  const _Content({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Breakpoints.contentMaxWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}
