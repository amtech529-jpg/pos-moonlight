import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../l10n/app_localizations.dart';

class ImageUploadWidget extends StatefulWidget {
  final String? initialImagePath;
  final Function(File?)? onImageChanged;
  final String label;
  final bool isRequired;
  final double maxHeight;
  final List<String> allowedExtensions;
  final int maxFileSizeMB;

  const ImageUploadWidget({
    super.key,
    this.initialImagePath,
    this.onImageChanged,
    required this.label,
    this.isRequired = false,
    this.maxHeight = 200,
    this.allowedExtensions = const ['jpg', 'jpeg', 'png', 'gif'],
    this.maxFileSizeMB = 5,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  File? _selectedImageFile;
  String? _currentImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.initialImagePath;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              widget.label,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
            ),
            if (widget.isRequired)
              Text(
                ' *',
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: Colors.red.shade600),
              ),
          ],
        ),
        SizedBox(height: context.smallPadding),

        // Image Preview Section
        if (_selectedImageFile != null || _currentImagePath != null) ...[
          Container(
            width: double.infinity,
            height: widget.maxHeight,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: ClipRRect(borderRadius: BorderRadius.circular(context.borderRadius()), child: _buildImageWidget()),
          ),
          SizedBox(height: context.smallPadding),

          // Image Actions Row
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: _removeImage,
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade600, size: context.iconSize('small')),
                  label: Text(
                    l10n.removeImage,
                    style: TextStyle(fontSize: context.captionFontSize, color: Colors.red.shade600),
                  ),
                ),
              ),
              if (_selectedImageFile != null || _currentImagePath != null)
                Expanded(
                  child: TextButton.icon(
                    onPressed: _viewImageFullScreen,
                    icon: Icon(Icons.fullscreen, color: AppTheme.primaryMaroon, size: context.iconSize('small')),
                    label: Text(
                      l10n.viewFullScreen,
                      style: TextStyle(fontSize: context.captionFontSize, color: AppTheme.primaryMaroon),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: context.smallPadding),
        ],

        // Upload Button
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedImageFile != null || _currentImagePath != null ? Colors.grey.shade300 : AppTheme.primaryMaroon.withValues(alpha: 0.3),
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(context.borderRadius()),
            color: _selectedImageFile != null || _currentImagePath != null ? Colors.grey.shade50 : AppTheme.primaryMaroon.withValues(alpha: 0.05),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _pickImage,
              borderRadius: BorderRadius.circular(context.borderRadius()),
              child: Container(
                padding: EdgeInsets.all(context.smallPadding),
                child: _isLoading
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: context.iconSize('medium'),
                        height: context.iconSize('medium'),
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon)),
                      ),
                      SizedBox(height: context.smallPadding / 2),
                      Text(
                        l10n.processing,
                        style: TextStyle(fontSize: context.captionFontSize, color: AppTheme.primaryMaroon),
                      ),
                    ],
                  ),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedImageFile != null || _currentImagePath != null ? Icons.edit_outlined : Icons.add_photo_alternate_outlined,
                      color: _selectedImageFile != null || _currentImagePath != null ? AppTheme.primaryMaroon : Colors.grey.shade600,
                      size: context.iconSize('medium'),
                    ),
                    SizedBox(height: context.smallPadding / 2),
                    Text(
                      _selectedImageFile != null || _currentImagePath != null ? l10n.tapToChangeImage : l10n.tapToAddImage,
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        color: _selectedImageFile != null || _currentImagePath != null ? AppTheme.primaryMaroon : Colors.grey.shade600,
                      ),
                    ),
                    if (_selectedImageFile != null || _currentImagePath != null) ...[
                      SizedBox(height: context.smallPadding / 2),
                      Text(
                        '${l10n.supports}: ${widget.allowedExtensions.join(', ').toUpperCase()} (${l10n.max} ${widget.maxFileSizeMB}MB)',
                        style: TextStyle(fontSize: context.captionFontSize - 2, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget() {
    if (_selectedImageFile != null) {
      return Image.file(
        _selectedImageFile!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    } else if (_currentImagePath != null) {
      // Handle backend image paths
      if (_currentImagePath!.startsWith('http://') || _currentImagePath!.startsWith('https://')) {
        // Full URL - use as is
        return Image.network(
          _currentImagePath!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget();
          },
        );
      } else if (_currentImagePath!.startsWith('/media/')) {
        // Backend media path - construct full URL
        final fullUrl = 'http://127.0.0.1:8000${_currentImagePath!}';
        return Image.network(
          fullUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget();
          },
        );
      } else {
        // Local file path
        return Image.file(
          File(_currentImagePath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget();
          },
        );
      }
    }
    return _buildErrorWidget();
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: context.iconSize('large')),
    );
  }

  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      setState(() {
        _isLoading = true;
      });

      final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false, allowedExtensions: widget.allowedExtensions);

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);

        // Check file size
        final fileSize = await file.length();
        if (fileSize > widget.maxFileSizeMB * 1024 * 1024) {
          _showErrorSnackbar('${l10n.fileSizeMustBeLessThan} ${widget.maxFileSizeMB}MB');
          return;
        }

        setState(() {
          _selectedImageFile = file;
        });

        // Notify parent
        widget.onImageChanged?.call(file);
      }
    } catch (e) {
      _showErrorSnackbar('${l10n.errorPickingImage}: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeImage() {
    setState(() {
      if (_selectedImageFile != null) {
        _selectedImageFile = null;
      } else if (_currentImagePath != null) {
        _currentImagePath = null;
      }
    });

    // Notify parent
    widget.onImageChanged?.call(null);
  }

  void _viewImageFullScreen() {
    if (_selectedImageFile != null || _currentImagePath != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(widget.label, style: TextStyle(color: Colors.white)),
            ),
            body: Center(child: InteractiveViewer(child: _selectedImageFile != null ? Image.file(_selectedImageFile!) : _buildImageWidget())),
          ),
        ),
      );
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red.shade600, duration: const Duration(seconds: 3)));
  }

  // Getter for current image file
  File? get selectedImageFile => _selectedImageFile;

  // Getter for current image path
  String? get currentImagePath => _currentImagePath;

  // Check if image was changed
  bool get isImageChanged => _selectedImageFile != null || _currentImagePath != null;
}
