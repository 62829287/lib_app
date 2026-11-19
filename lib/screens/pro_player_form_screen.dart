import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pro_player.dart';
import '../repositories/pro_player_repository.dart';
import '../state/catalog_notifier.dart';
import '../state/pro_player_list_notifier.dart';
import '../widgets/entity_form.dart';
import '../widgets/state_views.dart';

class ProPlayerFormScreen extends StatefulWidget {
  const ProPlayerFormScreen({super.key, this.id});

  final String? id;
  bool get isEditing => id != null && id!.isNotEmpty;

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
    context.read<CatalogNotifier>().recoverIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogNotifier>();

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
        final teams = catalog.teams;
        return EntityForm(
          title: widget.isEditing
              ? 'Редактирование про-игрока'
              : 'Новый про-игрок',
          initialValues: {
            'nickname': p?.nickname ?? '',
            'realName': p?.realName ?? '',
            'teamId': p?.teamId ?? '',
            'rating': '${p?.rating ?? 1000}',
            'country': p?.country ?? 'Россия',
          },
          fields: [
            const EntityFieldSpec(
              key: 'nickname',
              label: 'Ник',
              type: EntityFieldType.text,
            ),
            const EntityFieldSpec(
              key: 'realName',
              label: 'Настоящее имя',
              type: EntityFieldType.text,
            ),
            EntityFieldSpec(
              key: 'teamId',
              label: 'Команда',
              type: EntityFieldType.dropdown,
              dropdownItems: () => [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('— без команды —'),
                ),
                for (final t in teams)
                  DropdownMenuItem<String>(
                    value: t.id,
                    child: Text(t.displayName),
                  ),
              ],
            ),
            const EntityFieldSpec(
              key: 'rating',
              label: 'Рейтинг',
              type: EntityFieldType.number,
            ),
            const EntityFieldSpec(
              key: 'country',
              label: 'Страна',
              type: EntityFieldType.text,
            ),
          ],
          onSubmit: (values) async {
            final repo = context.read<ProPlayerRepository>();
            final player = ProPlayer(
              id: p?.id ?? '',
              nickname: '${values['nickname']}'.trim(),
              realName: '${values['realName']}'.trim(),
              teamId: '${values['teamId'] ?? ''}'.trim(),
              rating: int.tryParse('${values['rating']}'.trim()) ?? -1,
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