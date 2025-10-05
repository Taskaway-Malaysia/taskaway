import 'package:flutter/material.dart';
import '../../../core/theme/app_radius.dart';

class MapSearchBar extends StatelessWidget {
  final bool isTaskerMode;
  final Function(bool) onToggle;
  final Function(String) onSearch;
  final VoidCallback? onFilterTap;

  const MapSearchBar({
    super.key,
    required this.isTaskerMode,
    required this.onToggle,
    required this.onSearch,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: AppRadius.md,
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            Icons.search,
                            color: Colors.grey.shade500,
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            onChanged: onSearch,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search for any service',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 15,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: AppRadius.md,
                  ),
                  child: IconButton(
                    onPressed: () {
                      print('Filter button tapped in MapSearchBar!');
                      onFilterTap?.call();
                    },
                    icon: const Icon(Icons.tune, size: 20),
                    color: Colors.grey.shade700,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          
          
          Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: 'TASKER',
                  isSelected: isTaskerMode,
                  onTap: () => onToggle(true),
                ),
              ),
              Expanded(
                child: _TabButton(
                  label: 'POSTER',
                  isSelected: !isTaskerMode,
                  onTap: () => onToggle(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.amber : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.black : Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}