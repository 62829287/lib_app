import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../state/auth_notifier.dart';
import '../state/catalog_notifier.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthNotifier>();
    if (auth.isAuthenticated) {
      context.read<CatalogNotifier>().recoverIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final sections = _sectionsFor(auth);
    final layout = layoutSizeOf(context);
    final location = GoRouterState.of(context).uri.path;
    final selected = _sectionIndex(sections, location);
    final userLabel = auth.user?.displayName ?? auth.user?.username ?? '';

    if (layout == LayoutSize.compact) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dota Builds'),
          actions: [
            if (userLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Text(userLabel, style: const TextStyle(fontSize: 14)),
                ),
              ),
            IconButton(
              tooltip: 'Выйти',
              onPressed: () => auth.logout(),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: _Content(child: widget.child),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selected.clamp(0, sections.length - 1),
          onDestinationSelected: (index) => context.go(sections[index].path),
          destinations: [
            for (final section in sections)
              NavigationDestination(
                icon: Icon(section.icon),
                label: section.title,
                tooltip: section.title,
              ),
          ],
        ),
      );
    }

    final extended = layout == LayoutSize.expanded;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            selectedIndex: selected < 0 ? 0 : selected,
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  const Icon(
                    Icons.sports_esports,
                    size: 28,
                    semanticLabel: 'Dota Builds',
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: extended ? 120 : 72,
                    child: Text(
                      userLabel,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  Text(
                    auth.user?.role.label ?? '',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            trailing: IconButton(
              tooltip: 'Выйти',
              onPressed: () => auth.logout(),
              icon: const Icon(Icons.logout),
            ),
            onDestinationSelected: (index) => context.go(sections[index].path),
            destinations: [
              for (final section in sections)
                NavigationRailDestination(
                  icon: Icon(section.icon, semanticLabel: section.title),
                  label: Text(section.title),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _Content(child: widget.child)),
        ],
      ),
    );
  }

  List<_Section> _sectionsFor(AuthNotifier auth) {
    final list = <_Section>[
      const _Section('Обзор', '/', Icons.home_outlined),
      const _Section('Сборки', '/builds', Icons.construction_outlined),
    ];
    if (auth.canBrowsePros()) {
      list.add(
        const _Section('Про-игроки', '/pros', Icons.sports_esports_outlined),
      );
    }
    if (auth.canBrowseReferenceData()) {
      list.addAll(const [
        _Section('Роли', '/roles', Icons.category_outlined),
        _Section('Команды', '/teams', Icons.groups),
        _Section('Герои', '/heroes', Icons.shield_outlined),
      ]);
    }
    if (auth.canManageUsers()) {
      list.addAll(const [
        _Section('Учётные записи', '/accounts', Icons.manage_accounts_outlined),
        _Section('Пользователи', '/users', Icons.person_outline),
      ]);
    }
    return list;
  }

  int _sectionIndex(List<_Section> sections, String location) {
    for (var i = sections.length - 1; i >= 0; i--) {
      final path = sections[i].path;
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
          child: Padding(padding: const EdgeInsets.all(20), child: child),
        ),
      ),
    );
  }
}
