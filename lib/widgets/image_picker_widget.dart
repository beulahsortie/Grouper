import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/s3_upload_service.dart';
import '../theme/app_theme.dart';

class ImagePickerWidget extends StatefulWidget {
  /// Called with the final S3 URL after a successful upload
  final void Function(String url) onUploaded;

  /// Optional initial image URL to show (e.g. existing avatar)
  final String? initialUrl;

  /// Shape: circle for avatars, rounded rect for venues
  final bool circular;

  final double size;

  const ImagePickerWidget({
    super.key,
    required this.onUploaded,
    this.initialUrl,
    this.circular = false,
    this.size = 120,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final _picker = ImagePicker();
  File? _localFile;
  bool _uploading = false;
  String? _errorMsg;

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;

    setState(() {
      _localFile = File(picked.path);
      _uploading = true;
      _errorMsg = null;
    });

    try {
      final url = await S3UploadService.uploadImage(_localFile!);
      widget.onUploaded(url);
    } catch (e) {
      setState(() => _errorMsg = 'Upload failed. Tap to retry.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.navy),
              title: const Text('Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt_rounded, color: AppColors.navy),
              title: const Text('Take a Photo',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _localFile != null || widget.initialUrl != null;

    Widget imageContent;
    if (_uploading) {
      imageContent = const Center(
        child: CircularProgressIndicator(color: AppColors.navy, strokeWidth: 2.5),
      );
    } else if (_localFile != null) {
      imageContent = Image.file(_localFile!,
          fit: BoxFit.cover, width: widget.size, height: widget.size);
    } else if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      imageContent = Image.network(widget.initialUrl!,
          fit: BoxFit.cover,
          width: widget.size,
          height: widget.size,
          errorBuilder: (_, __, ___) => _placeholder());
    } else {
      imageContent = _placeholder();
    }

    final borderRadius = widget.circular
        ? BorderRadius.circular(widget.size)
        : BorderRadius.circular(16);

    return GestureDetector(
      onTap: _showSourceSheet,
      child: Stack(
        alignment: widget.circular ? Alignment.bottomRight : Alignment.center,
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: borderRadius,
              border: Border.all(
                color: _errorMsg != null ? AppColors.error : AppColors.divider,
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: ClipRRect(
              borderRadius: borderRadius,
              child: imageContent,
            ),
          ),

          // Edit badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.navy,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.camera_alt_rounded,
                color: Colors.white, size: 14),
          ),

          // Error overlay
          if (_errorMsg != null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: borderRadius,
                ),
                child: Center(
                  child: Text(_errorMsg!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: widget.size,
      height: widget.size,
      color: AppColors.cardBg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.circular
                ? Icons.person_rounded
                : Icons.add_photo_alternate_rounded,
            color: AppColors.textMuted,
            size: widget.size * 0.3,
          ),
          if (!widget.circular) ...[
            const SizedBox(height: 6),
            const Text('Tap to add photo',
                style:
                    TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]
        ],
      ),
    );
  }
}