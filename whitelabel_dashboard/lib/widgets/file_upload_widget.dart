import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class FileUploadWidget extends StatefulWidget {
  final Function(Uint8List bytes, String fileName) onFileSelected;
  final VoidCallback? onFileClear;

  const FileUploadWidget({
    super.key,
    required this.onFileSelected,
    this.onFileClear,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  Uint8List? _fileBytes;
  String? _fileName;
  bool _isHovering = false;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Validate file size (max 5MB)
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size must be less than 5MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _fileBytes = file.bytes;
          _fileName = file.name;
        });

        if (_fileBytes != null && _fileName != null) {
          widget.onFileSelected(_fileBytes!, _fileName!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearFile() {
    setState(() {
      _fileBytes = null;
      _fileName = null;
    });
    widget.onFileClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade900.withOpacity(0.3),
            Colors.blue.shade900.withOpacity(0.3),
          ],
        ),
        border: Border.all(
          color: _isHovering ? Colors.cyanAccent : Colors.white24,
          width: 2,
        ),
      ),
      child: _fileBytes == null ? _buildUploadZone() : _buildPreview(),
    );
  }

  Widget _buildUploadZone() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: InkWell(
        onTap: _pickFile,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 64,
                color: _isHovering ? Colors.cyanAccent : Colors.white70,
              ),
              const SizedBox(height: 16),
              Text(
                'Click to upload logo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _isHovering ? Colors.cyanAccent : Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'PNG format, max 5MB\nRecommended: 1024x1024px',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Image preview
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(_fileBytes!, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 24),
          // File info
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.greenAccent,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  _fileName ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_fileBytes!.length / 1024).toStringAsFixed(1)} KB',
                  style: const TextStyle(fontSize: 14, color: Colors.white60),
                ),
              ],
            ),
          ),
          // Clear button
          IconButton(
            onPressed: _clearFile,
            icon: const Icon(Icons.close),
            color: Colors.redAccent,
            iconSize: 32,
            tooltip: 'Remove file',
          ),
        ],
      ),
    );
  }
}
