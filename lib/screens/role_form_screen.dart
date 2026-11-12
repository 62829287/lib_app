import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/role.dart';
import '../repositories/role_repository.dart';
import '../state/role_list_notifier.dart';
import '../widgets/entity_form.dart';
import '../widgets/state_views.dart';

class RoleFormScreen extends StatefulWidget {
  const RoleFormScreen({super.key, this.id});

  final int? id;
  bool get isEditing => id != null;

  @override
  State<RoleFormScreen> createState() => _RoleFormScreenState();
}

class _RoleFormScreenState extends State<RoleFormScreen> {
  Future<Role?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= widget.isEditing
        ? context.read<RoleRepository>().findById(widget.id!)
        : Future.value(null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Role?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (widget.isEditing && snap.data == null) {
          return const EmptyView(message: 'Роль не найдена');
        }
        final r = snap.data;
        return EntityForm(
          title: widget.isEditing ? 'Редактирование роли' : 'Новая роль',
          initialValues: {
            'name': r?.name ?? '',
            'description': r?.description ?? '',
          },
          fields: [
            EntityFieldSpec(
              key: 'name',
              label: 'Название',
              type: EntityFieldType.text,
              stringValidator: (v) => Validators.combine(v, [
                (x) => Validators.required(x, label: 'Название'),
                (x) => Validators.maxLength(x, 80, label: 'Название'),
              ]),
            ),
            EntityFieldSpec(
              key: 'description',
              label: 'Описание',
              type: EntityFieldType.multiline,
              maxLines: 3,
              stringValidator: (v) =>
                  Validators.maxLength(v, 500, label: 'Описание'),
            ),
          ],
          onSubmit: (values) async {
            final repo = context.read<RoleRepository>();
            final role = Role(
              id: r?.id ?? 0,
              name: '${values['name']}'.trim(),
              description: '${values['description']}'.trim(),
              deletedAt: r?.deletedAt,
            );
            if (widget.isEditing) {
              await repo.update(role);
            } else {
              await repo.create(role);
            }
            if (context.mounted) {
              await context.read<RoleListNotifier>().load();
            }
            return FormSubmitResult.ok;
          },
        );
      },
    );
  }
}
