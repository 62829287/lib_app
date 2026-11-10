import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../core/validators.dart";
import "../models/author.dart";
import "../repositories/author_repository.dart";
import "../state/author_list_notifier.dart";
import "../widgets/entity_form.dart";
import "../widgets/state_views.dart";

class AuthorFormScreen extends StatefulWidget {
  const AuthorFormScreen({super.key, this.id});
  final int? id;
  bool get isEditing => id != null;

  @override
  State<AuthorFormScreen> createState() => _AuthorFormScreenState();
}

class _AuthorFormScreenState extends State<AuthorFormScreen> {
  Future<Author?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= widget.isEditing
        ? context.read<AuthorRepository>().findById(widget.id!)
        : Future.value(null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Author?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (widget.isEditing && snap.data == null) {
          return const EmptyView(message: "Автор не найден");
        }
        final a = snap.data;
        return EntityForm(
          title: widget.isEditing ? "Редактирование автора" : "Новый автор",
          initialValues: {
            "firstName": a?.firstName ?? "",
            "lastName": a?.lastName ?? "",
            "country": a?.country ?? "Россия",
            "birthYear": "${a?.birthYear ?? 1970}",
          },
          fields: [
            EntityFieldSpec(
              key: "firstName",
              label: "Имя",
              type: EntityFieldType.text,
              stringValidator: (v) => Validators.combine(v, [
                (x) => Validators.required(x, label: "Имя"),
                (x) => Validators.maxLength(x, 80, label: "Имя"),
              ]),
            ),
            EntityFieldSpec(
              key: "lastName",
              label: "Фамилия",
              type: EntityFieldType.text,
              stringValidator: (v) => Validators.combine(v, [
                (x) => Validators.required(x, label: "Фамилия"),
                (x) => Validators.maxLength(x, 80, label: "Фамилия"),
              ]),
            ),
            EntityFieldSpec(
              key: "country",
              label: "Страна",
              type: EntityFieldType.text,
              stringValidator: (v) => Validators.combine(v, [
                (x) => Validators.required(x, label: "Страна"),
                (x) => Validators.maxLength(x, 80, label: "Страна"),
              ]),
            ),
            EntityFieldSpec(
              key: "birthYear",
              label: "Год рождения",
              type: EntityFieldType.number,
              stringValidator: (v) => Validators.intInRange(
                v,
                min: 1400,
                max: DateTime.now().year,
                label: "Год рождения",
              ),
            ),
          ],
          onSubmit: (values) async {
            final repo = context.read<AuthorRepository>();
            final author = Author(
              id: a?.id ?? 0,
              firstName: "${values["firstName"]}".trim(),
              lastName: "${values["lastName"]}".trim(),
              country: "${values["country"]}".trim(),
              birthYear: int.parse("${values["birthYear"]}".trim()),
              deletedAt: a?.deletedAt,
            );
            if (widget.isEditing) {
              await repo.update(author);
            } else {
              await repo.create(author);
            }
            if (context.mounted) {
              await context.read<AuthorListNotifier>().load();
            }
            return FormSubmitResult.ok;
          },
        );
      },
    );
  }
}