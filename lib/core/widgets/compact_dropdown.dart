import 'package:flutter/material.dart';

class CompactDropdown extends StatelessWidget {
  final String label;
  final String? selectedValue;
  final List<String> options;
  final Function(String?) onChanged;
  final double maxHeight;

  const CompactDropdown({
    super.key,
    required this.label,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
    this.maxHeight = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: PopupMenuButton<String>(
        constraints: BoxConstraints(maxHeight: maxHeight),
        position: PopupMenuPosition.under,
        offset: const Offset(0, 4),
        onSelected: onChanged,
        itemBuilder: (context) => [
          ...options.map((option) => PopupMenuItem<String>(
            value: option,
            height: 32, // Smaller height for menu items
            child: Text(
              option,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          )),
        ],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedValue ?? label,
                style: TextStyle(
                  color: selectedValue == null ? Colors.black54 : Colors.black,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 20),
          ],
        ),
      ),
    );
  }
} 