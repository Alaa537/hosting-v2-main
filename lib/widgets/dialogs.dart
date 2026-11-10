import 'package:flutter/material.dart';
import '../utils/constants.dart';

Future<bool> confirm(
  BuildContext ctx,
  String title, {
  String? msg,
  bool danger = false,
  bool default_ = false,
}) async {
  final r = await showDialog<bool>(
    context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: C.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      content: msg == null
          ? null
          : Text(msg, style: const TextStyle(color: C.muted, fontSize: 13)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('إلغاء', style: TextStyle(color: C.muted)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: danger
              ? ElevatedButton.styleFrom(backgroundColor: C.danger)
              : null,
          child: Text(danger ? 'نعم، متأكد' : 'تأكيد'),
        ),
      ],
    ),
  );
  return r ?? default_;
}

Future<String?> promptText(
  BuildContext ctx,
  String title, {
  String? hint,
  String initial = '',
  bool obscure = false,
  int maxLines = 1,
}) async {
  final c = TextEditingController(text: initial);
  final r = await showDialog<String>(
    context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: C.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      content: TextField(
        controller: c,
        obscureText: obscure,
        maxLines: maxLines,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إلغاء', style: TextStyle(color: C.muted)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, c.text),
          child: const Text('حسناً'),
        ),
      ],
    ),
  );
  return r;
}

Future<int?> promptInt(
  BuildContext ctx,
  String title, {
  String? hint,
  int? initial,
}) async {
  final r = await promptText(ctx, title,
      hint: hint, initial: initial?.toString() ?? '');
  if (r == null || r.trim().isEmpty) return null;
  return int.tryParse(r.trim());
}

void snack(BuildContext ctx, String msg, {bool error = false}) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Text(msg,
        style: TextStyle(color: error ? Colors.white : Colors.black)),
    backgroundColor: error ? C.danger : C.success,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    duration: const Duration(seconds: 3),
  ));
}

void snackInfo(BuildContext ctx, String msg) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(color: Colors.white)),
    backgroundColor: C.info,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    duration: const Duration(seconds: 3),
  ));
}
