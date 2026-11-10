import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../core/validators.dart";
import "../models/publisher.dart";
import "../repositories/publisher_repository.dart";
import "../state/publisher_list_notifier.dart";
import "../widgets/entity_form.dart";
import "../widgets/state_views.dart";

class PublisherFormScreen extends StatefulWidget {
  const PublisherFormScreen({super.key, this.id});
  final int? id;
  bool get isEditing => id != null;

  @override
  State<PublisherFormScreen> createState() => _PublisherFormScreenState();
}

class _PublisherFormScreenState extends State<PublisherFormScreen> {
  Future<Publisher?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= widget.isEditing
        ? context.read<PublisherRepository>().findById(widget.id!)
        : Future.value(null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Publisher?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (widget.isEditing && snap.data == null) {
          return const EmptyView(message: "Издательство не найдено");
        }
        final p = snap.data;
        return EntityForm(
          title: widget.isEditing
              ? "Редактирование издательства"
              : "Новое издательство",
          initialValues: {
            "name": p?.name ?? "",
            "city": p?.city ?? "",
            "country": p?.country ?? "Россия",
          },
          fields: [
            EntityFieldSpec(
              key: "name",
              label: "Название",
              type: EntityFieldType.text,
              stringValidator: (v) => Validators.combine(v, [
                (x) => Validators.required(x, label: "Название"),
                (x) => Validators.maxLength(x, 120, label: "Название"),
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
              key: "city",
              label: "Город",
              type: EntityFieldType.text,
              stringValidator: (v) => Validators.combine(v, [
                (x) => Validators.required(x, label: "Город"),
                (x) => Validators.maxLength(x, 80, label: "Город"),
              ]),
            ),
          ],
          onSubmit: (values) async {
            final repo = context.read<PublisherRepository>();
            final publisher = Publisher(
              id: p?.id ?? 0,
              name: "${values["name"]}".trim(),
              city: "${values["city"]}".trim(),
              country: "${values["country"]}".trim(),
              deletedAt: p?.deletedAt,
            );
            if (widget.isEditing) {
              await repo.update(publisher);
            } else {
              await repo.create(publisher);
            }
            if (context.mounted) {
              await context.read<PublisherListNotifier>().load();
            }
            return FormSubmitResult.ok;
          },
        );
      },
    );
  }
}