import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/upload_service.dart';

class ImageUploadWidget extends StatefulWidget {
  final String label;
  final String? initialImageUrl;
  final Function(String? imageUrl)? onImageUploaded;
  final Function(String? error)? onError;
  final double height;
  final double width;
  final IconData placeholderIcon;

  const ImageUploadWidget({
    super.key,
    required this.label,
    this.initialImageUrl,
    this.onImageUploaded,
    this.onError,
    this.height = 120,
    this.width = double.infinity,
    this.placeholderIcon = Icons.image,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  String? _currentImageUrl;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.initialImageUrl;
  }

  Future<void> _pickAndUploadImage() async {
    try {
      setState(() => _isUploading = true);

      // Seleccionar archivo
      final fileData = await UploadService.pickImageFile();
      if (fileData == null) {
        setState(() => _isUploading = false);
        return;
      }

      // Validar tipo de archivo
      if (!UploadService.isValidImageType(fileData['type'])) {
        widget.onError?.call('Tipo de archivo no válido. Solo se permiten imágenes.');
        setState(() => _isUploading = false);
        return;
      }

      // Validar tamaño
      if (fileData['size'] > 5 * 1024 * 1024) {
        widget.onError?.call('El archivo es muy grande. Máximo 5MB permitido.');
        setState(() => _isUploading = false);
        return;
      }

      // Mostrar vista previa inmediatamente
      setState(() {
        _selectedImageBytes = fileData['bytes'];
        _selectedImageName = fileData['name'];
      });

      // Subir al servidor
      final uploadResult = await UploadService.uploadImage(
        filename: fileData['name'],
        bytes: fileData['bytes'],
        mimeType: fileData['type'],
      );

      print('Upload result: $uploadResult'); // Debug log
      
      if (uploadResult != null && uploadResult['url'] != null) {
        setState(() {
          _currentImageUrl = uploadResult['url'];
          _selectedImageBytes = null; // Limpiar preview local
          _selectedImageName = null;
        });
        widget.onImageUploaded?.call(uploadResult['url']);
      } else {
        print('Upload failed - uploadResult: $uploadResult'); // Debug log
        setState(() {
          _selectedImageBytes = null;
          _selectedImageName = null;
        });
        widget.onError?.call('Error al subir la imagen al servidor.');
      }
    } catch (e) {
      setState(() {
        _selectedImageBytes = null;
        _selectedImageName = null;
      });
      widget.onError?.call('Error al procesar la imagen: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _removeImage() {
    setState(() {
      _currentImageUrl = null;
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
    widget.onImageUploaded?.call(null);
  }

  Widget _buildImageDisplay() {
    // Si hay una imagen siendo subida, mostrar preview
    if (_selectedImageBytes != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _selectedImageBytes!,
              width: widget.width,
              height: widget.height,
              fit: BoxFit.cover,
            ),
          ),
          if (_isUploading)
            Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      );
    }

    // Si hay una imagen en el servidor, mostrarla
    if (_currentImageUrl != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              UploadService.getImageUrl(_currentImageUrl!.split('/').last),
              width: widget.width,
              height: widget.height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.placeholderIcon,
                  size: 40,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: _removeImage,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
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
      );
    }

    // Placeholder cuando no hay imagen
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        widget.placeholderIcon,
        size: 40,
        color: Colors.grey[400],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _buildImageDisplay(),
        const SizedBox(height: 8),
        SizedBox(
          width: widget.width,
          child: OutlinedButton.icon(
            onPressed: _isUploading ? null : _pickAndUploadImage,
            icon: _isUploading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload),
            label: Text(
              _isUploading 
                  ? 'Subiendo...'
                  : (_currentImageUrl != null || _selectedImageBytes != null)
                      ? 'Cambiar Imagen'
                      : 'Seleccionar Imagen',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (_selectedImageName != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Archivo: $_selectedImageName',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }
}