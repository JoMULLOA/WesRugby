import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/data/services/background_service.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';

class ConfiguracionFondoScreen extends StatefulWidget {
  const ConfiguracionFondoScreen({super.key});

  @override
  State<ConfiguracionFondoScreen> createState() =>
      _ConfiguracionFondoScreenState();
}

class _ConfiguracionFondoScreenState extends State<ConfiguracionFondoScreen> {
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isUploading = false;
  bool _isSaving = false;
  String? _previewUrl; // URL que estamos a punto de guardar

  @override
  void initState() {
    super.initState();
    _previewUrl = BackgroundService.instance.backgroundUrl.value;
  }

  Future<void> _selectImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() {
      _imageBytes = file.bytes;
      _imageName = file.name;
    });
  }

  Future<void> _uploadAndSave() async {
    if (_imageBytes == null || _imageName == null) return;

    setState(() => _isUploading = true);
    try {
      final mimeType = _imageName!.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';

      final url = await ApiService.uploadImagenInformacionPublica(
        bytes: _imageBytes!,
        fileName: _imageName!,
        mimeType: mimeType,
      );

      if (url == null) {
        _showSnack('Error al subir la imagen. Intenta nuevamente.', error: true);
        return;
      }

      setState(() {
        _isUploading = false;
        _isSaving = true;
        _previewUrl = url;
      });

      final ok = await BackgroundService.instance.actualizar(url);
      if (ok) {
        setState(() {
          _imageBytes = null;
          _imageName = null;
        });
        _showSnack('¡Fondo actualizado exitosamente!');
      } else {
        _showSnack('Error al guardar el fondo en el servidor.', error: true);
      }
    } finally {
      if (mounted) setState(() => _isUploading = _isSaving = false);
    }
  }

  Future<void> _restoreDefault() async {
    setState(() => _isSaving = true);
    final ok = await BackgroundService.instance.actualizar(null);
    if (mounted) {
      setState(() {
        _isSaving = false;
        _previewUrl = null;
        _imageBytes = null;
        _imageName = null;
      });
      if (ok) {
        _showSnack('Fondo restablecido al predeterminado.');
      } else {
        _showSnack('Error al restablecer el fondo.', error: true);
      }
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? WessexColors.crimsonAlert : WessexColors.leafGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 600;

    return Scaffold(
      appBar: const WessexAppBar(
        title: 'Fondo de la Aplicación',
        elevation: 2,
      ),
      body: WessexBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32 : (isTablet ? 24 : 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info card
                WessexCard(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.wallpaper,
                          color: WessexColors.deepRoyalBlue,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fondo de la Aplicación',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: WessexColors.darkGrape,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'El fondo se aplica a todas las pantallas internas de la aplicación para todos los usuarios.',
                              style: TextStyle(
                                fontSize: 13,
                                color: WessexColors.darkGrape,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Vista previa actual
                WessexCard(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vista previa actual',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: WessexColors.darkGrape,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<String?>(
                        valueListenable:
                            BackgroundService.instance.backgroundUrl,
                        builder: (context, currentUrl, _) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: isDesktop ? 260 : 180,
                              width: double.infinity,
                              color: WessexColors.mistyRoseGray,
                              child: currentUrl != null
                                  ? Image.network(
                                      currentUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, e, st) =>
                                          _defaultBgPreview(),
                                    )
                                  : _defaultBgPreview(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<String?>(
                        valueListenable:
                            BackgroundService.instance.backgroundUrl,
                        builder: (context, currentUrl, _) {
                          return Text(
                            currentUrl != null
                                ? 'Fondo personalizado activo'
                                : 'Fondo predeterminado activo',
                            style: TextStyle(
                              fontSize: 12,
                              color: WessexColors.darkGrape.withOpacity(0.6),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Subir nueva imagen
                WessexCard(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cambiar fondo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: WessexColors.darkGrape,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Selector de archivo
                      InkWell(
                        onTap: _isUploading || _isSaving ? null : _selectImage,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _imageBytes != null
                                  ? WessexColors.leafGreen
                                  : WessexColors.deepRoyalBlue.withOpacity(0.3),
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            color: _imageBytes != null
                                ? WessexColors.leafGreen.withOpacity(0.05)
                                : Colors.transparent,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _imageBytes != null
                                    ? Icons.check_circle
                                    : Icons.upload_file,
                                size: 48,
                                color: _imageBytes != null
                                    ? WessexColors.leafGreen
                                    : WessexColors.deepRoyalBlue.withOpacity(0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _imageName ?? 'Toca para seleccionar imagen de fondo',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _imageBytes != null
                                      ? WessexColors.leafGreen
                                      : WessexColors.darkGrape.withOpacity(0.7),
                                  fontWeight: _imageBytes != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_imageBytes == null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Formatos: PNG, JPG, JPEG, WEBP',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: WessexColors.darkGrape.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Preview de la imagen seleccionada
                      if (_imageBytes != null) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            _imageBytes!,
                            height: isDesktop ? 200 : 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Botones
                      Row(
                        children: [
                          if (_imageBytes != null)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isUploading || _isSaving
                                    ? null
                                    : _uploadAndSave,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: WessexColors.leafGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: _isUploading || _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: Text(
                                  _isUploading
                                      ? 'Subiendo...'
                                      : _isSaving
                                          ? 'Guardando...'
                                          : 'Guardar fondo',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Restablecer predeterminado
                WessexCard(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.restore,
                            color: WessexColors.primaryAction,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Restablecer predeterminado',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: WessexColors.darkGrape,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Elimina el fondo personalizado y vuelve a la imagen de fondo por defecto de la aplicación.',
                        style: TextStyle(
                          fontSize: 13,
                          color: WessexColors.darkGrape.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isUploading || _isSaving
                              ? null
                              : _restoreDefault,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: WessexColors.primaryAction,
                            side: const BorderSide(
                                color: WessexColors.primaryAction),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: WessexColors.primaryAction,
                                  ),
                                )
                              : const Icon(Icons.restore),
                          label: const Text(
                            'Usar fondo predeterminado',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultBgPreview() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            WessexColors.midnightNavy,
            WessexColors.deepRoyalBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Text(
          'Fondo predeterminado',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ),
    );
  }
}
