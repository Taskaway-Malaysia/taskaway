import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_radius.dart';

class SearchOverlay extends ConsumerWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final Function(String)? onSearchChanged;
  final VoidCallback? onFilterTap;

  const SearchOverlay({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    this.onSearchChanged,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.smMd,
                border: Border.all(color: const Color(0xFFE4E4E4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.search,
                      color: Color(0xFF202020),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      onChanged: onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'Search for any service',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF202020),
                          fontWeight: FontWeight.w500,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF202020),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.smMd,
              border: Border.all(color: const Color(0xFFD9D9D9)),
            ),
            child: IconButton(
              onPressed: onFilterTap,
              icon: const Icon(
                Icons.tune,
                color: Color(0xFF000000),
                size: 16.5,
              ),
              padding: const EdgeInsets.all(5),
            ),
          ),
        ],
      ),
    );
  }
}