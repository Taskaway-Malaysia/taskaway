import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/constants/api_constants.dart';

class ImagePickerGrid extends StatefulWidget {
  final List<String> initialImages;
  final Function(List<String>) onImagesChanged;
  final bool enabled;
  final String userId;

  const ImagePickerGrid({
    super.key,
    required this.initialImages,
    required this.onImagesChanged,
    required this.userId,
    this.enabled = true,
  });

  @override
  State<ImagePickerGrid> createState() => _ImagePickerGridState();
}

class _ImagePickerGridState extends State<ImagePickerGrid> {
  late List<String> _imageUrls;
  final List<String> _uploadingImages = [];
  final ImagePicker _picker = ImagePicker();
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _imageUrls = List.from(widget.initialImages);
  }

  Future<void> _pickAndUploadImage() async {
    if (_imageUrls.length >= 10) {
      _showSnackBar('Maximum 10 images allowed', Colors.orange);
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      // Add to uploading list for UI feedback
      setState(() {
        _uploadingImages.add(image.path);
      });

      // Upload to Supabase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}.jpg';
      final filePath = 'profiles/${widget.userId}/works/$fileName';

      final imageUrl = await _supabaseService.uploadFile(
        filePath: filePath,
        file: image,
        bucket: ApiConstants.taskImagesBucket,
      );

      if (imageUrl != null) {
        setState(() {
          _uploadingImages.remove(image.path);
          _imageUrls.add(imageUrl);
        });
        widget.onImagesChanged(_imageUrls);
        _showSnackBar('Image uploaded successfully', const Color(0xFF6C5CE7));
      } else {
        setState(() {
          _uploadingImages.remove(image.path);
        });
        _showSnackBar('Failed to upload image', Colors.red);
      }
    } catch (e) {
      setState(() {
        _uploadingImages.clear();
      });
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _removeImage(String imageUrl) async {
    try {
      setState(() {
        _imageUrls.remove(imageUrl);
      });
      widget.onImagesChanged(_imageUrls);

      // Delete from storage (extract file path from URL)
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 3) {
        final filePath = pathSegments.sublist(2).join('/');
        await _supabaseService.deleteFile(
          bucket: ApiConstants.taskImagesBucket,
          filePath: filePath,
        );
      }

      _showSnackBar('Image removed successfully', const Color(0xFF6C5CE7));
    } catch (e) {
      _showSnackBar('Error removing image: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _imageUrls.length + _uploadingImages.length + (widget.enabled && _imageUrls.length < 10 ? 1 : 0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload limit indicator
        Text(
          '${_imageUrls.length}/10 images',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 16),

        // Image grid
        if (totalItems > 0)
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              // Add button (if enabled and under limit)
              if (widget.enabled && _imageUrls.length < 10)
                _buildAddImageButton(),
              
              // Uploading images
              ..._uploadingImages.map((path) => _buildUploadingImage(path)),
              
              // Existing images
              ..._imageUrls.map((url) => _buildImageItem(url)),
            ],
          )
        else
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No work images yet',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.enabled)
                  ElevatedButton.icon(
                    onPressed: _pickAndUploadImage,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Add Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickAndUploadImage,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              size: 48,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              'Add Image',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingImage(String path) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(path),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          // Upload overlay
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Uploading...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageItem(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.grey.shade600,
                    size: 48,
                  ),
                );
              },
            ),
          ),
          if (widget.enabled)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removeImage(imageUrl),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}