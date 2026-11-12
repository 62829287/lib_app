import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/pro_player.dart';
import '../repositories/pro_player_repository.dart';
import '../state/pro_player_list_notifier.dart';
import '../widgets/entity_form.dart';
import '../widgets/state_views.dart';

class ProPlayerFormScreen extends StatefulWidget {
  const ProPlayerFormScreen({super.key, this.id});

  final int? id;
  bool get isEditing => id != null;

  @override
  State<ProPlayerFormScreen> createState() => _ProPlayerFormScreenState();
}

class _ProPlayerFormScreenState extends State<ProPlayerFormScreen> {
  Future<ProPlayer?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= widget.isEditing
        ? context.read<ProPlayerRepository>().findById(widget.id!)
        : Future.value(null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProPlayer?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (widget.isEditing && snap.data == null) {
          return const EmptyView(message: 'Про-игрок не найден');
        }
        final p = snap.data;
        return EntityForm(
          title: widget.isEditing
              ? 'Редактирование про-игрока'
              : 'Новый про-игрок',
          initialValues: {
            'nickname': p?.nickname ?? '',
            'realName': p?.realName ?? '',
            'team': p?.team ?? '',
            'rating': '${p?.rating ?? 1000}',
            'country': p?.country ?? 'Россия',
          },
          fields: [
            EntityFieldSpec(
              key: 'nickname',
              label: 'Ник',
              type: EntityFieldType.text,
              stringValidator: (v) => Validators.combine(v, [
                (x) => Validators.required(x, label: 'Ник'),
                (x) => Validators.maxLength(x, 80, label: 'Ник'),
              ]),
            ),
            EntityFieldSpec(
              key: 'realName',
              label: 'Настоящее имя',
              type: EntityFieldType.text,
              stringValidator: (v) => Validators.combine(v, [
                (x) => Validators.required(x, label: 'Имя'),
                (x) => Validators.maxLength(x, 80, label: 'Имя'),
              ]),
            ),
            EntityFieldSpec(
              key: 'team',
              label: 'Команда',
              type: EntityFieldType.text,
              stringValidator: (v) => Validators.combine(v, [
                (x) => Validators.required(x, label: 'Команда'),
                (x) => Validators.maxLength(x, 80, label: 'Команда'),
              ]),
            ),
            EntityFieldSpec(
              key: 'rating',
              label: 'Рейтинг',
              type: EntityFieldType.number,
              stringValidator: (v) =>
                  Validators.positiveInt(v, label: 'Рейтинг'),
            ),
            EntityFieldSpec(
              key: 'country',
              label: 'Страна',
              type: EntityFieldType.text,
              stringValidator: (v) => Validators.combine(v, [
                (x) => Validators.required(x, label: 'Страна'),
                (x) => Validators.maxLength(x, 80, label: 'Страна'),
              ]),
            ),
          ],
          onSubmit: (values) async {
            final repo = context.read<ProPlayerRepository>();
            final player = ProPlayer(
              id: p?.id ?? 0,
              nickname: '${values['nickname']}'.trim(),
              realName: '${values['realName']}'.trim(),
              team: '${values['team']}'.trim(),
              rating: int.parse('${values['rating']}'.trim()),
              country: '${values['country']}'.trim(),
              deletedAt: p?.deletedAt,
            );
            if (widget.isEditing) {
              await repo.update(player);
            } else {
              await repo.create(player);
            }
            if (context.mounted) {
              await context.read<ProPlayerListNotifier>().load();
            }
            return FormSubmitResult.ok;
          },
        );
      },
    );
  }
}
