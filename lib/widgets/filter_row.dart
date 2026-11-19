import 'package:material_ui/material_ui.dart';

/// Single-choice filter chips. Without the checkmark the selected chip keeps its width,
/// so four short filters fit on one row of a phone; selection still shows as a filled chip.
class FilterRow<T> extends StatelessWidget {
  const FilterRow({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.enabled,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final bool Function(T)? enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final value in values)
          ChoiceChip(
            label: Text(labelOf(value)),
            showCheckmark: false,
            selected: value == selected,
            onSelected: (enabled?.call(value) ?? true) ? (_) => onSelected(value) : null,
          ),
      ],
    );
  }
}
