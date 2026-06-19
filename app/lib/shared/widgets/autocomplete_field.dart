import 'package:flutter/material.dart';

/// A text field that suggests previously-seen names as you type. Backed by an
/// external [controller] so callers can read the typed/selected value exactly
/// like a plain [TextField].
class AutocompleteField extends StatefulWidget {
  const AutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    this.suggestions = const [],
    this.autofocus = false,
    this.onSubmitted,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String label;
  final List<String> suggestions;
  final bool autofocus;
  final Widget? prefixIcon;

  /// Called when the user submits the field (keyboard action).
  final VoidCallback? onSubmitted;

  @override
  State<AutocompleteField> createState() => _AutocompleteFieldState();
}

class _AutocompleteFieldState extends State<AutocompleteField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focus,
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        final all = widget.suggestions;
        final matches = q.isEmpty
            ? all
            : all.where((s) => s.toLowerCase().contains(q));
        // Hide the dropdown once the text already equals the only suggestion.
        final list = matches.where((s) => s.toLowerCase() != q).take(8).toList();
        return list;
      },
      onSelected: (s) => widget.controller.text = s,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: widget.autofocus,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: widget.label, prefixIcon: widget.prefixIcon),
          onSubmitted: (_) {
            onFieldSubmitted();
            widget.onSubmitted?.call();
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 340),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final option = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.person_outline_rounded, size: 18),
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
