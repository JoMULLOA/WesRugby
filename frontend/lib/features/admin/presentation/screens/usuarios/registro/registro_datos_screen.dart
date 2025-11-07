import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:intl/intl.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/estudiante_service.dart';
import 'package:wesrugby/data/services/refresh_service.dart';
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
                // Instrucciones del formato Excel
                _buildInstructionsSection(isDesktop, isTablet),
                const SizedBox(height: 24),
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
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _downloadTemplate,
                icon: Icon(Icons.download, color: WessexColors.deepRoyalBlue),
                label: Text(
                  'Descargar Plantilla',
                  style: TextStyle(color: WessexColors.deepRoyalBlue),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: WessexColors.deepRoyalBlue),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  'Nombre',
                  'Nombre completo del estudiante',
                  true,
                ),
                _buildColumnRow(
                  'Fecha Nacimiento',
                  'Formato recomendado: DD-MM-AAAA (ej: 05-04-2019)',
                  true,
                ),
                _buildColumnRow(
                  'RUN',
                  'RUN del estudiante con guión y dígito verificador',
                  true,
                ),
                _buildColumnRow(
                  'Categoria',
                  'Categoría deportiva (ej: M12, M14, M16)',
                  true,
                ),
                _buildColumnRow(
                  'Ficha',
                  'Indica SI/NO si cuenta con ficha médica completa',
                  true,
                ),
                _buildColumnRow(
                  'Curso',
                  'Curso académico actual (ej: 6° Básico, II Medio)',
                  true,
                ),
                _buildColumnRow(
                  'Nombre Madre',
                  'Nombre completo de la madre o tutora',
                  false,
                ),
                _buildColumnRow(
                  'N° Telefono Madre',
                  'Número de teléfono de la madre (solo dígitos)',
                  false,
                ),
                _buildColumnRow(
                  'Correo Electrónico Madre',
                  'Correo de contacto de la madre',
                  false,
                ),
                _buildColumnRow(
                  'Nombre Padre',
                  'Nombre completo del padre o tutor',
                  false,
                ),
                _buildColumnRow(
                  'N° Teléfono Padre',
                  'Número de teléfono del padre (solo dígitos)',
                  false,
                ),
                _buildColumnRow(
                  'Correo Electrónico Padre',
                  'Correo de contacto del padre',
                  false,
                ),
                _buildColumnRow(
                  'Hermanos',
                  'RUN de hermanos en el club separados por coma',
                  false,
                ),
                _buildColumnRow(
                  'Enfermedad',
                  'Antecedentes médicos relevantes',
                  false,
                ),
                _buildColumnRow(
                  'Talla',
                  'Talla de polera/polera deportiva',
                  false,
                ),
                _buildColumnRow(
                  'Dorsal Nombre',
                  'Nombre que llevará en la camiseta',
                  false,
                ),
                _buildColumnRow(
                  'Alumno Nuevo',
                  'Usar SI/NO para identificar ingresos recientes',
                  false,
                ),
                _buildColumnRow(
                  'Asistencia',
                  'Porcentaje de asistencia anual si está disponible',
                  false,
                ),
                _buildColumnRow(
                  'Matricula',
                  'Estado o monto de matrícula',
                  false,
                ),
                _buildColumnRow(
                  'Marzo',
                  'Pago o deuda del mes de marzo',
                  false,
                ),
                _buildColumnRow(
                  'Abril',
                  'Pago o deuda del mes de abril',
                  false,
                ),
                _buildColumnRow('Mayo', 'Pago o deuda del mes de mayo', false),
                _buildColumnRow(
                  'Junio',
                  'Pago o deuda del mes de junio',
                  false,
                ),
                _buildColumnRow(
                  'Julio',
                  'Pago o deuda del mes de julio',
                  false,
                ),
                _buildColumnRow(
                  'Agosto',
                  'Pago o deuda del mes de agosto',
                  false,
                ),
                _buildColumnRow(
                  'Septiembre',
                  'Pago o deuda del mes de septiembre',
                  false,
                ),
                _buildColumnRow(
                  'Octubre',
                  'Pago o deuda del mes de octubre',
                  false,
                ),
                _buildColumnRow(
                  'Noviembre',
                  'Pago o deuda del mes de noviembre',
                  false,
                ),
                _buildColumnRow(
                  'Diciembre',
                  'Pago o deuda del mes de diciembre',
                  false,
                ),
                _buildColumnRow(
                  'Total Año',
                  'Total cancelado o adeudado en el año',
                  false,
                ),
                _buildColumnRow(
                  'Poleron',
                  'Estado o entrega de polerón',
                  false,
                ),
                _buildColumnRow(
                  'Calcetas',
                  'Estado o entrega de calcetas',
                  false,
                ),
                _buildColumnRow(
                  'Protector Bucal',
                  'Estado o entrega de protector bucal',
                  false,
                ),
                _buildColumnRow(
                  'Uniforme',
                  'Estado o entrega de uniforme',
                  false,
                ),
                _buildColumnRow(
                  'Anadido',
                  'Observaciones adicionales de la directiva',
                  false,
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
                  '• No debe haber filas vacías entre los datos\n'
                  '• Máximo 500 registros por archivo',
                  style: TextStyle(color: WessexColors.leafGreen, fontSize: 12),
                ),
              ],
            ),
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
                columns: const [
                  DataColumn(
                    label: Text(
                      'NOMBRE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'FECHA NAC.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'RUT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'CATEGORIA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'FICHA',
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
                ],
                rows:
                    _previewData.take(10).map((student) {
                      final fichaValor = student['ficha'];
                      final fichaTexto =
                          fichaValor == null ||
                                  fichaValor.toString().trim().isEmpty
                              ? 'NO'
                              : fichaValor.toString().trim().toUpperCase();
                      final fichaColor = _getFichaColor(fichaValor);

                      return DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 160,
                              child: Text(
                                student['nombre']?.toString() ?? '',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              student['fechaNacimiento']?.toString() ?? '',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            Text(
                              student['rut']?.toString() ?? '',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            Text(
                              student['categoria']?.toString().toUpperCase() ??
                                  '',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: fichaColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                fichaTexto,
                                style: TextStyle(
                                  color: fichaColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              student['curso']?.toString() ?? '',
                              style: const TextStyle(fontSize: 11),
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
                Icons.warning_amber_rounded,
                color: WessexColors.goldenYellow,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Advertencias de Formato',
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
                  color: WessexColors.goldenYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_errorMessages.length} advertencias',
                  style: TextStyle(
                    color: WessexColors.darkGrape,
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
              color: WessexColors.goldenYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: WessexColors.goldenYellow.withOpacity(0.4),
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
                              color: WessexColors.darkGrape,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              error,
                              style: TextStyle(
                                color: WessexColors.darkGrape,
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

  Color _getFichaColor(dynamic ficha) {
    if (ficha == true) return WessexColors.leafGreen;
    if (ficha is String && ficha.toLowerCase() == 'si') {
      return WessexColors.leafGreen;
    }
    if (ficha == null ||
        (ficha is String && ficha.trim().isEmpty) ||
        ficha == false) {
      return WessexColors.crimsonAlert;
    }
    return WessexColors.deepRoyalBlue;
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
      debugPrint('Error al seleccionar archivo: $e');
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
      final rows = _decodeSpreadsheetRows(_fileData!);
      if (rows.isEmpty) {
        throw Exception('El archivo Excel está vacío');
      }

      final headerRow = rows.first;
      final List<String> headersOriginal = [];
      final List<String> headersNormalized = [];

      for (final cell in headerRow) {
        final cellText = _stringifyCellValue(cell, '');
        if (cellText.isEmpty) continue;
        headersOriginal.add(cellText);
        headersNormalized.add(_normalizeHeaderKey(cellText));
      }

      if (kDebugMode) {
        debugPrint('📋 Encabezados encontrados: $headersNormalized');
      }

      final Map<String, String> headerMapping = {
        'nombrecompleto': 'nombre',
        'nombre': 'nombre',
        'fechanacimiento': 'fechaNacimiento',
        'rut': 'rut',
        'categoria': 'categoria',
        'ficha': 'ficha',
        'curso': 'curso',
        'nombremadre': 'nombreMadre',
        'ntelefonomadre': 'telefonoMadre',
        'telefonomadre': 'telefonoMadre',
        'correoelectronicomadre': 'emailMadre',
        'correomadre': 'emailMadre',
        'nombrepadre': 'nombrePadre',
        'ntelefonopadre': 'telefonoPadre',
        'telefonopadre': 'telefonoPadre',
        'correoelectronicopadre': 'emailPadre',
        'correopadre': 'emailPadre',
        'responsable': 'responsable',
        'hermanos': 'hermanos',
        'enfermedad': 'enfermedad',
        'talla': 'talla',
        'dorsalnombre': 'dorsalNombre',
        'alumnonuevo': 'alumnoNuevo',
        'asistencia': 'asistencia',
        'matricula': 'matricula',
        'marzo': 'marzo',
        'abril': 'abril',
        'mayo': 'mayo',
        'junio': 'junio',
        'julio': 'julio',
        'agosto': 'agosto',
        'septiembre': 'septiembre',
        'octubre': 'octubre',
        'noviembre': 'noviembre',
        'diciembre': 'diciembre',
        'totalano': 'totalAnio',
        'totalanio': 'totalAnio',
        'totalanno': 'totalAnio',
        'poleron': 'poleron',
        'calcetas': 'calcetas',
        'protectorbucal': 'protectorBucal',
        'uniforme': 'uniforme',
        'anadido': 'anadido',
      };

      final Map<String, String> requiredFieldsMapping = {
        'nombre': 'Nombre',
        'fechanacimiento': 'Fecha nacimiento',
        'rut': 'RUT',
        'categoria': 'Categoria',
        'curso': 'Curso',
      };

      final Set<String> availableFields =
          headersNormalized
              .map((header) => headerMapping[header] ?? header)
              .toSet();

      final List<String> missingHeaders = [];
      for (final entry in requiredFieldsMapping.entries) {
        final requiredKey = headerMapping[entry.key] ?? entry.key;
        if (!availableFields.contains(requiredKey)) {
          missingHeaders.add(entry.value);
          if (kDebugMode) {
            debugPrint('❌ Header obligatorio faltante: ${entry.value}');
          }
        }
      }

      if (missingHeaders.isNotEmpty) {
        final foundHeaders = headersOriginal.join(', ');
        throw Exception(
          'Faltan las siguientes columnas: ${missingHeaders.join(', ')}\n\n'
          'Columnas encontradas: $foundHeaders',
        );
      }

      final List<Map<String, dynamic>> processedData = [];
      final List<String> warnings = [];

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];

        if (row.isEmpty || row.every((cell) => _cellIsEmpty(cell))) {
          continue;
        }

        final Map<String, dynamic> studentData = {};
        bool hasAnyValue = false;

        for (int j = 0; j < headersNormalized.length && j < row.length; j++) {
          final rawCell = row[j];
          final normalizedHeader = headersNormalized[j];
          final value = _stringifyCellValue(rawCell, normalizedHeader);
          if (value.isEmpty) continue;

          final mappedField =
              headerMapping[normalizedHeader] ?? normalizedHeader;
          studentData[mappedField] = value;
          hasAnyValue = true;

          if (kDebugMode) {
            debugPrint(
              '📋 Mapeado: "${headersOriginal[j]}" -> $mappedField = "$value"',
            );
          }
        }

        if (hasAnyValue) {
          _ensureResponsable(studentData);
          processedData.add(studentData);

          final rowIssues = _collectRowIssues(studentData);
          if (rowIssues.isNotEmpty) {
            warnings.add('Fila ${i + 1}: ${rowIssues.join(' · ')}');
          }
        }
      }

      setState(() {
        _previewData = processedData;
        _errorMessages = warnings;
        _showPreview = true;
        _isProcessing = false;
      });

      if (processedData.isNotEmpty) {
        final warningMessage =
            warnings.isNotEmpty
                ? ' (con ${warnings.length} advertencias de formato)'
                : '';
        _showSuccessSnackBar(
          'Archivo procesado: ${processedData.length} registros listos$warningMessage.',
        );
      } else {
        _showErrorSnackBar(
          'No se encontraron registros con datos en el archivo.',
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

  List<List<dynamic>> _decodeSpreadsheetRows(Uint8List bytes) {
    try {
      final decoder = SpreadsheetDecoder.decodeBytes(bytes);
      for (final table in decoder.tables.values) {
        if (table.rows.isNotEmpty) {
          return table.rows;
        }
      }
      throw Exception('No se encontraron hojas con datos en el archivo Excel');
    } catch (spreadsheetError) {
      if (kDebugMode) {
        debugPrint('⚠️ Error con SpreadsheetDecoder: $spreadsheetError');
        debugPrint('Intentando fallback con package:excel');
      }

      try {
        final excel = excel_lib.Excel.decodeBytes(bytes);
        for (final key in excel.tables.keys) {
          final table = excel.tables[key];
          if (table != null && table.rows.isNotEmpty) {
            return table.rows
                .map((row) => row.map((cell) => cell?.value).toList())
                .toList();
          }
        }
        throw Exception(
          'No se encontraron hojas con datos en el archivo Excel',
        );
      } catch (excelError) {
        throw Exception(
          'No se pudo leer el archivo Excel. Detalle: ${excelError.toString()}',
        );
      }
    }
  }

  bool _cellIsEmpty(dynamic cell) {
    if (cell == null) return true;
    if (cell is String) return cell.trim().isEmpty;
    if (cell is Iterable) return cell.every(_cellIsEmpty);
    return false;
  }

  String _stringifyCellValue(dynamic value, String headerKey) {
    if (value == null) {
      return '';
    }

    if (value is DateTime) {
      return DateFormat('dd-MM-yyyy').format(value.toLocal());
    }

    if (value is num) {
      if (headerKey == 'fechanacimiento') {
        final convertedDate = _excelSerialToDate(value);
        if (convertedDate != null) {
          return DateFormat('dd-MM-yyyy').format(convertedDate);
        }
      }

      if (value % 1 == 0) {
        return value.toInt().toString();
      }
      return value.toString();
    }

    final stringValue = value.toString().trim();
    if (headerKey == 'fechanacimiento') {
      final parsedDate = _parseFlexibleDate(stringValue);
      if (parsedDate != null) {
        return DateFormat('dd-MM-yyyy').format(parsedDate);
      }
    }

    return stringValue;
  }

  void _ensureResponsable(Map<String, dynamic> data) {
    final rawResponsable = data['responsable']?.toString().trim() ?? '';
    if (rawResponsable.isNotEmpty) {
      final normalized = rawResponsable.toLowerCase();
      if (normalized == 'madre') {
        data['responsable'] = 'Madre';
        return;
      }
      if (normalized == 'padre') {
        data['responsable'] = 'Padre';
        return;
      }

      final formatted = rawResponsable
          .split(RegExp(r'\s+'))
          .where((segment) => segment.isNotEmpty)
          .map((segment) {
            final lower = segment.toLowerCase();
            return lower.isEmpty
                ? ''
                : '${lower[0].toUpperCase()}${lower.substring(1)}';
          })
          .where((segment) => segment.isNotEmpty)
          .join(' ');

      data['responsable'] = formatted.isNotEmpty ? formatted : 'Madre';
      return;
    }

    final madreNombre = data['nombreMadre']?.toString().trim() ?? '';
    final padreNombre = data['nombrePadre']?.toString().trim() ?? '';

    if (madreNombre.isNotEmpty) {
      data['responsable'] = 'Madre';
    } else if (padreNombre.isNotEmpty) {
      data['responsable'] = 'Padre';
    } else {
      data['responsable'] = 'Madre';
    }
  }

  DateTime? _excelSerialToDate(num rawValue) {
    if (rawValue.isNaN) {
      return null;
    }

    final baseDate = DateTime(1899, 12, 30);
    final intDays = rawValue.floor();
    final fractionalDay = rawValue - intDays;
    final seconds = (fractionalDay * Duration.secondsPerDay).round();

    try {
      return baseDate
          .add(Duration(days: intDays))
          .add(Duration(seconds: seconds));
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseFlexibleDate(String raw) {
    if (raw.isEmpty) {
      return null;
    }

    final directParsed = DateTime.tryParse(raw);
    if (directParsed != null) {
      return DateTime(directParsed.year, directParsed.month, directParsed.day);
    }

    final normalized =
        raw
            .replaceAll('.', '-')
            .replaceAll('/', '-')
            .replaceAll(RegExp(r'\s+'), '')
            .trim();

    final isoSplit = normalized.split('T');
    final datePortion = isoSplit.isNotEmpty ? isoSplit.first : normalized;

    final parts =
        datePortion.split('-').where((segment) => segment.isNotEmpty).toList();

    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    int? year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) {
      return null;
    }

    if (year < 100) {
      year += year >= 50 ? 1900 : 2000;
    }

    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  String _normalizeHeaderKey(String header) {
    String normalized = header.toLowerCase().trim();
    const replacements = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ä': 'a',
      'ë': 'e',
      'ï': 'i',
      'ö': 'o',
      'ü': 'u',
      'ñ': 'n',
    };

    replacements.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });

    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');

    if (kDebugMode) {
      debugPrint('🔍 Header original: "$header" -> normalizado: "$normalized"');
    }

    return normalized;
  }

  List<String> _collectRowIssues(Map<String, dynamic> data) {
    if (kDebugMode) {
      debugPrint('🔍 Validando fila con datos: ${data.keys.join(', ')}');
      data.forEach((key, value) {
        debugPrint('  $key: "$value"');
      });
    }

    final List<String> issues = [];

    final nombre = data['nombre']?.toString().trim() ?? '';
    if (nombre.isEmpty) {
      issues.add('Nombre faltante');
      if (kDebugMode) {
        debugPrint('⚠️ Nombre faltante');
      }
    }

    final rut = data['rut']?.toString().trim() ?? '';
    if (rut.isEmpty) {
      issues.add('RUT faltante');
      if (kDebugMode) {
        debugPrint('⚠️ RUT faltante');
      }
    } else if (!RegExp(r'^[0-9\.\-kK]+$').hasMatch(rut) || rut.length < 8) {
      issues.add('RUT con formato inválido ($rut)');
      if (kDebugMode) {
        debugPrint('⚠️ RUT inválido: "$rut"');
      }
    }

    final fecha = data['fechaNacimiento']?.toString().trim() ?? '';
    if (fecha.isEmpty) {
      issues.add('Fecha de nacimiento faltante');
      if (kDebugMode) {
        debugPrint('⚠️ Fecha de nacimiento faltante');
      }
    } else {
      final fechaRegex = RegExp(r'^\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}$');
      if (!fechaRegex.hasMatch(fecha)) {
        issues.add('Fecha de nacimiento inválida ($fecha)');
        if (kDebugMode) {
          debugPrint('⚠️ Fecha de nacimiento inválida: "$fecha"');
        }
      }
    }

    final categoria = data['categoria']?.toString().trim();
    if (categoria != null && categoria.isNotEmpty) {
      final categoriaRegex = RegExp(r'^M\d{1,2}$', caseSensitive: false);
      if (!categoriaRegex.hasMatch(categoria.toUpperCase())) {
        issues.add('Categoria no reconocida ($categoria)');
        if (kDebugMode) {
          debugPrint('⚠️ Categoria no reconocida: "$categoria"');
        }
      }
    }

    if (kDebugMode && issues.isEmpty) {
      debugPrint('✅ Fila sin advertencias');
    }

    return issues;
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
        int correosGenerados = result['correosApoderadoGenerados'] ?? apoderadosCreados;
        int hermanosSincronizados = result['hermanosSincronizados'] ?? 0;
        List<dynamic> errores = result['errores'] ?? [];

        _showSuccessDialog(
          estudiantesCreados,
          apoderadosCreados,
          correosGenerados,
          hermanosSincronizados,
          errores,
        );

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
    final url = 'excelBase.xlsx';
    html.AnchorElement(href: url)
      ..setAttribute('download', 'plantilla.xlsx')
      ..click();
  }

  void _showSuccessDialog(
    int estudiantesCreados,
    int apoderadosCreados,
    int correosGenerados,
    int hermanosSincronizados,
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
                if (correosGenerados > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '📧 Se generaron $correosGenerados correos institucionales para apoderados.',
                      style: TextStyle(
                        color: WessexColors.darkGrape.withOpacity(0.7),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (hermanosSincronizados > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '🤝 Se sincronizaron $hermanosSincronizados hermanos con el mismo apoderado.',
                      style: TextStyle(
                        color: WessexColors.darkGrape.withOpacity(0.7),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
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
