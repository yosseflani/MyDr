import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';

/// Form field for a list of short texts (e.g. allergies): a text input with
/// an add button, and a removable chip per item.
///
/// Empty and duplicate items (ignoring case and surrounding spaces) are
/// rejected. Validation also fails while text is typed but not yet added,
/// so it is never silently lost on save.
class StringListField extends FormField<List<String>> {
  StringListField({
    super.key,
    required this.title,
    required this.inputLabel,
    required List<String> initialItems,
    this.onChanged,
    this.maxItemLength = 50,
    super.enabled,
  }) : super(
         initialValue: List.unmodifiable(initialItems),
         builder: (field) => (field as _StringListFieldState)._buildContent(),
       );

  final String title;
  final String inputLabel;
  final ValueChanged<List<String>>? onChanged;
  final int maxItemLength;

  @override
  FormFieldState<List<String>> createState() => _StringListFieldState();
}

class _StringListFieldState extends FormFieldState<List<String>> {
  final TextEditingController _input = TextEditingController();
  String? _inputError;

  StringListField get _field => widget as StringListField;
  List<String> get _items => value ?? const [];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _input.text.trim();
    final String? error;
    if (text.isEmpty) {
      error = AppStrings.listItemEmpty;
    } else if (_items.any((item) => item.toLowerCase() == text.toLowerCase())) {
      error = AppStrings.listItemDuplicate;
    } else {
      error = null;
    }

    if (error != null) {
      setState(() => _inputError = error);
      return;
    }

    _input.clear();
    setState(() => _inputError = null);
    _updateItems(List.unmodifiable([..._items, text]));
  }

  void _removeItem(String item) {
    _updateItems(List.unmodifiable(_items.where((i) => i != item)));
  }

  void _updateItems(List<String> items) {
    didChange(items);
    _field.onChanged?.call(items);
  }

  @override
  bool validate() {
    final isValid = super.validate();
    if (_input.text.trim().isNotEmpty) {
      setState(() => _inputError = AppStrings.listItemPending);
      return false;
    }
    return isValid;
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    final enabled = widget.enabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            _field.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                enabled: enabled,
                maxLength: _field.maxItemLength,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: _field.inputLabel,
                  errorText: _inputError,
                  errorMaxLines: 3,
                  counterText: '',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_inputError != null) setState(() => _inputError = null);
                },
                onSubmitted: (_) => _addItem(),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: IconButton.filledTonal(
                tooltip: AppStrings.addItem,
                onPressed: enabled ? _addItem : null,
                icon: const Icon(Icons.add),
              ),
            ),
          ],
        ),
        if (_items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in _items)
                InputChip(
                  label: Text(item),
                  onDeleted: enabled ? () => _removeItem(item) : null,
                  deleteButtonTooltipMessage: AppStrings.removeItem(item),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
