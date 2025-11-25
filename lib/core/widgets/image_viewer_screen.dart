import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../theme/app_colors.dart';

/// Full-screen image viewer with gallery support
///
/// Features:
/// - Pinch-to-zoom on images
/// - Swipe navigation between images
/// - Hero animation from thumbnails
/// - Image position indicator (e.g., "1 / 5")
/// - Tap-to-dismiss overlay controls
///
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => ImageViewerScreen(
///       images: ['url1', 'url2', 'url3'],
///       initialIndex: 0,
///     ),
///   ),
/// );
/// ```
class ImageViewerScreen extends StatefulWidget {
  /// List of image URLs to display in the gallery
  final List<String> images;

  /// Index of the image to display initially (0-based)
  final int initialIndex;

  /// Optional hero tag prefix for smooth transition
  /// Default: 'task_image'
  final String heroTagPrefix;

  const ImageViewerScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.heroTagPrefix = 'task_image',
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Toggle visibility of controls (AppBar with indicators)
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  /// Navigate to previous image
  void _previousImage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Navigate to next image
  void _nextImage() {
    if (_currentIndex < widget.images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      extendBodyBehindAppBar: true,
      appBar: _showControls
          ? AppBar(
              backgroundColor: Colors.black54,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: AppColors.white),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
              ),
              title: Text(
                '${_currentIndex + 1} / ${widget.images.length}',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              centerTitle: true,
              actions: widget.images.length > 1
                  ? [
                      // Previous button
                      if (_currentIndex > 0)
                        IconButton(
                          icon: const Icon(Icons.chevron_left,
                              color: AppColors.white),
                          onPressed: _previousImage,
                          tooltip: 'Previous',
                        ),
                      // Next button
                      if (_currentIndex < widget.images.length - 1)
                        IconButton(
                          icon: const Icon(Icons.chevron_right,
                              color: AppColors.white),
                          onPressed: _nextImage,
                          tooltip: 'Next',
                        ),
                    ]
                  : null,
            )
          : null,
      body: GestureDetector(
        onTap: _toggleControls,
        child: PhotoViewGallery.builder(
          scrollPhysics: const BouncingScrollPhysics(),
          builder: (BuildContext context, int index) {
            final imageUrl = widget.images[index];
            final heroTag = '${widget.heroTagPrefix}_$index';

            return PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(imageUrl),
              heroAttributes: PhotoViewHeroAttributes(tag: heroTag),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              initialScale: PhotoViewComputedScale.contained,
              // Error builder for failed image loads
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.black,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.white,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          itemCount: widget.images.length,
          loadingBuilder: (context, event) {
            if (event == null) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.white,
                ),
              );
            }

            final value = event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1);
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.white,
                value: value,
              ),
            );
          },
          backgroundDecoration: const BoxDecoration(
            color: AppColors.black,
          ),
          pageController: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          // Enable scroll direction for easier swiping on web
          scrollDirection: Axis.horizontal,
        ),
      ),
    );
  }
}
