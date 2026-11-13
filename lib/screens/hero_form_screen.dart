import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dota_hero.dart';
import '../repositories/hero_repository.dart';
import '../state/hero_list_notifier.dart';
import '../widgets/entity_form.dart';
import '../widgets/state_views.dart';

class HeroFormScreen extends StatefulWidget {
  const HeroFormScreen({super.key, this.id});

  final int? id;
  bool get isEditing => id != null;

  @override
  State<HeroFormScreen> createState() => _HeroFormScreenState();
}

class _HeroFormScreenState extends State<HeroFormScreen> {
  Future<DotaHero?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= widget.isEditing
        ? context.read<HeroRepository>().findById(widget.id!)
        : Future.value(null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DotaHero?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (widget.isEditing && snap.data == null) {
          return const EmptyView(message: 'Герой не найден');
        }
        final h = snap.data;
        return EntityForm(
          title: widget.isEditing ? 'Редактирование героя' : 'Новый герой',
          initialValues: {
            'name': h?.name ?? '',
            'primaryAttribute': h?.primaryAttribute ?? 'Сила',
            'attackType': h?.attackType ?? 'Ближний',
          },
          fields: const [
            EntityFieldSpec(
              key: 'name',
              label: 'Имя',
              type: EntityFieldType.text,
            ),
            EntityFieldSpec(
              key: 'primaryAttribute',
              label: 'Основной атрибут',
              type: EntityFieldType.text,
            ),
            EntityFieldSpec(
              key: 'attackType',
              label: 'Тип атаки',
              type: EntityFieldType.text,
            ),
          ],
          onSubmit: (values) async {
            final repo = context.read<HeroRepository>();
            final hero = DotaHero(
              id: h?.id ?? 0,
              name: '${values['name']}'.trim(),
              primaryAttribute: '${values['primaryAttribute']}'.trim(),
              attackType: '${values['attackType']}'.trim(),
              deletedAt: h?.deletedAt,
            );
            if (widget.isEditing) {
              await repo.update(hero);
            } else {
              await repo.create(hero);
            }
            if (context.mounted) {
              await context.read<HeroListNotifier>().load();
            }
            return FormSubmitResult.ok;
          },
        );
      },
    );
  }
}
