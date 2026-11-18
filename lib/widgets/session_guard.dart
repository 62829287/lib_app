import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_notifier.dart';
import 'inactivity_watcher.dart';

class SessionGuard extends StatefulWidget {
  const SessionGuard({super.key, required this.child});

  final Widget child;

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard> {
  Timer? _sessionTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthNotifier>();
    _sessionTimer?.cancel();
    if (!auth.isAuthenticated || auth.sessionStartedAt == null) return;

    final elapsed = DateTime.now().difference(auth.sessionStartedAt!);
    final left = AuthNotifier.sessionMaxDuration - elapsed;
    if (left <= Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _endSession('Сессия истекла по времени. Войдите снова.');
      });
      return;
    }
    _sessionTimer = Timer(left, () {
      if (!mounted) return;
      _endSession('Сессия истекла по времени. Войдите снова.');
    });
  }

  Future<void> _endSession(String message) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    await context.read<AuthNotifier>().logout();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    return InactivityWatcher(
      enabled: auth.isAuthenticated,
      timeout: AuthNotifier.inactivityTimeout,
      warningBefore: AuthNotifier.inactivityWarning,
      onWarning: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Вы будете выведены из системы через 30 секунд из‑за неактивности.',
            ),
            duration: Duration(seconds: 25),
          ),
        );
      },
      onTimeout: () => _endSession(
        'Сессия завершена из‑за неактивности.',
      ),
      child: widget.child,
    );
  }
}
