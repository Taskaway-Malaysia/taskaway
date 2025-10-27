import 'package:flutter/material.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_colors.dart';

class MapSearchBar extends StatefulWidget {
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
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // Bottom layer - white background with bottom corner radius
              Container(
                height: 68, // Total height (44 for content + 12 padding top + 12 padding bottom)
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),  // Large corner radius only at bottom
                  ),
                ),
              ),
              // Top layer - taskaway color (covers top half)
              Container(
                height: 34, // Half of total height (68 / 2)
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                ),
              ),
              // Content layer - search bar and filter button
              Padding(
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
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                            onChanged: widget.onSearch,
                            textAlignVertical: TextAlignVertical.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                              height: 1.2,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search for any service',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 15,
                                height: 1.2,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 12,
                              ),
                              isDense: true,
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
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: AppRadius.md,
                  ),
                  child: IconButton(
                    onPressed: () {
                      print('Filter button tapped in MapSearchBar!');
                      widget.onFilterTap?.call();
                    },
                    icon: const Icon(Icons.tune, size: 20),
                    color: Colors.grey.shade700,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
            ],
          ),

          // Banner Carousel Section with background layer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                Stack(
                  children: [
                    // Background layer (white rounded container)
                    Container(
                      margin: const EdgeInsets.only(top: 4, left: 4, right: 4),
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: AppRadius.md,
                      ),
                    ),
                    // Main banner
                    ClipRRect(
                      borderRadius: AppRadius.md,
                      child: Image.asset(
                        'assets/images/my-11134258-820lh-mf2fi3npb2tn0f.webp',
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: 'FIND JOB',
                  isSelected: widget.isTaskerMode,
                  onTap: () => widget.onToggle(true),
                ),
              ),
              Expanded(
                child: _TabButton(
                  label: 'ONGOING JOB',
                  isSelected: !widget.isTaskerMode,
                  onTap: () => widget.onToggle(false),
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
        padding: const EdgeInsets.symmetric(vertical: 10),
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