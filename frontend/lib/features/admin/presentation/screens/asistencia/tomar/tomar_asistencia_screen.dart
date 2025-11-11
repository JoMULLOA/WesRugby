import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/estudiante_service.dart';
import 'package:wesrugby/data/services/asistencia_service.dart';

class TomarAsistenciaScreen extends StatefulWidget {
  const TomarAsistenciaScreen({super.key});

  @override
  State<TomarAsistenciaScreen> createState() => _TomarAsistenciaScreenState();
}

class _TomarAsistenciaScreenState extends State<TomarAsistenciaScreen> {
  final EstudianteService _estudianteService = EstudianteService();
  final AsistenciaService _asistenciaService = AsistenciaService();

  // Estado de carga
  bool _isLoadingEstudiantes = false;
  bool _isSavingAsistencia = false;

  // Datos
  List<Map<String, dynamic>> _todosEstudiantes = [];
  List<String> _categoriasDisponibles = [];
  String? _categoriaSeleccionada;

  // Asistencia
  Map<String, String> _asistenciaEstudiantes = {}; // RUT -> estado
  Map<String, String> _observacionesEstudiantes = {}; // RUT -> observación

  // Formulario de sesión
  final _nombreSesionController = TextEditingController();
  final _descripcionController = TextEditingController();
  DateTime _fechaSesion = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTodosEstudiantes();
  }

  @override
  void dispose() {
    _nombreSesionController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _loadTodosEstudiantes() async {
    try {
      setState(() {
        _isLoadingEstudiantes = true;
      });

      final estudiantes = await _estudianteService.getAllStudentsFromAPI();

      // Extraer categorías únicas
      final categoriasSet = <String>{};
      for (var estudiante in estudiantes) {
        final categoria = estudiante['categoria'];
        if (categoria != null && categoria.toString().isNotEmpty) {
          categoriasSet.add(categoria.toString());
        }
      }

      setState(() {
        _todosEstudiantes = estudiantes;
        _categoriasDisponibles = categoriasSet.toList()..sort();
        _isLoadingEstudiantes = false;
      });

      if (kDebugMode) {
        print('📚 Estudiantes cargados: ${estudiantes.length}');
        print('📋 Categorías disponibles: $_categoriasDisponibles');
      }
    } catch (e) {
      setState(() {
        _isLoadingEstudiantes = false;
      });
      if (kDebugMode) {
        print('Error al cargar estudiantes: $e');
      }
      _showErrorSnackBar('Error al cargar estudiantes');
    }
  }

  List<Map<String, dynamic>> _getEstudiantesPorCategoria() {
    if (_categoriaSeleccionada == null) return [];

    return _todosEstudiantes
        .where(
          (estudiante) =>
              estudiante['categoria'] == _categoriaSeleccionada &&
              estudiante['estado'] == 'activo',
        )
        .toList();
  }

  void _onCategoriaSelected(String? categoria) {
    setState(() {
      _categoriaSeleccionada = categoria;
      _asistenciaEstudiantes.clear();
      _observacionesEstudiantes.clear();

      // Inicializar asistencia como "presente" para todos los estudiantes de la categoría
      final estudiantes = _getEstudiantesPorCategoria();
      for (var estudiante in estudiantes) {
        _asistenciaEstudiantes[estudiante['rut']] = 'presente';
      }
    });
  }

  Future<void> _guardarAsistencia() async {
    if (_categoriaSeleccionada == null) {
      _showErrorSnackBar('Selecciona una categoría');
      return;
    }

    if (_nombreSesionController.text.trim().isEmpty) {
      _showErrorSnackBar('Ingresa el nombre de la sesión');
      return;
    }

    if (_asistenciaEstudiantes.isEmpty) {
      _showErrorSnackBar('No hay estudiantes para registrar asistencia');
      return;
    }

    setState(() {
      _isSavingAsistencia = true;
    });

    try {
      // Obtener estudiantes de la categoría seleccionada para incluir nombres
      final estudiantesCategoria = _getEstudiantesPorCategoria();

      // Crear el objeto de sesión de asistencia
      final sesionAsistencia = {
        'nombre': _nombreSesionController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'fecha': _fechaSesion.toIso8601String(),
        'categoria': _categoriaSeleccionada,
        'asistencias':
            _asistenciaEstudiantes.entries
                .map(
                  (entry) => {
                    'rutEstudiante': entry.key,
                    'nombreEstudiante':
                        estudiantesCategoria.firstWhere(
                          (e) => e['rut'] == entry.key,
                          orElse: () => {'nombre': 'Estudiante ${entry.key}'},
                        )['nombre'],
                    'estado': entry.value,
                    'observaciones': _observacionesEstudiantes[entry.key] ?? '',
                  },
                )
                .toList(),
      };

      // Llamar al servicio para guardar en el backend
      await _asistenciaService.guardarSesionAsistencia(sesionAsistencia);

      if (kDebugMode) {
        print('✅ Asistencia guardada: $sesionAsistencia');
      }

      _showSuccessDialog();
    } catch (e) {
      if (kDebugMode) {
        print('Error al guardar asistencia: $e');
      }
      _showErrorSnackBar('Error al guardar la asistencia');
    } finally {
      setState(() {
        _isSavingAsistencia = false;
      });
    }
  }

  void _showSuccessDialog() {
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
                  '¡Asistencia Guardada!',
                  style: TextStyle(
                    color: WessexColors.darkGrape,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'La asistencia de $_categoriaSeleccionada ha sido registrada correctamente.',
                  style: TextStyle(
                    color: WessexColors.darkGrape.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Cerrar diálogo
                      Navigator.pop(context); // Volver al dashboard
                    },
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(title: 'Tomar Asistencia', elevation: 2),
      body: WessexBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header informativo
                WessexCard(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.how_to_reg,
                          color: WessexColors.deepRoyalBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registro de Asistencia',
                              style: TextStyle(
                                color: WessexColors.darkGrape,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Toma la asistencia de los estudiantes por curso',
                              style: TextStyle(
                                color: WessexColors.darkGrape.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Información de la sesión
                WessexCard(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información de la Sesión',
                        style: TextStyle(
                          color: WessexColors.darkGrape,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nombre y Fecha en una fila (más compacto)
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _nombreSesionController,
                              decoration: InputDecoration(
                                labelText: 'Nombre de la Sesión *',
                                hintText: 'Ej: Entrenamiento',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(
                                  Icons.sports_rugby,
                                  color: WessexColors.deepRoyalBlue,
                                  size: 20,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final fecha = await showDatePicker(
                                  context: context,
                                  initialDate: _fechaSesion,
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 30),
                                  ),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 1),
                                  ),
                                );
                                if (fecha != null) {
                                  setState(() {
                                    _fechaSesion = fecha;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: WessexColors.leafGreen,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${_fechaSesion.day.toString().padLeft(2, '0')}/${_fechaSesion.month.toString().padLeft(2, '0')}/${_fechaSesion.year}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Descripción más compacta
                      TextFormField(
                        controller: _descripcionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Descripción (Opcional)',
                          hintText: 'Actividades de la sesión',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(
                            Icons.description,
                            color: WessexColors.darkGrape,
                            size: 20,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // Selección de curso
                WessexCard(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seleccionar Curso',
                        style: TextStyle(
                          color: WessexColors.darkGrape,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_isLoadingEstudiantes)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              color: WessexColors.deepRoyalBlue,
                            ),
                          ),
                        )
                      else if (_categoriasDisponibles.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: WessexColors.crimsonAlert.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: WessexColors.crimsonAlert.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: WessexColors.crimsonAlert,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'No se encontraron categorías disponibles.',
                                  style: TextStyle(
                                    color: WessexColors.crimsonAlert,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: _categoriaSeleccionada,
                          decoration: InputDecoration(
                            labelText: 'Categoría',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(
                              Icons.sports_rugby,
                              color: WessexColors.crimsonAlert,
                              size: 20,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          isExpanded: true,
                          hint: const Text('Selecciona una categoría', style: TextStyle(fontSize: 14)),
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                          items:
                              _categoriasDisponibles
                                  .map(
                                    (categoria) => DropdownMenuItem<String>(
                                      value: categoria,
                                      child: Text(categoria),
                                    ),
                                  )
                                  .toList(),
                          onChanged: _onCategoriaSelected,
                        ),
                    ],
                  ),
                ),

                // Lista de estudiantes para tomar asistencia
                if (_categoriaSeleccionada != null) ...[
                  _buildListaAsistencia(),

                  const SizedBox(height: 24),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: WessexColors.darkGrape),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              color: WessexColors.darkGrape,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed:
                              _isSavingAsistencia ? null : _guardarAsistencia,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WessexColors.leafGreen,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child:
                              _isSavingAsistencia
                                  ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: WessexColors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Guardando...',
                                        style: TextStyle(
                                          color: WessexColors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                  : Text(
                                    'Guardar Asistencia',
                                    style: TextStyle(
                                      color: WessexColors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListaAsistencia() {
    final estudiantes = _getEstudiantesPorCategoria();

    if (estudiantes.isEmpty) {
      return WessexCard(
        margin: const EdgeInsets.only(bottom: 24),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info, color: WessexColors.deepRoyalBlue, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No hay estudiantes activos en esta categoría.',
                  style: TextStyle(
                    color: WessexColors.deepRoyalBlue,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return WessexCard(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estudiantes - $_categoriaSeleccionada',
                style: TextStyle(
                  color: WessexColors.darkGrape,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${estudiantes.length} estudiantes',
                style: TextStyle(
                  color: WessexColors.darkGrape.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Botones rápidos
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      for (var estudiante in estudiantes) {
                        _asistenciaEstudiantes[estudiante['rut']] = 'presente';
                      }
                    });
                  },
                  icon: Icon(Icons.check_circle, size: 16, color: WessexColors.leafGreen),
                  label: Text('Todos Presentes', style: TextStyle(color: WessexColors.leafGreen, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: WessexColors.leafGreen),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      for (var estudiante in estudiantes) {
                        _asistenciaEstudiantes[estudiante['rut']] = 'ausente';
                      }
                    });
                  },
                  icon: Icon(Icons.cancel, size: 16, color: WessexColors.crimsonAlert),
                  label: Text('Todos Ausentes', style: TextStyle(color: WessexColors.crimsonAlert, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: WessexColors.crimsonAlert),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Header de la tabla
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: WessexColors.deepRoyalBlue.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 30), // N°
                const SizedBox(width: 80), // RUT
                Expanded(
                  child: Text(
                    'Alumno',
                    style: TextStyle(
                      color: WessexColors.darkGrape,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    'Asistencia',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: WessexColors.darkGrape,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    'Just.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: WessexColors.darkGrape,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    'Obs.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: WessexColors.darkGrape,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filas de estudiantes
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Column(
              children: estudiantes.asMap().entries.map((entry) {
                final index = entry.key;
                final estudiante = entry.value;
                final rut = estudiante['rut'];
                final estadoAsistencia = _asistenciaEstudiantes[rut] ?? 'presente';
                final tieneObservaciones = _observacionesEstudiantes.containsKey(rut);
                final isLastItem = index == estudiantes.length - 1;

                return Container(
                  decoration: BoxDecoration(
                    color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                    border: isLastItem ? null : Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Row(
                          children: [
                            // Número
                            SizedBox(
                              width: 30,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: WessexColors.darkGrape.withOpacity(0.7),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            // RUT
                            SizedBox(
                              width: 80,
                              child: Text(
                                rut.toString(),
                                style: TextStyle(
                                  color: WessexColors.darkGrape.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            // Nombre
                            Expanded(
                              child: Text(
                                estudiante['nombre'] ?? 'Sin nombre',
                                style: TextStyle(
                                  color: WessexColors.darkGrape,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Switch Presente/Ausente
                            SizedBox(
                              width: 120,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'A',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: estadoAsistencia == 'ausente' 
                                          ? WessexColors.crimsonAlert 
                                          : Colors.grey,
                                    ),
                                  ),
                                  Switch(
                                    value: estadoAsistencia == 'presente',
                                    onChanged: (value) {
                                      setState(() {
                                        _asistenciaEstudiantes[rut] = value ? 'presente' : 'ausente';
                                      });
                                    },
                                    activeColor: WessexColors.leafGreen,
                                    inactiveThumbColor: WessexColors.crimsonAlert,
                                    inactiveTrackColor: WessexColors.crimsonAlert.withOpacity(0.3),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  Text(
                                    'P',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: estadoAsistencia == 'presente' 
                                          ? WessexColors.leafGreen 
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Botón Justificado
                            SizedBox(
                              width: 50,
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _asistenciaEstudiantes[rut] = 
                                        estadoAsistencia == 'justificado' ? 'ausente' : 'justificado';
                                  });
                                },
                                icon: Icon(
                                  estadoAsistencia == 'justificado' 
                                      ? Icons.check_circle 
                                      : Icons.radio_button_unchecked,
                                  color: estadoAsistencia == 'justificado'
                                      ? WessexColors.deepRoyalBlue
                                      : Colors.grey.shade400,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Justificado',
                              ),
                            ),
                            // Switch Observaciones
                            SizedBox(
                              width: 60,
                              child: Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: tieneObservaciones,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value) {
                                        _observacionesEstudiantes[rut] = '';
                                      } else {
                                        _observacionesEstudiantes.remove(rut);
                                      }
                                    });
                                  },
                                  activeColor: WessexColors.darkGrape,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Campo de observaciones (si está activado)
                      if (tieneObservaciones)
                        Container(
                          padding: const EdgeInsets.fromLTRB(54, 4, 12, 12),
                          child: TextFormField(
                            initialValue: _observacionesEstudiantes[rut],
                            autofocus: false,
                            decoration: InputDecoration(
                              labelText: 'Observaciones',
                              hintText: 'Escribe aquí cualquier observación...',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: WessexColors.darkGrape.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: WessexColors.deepRoyalBlue, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              isDense: true,
                              labelStyle: TextStyle(
                                color: WessexColors.darkGrape.withOpacity(0.7),
                                fontSize: 13,
                              ),
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: WessexColors.darkGrape,
                            ),
                            maxLines: 2,
                            minLines: 2,
                            onChanged: (value) {
                              _observacionesEstudiantes[rut] = value;
                            },
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Leyenda
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: WessexColors.leafGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Presente',
                    style: TextStyle(
                      fontSize: 12,
                      color: WessexColors.darkGrape.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: WessexColors.crimsonAlert,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ausente',
                    style: TextStyle(
                      fontSize: 12,
                      color: WessexColors.darkGrape.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: WessexColors.deepRoyalBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Justificado',
                    style: TextStyle(
                      fontSize: 12,
                      color: WessexColors.darkGrape.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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