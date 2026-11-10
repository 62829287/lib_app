import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../core/validators.dart";
import "../models/library_card.dart";
import "../models/reader.dart";
import "../repositories/reader_repository.dart";
import "../state/reader_list_notifier.dart";
import "../widgets/entity_form.dart";
import "../widgets/state_views.dart";

class ReaderFormScreen extends StatefulWidget {
  const ReaderFormScreen({super.key, this.id});
  final int? id;
  bool get isEditing => id != null;

  @override
  State<ReaderFormScreen> createState() => _ReaderFormScreenState();
}

class _ReaderFormScreenState extends State<ReaderFormScreen> {
  Future<Reader?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= widget.isEditing
        ? context.read<ReaderRepository>().findById(widget.id!)
        : Future.value(null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Reader?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (widget.isEditing && snap.data == null) {
          return const EmptyView(message: "Читатель не найден");
        }
        final r = snap.data;
        final now = DateTime.now();
        final issued = r?.card.issuedAt ?? now;
        final expires = r?.card.expiresAt ?? now.add(const Duration(days: 365 * 3));

        return EntityForm(
          title: widget.isEditing ? "Редактирование читателя" : "Новый читатель",
          initialValues: {
            "firstName": r?.firstName ?? "",
            "lastName": r?.lastName ?? "",
            "email": r?.email ?? "",
            "phone": r?.phone ?? "",
            "cardNumber": r?.card.number ?? "",
            "cardIssued":
                "${issued.year.toString().padLeft(4, "0")}-${issued.month.toString().padLeft(2, "0")}-${issued.day.toString().padLeft(2, "0")}",
            "cardExpires":
                "${expires.year.toString().padLeft(4, "0")}-${expires.month.toString().padLeft(2, "0")}-${expires.day.toString().padLeft(2, "0")}",
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
              key: "email",
              label: "Email",
              type: EntityFieldType.email,
              stringValidator: Validators.email,
            ),
            EntityFieldSpec(
              key: "phone",
              label: "Телефон",
              type: EntityFieldType.text,
              stringValidator: (v) => Validators.combine(v, [
                (x) => Validators.required(x, label: "Телефон"),
                (x) => Validators.maxLength(x, 30, label: "Телефон"),
              ]),
            ),
            EntityFieldSpec(
              key: "cardNumber",
              label: "Номер билета",
              type: EntityFieldType.text,
              group: "card",
              groupTitle: "Читательский билет",
              stringValidator: (v) => Validators.combine(v, [
                (x) => Validators.required(x, label: "Номер билета"),
                (x) => Validators.maxLength(x, 40, label: "Номер билета"),
              ]),
            ),
            EntityFieldSpec(
              key: "cardIssued",
              label: "Билет выдан (ГГГГ-ММ-ДД)",
              type: EntityFieldType.text,
              group: "card",
              groupTitle: "Читательский билет",
              stringValidator: (v) {
                final required = Validators.required(v, label: "Дата выдачи");
                if (required != null) return required;
                if (DateTime.tryParse(v!.trim()) == null) {
                  return "Формат даты: ГГГГ-ММ-ДД";
                }
                return null;
              },
            ),
            EntityFieldSpec(
              key: "cardExpires",
              label: "Билет действует до (ГГГГ-ММ-ДД)",
              type: EntityFieldType.text,
              group: "card",
              groupTitle: "Читательский билет",
              stringValidator: (v) {
                final required = Validators.required(v, label: "Срок билета");
                if (required != null) return required;
                if (DateTime.tryParse(v!.trim()) == null) {
                  return "Формат даты: ГГГГ-ММ-ДД";
                }
                return null;
              },
            ),
          ],
          onSubmit: (values) async {
            final repo = context.read<ReaderRepository>();
            final email = "${values["email"]}".trim();
            if (await repo.emailExists(email, excludingId: r?.id)) {
              return const FormSubmitResult(
                fieldErrors: {"email": "Такой email уже зарегистрирован"},
              );
            }
            final issued = DateTime.parse("${values["cardIssued"]}".trim());
            final expires = DateTime.parse("${values["cardExpires"]}".trim());
            if (!expires.isAfter(issued)) {
              return const FormSubmitResult(
                fieldErrors: {
                  "cardExpires": "Срок действия должен быть позже даты выдачи",
                },
              );
            }

            final reader = Reader(
              id: r?.id ?? 0,
              firstName: "${values["firstName"]}".trim(),
              lastName: "${values["lastName"]}".trim(),
              email: email,
              phone: "${values["phone"]}".trim(),
              card: LibraryCard(
                number: "${values["cardNumber"]}".trim(),
                issuedAt: issued,
                expiresAt: expires,
              ),
              deletedAt: r?.deletedAt,
            );

            if (widget.isEditing) {
              await repo.update(reader);
            } else {
              await repo.create(reader);
            }
            if (context.mounted) {
              await context.read<ReaderListNotifier>().load();
            }
            return FormSubmitResult.ok;
          },
        );
      },
    );
  }
}