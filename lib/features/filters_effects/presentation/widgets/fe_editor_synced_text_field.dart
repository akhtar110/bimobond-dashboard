import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final List<TextInputFormatter>? inputFormatters;

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
      inputFormatters: widget.inputFormatters,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      onChanged: widget.onChanged,
    );
  }
}

/// Numeric text field synced with a slider value.
/// Supports manual entry of integer and decimal values within [min, max] bounds.
class FeSyncedNumberInput extends StatefulWidget {
  const FeSyncedNumberInput({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.width = 62,
    this.height = 32,
    this.isDouble = false,
    this.decimals = 1,
    this.enabled = true,
  });

  final num value;
  final num min;
  final num max;
  final ValueChanged<num> onChanged;
  final double width;
  final double height;
  final bool isDouble;
  final int decimals;
  final bool enabled;

  @override
  State<FeSyncedNumberInput> createState() => _FeSyncedNumberInputState();
}

class _FeSyncedNumberInputState extends State<FeSyncedNumberInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  String _format(num v) {
    if (widget.isDouble) {
      return (v.toDouble()).toStringAsFixed(widget.decimals);
    }
    return '${v.round()}';
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void didUpdateWidget(FeSyncedNumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_focusNode.hasFocus) {
      final text = _format(widget.value);
      if (text != _controller.text) {
        _controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final parsed = widget.isDouble
        ? double.tryParse(trimmed)
        : int.tryParse(trimmed);
    if (parsed == null) return;
    final clamped = parsed.clamp(widget.min, widget.max);
    widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        keyboardType: TextInputType.numberWithOptions(
          decimal: widget.isDouble,
          signed: widget.min < 0,
        ),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.primary,
              height: 1.1,
            ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          filled: true,
          fillColor: scheme.surfaceContainerLowest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: scheme.primary, width: 1.5),
          ),
        ),
        onChanged: _submit,
      ),
    );
  }
}
