import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/justificante_service.dart';
import 'package:wesrugby/data/services/estudiante_service.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class JustificanteScreen extends StatefulWidget {
  const JustificanteScreen({super.key});

  @override
  State<JustificanteScreen> createState() => _JustificanteScreenState();
}

class _JustificanteScreenState extends State<JustificanteScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final JustificanteService _justificanteService = JustificanteService();
  final EstudianteService _estudianteService = EstudianteService();

  // Controladores
  final TextEditingController _motivoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  // Variables de estado
  String? _selectedTipoJustificante;
  String? _selectedEstudiante;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _isUploading = false;
  bool _isLoadingEstudiantes = true;
  bool _isLoadingUserData = true;
  bool _isLoadingAsistencias = true;

  // Archivo
  Uint8List? _webFile;
  String? _archivoNombre;

  // Datos del usuario autenticado
  Map<String, dynamic>? _userData;

  // Lista de estudiantes asignados
  List<Map<String, dynamic>> _misEstudiantes = [];
  
  // Lista de asistencias pendientes de justificación
  List<Map<String, dynamic>> _asistenciasPendientes = [];
  Map<String, dynamic>? _selectedAsistencia;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserData();
        _loadMisEstudiantes();
        _loadAsistenciasPendientes();
      }
    });
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoadingUserData = true;
      });

      print('🔍 Cargando perfil del usuario...');
      final response = await ApiService.getProfile();
      print('📋 Respuesta del perfil: ${response.statusCode}');

      if (mounted && response.statusCode == 200 && response.data != null) {
        setState(() {
          _userData = response.data;
          _isLoadingUserData = false;
        });
        print('✅ Perfil cargado exitosamente');
      } else if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
      }
    } catch (e) {
      print('❌ Error al cargar datos del usuario: $e');
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
      }
    }
  }

  Future<void> _loadMisEstudiantes() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoadingEstudiantes = true;
      });

      print('🔍 Cargando estudiantes...');
      final estudiantes = await _estudianteService.getMisEstudiantes();
      print('📋 Estudiantes recibidos: ${estudiantes.length}');

      if (mounted) {
        setState(() {
          _misEstudiantes = estudiantes;
          _isLoadingEstudiantes = false;
        });
        print('✅ Estudiantes cargados en UI: ${_misEstudiantes.length}');
      }
    } catch (e) {
      print('❌ Error al cargar estudiantes: $e');
      if (mounted) {
        setState(() {
          _isLoadingEstudiantes = false;
        });
        _showErrorSnackBar('Error al cargar estudiantes asignados');
      }
    }
  }

  Future<void> _loadAsistenciasPendientes() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoadingAsistencias = true;
      });

      print('🔍 Cargando asistencias pendientes de justificación...');
      final asistencias = await _justificanteService.obtenerAsistenciasPendientes();
      print('📋 Asistencias pendientes recibidas: ${asistencias.length}');

      if (mounted) {
        setState(() {
          _asistenciasPendientes = asistencias;
          _isLoadingAsistencias = false;
        });
        print('✅ Asistencias pendientes cargadas: ${_asistenciasPendientes.length}');
      }
    } catch (e) {
      print('❌ Error al cargar asistencias pendientes: $e');
      if (mounted) {
        setState(() {
          _isLoadingAsistencias = false;
        });
        _showErrorSnackBar('Error al cargar asistencias pendientes');
      }
    }
  }

  @override
  void dispose() {
    _motivoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  final List<String> _tiposJustificante = [
    'Médico',
    'Académico',
    'Familiar',
    'Laboral',
    'Otro',
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(title: 'Subir Justificante', elevation: 2),
      body: WessexBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
            child: Form(
              key: _formKey,
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
                            Icons.medical_information,
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
                                'Justificar Inasistencia',
                                style: TextStyle(
                                  color: WessexColors.darkGrape,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Envía un justificante por ausencias pasadas o futuras (lesiones, viajes, etc.)',
                                style: TextStyle(
                                  color: WessexColors.darkGrape.withOpacity(
                                    0.7,
                                  ),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Información del Justificante
                  WessexCard(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: WessexColors.leafGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.medical_information,
                            color: WessexColors.leafGreen,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedEstudiante != null
                                    ? 'Justificante para:'
                                    : 'Selecciona un estudiante',
                                style: TextStyle(
                                  color: WessexColors.darkGrape.withOpacity(
                                    0.7,
                                  ),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (_selectedEstudiante != null) ...[
                                Builder(
                                  builder: (context) {
                                    final estudianteSeleccionado =
                                        _misEstudiantes.firstWhere(
                                          (e) =>
                                              e['rut'] == _selectedEstudiante,
                                          orElse: () => {},
                                        );
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${estudianteSeleccionado['nombres']} ${estudianteSeleccionado['apellidos']}',
                                          style: TextStyle(
                                            color: WessexColors.darkGrape,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Estudiante - ${estudianteSeleccionado['curso'] ?? 'Sin curso'}',
                                          style: TextStyle(
                                            color: WessexColors.leafGreen,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Enviado por: ${_userData?['nombreCompleto'] ?? 'Apoderado'}',
                                          style: TextStyle(
                                            color: WessexColors.darkGrape
                                                .withOpacity(0.6),
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ] else ...[
                                Text(
                                  'Primero selecciona un estudiante',
                                  style: TextStyle(
                                    color: WessexColors.darkGrape.withOpacity(
                                      0.5,
                                    ),
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                Text(
                                  'Enviado por: ${_userData?['nombreCompleto'] ?? 'Apoderado'}',
                                  style: TextStyle(
                                    color: WessexColors.leafGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Asistencias Pendientes de Justificación
                  if (_isLoadingAsistencias)
                    const WessexCard(
                      margin: EdgeInsets.only(bottom: 24),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  else if (_asistenciasPendientes.isNotEmpty)
                    WessexCard(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: WessexColors.crimsonAlert.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.warning,
                                  color: WessexColors.crimsonAlert,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Asistencias Registradas (Informativo)',
                                      style: TextStyle(
                                        color: WessexColors.darkGrape,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_asistenciasPendientes.length} ausencia(s) sin justificar. Puedes enviar justificante aunque no haya registros.',
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
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          ..._asistenciasPendientes.map((asistencia) {
                            final fecha = asistencia['fecha']?.toString().split('T')[0] ?? '';
                            final alumno = asistencia['alumno']?.toString() ?? 'Sin nombre';
                            final estado = asistencia['estado']?.toString() ?? '';
                            final tipoActividad = asistencia['tipoActividad']?.toString() ?? '';
                            final categoria = asistencia['categoria']?.toString() ?? '';
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: WessexColors.darkGrape.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: WessexColors.darkGrape.withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        estado == 'ausente' ? Icons.cancel : Icons.access_time,
                                        color: WessexColors.crimsonAlert,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          alumno,
                                          style: TextStyle(
                                            color: WessexColors.darkGrape,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        estado.toUpperCase(),
                                        style: TextStyle(
                                          color: WessexColors.crimsonAlert,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Fecha: $fecha',
                                    style: TextStyle(
                                      color: WessexColors.darkGrape.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (tipoActividad.isNotEmpty)
                                    Text(
                                      'Actividad: $tipoActividad',
                                      style: TextStyle(
                                        color: WessexColors.darkGrape.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  if (categoria.isNotEmpty)
                                    Text(
                                      'Categoría: $categoria',
                                      style: TextStyle(
                                        color: WessexColors.darkGrape.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                  // Selección de Estudiante
                  WessexCard(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: WessexColors.crimsonAlert.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.school,
                                color: WessexColors.crimsonAlert,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Seleccionar Estudiante',
                                    style: TextStyle(
                                      color: WessexColors.darkGrape,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Selecciona el estudiante para el cual envías este justificante',
                                    style: TextStyle(
                                      color: WessexColors.darkGrape.withOpacity(
                                        0.7,
                                      ),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_isLoadingEstudiantes)
                          Center(
                            child: CircularProgressIndicator(
                              color: WessexColors.deepRoyalBlue,
                            ),
                          )
                        else if (_misEstudiantes.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: WessexColors.crimsonAlert.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: WessexColors.crimsonAlert.withOpacity(
                                  0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning,
                                  color: WessexColors.crimsonAlert,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No tienes estudiantes asignados. Contacta con la administración.',
                                    style: TextStyle(
                                      color: WessexColors.crimsonAlert,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            value: _selectedEstudiante,
                            decoration: InputDecoration(
                              labelText: 'Estudiante',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(
                                Icons.person,
                                color: WessexColors.crimsonAlert,
                              ),
                            ),
                            isExpanded: true,
                            hint: const Text('Selecciona un estudiante'),
                            items:
                                _misEstudiantes
                                    .map(
                                      (estudiante) => DropdownMenuItem<String>(
                                        value: estudiante['rut'] as String,
                                        child: Text(
                                          '${estudiante['nombres']} ${estudiante['apellidos']} (${estudiante['curso'] ?? 'Sin curso'})',
                                          style: const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (value) =>
                                    setState(() => _selectedEstudiante = value),
                            validator:
                                (value) =>
                                    value == null
                                        ? 'Selecciona un estudiante'
                                        : null,
                          ),
                      ],
                    ),
                  ),

                  // Formulario principal
                  WessexCard(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información del Justificante',
                          style: TextStyle(
                            color: WessexColors.darkGrape,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tipo de justificante
                        DropdownButtonFormField<String>(
                          value: _selectedTipoJustificante,
                          decoration: InputDecoration(
                            labelText: 'Tipo de Justificante',
                            prefixIcon: Icon(
                              Icons.category,
                              color: WessexColors.deepRoyalBlue,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items:
                              _tiposJustificante.map((tipo) {
                                IconData icon;
                                switch (tipo) {
                                  case 'Médico':
                                    icon = Icons.medical_services;
                                    break;
                                  case 'Académico':
                                    icon = Icons.school;
                                    break;
                                  case 'Familiar':
                                    icon = Icons.family_restroom;
                                    break;
                                  case 'Laboral':
                                    icon = Icons.work;
                                    break;
                                  default:
                                    icon = Icons.info;
                                }

                                return DropdownMenuItem(
                                  value: tipo,
                                  child: Row(
                                    children: [
                                      Icon(
                                        icon,
                                        size: 20,
                                        color: WessexColors.deepRoyalBlue,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(tipo),
                                    ],
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedTipoJustificante = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Selecciona el tipo de justificante';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Rango de Fechas (Inicio y Fin)
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fecha Inicio *',
                                    style: TextStyle(
                                      color: WessexColors.darkGrape,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: _selectFechaInicio,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: WessexColors.darkGrape.withOpacity(0.3),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            color: WessexColors.deepRoyalBlue,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _fechaInicio != null
                                                ? '${_fechaInicio!.day.toString().padLeft(2, '0')}/${_fechaInicio!.month.toString().padLeft(2, '0')}/${_fechaInicio!.year}'
                                                : 'Seleccionar',
                                            style: TextStyle(
                                              color: _fechaInicio != null
                                                  ? WessexColors.darkGrape
                                                  : WessexColors.darkGrape.withOpacity(0.5),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fecha Fin (opcional)',
                                    style: TextStyle(
                                      color: WessexColors.darkGrape,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: _fechaInicio != null ? _selectFechaFin : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: WessexColors.darkGrape.withOpacity(0.3),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        color: _fechaInicio == null
                                            ? WessexColors.darkGrape.withOpacity(0.05)
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            color: _fechaInicio != null
                                                ? WessexColors.deepRoyalBlue
                                                : WessexColors.darkGrape.withOpacity(0.3),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _fechaFin != null
                                                ? '${_fechaFin!.day.toString().padLeft(2, '0')}/${_fechaFin!.month.toString().padLeft(2, '0')}/${_fechaFin!.year}'
                                                : 'Seleccionar',
                                            style: TextStyle(
                                              color: _fechaFin != null
                                                  ? WessexColors.darkGrape
                                                  : WessexColors.darkGrape.withOpacity(0.5),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Motivo
                        TextFormField(
                          controller: _motivoController,
                          decoration: InputDecoration(
                            labelText: 'Motivo de la Inasistencia',
                            prefixIcon: Icon(
                              Icons.edit_note,
                              color: WessexColors.deepRoyalBlue,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            hintText:
                                'Ej: Consulta médica, examen académico, etc.',
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa el motivo de la inasistencia';
                            }
                            if (value.trim().length < 10) {
                              return 'El motivo debe tener al menos 10 caracteres';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Descripción adicional (opcional)
                        TextFormField(
                          controller: _descripcionController,
                          decoration: InputDecoration(
                            labelText: 'Descripción Adicional (Opcional)',
                            prefixIcon: Icon(
                              Icons.description,
                              color: WessexColors.deepRoyalBlue,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            hintText:
                                'Información adicional o detalles relevantes...',
                          ),
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),

                  // Sección de archivo adjunto
                  WessexCard(
                    margin: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Documento de Respaldo (Opcional)',
                          style: TextStyle(
                            color: WessexColors.darkGrape,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Adjunta certificados médicos, constancias académicas u otros documentos que respalden el justificante.',
                          style: TextStyle(
                            color: WessexColors.darkGrape.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Botón para seleccionar archivo
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  _archivoNombre != null
                                      ? WessexColors.leafGreen
                                      : WessexColors.mistyRoseGray,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color:
                                _archivoNombre != null
                                    ? WessexColors.leafGreen.withOpacity(0.1)
                                    : WessexColors.mistyRoseGray.withOpacity(
                                      0.1,
                                    ),
                          ),
                          child: InkWell(
                            onTap: _pickFile,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(
                                    _archivoNombre != null
                                        ? Icons.check_circle
                                        : Icons.cloud_upload,
                                    color:
                                        _archivoNombre != null
                                            ? WessexColors.leafGreen
                                            : WessexColors.deepRoyalBlue,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _archivoNombre != null
                                        ? 'Archivo seleccionado: $_archivoNombre'
                                        : 'Haz clic para seleccionar un archivo',
                                    style: TextStyle(
                                      color:
                                          _archivoNombre != null
                                              ? WessexColors.leafGreen
                                              : WessexColors.deepRoyalBlue,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Formatos permitidos: PDF, JPG, PNG (Máx. 10MB)',
                                    style: TextStyle(
                                      color: WessexColors.darkGrape.withOpacity(
                                        0.7,
                                      ),
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        if (_archivoNombre != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _archivoNombre = null;
                                      _webFile = null;
                                    });
                                  },
                                  icon: Icon(Icons.delete, size: 16),
                                  label: Text('Remover Archivo'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: WessexColors.crimsonAlert,
                                    side: BorderSide(
                                      color: WessexColors.crimsonAlert,
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

                  // Botón de envío
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _submitJustificante,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WessexColors.deepRoyalBlue,
                        foregroundColor: WessexColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isUploading
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
                                  Text('Enviando Justificante...'),
                                ],
                              )
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Enviar Justificante',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectFechaInicio() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: WessexColors.deepRoyalBlue,
              onPrimary: WessexColors.white,
              surface: WessexColors.white,
              onSurface: WessexColors.darkGrape,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _fechaInicio = picked;
        // Si la fecha fin es anterior a la fecha inicio, resetearla
        if (_fechaFin != null && _fechaFin!.isBefore(picked)) {
          _fechaFin = null;
        }
      });
    }
  }

  Future<void> _selectFechaFin() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? _fechaInicio ?? DateTime.now(),
      firstDate: _fechaInicio ?? DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: WessexColors.deepRoyalBlue,
              onPrimary: WessexColors.white,
              surface: WessexColors.white,
              onSurface: WessexColors.darkGrape,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _fechaFin = picked;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      if (kIsWeb) {
        final html.FileUploadInputElement uploadInput =
            html.FileUploadInputElement();
        uploadInput.accept = 'image/*,.pdf';
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

            final reader = html.FileReader();
            reader.readAsArrayBuffer(file);
            reader.onLoadEnd.listen((event) {
              setState(() {
                _webFile = reader.result as Uint8List;
                _archivoNombre = file.name;
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

  Future<void> _submitJustificante() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedEstudiante == null) {
      _showErrorSnackBar('Debes seleccionar un estudiante');
      return;
    }

    if (_fechaInicio == null) {
      _showErrorSnackBar('Debes seleccionar una fecha de inicio');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final resultado = await _justificanteService.crearJustificantePersistente(
        estudianteRut: _selectedEstudiante!,
        fechaInicio: _fechaInicio!,
        fechaFin: _fechaFin,
        tipo: _selectedTipoJustificante ?? 'otro',
        motivo: _motivoController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        archivoBytes: _webFile,
        archivoNombre: _archivoNombre,
      );

      setState(() { _isUploading = false; });

      if (resultado['success'] == true) {
        _showSuccessDialog(1, 0);
      } else {
        _showErrorSnackBar('Error al enviar justificante: ${resultado['error']}');
      }
    } catch (e) {
      setState(() { _isUploading = false; });
      _showErrorSnackBar('Error al enviar justificante: ${e.toString()}');
    }
  }

  void _showInfoDialog(String titulo, String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info,
                color: WessexColors.deepRoyalBlue,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              titulo,
              style: TextStyle(
                color: WessexColors.darkGrape,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              mensaje,
              style: TextStyle(
                color: WessexColors.darkGrape.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            WessexButton(
              text: 'Entendido',
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Volver a la pantalla anterior
              },
              icon: Icons.check,
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(int exitosos, int fallidos) {
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
                  '¡Justificante${exitosos > 1 ? 's' : ''} Enviado${exitosos > 1 ? 's' : ''}!',
                  style: TextStyle(
                    color: WessexColors.darkGrape,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  exitosos > 1
                      ? 'Se han justificado $exitosos asistencias exitosamente${fallidos > 0 ? ' ($fallidos fallaron)' : ''}. Serán revisadas y procesadas. Puedes verificar el estado en tu historial.'
                      : 'Tu justificante ha sido enviado correctamente. Será revisado y procesado. Puedes verificar el estado en tu historial.',
                  style: TextStyle(
                    color: WessexColors.darkGrape.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: WessexColors.deepRoyalBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Enviado por: ${_userData?['nombreCompleto'] ?? 'Apoderado'}\nFecha: ${DateTime.now().toString().substring(0, 10)}',
                          style: TextStyle(
                            color: WessexColors.deepRoyalBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
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
