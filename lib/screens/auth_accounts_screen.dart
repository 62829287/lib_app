import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auth_role.dart';
import '../models/auth_user.dart';
import '../state/auth_accounts_notifier.dart';
import '../state/auth_notifier.dart';
import '../state/load_status.dart';
import '../widgets/api_feedback.dart';
import '../widgets/state_views.dart';

class AuthAccountsScreen extends StatefulWidget {
  const AuthAccountsScreen({super.key});

  @override
  State<AuthAccountsScreen> createState() => _AuthAccountsScreenState();
}

class _AuthAccountsScreenState extends State<AuthAccountsScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthAccountsNotifier>().load();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _changeRole(AuthUser user, AuthRole? next) async {
    if (next == null || next == user.role) return;
    final auth = context.read<AuthNotifier>();
    await runApiAction(context, () async {
      final updated = await context.read<AuthAccountsNotifier>().updateRole(
        user.id,
        next.key,
      );
      if (auth.user?.id == updated.id) {
        await auth.applyLocalUser(updated);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Роль «${updated.username}» → ${updated.role.label}'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<AuthAccountsNotifier>();
    final selfId = context.watch<AuthNotifier>().user?.id;

    return ListView(
      children: [
        Text(
          'Учётные записи',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          decoration: const InputDecoration(
            hintText: 'Логин, имя или роль',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 350), () {
              context.read<AuthAccountsNotifier>().load(search: v);
            });
          },
        ),
        const SizedBox(height: 16),
        _body(n, selfId),
      ],
    );
  }

  Widget _body(AuthAccountsNotifier n, int? selfId) {
    switch (n.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(message: n.error ?? '', onRetry: () => n.load());
      case LoadStatus.success:
        if (n.items.isEmpty) {
          return const EmptyView(message: 'Учётные записи не найдены');
        }
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < n.items.length; i++) ...[
                _AccountTile(
                  user: n.items[i],
                  isSelf: n.items[i].id == selfId,
                  onRoleChanged: (role) => _changeRole(n.items[i], role),
                ),
                if (i != n.items.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        );
    }
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.user,
    required this.isSelf,
    required this.onRoleChanged,
  });

  final AuthUser user;
  final bool isSelf;
  final ValueChanged<AuthRole?> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          user.displayName.isNotEmpty
              ? user.displayName.substring(0, 1).toUpperCase()
              : '?',
        ),
      ),
      title: Text(user.displayName),
      subtitle: Text([user.username, if (isSelf) 'это вы'].join(' · ')),
      trailing: SizedBox(
        width: 160,
        child: DropdownButtonFormField<AuthRole>(
          key: ValueKey('role-${user.id}-${user.role.key}'),
          initialValue: user.role,
          isExpanded: true,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            for (final role in AuthRole.values)
              DropdownMenuItem(value: role, child: Text(role.label)),
          ],
          onChanged: onRoleChanged,
        ),
      ),
    );
  }
}
