import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/core/password_rules.dart';
import 'package:library_app/models/auth_role.dart';
import 'package:library_app/widgets/state_views.dart';

void main() {
  group('Состояния интерфейса', () {
    testWidgets('экран загрузки показывает индикатор', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LoadingView())),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('пустой результат показывает сообщение', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EmptyView(message: 'Ничего не найдено')),
        ),
      );
      expect(find.text('Ничего не найдено'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('ошибка показывает текст и кнопку повтора', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'Сервер недоступен',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );
      expect(find.text('Данные не загрузились'), findsOneWidget);
      expect(find.text('Сервер недоступен'), findsOneWidget);
      await tester.tap(find.text('Повторить'));
      expect(retried, isTrue);
    });

    testWidgets('валидация формы срабатывает на слабом пароле', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Пароль'),
                validator: PasswordRules.validate,
              ),
            ),
          ),
        ),
      );
      expect(formKey.currentState!.validate(), isFalse);
      await tester.enterText(find.byType(TextFormField), 'reader123!');
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('кнопка скрыта при недостаточной роли', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                const role = AuthRole.viewer;
                return Column(
                  children: [
                    const Text('Список'),
                    if (Permissions.canEditCatalog(role))
                      FilledButton(
                        onPressed: () {},
                        child: const Text('Добавить'),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      expect(find.text('Список'), findsOneWidget);
      expect(find.text('Добавить'), findsNothing);
    });
  });
}
