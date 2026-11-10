import 'package:flutter/material.dart';

import 'confirm_dialog.dart';
import 'form_exit_scope.dart';

class FormSubmitResult {
  const FormSubmitResult({this.formError, this.fieldErrors = const {}});

  final String? formError;
  final Map<String, String> fieldErrors;

  static const ok = FormSubmitResult();
}

typedef EntityFormSubmit = Future<FormSubmitResult> Function(
  Map<String, dynamic> values,
);

enum EntityFieldType { text, multiline, number, email, dropdown, multiChip }

class EntityFieldSpec {
  final String key;
  final String label;
  final EntityFieldType type;
  final String? Function(String?)? stringValidator;
  final String? Function(int?)? idValidator;
  final String? Function(List<int>?)? idsValidator;
  final List<DropdownMenuItem<int>> Function()? dropdownItems;
  final List<({int id, String label})> Function()? chipItems;
  final int maxLines;
  final bool readOnly;
  final String? group;
  final String? groupTitle;

  const EntityFieldSpec({
    required this.key,
    required this.label,
    required this.type,
    this.stringValidator,
    this.idValidator,
    this.idsValidator,
    this.dropdownItems,
    this.chipItems,
    this.maxLines = 1,
    this.readOnly = false,
    this.group,
    this.groupTitle,
  });
}

class EntityForm extends StatefulWidget {
  const EntityForm({
    super.key,
    required this.title,
    required this.fields,
    required this.initialValues,
    required this.onSubmit,
    this.onChanged,
    this.submitLabel = 'Сохранить',
    this.extra,
  });

  final String title;
  final List<EntityFieldSpec> fields;
  final Map<String, dynamic> initialValues;
  final EntityFormSubmit onSubmit;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final String submitLabel;
  final Widget? extra;

  @override
  State<EntityForm> createState() => EntityFormState();
}

class EntityFormState extends State<EntityForm> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _values;
  late Map<String, dynamic> _baseline;
  Map<String, String> _fieldErrors = {};
  bool _saving = false;
  String? _formError;
  int _generation = 0;
  late final int _exitToken;

  bool get _dirty => _values.toString() != _baseline.toString();

  @override
  void initState() {
    super.initState();
    _values = Map<String, dynamic>.from(widget.initialValues);
    _baseline = Map<String, dynamic>.from(widget.initialValues);
    _exitToken = FormExitScope.bind(() => _dirty);
  }

  @override
  void dispose() {
    FormExitScope.unbind(_exitToken);
    super.dispose();
  }

  void updateValues(Map<String, dynamic> patch, {bool rebuildFields = false}) {
    setState(() {
      _values.addAll(patch);
      if (rebuildFields) _generation++;
    });
    widget.onChanged?.call(Map<String, dynamic>.from(_values));
  }

  Future<void> _submit() async {
    setState(() {
      _formError = null;
      _fieldErrors = {};
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final result = await widget.onSubmit(Map<String, dynamic>.from(_values));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _formError = result.formError;
      _fieldErrors = Map<String, String>.from(result.fieldErrors);
    });
    if (result.formError != null || result.fieldErrors.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _formKey.currentState?.validate();
      });
      return;
    }
    _baseline = Map<String, dynamic>.from(_values);
    FormExitScope.allowNextExit();
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _handlePop(bool didPop) async {
    if (didPop) return;
    if (!_dirty) {
      FormExitScope.allowNextExit();
      Navigator.of(context).pop();
      return;
    }
    final leave = await confirmAction(
      context,
      title: 'Уйти без сохранения?',
      message: 'Есть несохранённые изменения. Они будут потеряны.',
      confirmLabel: 'Уйти',
    );
    if (leave && mounted) {
      FormExitScope.allowNextExit();
      Navigator.of(context).pop();
    }
  }

  void _setValue(String key, dynamic value) {
    setState(() {
      _values[key] = value;
      _fieldErrors.remove(key);
    });
    widget.onChanged?.call(Map<String, dynamic>.from(_values));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) => _handlePop(didPop),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._buildFieldBlocks(),
                if (widget.extra != null) ...[
                  widget.extra!,
                  const SizedBox(height: 12),
                ],
                if (_formError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _formError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: Text(_saving ? 'Сохранение…' : widget.submitLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFieldBlocks() {
    final blocks = <Widget>[];
    var i = 0;
    while (i < widget.fields.length) {
      final field = widget.fields[i];
      if (field.group == null) {
        blocks.add(
          KeyedSubtree(
            key: ValueKey('${field.key}-$_generation'),
            child: _buildField(field),
          ),
        );
        blocks.add(const SizedBox(height: 12));
        i++;
        continue;
      }

      final groupId = field.group!;
      final groupFields = <EntityFieldSpec>[];
      while (i < widget.fields.length && widget.fields[i].group == groupId) {
        groupFields.add(widget.fields[i]);
        i++;
      }
      final title = groupFields.first.groupTitle ?? groupId;
      blocks.add(
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                for (var g = 0; g < groupFields.length; g++) ...[
                  KeyedSubtree(
                    key: ValueKey('${groupFields[g].key}-$_generation'),
                    child: _buildField(groupFields[g]),
                  ),
                  if (g < groupFields.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      );
      blocks.add(const SizedBox(height: 12));
    }
    return blocks;
  }

  Widget _buildField(EntityFieldSpec field) {
    switch (field.type) {
      case EntityFieldType.text:
      case EntityFieldType.multiline:
      case EntityFieldType.number:
      case EntityFieldType.email:
        return TextFormField(
          initialValue: '${_values[field.key] ?? ''}',
          readOnly: field.readOnly,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          keyboardType: field.type == EntityFieldType.number
              ? TextInputType.number
              : field.type == EntityFieldType.email
                  ? TextInputType.emailAddress
                  : TextInputType.text,
          maxLines:
              field.type == EntityFieldType.multiline ? field.maxLines : 1,
          decoration: InputDecoration(labelText: field.label),
          validator: (v) =>
              _fieldErrors[field.key] ?? field.stringValidator?.call(v),
          onChanged: (v) => _setValue(field.key, v),
        );
      case EntityFieldType.dropdown:
        final items =
            field.dropdownItems?.call() ?? const <DropdownMenuItem<int>>[];
        return DropdownButtonFormField<int>(
          initialValue: _values[field.key] as int?,
          isExpanded: true,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(labelText: field.label),
          items: items,
          onChanged: field.readOnly
              ? null
              : (v) {
                  _setValue(field.key, v);
                },
          validator: (v) =>
              _fieldErrors[field.key] ?? field.idValidator?.call(v),
        );
      case EntityFieldType.multiChip:
        final options =
            field.chipItems?.call() ?? const <({int id, String label})>[];
        final selected =
            List<int>.from((_values[field.key] as List?) ?? const []);
        return FormField<List<int>>(
          initialValue: selected,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (v) =>
              _fieldErrors[field.key] ?? field.idsValidator?.call(v),
          builder: (state) {
            return InputDecorator(
              decoration: InputDecoration(
                labelText: field.label,
                errorText: state.errorText,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final opt in options)
                    FilterChip(
                      label: Text(opt.label),
                      selected: state.value!.contains(opt.id),
                      onSelected: (_) {
                        final next = [...state.value!];
                        if (next.contains(opt.id)) {
                          next.remove(opt.id);
                        } else {
                          next.add(opt.id);
                        }
                        state.didChange(next);
                        _setValue(field.key, next);
                      },
                    ),
                ],
              ),
            );
          },
        );
    }
  }
}
