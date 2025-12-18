import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/estudiante_service.dart';
import 'dart:html' as html;
class RegistroFormulariosScreen extends StatefulWidget {
  const RegistroFormulariosScreen({super.key});

  @override
  State<RegistroFormulariosScreen> createState() => _RegistroFormulariosScreenState();
}

class _RegistroFormulariosScreenState extends State<RegistroFormulariosScreen> {
  final EstudianteService _estudianteService = EstudianteService();

  // Estado de carga
  bool _isProcessing = false;
  String? _fileName;

  // Resultados del procesamiento
  List<Map<String, dynamic>> _previewData = [];
  List<String> _errorMessages = [];
  bool _showPreview = false;

  // Columnas esperadas del formulario
  final List<String> _columnasRequeridas = [
    'Marca temporal',
    'Nombre Completo del alumno',
    'Alumno nuevo en la Rama de Rugby',
    'Fecha de nacimiento',
    'Run',
    'Curso y Letra',
    'Indique si presenta alguna enfermedad',
    'En caso que su respuesta anterior sea SI, indicar CUAL (Debe hacer llegar Certificado Médico) a ramarugbyweesex@gmail.com',
    'Run hermano',
    'Requiere confección de uniforme',
    'En caso que la respuesta anterior sea un SI , indicar Talla',
    'Nombre dorsal ( nombre espalda , puede ser apellido, nombre , apodo, etc.)',
    'Nombre madre',
    'N° telefono madre',
    'Correo electrónico madre',
    'Nombre padre',
    'N° teléfono padre',
    'Correo electrónico padre',
    'Responsable',
  ];

  static const Map<String, List<String>> _excelAliases = {
    'nombre': ['Nombre Completo del alumno', 'Nombre Completo', 'Nombre'],
    'alumnoNuevo': ['Alumno nuevo en la Rama de Rugby', 'Alumno nuevo'],
    'fechaNacimiento': ['Fecha de nacimiento'],
    'rut': ['Run', 'RUT'],
    'curso': ['Curso y Letra', 'Curso'],
    'tieneEnfermedad': ['Indique si presenta alguna enfermedad'],
    'detalleEnfermedad': [
      'En caso que su respuesta anterior sea SI, indicar CUAL (Debe hacer llegar Certificado Médico) a ramarugbyweesex@gmail.com',
      'Detalle enfermedad',
    ],
    'hermanosTexto': ['Run hermano', 'Hermanos'],
    'requiereUniforme': ['Requiere confección de uniforme'],
    'talla': ['En caso que la respuesta anterior sea un SI , indicar Talla', 'Talla'],
    'nombreDorsal': ['Nombre dorsal ( nombre espalda , puede ser apellido, nombre , apodo, etc.)', 'Nombre dorsal'],
    'nombreMadre': ['Nombre madre'],
    'telefonoMadre': ['N° telefono madre', 'Número telefono madre'],
    'emailMadre': ['Correo electrónico madre'],
    'nombrePadre': ['Nombre padre'],
    'telefonoPadre': ['N° teléfono padre'],
    'emailPadre': ['Correo electrónico padre'],
    'responsable': ['Responsable'],
  };

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(
        title: 'Importar Formularios de Registro',
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
              color: WessexColors.leafGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.file_upload,
              color: WessexColors.leafGreen,
              size: isDesktop ? 32 : (isTablet ? 28 : 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Importar Formularios de Registro',
                  style: TextStyle(
                    color: WessexColors.darkGrape,
                    fontSize: isDesktop ? 24 : (isTablet ? 20 : 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Carga masiva de estudiantes desde formularios Google Forms (.xlsx)',
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

          // Botón de carga
          Center(
            child: Column(
              children: [
                Container(
                  width: isDesktop ? 400 : double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: WessexColors.deepRoyalBlue.withOpacity(0.3),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: WessexColors.deepRoyalBlue.withOpacity(0.05),
                  ),
                  child: InkWell(
                    onTap: _isProcessing ? null : _pickFile,
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          size: 64,
                          color: WessexColors.deepRoyalBlue,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _fileName ?? 'Click para seleccionar archivo',
                          style: TextStyle(
                            color: WessexColors.darkGrape,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Formato: .xlsx (Excel de Google Forms)',
                          style: TextStyle(
                            color: WessexColors.darkGrape.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (_isProcessing) ...[
                  const SizedBox(height: 24),
                  CircularProgressIndicator(
                    color: WessexColors.deepRoyalBlue,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Procesando archivo...',
                    style: TextStyle(
                      color: WessexColors.darkGrape,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vista Previa (${_previewData.length} registros)',
                style: TextStyle(
                  color: WessexColors.darkGrape,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _importarDatos,
                icon: const Icon(Icons.upload),
                label: Text(
                  _isProcessing
                      ? 'Importando...'
                      : 'Importar ${_previewData.length} Registros',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WessexColors.leafGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tabla de previsualización
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                WessexColors.deepRoyalBlue.withOpacity(0.1),
              ),
              columns: const [
                DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('RUT', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Curso', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Alumno Nuevo', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Talla', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Madre', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Padre', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _previewData.take(10).map((registro) {
                return DataRow(cells: [
                  DataCell(Text(registro['nombre'] ?? '')),
                  DataCell(Text(registro['rut'] ?? '')),
                  DataCell(Text(registro['curso'] ?? '')),
                  DataCell(Text(registro['esAlumnoNuevo'] == true ? 'Sí' : 'No')),
                  DataCell(Text(registro['talla'] ?? '-')),
                  DataCell(Text(registro['nombreMadre'] ?? '')),
                  DataCell(Text(registro['nombrePadre'] ?? '')),
                ]);
              }).toList(),
            ),
          ),
          
          if (_previewData.length > 10) ...[
            const SizedBox(height: 12),
            Text(
              'Mostrando 10 de ${_previewData.length} registros',
              style: TextStyle(
                color: WessexColors.darkGrape.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
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
                Icons.warning,
                color: WessexColors.crimsonAlert,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Errores Encontrados (${_errorMessages.length})',
                style: TextStyle(
                  color: WessexColors.crimsonAlert,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
              children: _errorMessages.map((error) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: WessexColors.crimsonAlert,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
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
          Center(
            child: ElevatedButton.icon(
              onPressed: _downloadTemplate,
              icon: const Icon(Icons.download),
              label: const Text('Descargar Plantilla Base'),
              style: ElevatedButton.styleFrom(
                backgroundColor: WessexColors.leafGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'El archivo Excel debe ser exportado directamente desde Google Forms y contener las siguientes columnas en orden:',
            style: TextStyle(
              color: WessexColors.darkGrape,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Lista de columnas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WessexColors.deepRoyalBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: WessexColors.deepRoyalBlue.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _columnasRequeridas.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final columna = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: WessexColors.deepRoyalBlue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          columna,
                          style: const TextStyle(
                            fontSize: 13,
                            color: WessexColors.darkGrape,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WessexColors.crimsonAlert.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: WessexColors.crimsonAlert,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'IMPORTANTE: Las columnas deben estar en el mismo orden que aparecen en el formulario de Google Forms.',
                    style: TextStyle(
                      color: WessexColors.darkGrape,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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

  void _downloadTemplate() {
    const url = 'formBase.xlsx';
    html.AnchorElement(href: url)
      ..setAttribute('download', 'plantilla_registro.xlsx')
      ..click();
  }

  Future<void> _pickFile() async {
    try {
      final uploadInput = html.FileUploadInputElement()..accept = '.xlsx';
      uploadInput.click();

      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files == null || files.isEmpty) return;

        final file = files[0];
        final reader = html.FileReader();

        reader.onLoadEnd.listen((e) async {
          if (reader.result != null) {
            final bytes = reader.result as Uint8List;
            setState(() {
              _fileName = file.name;
              _isProcessing = true;
              _errorMessages = [];
              _previewData = [];
              _showPreview = false;
            });

            await _processFile(bytes);
          }
        });

        reader.readAsArrayBuffer(file);
      });
    } catch (e) {
      _showErrorSnackBar('Error al seleccionar archivo: $e');
    }
  }

  Future<void> _processFile(Uint8List bytes) async {
    try {
      final excel = excel_lib.Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first];

      if (sheet == null || sheet.rows.isEmpty) {
        setState(() {
          _errorMessages.add('El archivo está vacío');
          _isProcessing = false;
        });
        return;
      }

      // Validar encabezados
      final headers = sheet.rows.first.map((cell) => cell?.value?.toString() ?? '').toList();
      final headerIndex = _buildHeaderIndex(headers);
      
      final List<Map<String, dynamic>> datos = [];
      final List<String> errores = [];

      // Procesar filas (saltar encabezado)
      final totalRows = sheet.maxRows;
      for (int i = 1; i < totalRows; i++) {
        final row = i < sheet.rows.length ? sheet.rows[i] : <excel_lib.Data?>[];
        
        try {
          if (_isRowEmpty(row)) {
            continue;
          }

          final registro = _procesarFila(
            headers,
            sheet,
            headerIndex,
            row,
            i,
            i + 1,
          );
          if (registro != null) {
            datos.add(registro);
          }
        } catch (e) {
          errores.add('Fila ${i + 1}: $e');
        }
      }

      setState(() {
        _previewData = datos;
        _errorMessages = errores;
        _showPreview = datos.isNotEmpty;
        _isProcessing = false;
      });

      if (datos.isEmpty && errores.isEmpty) {
        _showErrorSnackBar('No se encontraron datos válidos en el archivo');
      }
    } catch (e) {
      setState(() {
        _errorMessages.add('Error al procesar archivo: $e');
        _isProcessing = false;
      });
      _showErrorSnackBar('Error al procesar el archivo');
    }
  }

  Map<String, dynamic>? _procesarFila(
    List<String> headers,
    excel_lib.Sheet sheet,
    Map<String, int> headerIndex,
    List<excel_lib.Data?> row,
    int rowIndex,
    int rowNumber,
  ) {
    String readValue(String key) {
      final aliases = _excelAliases[key] ?? [key];
      for (final alias in aliases) {
        final normalized = _normalizeHeader(alias);
        final columnIndex = headerIndex[normalized];
        if (columnIndex == null) continue;
        final value = _readCell(sheet, rowIndex, columnIndex);
        if (value.isNotEmpty) {
          return value;
        }
      }
      return '';
    }

    final nombreCompleto = readValue('nombre');
    final alumnoNuevoRaw = readValue('alumnoNuevo');
    final fechaNacimiento = readValue('fechaNacimiento');
    final rut = readValue('rut');
    final cursoLetra = readValue('curso');
    final tieneEnfermedadRaw = readValue('tieneEnfermedad');
    final detalleEnfermedad = readValue('detalleEnfermedad');
    final hermanosTexto = readValue('hermanosTexto');
    final requiereUniformeRaw = readValue('requiereUniforme');
    final talla = readValue('talla');
    final nombreDorsal = readValue('nombreDorsal');
    final nombreMadre = readValue('nombreMadre');
    final telefonoMadre = readValue('telefonoMadre');
    final emailMadre = readValue('emailMadre');
    final nombrePadre = readValue('nombrePadre');
    final telefonoPadre = readValue('telefonoPadre');
    final emailPadre = readValue('emailPadre');
    final responsable = readValue('responsable');

    final esAlumnoNuevo = _parseYesNo(alumnoNuevoRaw);
    final tieneEnfermedad = _parseYesNo(tieneEnfermedadRaw);
    final requiereUniforme = _parseYesNo(requiereUniformeRaw);

    // Validaciones básicas
    if (nombreCompleto.isEmpty || rut.isEmpty || cursoLetra.isEmpty) {
      throw Exception('Faltan datos obligatorios (Nombre, RUT o Curso)');
    }

    return {
      'nombre': nombreCompleto,
      'rut': rut,
      'curso': cursoLetra,
      'fechaNacimiento': fechaNacimiento,
      'esAlumnoNuevo': esAlumnoNuevo,
      'alumnoNuevo': esAlumnoNuevo ? 'si' : 'no',
      'nombreDorsal': nombreDorsal.isNotEmpty ? nombreDorsal : nombreCompleto,
      'talla': talla,
      'enfermedad': detalleEnfermedad.isNotEmpty
          ? detalleEnfermedad
          : (tieneEnfermedad ? 'si' : ''),
      'tieneEnfermedad': tieneEnfermedad,
      'hermanos': hermanosTexto,
      'requiereUniforme': requiereUniforme ? 'si' : 'no',
      'requiereUniformeBool': requiereUniforme,
      // Datos familiares
      'nombreMadre': nombreMadre,
      'telefonoMadre': telefonoMadre,
      'emailMadre': emailMadre,
      'nombrePadre': nombrePadre,
      'telefonoPadre': telefonoPadre,
      'emailPadre': emailPadre,
      'responsable': responsable,
      ..._buildRawColumnMap(headers, sheet, rowIndex),
    };
  }

  Map<String, int> _buildHeaderIndex(List<String> headers) {
    final map = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      final normalized = _normalizeHeader(headers[i]);
      if (normalized.isEmpty || map.containsKey(normalized)) continue;
      map[normalized] = i;
    }
    return map;
  }

  bool _isRowEmpty(List<excel_lib.Data?> row) {
    if (row.isEmpty) return true;
    for (final cell in row) {
      final value = cell?.value?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return false;
      }
    }
    return true;
  }

  String _readCell(excel_lib.Sheet sheet, int rowIndex, int columnIndex) {
    final cell = sheet.cell(
      excel_lib.CellIndex.indexByColumnRow(
        columnIndex: columnIndex,
        rowIndex: rowIndex,
      ),
    );
    final value = cell.value;
    if (value == null) return '';
    return value.toString().trim();
  }

  Map<String, String> _buildRawColumnMap(
    List<String> headers,
    excel_lib.Sheet sheet,
    int rowIndex,
  ) {
    final raw = <String, String>{};
    for (var col = 0; col < headers.length; col++) {
      final header = headers[col].trim();
      if (header.isEmpty) continue;
      raw[header] = _readCell(sheet, rowIndex, col);
    }
    return raw;
  }

  String _normalizeHeader(String value) {
    var normalized = value.toLowerCase().trim();
    normalized = normalized
        .replaceAll(RegExp('[áàä]'), 'a')
        .replaceAll(RegExp('[éèë]'), 'e')
        .replaceAll(RegExp('[íìï]'), 'i')
        .replaceAll(RegExp('[óòö]'), 'o')
        .replaceAll(RegExp('[úùü]'), 'u')
        .replaceAll('ñ', 'n');
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return normalized;
  }

  bool _parseYesNo(String value) {
    if (value.isEmpty) return false;
    final lower = value.toLowerCase();
    return lower.contains('si') || lower.contains('sí') || lower.contains('yes');
  }

  Future<void> _importarDatos() async {
    if (_previewData.isEmpty) {
      _showErrorSnackBar('No hay datos para importar');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Llamar al servicio de importación
      final resultado = await _estudianteService.importRegistrationFormsFromExcel(_previewData);

      setState(() {
        _isProcessing = false;
      });

      if (resultado['success'] == true) {
        _showSuccessDialog(resultado);
      } else {
        _showErrorSnackBar(resultado['message'] ?? 'Error al importar datos');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorSnackBar('Error al importar: $e');
    }
  }

  void _showSuccessDialog(Map<String, dynamic> resultado) {
    final int nuevos = _resolveCount(
      resultado['estudiantesCreados'],
      resultado['nuevos'],
    );
    final int actualizados = _resolveCount(
      resultado['estudiantesActualizados'],
      resultado['actualizados'],
    );
    final int errores = _parseCount(resultado['errores']);
    final int apoderados = _parseCount(resultado['apoderadosCreados']);
    final int totalProcesados = _parseCount(resultado['total']);
    final int totalFinal = totalProcesados > 0 ? totalProcesados : (nuevos + actualizados);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: WessexColors.leafGreen, size: 32),
            const SizedBox(width: 12),
            const Text('Importación Exitosa'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registros procesados: $totalFinal'),
            Text(
              'Nuevos estudiantes: $nuevos',
              style: const TextStyle(color: WessexColors.leafGreen),
            ),
            Text(
              'Actualizados: $actualizados',
              style: const TextStyle(color: WessexColors.deepRoyalBlue),
            ),
            if (apoderados > 0)
              Text(
                'Apoderados creados: $apoderados',
                style: const TextStyle(color: WessexColors.deepRoyalBlue),
              ),
            if (errores > 0)
              Text(
                'Con errores: $errores',
                style: const TextStyle(color: WessexColors.crimsonAlert),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _previewData = [];
                _showPreview = false;
                _fileName = null;
              });
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  int _parseCount(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is List) return value.length;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    return 0;
  }

  int _resolveCount(dynamic primary, dynamic fallback) {
    final primaryCount = _parseCount(primary);
    if (primaryCount > 0) {
      return primaryCount;
    }
    return _parseCount(fallback);
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
