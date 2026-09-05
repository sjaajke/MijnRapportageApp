// Copyright (C) 2026 Jay Smeekes
//
// This file is part of MijnRapportage.
//
// MijnRapportage is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// MijnRapportage is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with MijnRapportage. If not, see <https://www.gnu.org/licenses/>.

import 'package:flutter/material.dart';

/// A text field that behaves like [CustomTextField] (free typing allowed)
/// but shows a filtered suggestions list, similar to a dropdown, based on
/// [options]. Selecting a suggestion or typing a value not in [options] are
/// both supported.
class AutocompleteTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const AutocompleteTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.options,
    required this.onChanged,
  });

  @override
  State<AutocompleteTextField> createState() => _AutocompleteTextFieldState();
}

class _AutocompleteTextFieldState extends State<AutocompleteTextField> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: RawAutocomplete<String>(
        textEditingController: widget.controller,
        focusNode: _focusNode,
        optionsBuilder: (TextEditingValue value) {
          if (value.text.isEmpty) return widget.options;
          final query = value.text.toLowerCase();
          return widget.options.where((o) => o.toLowerCase().contains(query));
        },
        onSelected: widget.onChanged,
        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
          return TextFormField(
            controller: textEditingController,
            focusNode: focusNode,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            ),
            style: const TextStyle(fontSize: 14),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          final list = options.toList();
          return Material(
            elevation: 4.0,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: list.length,
              itemBuilder: (context, index) {
                final option = list[index];
                return ListTile(
                  dense: true,
                  title: Text(option, style: const TextStyle(fontSize: 14)),
                  onTap: () => onSelected(option),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
