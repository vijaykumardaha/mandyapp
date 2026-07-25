import 'package:flutter/material.dart';

class AlphabetFilter extends StatefulWidget {
  final ValueChanged<String?> onAlphabetSelected;

  const AlphabetFilter({super.key, required this.onAlphabetSelected});

  @override
  State<AlphabetFilter> createState() => _AlphabetFilterState();
}

class _AlphabetFilterState extends State<AlphabetFilter> {
  String? _selectedAlphabet;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
      child: Row(
        children: [
          _buildAlphabetTag('All', _selectedAlphabet == null),
          const SizedBox(width: 8),
          ...List.generate(26, (index) {
            final alphabet = String.fromCharCode(65 + index);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildAlphabetTag(alphabet, _selectedAlphabet == alphabet),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAlphabetTag(String alphabet, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAlphabet =
              isSelected ? null : (alphabet == 'All' ? null : alphabet);
        });
        widget.onAlphabetSelected(_selectedAlphabet);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Text(
          alphabet,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
