import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/password_rules.dart';
import '../state/auth_notifier.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;
  String _passwordLive = '';

  @override
  void initState() {
    super.initState();
    _password.addListener(() {
      setState(() => _passwordLive = _password.text);
    });
  }

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthNotifier>().register(
        username: _username.text,
        displayName: _displayName.text,
        password: _password.text,
      );
      if (!mounted) return;
      context.go('/');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Не удалось зарегистрироваться.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Регистрация', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Новый аккаунт получает роль «Читатель».',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _username,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Логин',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return 'Введите логин';
                        if (t.length < 3) return 'Не меньше 3 символов';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _displayName,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Отображаемое имя',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Введите имя'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscure
                              ? 'Показать пароль'
                              : 'Скрыть пароль',
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: PasswordRules.validate,
                    ),
                    const SizedBox(height: 12),
                    _PasswordChecklist(value: _passwordLive),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Зарегистрироваться'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : () => context.go('/login'),
                      child: const Text('Уже есть аккаунт'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordChecklist extends StatelessWidget {
  const _PasswordChecklist({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Не меньше ${PasswordRules.minLength} символов',
        PasswordRules.hasMinLength(value),
      ),
      ('Есть цифра', PasswordRules.hasDigit(value)),
      ('Есть спецсимвол', PasswordRules.hasSpecial(value)),
    ];
    return Column(
      children: [
        for (final item in items)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              item.$2 ? Icons.check_circle : Icons.radio_button_unchecked,
              color: item.$2
                  ? Colors.green.shade700
                  : Theme.of(context).colorScheme.outline,
              size: 20,
            ),
            title: Text(item.$1, style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }
}
