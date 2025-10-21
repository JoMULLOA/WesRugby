import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart' as ExcelLib;
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/estudiante_service.dart';
import 'package:wesrugby/data/services/refresh_service.dart';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class RegistroDatosScreen extends StatefulWidget {
  const RegistroDatosScreen({super.key});

  @override
  State<RegistroDatosScreen> createState() => _RegistroDatosScreenState();
}

class _RegistroDatosScreenState extends State<RegistroDatosScreen> {
  final EstudianteService _estudianteService = EstudianteService();

  // Estado de carga
  bool _isProcessing = false;
  String? _fileName;
  Uint8List? _fileData;

  // Resultados del procesamiento
  List<Map<String, dynamic>> _previewData = [];
  List<String> _errorMessages = [];
  bool _showPreview = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(
        title: 'Registro Masivo de Datos',
        elevation: 2,
      ),
      body: WessexBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header informativo
                _buildHeaderSection(isDesktop, isTablet),
                const SizedBox(height: 24),

                // Instrucciones del formato Excel
                _buildInstructionsSection(isDesktop, isTablet),
                const SizedBox(height: 24),

                // Área de carga de archivo
                _buildUploadSection(isDesktop, isTablet),
                const SizedBox(height: 24),

                // Previsualización de datos
                if (_showPreview) ...[
                  _buildPreviewSection(isDesktop, isTablet),
                  const SizedBox(height: 24),
                ],

                // Errores encontrados
                if (_errorMessages.isNotEmpty) ...[
                  _buildErrorsSection(isDesktop, isTablet),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isDesktop, bool isTablet) {
    return WessexCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WessexColors.crimsonAlert.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.upload_file,
              color: WessexColors.crimsonAlert,
              size: isDesktop ? 32 : (isTablet ? 28 : 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registro Masivo de Estudiantes',
                  style: TextStyle(
                    color: WessexColors.darkGrape,
                    fontSize: isDesktop ? 24 : (isTablet ? 20 : 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Importa datos de estudiantes desde archivos Excel (.xlsx)',
                  style: TextStyle(
                    color: WessexColors.darkGrape.withOpacity(0.7),
                    fontSize: isDesktop ? 16 : (isTablet ? 14 : 12),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: WessexColors.deepRoyalBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'Solo Directiva',
                    style: TextStyle(
                      color: WessexColors.deepRoyalBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection(bool isDesktop, bool isTablet) {
    return WessexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: WessexColors.deepRoyalBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Formato Requerido del Excel',
                style: TextStyle(
                  color: WessexColors.darkGrape,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'El archivo Excel debe contener las siguientes columnas en la primera fila (encabezados):',
            style: TextStyle(
              color: WessexColors.darkGrape,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Tabla de columnas requeridas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WessexColors.mistyRoseGray.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: WessexColors.deepRoyalBlue.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                _buildColumnRow(
                  'Nombre Completo',
                  'Nombre completo del estudiante',
                  true,
                ),
                _buildColumnRow(
                  'RUN',
                  'RUN del estudiante (ej: 12345678-9)',
                  true,
                ),
                _buildColumnRow(
                  'Curso',
                  'Categoría deportiva (ej: Sub-16, Sub-18)',
                  true,
                ),
                _buildColumnRow(
                  'Nombre Madre',
                  'Nombre completo de la madre o tutora',
                  false,
                ),
                _buildColumnRow(
                  'Telefono Madre',
                  'Número de teléfono de la madre',
                  false,
                ),
                _buildColumnRow(
                  'Nombre Padre',
                  'Nombre completo del padre o tutor',
                  false,
                ),
                _buildColumnRow(
                  'Telefono Padre',
                  'Número de teléfono del padre',
                  false,
                ),
                _buildColumnRow(
                  'Validez',
                  'Estado del registro (Vigente/No Vigente)',
                  true,
                ),
                _buildColumnRow(
                  'Responsable',
                  'Nombre del responsable del registro',
                  true,
                ),
                _buildColumnRow(
                  'RUN Responsable',
                  'RUN del apoderado (ej: 12345678-9)',
                  true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Notas importantes
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WessexColors.leafGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: WessexColors.leafGreen.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: WessexColors.leafGreen,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Notas Importantes:',
                      style: TextStyle(
                        color: WessexColors.leafGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Los nombres de las columnas deben ser exactamente como se muestran arriba\n'
                  '• El RUT debe incluir guión y dígito verificador\n'
                  '• VALIDEZ acepta: "Activo", "Inactivo", "Vigente", "No Vigente"\n'
                  '• No debe haber filas vacías entre los datos\n'
                  '• Máximo 500 registros por archivo',
                  style: TextStyle(color: WessexColors.leafGreen, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Botón para descargar plantilla
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _downloadTemplate,
                  icon: Icon(Icons.download, color: WessexColors.deepRoyalBlue),
                  label: Text(
                    'Descargar Plantilla Excel',
                    style: TextStyle(color: WessexColors.deepRoyalBlue),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: WessexColors.deepRoyalBlue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColumnRow(String column, String description, bool required) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: WessexColors.deepRoyalBlue,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              column,
              style: TextStyle(
                color: WessexColors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(color: WessexColors.darkGrape, fontSize: 12),
            ),
          ),
          if (required) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: WessexColors.crimsonAlert,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Obligatorio',
                style: TextStyle(
                  color: WessexColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadSection(bool isDesktop, bool isTablet) {
    return WessexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cargar Archivo Excel',
            style: TextStyle(
              color: WessexColors.darkGrape,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Área de drop/upload
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border.all(
                color:
                    _fileName != null
                        ? WessexColors.leafGreen
                        : WessexColors.deepRoyalBlue,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color:
                  _fileName != null
                      ? WessexColors.leafGreen.withOpacity(0.1)
                      : WessexColors.deepRoyalBlue.withOpacity(0.1),
            ),
            child: Column(
              children: [
                Icon(
                  _fileName != null ? Icons.check_circle : Icons.cloud_upload,
                  size: 48,
                  color:
                      _fileName != null
                          ? WessexColors.leafGreen
                          : WessexColors.deepRoyalBlue,
                ),
                const SizedBox(height: 16),
                Text(
                  _fileName != null
                      ? 'Archivo seleccionado: $_fileName'
                      : 'Arrastra tu archivo Excel aquí o haz clic para seleccionar',
                  style: TextStyle(
                    color:
                        _fileName != null
                            ? WessexColors.leafGreen
                            : WessexColors.deepRoyalBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Formatos soportados: .xlsx (máximo 10MB)',
                  style: TextStyle(
                    color: WessexColors.darkGrape.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _pickFile,
                  icon: Icon(Icons.folder_open),
                  label: Text('Seleccionar Archivo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WessexColors.deepRoyalBlue,
                    foregroundColor: WessexColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_fileName != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _processFile,
                    icon:
                        _isProcessing
                            ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: WessexColors.white,
                              ),
                            )
                            : Icon(Icons.analytics),
                    label: Text(
                      _isProcessing ? 'Procesando...' : 'Procesar Archivo',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WessexColors.leafGreen,
                      foregroundColor: WessexColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _clearFile,
                  icon: Icon(Icons.clear),
                  label: Text('Limpiar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WessexColors.crimsonAlert,
                    side: BorderSide(color: WessexColors.crimsonAlert),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewSection(bool isDesktop, bool isTablet) {
    return WessexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: WessexColors.leafGreen, size: 24),
              const SizedBox(width: 12),
              Text(
                'Previsualización de Datos',
                style: TextStyle(
                  color: WessexColors.darkGrape,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: WessexColors.leafGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_previewData.length} registros encontrados',
                  style: TextStyle(
                    color: WessexColors.leafGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tabla de previsualización
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: WessexColors.mistyRoseGray),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  WessexColors.deepRoyalBlue.withOpacity(0.1),
                ),
                columns: [
                  DataColumn(
                    label: Text(
                      'NOMBRE COMPLETO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'RUN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'CURSO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'MADRE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'TEL. MADRE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'PADRE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'TEL. PADRE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'VALIDEZ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'RESPONSABLE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'RUN RESP.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
                rows:
                    _previewData.take(10).map((student) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Container(
                              width: 120,
                              child: Text(
                                student['nombreCompleto'] ??
                                    student['nombrecompleto'] ??
                                    '',
                                style: TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              student['run'] ?? '',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            Text(
                              student['curso'] ?? '',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            Container(
                              width: 100,
                              child: Text(
                                student['nombreMadre'] ??
                                    student['nombremadre'] ??
                                    '',
                                style: TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              student['telefonoMadre'] ??
                                  student['telefonomadre'] ??
                                  '',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            Container(
                              width: 100,
                              child: Text(
                                student['nombrePadre'] ??
                                    student['nombrepadre'] ??
                                    '',
                                style: TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              student['telefonoPadre'] ??
                                  student['telefonopadre'] ??
                                  '',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getValidezColor(
                                  student['validez'],
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                student['validez'] ?? '',
                                style: TextStyle(
                                  color: _getValidezColor(student['validez']),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              width: 100,
                              child: Text(
                                student['responsable'] ?? '',
                                style: TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              student['runResponsable'] ??
                                  student['runresponsable'] ??
                                  '',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),

          if (_previewData.length > 10) ...[
            const SizedBox(height: 12),
            Text(
              'Mostrando los primeros 10 registros de ${_previewData.length}',
              style: TextStyle(
                color: WessexColors.darkGrape.withOpacity(0.7),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _importData,
                  icon:
                      _isProcessing
                          ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: WessexColors.white,
                            ),
                          )
                          : Icon(Icons.save),
                  label: Text(
                    _isProcessing
                        ? 'Creando cuentas en BD...'
                        : 'Importar ${_previewData.length} Registros',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WessexColors.leafGreen,
                    foregroundColor: WessexColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _isProcessing ? null : _cancelImport,
                icon: Icon(Icons.cancel),
                label: Text('Cancelar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: WessexColors.crimsonAlert,
                  side: BorderSide(color: WessexColors.crimsonAlert),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorsSection(bool isDesktop, bool isTablet) {
    return WessexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: WessexColors.crimsonAlert,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Errores Encontrados',
                style: TextStyle(
                  color: WessexColors.darkGrape,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: WessexColors.crimsonAlert.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_errorMessages.length} errores',
                  style: TextStyle(
                    color: WessexColors.crimsonAlert,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WessexColors.crimsonAlert.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: WessexColors.crimsonAlert.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  _errorMessages.map((error) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              color: WessexColors.crimsonAlert,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              error,
                              style: TextStyle(
                                color: WessexColors.crimsonAlert,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getValidezColor(String? validez) {
    switch (validez?.toLowerCase()) {
      case 'activo':
      case 'vigente':
        return WessexColors.leafGreen;
      case 'inactivo':
      case 'no vigente':
        return WessexColors.crimsonAlert;
      default:
        return WessexColors.deepRoyalBlue;
    }
  }

  Future<void> _pickFile() async {
    try {
      if (kIsWeb) {
        final html.FileUploadInputElement uploadInput =
            html.FileUploadInputElement();
        uploadInput.accept = '.xlsx';
        uploadInput.click();

        uploadInput.onChange.listen((event) async {
          final files = uploadInput.files;
          if (files!.isNotEmpty) {
            final file = files[0];

            // Verificar tamaño (máx 10MB)
            if (file.size > 10 * 1024 * 1024) {
              _showErrorSnackBar(
                'El archivo es muy grande. Máximo 10MB permitido.',
              );
              return;
            }

            // Verificar extensión
            if (!file.name.toLowerCase().endsWith('.xlsx')) {
              _showErrorSnackBar('Solo se permiten archivos Excel (.xlsx).');
              return;
            }

            final reader = html.FileReader();
            reader.readAsArrayBuffer(file);
            reader.onLoadEnd.listen((event) {
              setState(() {
                _fileData = reader.result as Uint8List;
                _fileName = file.name;
                _showPreview = false;
                _errorMessages.clear();
                _previewData.clear();
              });

              _showSuccessSnackBar('Archivo seleccionado: ${file.name}');
            });
          }
        });
      } else {
        _showErrorSnackBar('Funcionalidad disponible solo en web por ahora');
      }
    } catch (e) {
      print('Error al seleccionar archivo: $e');
      _showErrorSnackBar('Error al seleccionar archivo: ${e.toString()}');
    }
  }

  void _clearFile() {
    setState(() {
      _fileName = null;
      _fileData = null;
      _showPreview = false;
      _errorMessages.clear();
      _previewData.clear();
    });
  }

  Future<void> _processFile() async {
    if (_fileData == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessages.clear();
      _previewData.clear();
    });

    try {
      // Procesar archivo Excel real
      var excel = ExcelLib.Excel.decodeBytes(_fileData!);

      // Buscar la primera hoja con datos
      String? firstSheetName;
      for (var table in excel.tables.keys) {
        if (excel.tables[table]!.rows.isNotEmpty) {
          firstSheetName = table;
          break;
        }
      }

      if (firstSheetName == null) {
        throw Exception(
          'No se encontraron hojas con datos en el archivo Excel',
        );
      }

      var sheet = excel.tables[firstSheetName]!;
      List<Map<String, dynamic>> processedData = [];
      List<String> errors = [];

      // Obtener encabezados de la primera fila
      if (sheet.rows.isEmpty) {
        throw Exception('El archivo Excel está vacío');
      }

      var headerRow = sheet.rows[0];
      List<String> headers = [];

      for (var cell in headerRow) {
        if (cell?.value != null) {
          headers.add(cell!.value.toString().toLowerCase().trim());
        }
      }

      print('📋 Encabezados encontrados: $headers');

      // Mapear encabezados EXACTAMENTE como aparecen en tu Excel (dos columnas separadas)
      Map<String, String> headerMapping = {
        'nombre completo': 'nombreCompleto', // Columna A del Excel
        'run': 'run', // Columna B del Excel
        'curso': 'curso', // Columna C del Excel
        'nombre madre': 'nombreMadre', // Columna D del Excel
        'telefono madre': 'telefonoMadre', // Columna E del Excel
        'nombre padre': 'nombrePadre', // Columna F del Excel
        'telefono padre': 'telefonoPadre', // Columna G del Excel
        'validez': 'validez', // Columna H del Excel
        'responsable': 'responsable', // Columna I del Excel
        'run responsable': 'runResponsable', // Columna J del Excel
        // Variantes adicionales por compatibilidad
        'nombrecompleto': 'nombreCompleto',
        'nombremadre': 'nombreMadre',
        'telefonomadre': 'telefonoMadre',
        'nombrepadre': 'nombrePadre',
        'telefonopadre': 'telefonoPadre',
        'runresponsable': 'runResponsable',
        'rutresponsable': 'runResponsable',
      };

      // Debug: imprimir todos los headers encontrados
      if (kDebugMode) {
        print('🔍 Headers encontrados en Excel:');
        for (int i = 0; i < headers.length; i++) {
          print('  $i: "${headers[i]}"');
        }
      }

      // Verificar que todos los campos obligatorios estén presentes
      // Mapeamos desde los nombres del Excel a los campos internos (DOS columnas separadas)
      Map<String, String> requiredFieldsMapping = {
        'nombre completo': 'nombreCompleto', // Columna A
        'run': 'run', // Columna B
        'curso': 'curso', // Columna C
        'validez': 'validez', // Columna H
        'responsable': 'responsable', // Columna I
        'run responsable': 'runResponsable', // Columna J
      };

      List<String> missingHeaders = [];

      for (String excelHeader in requiredFieldsMapping.keys) {
        String internalField = requiredFieldsMapping[excelHeader]!;

        bool headerExists = headers.any(
          (h) => h.toLowerCase().trim() == excelHeader,
        );

        if (!headerExists) {
          missingHeaders.add(excelHeader);
          if (kDebugMode) {
            print('❌ Header obligatorio faltante en Excel: "$excelHeader"');
          }
        } else {
          if (kDebugMode) {
            print(
              '✅ Header obligatorio encontrado: "$excelHeader" -> $internalField',
            );
          }
        }
      }

      if (missingHeaders.isNotEmpty) {
        String expectedHeaders = requiredFieldsMapping.keys.join(', ');
        String foundHeaders = headers.join(', ');
        throw Exception(
          'Faltan las siguientes columnas: ${missingHeaders.join(', ')}\n\n'
          'Columnas esperadas: $expectedHeaders\n'
          'Columnas encontradas: $foundHeaders',
        );
      }

      // Procesar cada fila de datos (saltando la primera que son encabezados)
      for (int i = 1; i < sheet.rows.length; i++) {
        var row = sheet.rows[i];

        if (row.isEmpty || row.every((cell) => cell?.value == null)) {
          continue; // Saltar filas vacías
        }

        Map<String, dynamic> studentData = {};
        bool hasValidData = false;

        // Mapear datos de la fila actual
        for (int j = 0; j < headers.length && j < row.length; j++) {
          String originalHeader = headers[j];
          String normalizedHeader = originalHeader.toLowerCase().trim();
          var cellValue = row[j]?.value;

          if (cellValue != null) {
            String value = cellValue.toString().trim();
            if (value.isNotEmpty) {
              // Buscar el campo mapeado correspondiente
              String? mappedField = headerMapping[normalizedHeader];
              if (mappedField != null) {
                studentData[mappedField] = value;
                hasValidData = true;
                if (kDebugMode) {
                  print(
                    '📋 Mapeado: "$originalHeader" -> $mappedField = "$value"',
                  );
                }
              } else {
                // Si no hay mapeo directo, usar el header normalizado
                String normalizedField = _normalizeHeaderName(originalHeader);
                studentData[normalizedField] = value;
                hasValidData = true;
                if (kDebugMode) {
                  print(
                    '📋 Sin mapeo directo: "$originalHeader" -> $normalizedField = "$value"',
                  );
                }
              }
            }
          }
        }

        if (hasValidData) {
          // Validar campos obligatorios
          if (_isValidStudentRow(studentData)) {
            processedData.add(studentData);
          } else {
            errors.add('Fila ${i + 1}: Datos incompletos o inválidos');
          }
        }
      }

      setState(() {
        _previewData = processedData;
        _errorMessages = errors;
        _showPreview = true;
        _isProcessing = false;
      });

      if (processedData.isNotEmpty) {
        _showSuccessSnackBar(
          'Archivo procesado: ${processedData.length} registros válidos encontrados.',
        );
      } else {
        _showErrorSnackBar(
          'No se encontraron registros válidos en el archivo.',
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessages = ['Error al procesar el archivo: ${e.toString()}'];
      });
      _showErrorSnackBar('Error al procesar archivo: ${e.toString()}');
    }
  }

  String _normalizeHeaderName(String header) {
    // Solo normalizar a minúsculas y quitar espacios extra
    String normalized = header.toLowerCase().trim();

    if (kDebugMode) {
      print('🔍 Header original: "$header" -> normalizado: "$normalized"');
    }

    return normalized;
  }

  bool _isValidStudentRow(Map<String, dynamic> data) {
    // Debug: imprimir los datos de la fila para diagnóstico
    if (kDebugMode) {
      print('🔍 Validando fila con datos: ${data.keys.join(', ')}');
      data.forEach((key, value) {
        print('  $key: "$value"');
      });
    }

    // Campos obligatorios (dos columnas separadas: nombreCompleto y run)
    List<String> requiredFields = [
      'nombreCompleto',
      'run',
      'curso',
      'validez',
      'responsable',
      'runResponsable',
    ];

    for (String field in requiredFields) {
      if (!data.containsKey(field) ||
          data[field] == null ||
          data[field].toString().trim().isEmpty) {
        if (kDebugMode) {
          print('❌ Campo obligatorio faltante o vacío: $field');
        }
        return false;
      }
    }

    // Validación básica de RUN del estudiante
    String runEstudiante = data['run']?.toString() ?? '';
    if (!runEstudiante.contains('-') || runEstudiante.length < 9) {
      if (kDebugMode) {
        print('❌ RUN estudiante inválido: "$runEstudiante"');
      }
      return false;
    }

    // Validación básica de RUN del responsable
    String runResponsable = data['runResponsable']?.toString() ?? '';
    if (!runResponsable.contains('-') || runResponsable.length < 9) {
      if (kDebugMode) {
        print('❌ RUN responsable inválido: "$runResponsable"');
      }
      return false;
    }

    if (kDebugMode) {
      print('✅ Fila válida');
    }
    return true;
  }

  Future<void> _importData() async {
    try {
      setState(() {
        _isProcessing = true;
      });

      // Importar datos usando el servicio (ahora devuelve un Map con resultados)
      Map<String, dynamic> result = await _estudianteService
          .importStudentsFromExcel(_previewData);

      setState(() {
        _isProcessing = false;
      });

      if (result['success'] == true) {
        int estudiantesCreados = result['estudiantesCreados'] ?? 0;
        int apoderadosCreados = result['apoderadosCreados'] ?? 0;
        List<dynamic> errores = result['errores'] ?? [];

        _showSuccessDialog(estudiantesCreados, apoderadosCreados, errores);

        // Notificar que se han actualizado los usuarios
        RefreshService().notifyUsuariosChanged();

        // Limpiar después de importar exitosamente
        setState(() {
          _fileName = null;
          _fileData = null;
          _showPreview = false;
          _previewData.clear();
          _errorMessages.clear();
        });
      } else {
        _showErrorSnackBar(
          'Error durante la importación: ${result['message']}',
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorSnackBar('Error al importar datos: ${e.toString()}');
    }
  }

  void _cancelImport() {
    setState(() {
      _showPreview = false;
      _previewData.clear();
      _errorMessages.clear();
    });
  }

  void _downloadTemplate() {
    // Simular descarga de plantilla Excel
    _showSuccessSnackBar('Plantilla Excel descargada exitosamente');
  }

  void _showSuccessDialog(
    int estudiantesCreados,
    int apoderadosCreados,
    List<dynamic> errores,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: WessexColors.leafGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: WessexColors.leafGreen,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '¡Importación Completada!',
                  style: TextStyle(
                    color: WessexColors.darkGrape,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Se han creado $estudiantesCreados estudiantes en la base de datos.',
                  style: TextStyle(
                    color: WessexColors.darkGrape.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '👥 Se crearon $apoderadosCreados cuentas de apoderado con correos formato nombre.apellido0@wessex.cl',
                  style: TextStyle(
                    color: WessexColors.deepRoyalBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (errores.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: WessexColors.crimsonAlert.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ ${errores.length} error(es) durante la importación:',
                          style: TextStyle(
                            color: WessexColors.crimsonAlert,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...errores
                            .take(3)
                            .map(
                              (error) => Text(
                                '• ${error['error'] ?? error.toString()}',
                                style: TextStyle(
                                  color: WessexColors.crimsonAlert,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        if (errores.length > 3)
                          Text(
                            '... y ${errores.length - 3} errores más',
                            style: TextStyle(
                              color: WessexColors.crimsonAlert.withOpacity(0.7),
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🔑 Las contraseñas por defecto son "wessex123". Los apoderados pueden cambiarlas al ingresar por primera vez.',
                    style: TextStyle(
                      color: WessexColors.deepRoyalBlue,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WessexColors.leafGreen,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Entendido',
                      style: TextStyle(
                        color: WessexColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: WessexColors.leafGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: WessexColors.crimsonAlert,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
