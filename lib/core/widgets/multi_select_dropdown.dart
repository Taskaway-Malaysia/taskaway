import 'package:flutter/material.dart';

class MultiSelectDropdown extends StatelessWidget {
  final String label;
  final List<String> selectedValues;
  final List<String> options;
  final Function(List<String>) onChanged;
  final double maxHeight;

  const MultiSelectDropdown({
    super.key,
    required this.label,
    required this.selectedValues,
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
      child: PopupMenuButton<List<String>>(
        constraints: BoxConstraints(maxHeight: maxHeight),
        position: PopupMenuPosition.under,
        offset: const Offset(0, 4),
        onSelected: (_) {},
        itemBuilder: (context) => [
          PopupMenuItem<List<String>>(
            enabled: false,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...options.map((option) {
                      final isSelected = selectedValues.contains(option);
                      return InkWell(
                        onTap: () {
                          List<String> newSelection = List.from(selectedValues);
                          if (isSelected) {
                            newSelection.remove(option);
                          } else {
                            newSelection.add(option);
                          }
                          setState(() {});
                          onChanged(newSelection);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: isSelected,
                                  onChanged: (_) {
                                    List<String> newSelection = List.from(selectedValues);
                                    if (isSelected) {
                                      newSelection.remove(option);
                                    } else {
                                      newSelection.add(option);
                                    }
                                    setState(() {});
                                    onChanged(newSelection);
                                  },
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                option,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            onChanged([]);
                            setState(() {});
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Clear',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedValues.isEmpty ? label : selectedValues.join(', '),
                style: TextStyle(
                  color: selectedValues.isEmpty ? Colors.black54 : Colors.black,
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