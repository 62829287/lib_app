import 'package:flutter/material.dart';

import '../core/api_exceptions.dart';

Future<void> runApiAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } on ConflictException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message)),
    );
  } on ApiException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message)),
    );
  }
}
