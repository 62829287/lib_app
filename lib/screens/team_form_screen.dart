import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/team.dart';
import '../repositories/team_repository.dart';
import '../state/team_list_notifier.dart';
import '../widgets/entity_form.dart';
import '../widgets/state_views.dart';

class TeamFormScreen extends StatefulWidget {
  const TeamFormScreen({super.key, this.id});

  final String? id;
  bool get isEditing => id != null && id!.isNotEmpty;

  @override
  State<TeamFormScreen> createState() => _TeamFormScreenState();
}

class _TeamFormScreenState extends State<TeamFormScreen> {
  Future<Team?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= widget.isEditing
        ? context.read<TeamRepository>().findById(widget.id!)
        : Future.value(null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Team?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (widget.isEditing && snap.data == null) {
          return const EmptyView(message: 'Команда не найдена');
        }
        final t = snap.data;
        return EntityForm(
          title: widget.isEditing ? 'Редактирование команды' : 'Новая команда',
          initialValues: {
            'name': t?.name ?? '',
            'tag': t?.tag ?? '',
            'region': t?.region ?? '',
            'description': t?.description ?? '',
          },
          fields: const [
            EntityFieldSpec(
              key: 'name',
              label: 'Название',
              type: EntityFieldType.text,
            ),
            EntityFieldSpec(
              key: 'tag',
              label: 'Тег',
              type: EntityFieldType.text,
            ),
            EntityFieldSpec(
              key: 'region',
              label: 'Регион',
              type: EntityFieldType.text,
            ),
            EntityFieldSpec(
              key: 'description',
              label: 'Описание',
              type: EntityFieldType.multiline,
              maxLines: 3,
            ),
          ],
          onSubmit: (values) async {
            final repo = context.read<TeamRepository>();
            final team = Team(
              id: t?.id ?? '',
              name: '${values['name']}'.trim(),
              tag: '${values['tag']}'.trim(),
              region: '${values['region']}'.trim(),
              description: '${values['description']}'.trim(),
              deletedAt: t?.deletedAt,
            );
            if (widget.isEditing) {
              await repo.update(team);
            } else {
              await repo.create(team);
            }
            if (context.mounted) {
              await context.read<TeamListNotifier>().load();
            }
            return FormSubmitResult.ok;
          },
        );
      },
    );
  }
}