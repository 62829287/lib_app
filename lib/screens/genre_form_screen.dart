import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../core/validators.dart";
import "../models/genre.dart";
import "../repositories/genre_repository.dart";
import "../state/genre_list_notifier.dart";
import "../widgets/entity_form.dart";
import "../widgets/state_views.dart";

class GenreFormScreen extends StatefulWidget {
  const GenreFormScreen({super.key, this.id});
  final int? id;
  bool get isEditing => id != null;

  @override
  State<GenreFormScreen> createState() => _GenreFormScreenState();
}

class _GenreFormScreenState extends State<GenreFormScreen> {
  Future<Genre?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= widget.isEditing
        ? context.read<GenreRepository>().findById(widget.id!)
        : Future.value(null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Genre?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (widget.isEditing && snap.data == null) {
          return const EmptyView(message: "Жанр не найден");
        }
        final g = snap.data;
        return EntityForm(
          title: widget.isEditing ? "Редактирование жанра" : "Новый жанр",
          initialValues: {
            "name": g?.name ?? "",
            "description": g?.description ?? "",
          },
          fields: [
            EntityFieldSpec(
              key: "name",
              label: "Название",
              type: EntityFieldType.text,
              stringValidator: (v) => Validators.combine(v, [
                (x) => Validators.required(x, label: "Название"),
                (x) => Validators.maxLength(x, 80, label: "Название"),
              ]),
            ),
            EntityFieldSpec(
              key: "description",
              label: "Описание",
              type: EntityFieldType.multiline,
              maxLines: 3,
              stringValidator: (v) =>
                  Validators.maxLength(v, 500, label: "Описание"),
            ),
          ],
          onSubmit: (values) async {
            final repo = context.read<GenreRepository>();
            final genre = Genre(
              id: g?.id ?? 0,
              name: "${values["name"]}".trim(),
              description: "${values["description"]}".trim(),
              deletedAt: g?.deletedAt,
            );
            if (widget.isEditing) {
              await repo.update(genre);
            } else {
              await repo.create(genre);
            }
            if (context.mounted) {
              await context.read<GenreListNotifier>().load();
            }
            return FormSubmitResult.ok;
          },
        );
      },
    );
  }
}