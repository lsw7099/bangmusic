// 입력란이 있는 대화상자. 컨트롤러는 대화상자 State가 갖고 dispose에서 해제한다
// (호출한 쪽에서 닫힌 직후 해제하면 사라지는 중인 입력란이 해제된 컨트롤러를 써 오류가 났다 — 위젯 시험에서 발견).
import 'package:flutter/material.dart';

import '../tokens.dart';

class DialogField {
  const DialogField(this.label, {this.initial = '', this.obscure = false, this.maxLength, this.maxLines = 1});
  final String label;
  final String initial;
  final bool obscure;
  final int? maxLength;
  final int maxLines;
}

/// 입력값 목록을 돌려준다(취소면 null). onSubmit이 오류 문구를 돌려주면 닫지 않고 보여 준다.
Future<List<String>?> showFormDialog(
  BuildContext context, {
  required String title,
  required List<DialogField> fields,
  required String submitLabel,
  Widget? message,
  Future<String?> Function(List<String> values)? onSubmit,
  bool destructive = false,
}) =>
    showDialog<List<String>>(
      context: context,
      builder: (_) => _FormDialog(title: title, fields: fields, submitLabel: submitLabel, message: message, onSubmit: onSubmit, destructive: destructive),
    );

class _FormDialog extends StatefulWidget {
  const _FormDialog({required this.title, required this.fields, required this.submitLabel, this.message, this.onSubmit, this.destructive = false});
  final String title;
  final List<DialogField> fields;
  final String submitLabel;
  final Widget? message;
  final Future<String?> Function(List<String>)? onSubmit;
  final bool destructive;
  @override
  State<_FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialog> {
  late final _controllers = [for (final f in widget.fields) TextEditingController(text: f.initial)];
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final values = [for (final c in _controllers) c.text];
    if (widget.onSubmit != null) {
      setState(() {
        _busy = true;
        _error = null;
      });
      final err = await widget.onSubmit!(values);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = err;
      });
      if (err != null) return;
    }
    Navigator.pop(context, values);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ?widget.message,
            for (final (i, f) in widget.fields.indexed)
              TextField(
                controller: _controllers[i],
                autofocus: i == 0,
                obscureText: f.obscure,
                maxLength: f.maxLength,
                maxLines: f.obscure ? 1 : f.maxLines,
                minLines: 1,
                enabled: !_busy,
                decoration: InputDecoration(labelText: f.label),
              ),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: Space.sm), child: Semantics(liveRegion: true, child: Text(_error!, style: TextStyle(color: context.colors.danger)))),
          ]),
        ),
        actions: [
          TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('취소')),
          FilledButton(
            style: widget.destructive ? FilledButton.styleFrom(backgroundColor: context.colors.danger) : null,
            onPressed: _busy ? null : _submit,
            child: Text(widget.submitLabel),
          ),
        ],
      );
}
