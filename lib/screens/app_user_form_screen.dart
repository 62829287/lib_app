import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../models/steam_profile.dart';
import '../repositories/app_user_repository.dart';
import '../state/app_user_list_notifier.dart';
import '../widgets/entity_form.dart';
import '../widgets/state_views.dart';

class AppUserFormScreen extends StatefulWidget {
  const AppUserFormScreen({super.key, this.id});

  final int? id;
  bool get isEditing => id != null;

  @override
  State<AppUserFormScreen> createState() => _AppUserFormScreenState();
}

class _AppUserFormScreenState extends State<AppUserFormScreen> {
  Future<AppUser?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= widget.isEditing
        ? context.read<AppUserRepository>().findById(widget.id!)
        : Future.value(null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (widget.isEditing && snap.data == null) {
          return const EmptyView(message: 'Пользователь не найден');
        }
        final u = snap.data;
        return EntityForm(
          title: widget.isEditing
              ? 'Редактирование пользователя'
              : 'Новый пользователь',
          initialValues: {
            'nickname': u?.nickname ?? '',
            'email': u?.email ?? '',
            'region': u?.region ?? '',
            'steamUrl': u?.steam.url ?? '',
            'steamNickname': u?.steam.nickname ?? '',
            'steamRating': '${u?.steam.rating ?? 0}',
          },
          fields: const [
            EntityFieldSpec(
              key: 'nickname',
              label: 'Ник',
              type: EntityFieldType.text,
            ),
            EntityFieldSpec(
              key: 'email',
              label: 'Email',
              type: EntityFieldType.email,
            ),
            EntityFieldSpec(
              key: 'region',
              label: 'Регион',
              type: EntityFieldType.text,
            ),
            EntityFieldSpec(
              key: 'steamUrl',
              label: 'URL профиля',
              type: EntityFieldType.text,
              group: 'steam',
              groupTitle: 'Steam-профиль',
            ),
            EntityFieldSpec(
              key: 'steamNickname',
              label: 'Ник в Steam',
              type: EntityFieldType.text,
              group: 'steam',
              groupTitle: 'Steam-профиль',
            ),
            EntityFieldSpec(
              key: 'steamRating',
              label: 'Рейтинг Steam',
              type: EntityFieldType.number,
              group: 'steam',
              groupTitle: 'Steam-профиль',
            ),
          ],
          onSubmit: (values) async {
            final repo = context.read<AppUserRepository>();
            final user = AppUser(
              id: u?.id ?? 0,
              nickname: '${values['nickname']}'.trim(),
              email: '${values['email']}'.trim(),
              region: '${values['region']}'.trim(),
              steam: SteamProfile(
                url: '${values['steamUrl']}'.trim(),
                nickname: '${values['steamNickname']}'.trim(),
                rating: int.tryParse('${values['steamRating']}'.trim()) ?? -1,
              ),
              deletedAt: u?.deletedAt,
            );

            if (widget.isEditing) {
              await repo.update(user);
            } else {
              await repo.create(user);
            }
            if (context.mounted) {
              await context.read<AppUserListNotifier>().load();
            }
            return FormSubmitResult.ok;
          },
        );
      },
    );
  }
}
