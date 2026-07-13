import 'package:flutter/material.dart';

/// Text field that keeps local editing state and only syncs [value] from the
/// parent when the field is not focused (e.g. color picker, load, reset).
class FeEditorSyncedTextField extends StatefulWidget {
  const FeEditorSyncedTextField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.decoration,
    this.keyboardType,
    this.readOnly = false,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final bool readOnly;

  @override
  State<FeEditorSyncedTextField> createState() =>
      _FeEditorSyncedTextFieldState();
}

class _FeEditorSyncedTextFieldState extends State<FeEditorSyncedTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(FeEditorSyncedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text && !_focusNode.hasFocus) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      readOnly: widget.readOnly,
      decoration: widget.decoration,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
    );
  }
}
