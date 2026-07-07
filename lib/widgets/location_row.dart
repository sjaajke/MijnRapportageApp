import 'package:flutter/material.dart';
import 'custom_text_field.dart';

class LocationRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onPick;

  const LocationRow({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: CustomTextField(
            label: label,
            controller: controller,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Kies $label',
          child: IconButton.outlined(
            icon: const Icon(Icons.location_on_outlined),
            onPressed: onPick,
          ),
        ),
      ],
    );
  }
}
