import 'package:flutter/material.dart';

import '../widgets/state_views.dart';
import 'auth_accounts_screen.dart' deferred as accounts;
import 'app_user_list_screen.dart' deferred as users;

class DeferredAuthAccountsScreen extends StatefulWidget {
  const DeferredAuthAccountsScreen({super.key});

  @override
  State<DeferredAuthAccountsScreen> createState() =>
      _DeferredAuthAccountsScreenState();
}

class _DeferredAuthAccountsScreenState
    extends State<DeferredAuthAccountsScreen> {
  late final Future<void> _loading = accounts.loadLibrary();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loading,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (snap.hasError) {
          return ErrorView(
            message: '${snap.error}',
            onRetry: () => setState(() {}),
          );
        }
        return accounts.AuthAccountsScreen();
      },
    );
  }
}

class DeferredAppUserListScreen extends StatefulWidget {
  const DeferredAppUserListScreen({super.key});

  @override
  State<DeferredAppUserListScreen> createState() =>
      _DeferredAppUserListScreenState();
}

class _DeferredAppUserListScreenState extends State<DeferredAppUserListScreen> {
  late final Future<void> _loading = users.loadLibrary();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loading,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (snap.hasError) {
          return ErrorView(
            message: '${snap.error}',
            onRetry: () => setState(() {}),
          );
        }
        return users.AppUserListScreen();
      },
    );
  }
}
