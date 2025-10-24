import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/theme/app_radius.dart';

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
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                            onChanged: widget.onSearch,
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
                    // Main banner with shadow
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.md,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.md,
                        child: SizedBox(
                          width: double.infinity,
                          height: 120,
                          child: PageView(
                            controller: _pageController,
                            children: [
                              Image.asset(
                                'assets/images/my-11134258-820lh-mf2fi3npb2tn0f.webp',
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                              Image.asset(
                                'assets/images/my-11134258-820lh-mf2fi3npb2tn0f.webp',
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                              Image.asset(
                                'assets/images/my-11134258-820lh-mf2fi3npb2tn0f.webp',
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SmoothPageIndicator(
                  controller: _pageController,
                  count: 3,
                  effect: WormEffect(
                    dotHeight: 8,
                    dotWidth: 8,
                    activeDotColor: const Color(0xFFFFDB5B),
                    dotColor: Colors.grey.shade300,
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
                  isSelected: widget.isTaskerMode,
                  onTap: () => widget.onToggle(true),
                ),
              ),
              Expanded(
                child: _TabButton(
                  label: 'POSTER',
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