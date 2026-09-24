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

class ChecklistItem extends StatelessWidget {
  final String label;
  final String value; // 'Ja', 'Nee', 'N.v.t.'
  final ValueChanged<String> onChanged;

  /// Whether each radio button repeats its option text ('Ja'/'Nee'/'N.v.t.').
  /// Set to false when a column header already shows these labels once.
  final bool showOptionLabels;

  const ChecklistItem({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.showOptionLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          _buildRadio('Ja'),
          _buildRadio('Nee'),
          _buildRadio('N.v.t.'),
        ],
      ),
    );
  }

  Widget _buildRadio(String option) {
    final selected = value == option;
    final icon = SizedBox(
      width: 24,
      height: 24,
      child: selected
          ? Icon(Icons.radio_button_checked,
              size: 20, color: Colors.blue.shade700)
          : Icon(Icons.radio_button_unchecked, size: 20, color: Colors.grey),
    );
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(option),
        child: showOptionLabels
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(option, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              )
            : Center(child: icon),
      ),
    );
  }
}
