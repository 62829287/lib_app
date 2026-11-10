import 'package:flutter/material.dart';

import 'confirm_dialog.dart';

class FormExitScope {
  FormExitScope._();

  static int _tokenSeq = 0;
  static int? _activeToken;
  static bool Function()? _isDirty;
  static bool _allowOnce = false;

  static int bind(bool Function() isDirty) {
    final token = ++_tokenSeq;
    _activeToken = token;
    _isDirty = isDirty;
    _allowOnce = false;
    return token;
  }

  static void unbind(int token) {
    if (_activeToken == token) {
      _activeToken = null;
      _isDirty = null;
      _allowOnce = false;
    }
  }

  static void allowNextExit() {
    _allowOnce = true;
  }

  static Future<bool> allowExit(BuildContext context) async {
    if (_allowOnce) {
      _allowOnce = false;
      return true;
    }
    final dirty = _isDirty?.call() ?? false;
    if (!dirty) return true;
    return confirmAction(
      context,
      title: 'Уйти без сохранения?',
      message: 'Есть несохранённые изменения. Они будут потеряны.',
      confirmLabel: 'Уйти',
    );
  }
}
