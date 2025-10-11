import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../widgets/wessex_widgets.dart';
import '../config/colors.dart';
import '../services/justificante_service.dart';
import '../services/estudiante_service.dart';
import '../services/api_service.dart';
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
  DateTime? _selectedFechaInasistencia;
  bool _isUploading = false;
  bool _isLoadingEstudiantes = true;
  bool _isLoadingUserData = true;
  
  // Archivo
  Uint8List? _webFile;
  String? _archivoNombre;
  
  // Datos del usuario autenticado
  Map<String, dynamic>? _userData;
  
  // Lista de estudiantes asignados
  List<Map<String, dynamic>> _misEstudiantes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserData();
        _loadMisEstudiantes();
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
    'Otro'
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(
        title: 'Subir Justificante',
        elevation: 2,
      ),
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
                                'Envía un justificante por ausencia a entrenamientos o eventos',
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
                                _selectedEstudiante != null ? 'Justificante para:' : 'Selecciona un estudiante',
                                style: TextStyle(
                                  color: WessexColors.darkGrape.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (_selectedEstudiante != null) ...[
                                Builder(
                                  builder: (context) {
                                    final estudianteSeleccionado = _misEstudiantes.firstWhere(
                                      (e) => e['rut'] == _selectedEstudiante,
                                      orElse: () => {},
                                    );
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                            color: WessexColors.darkGrape.withOpacity(0.6),
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
                                    color: WessexColors.darkGrape.withOpacity(0.5),
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
                                color: WessexColors.crimsonAlert.withOpacity(0.1),
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
                                      color: WessexColors.darkGrape.withOpacity(0.7),
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
                                color: WessexColors.crimsonAlert.withOpacity(0.3),
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
                              prefixIcon: Icon(Icons.person, color: WessexColors.crimsonAlert),
                            ),
                            items: _misEstudiantes.map((estudiante) => DropdownMenuItem<String>(
                              value: estudiante['rut'] as String,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 300),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${estudiante['nombres']} ${estudiante['apellidos']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'RUT: ${estudiante['rut']} - ${estudiante['curso'] ?? 'Sin curso'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            )).toList(),
                            onChanged: (value) => setState(() => _selectedEstudiante = value),
                            validator: (value) => value == null ? 'Selecciona un estudiante' : null,
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
                            prefixIcon: Icon(Icons.category, color: WessexColors.deepRoyalBlue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: _tiposJustificante.map((tipo) {
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
                                  Icon(icon, size: 20, color: WessexColors.deepRoyalBlue),
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

                        // Fecha de inasistencia
                        TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Fecha de Inasistencia',
                            prefixIcon: Icon(Icons.calendar_today, color: WessexColors.deepRoyalBlue),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          controller: TextEditingController(
                            text: _selectedFechaInasistencia != null
                                ? '${_selectedFechaInasistencia!.day.toString().padLeft(2, '0')}/${_selectedFechaInasistencia!.month.toString().padLeft(2, '0')}/${_selectedFechaInasistencia!.year}'
                                : '',
                          ),
                          onTap: () => _selectDate(),
                          validator: (value) {
                            if (_selectedFechaInasistencia == null) {
                              return 'Selecciona la fecha de inasistencia';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Motivo
                        TextFormField(
                          controller: _motivoController,
                          decoration: InputDecoration(
                            labelText: 'Motivo de la Inasistencia',
                            prefixIcon: Icon(Icons.edit_note, color: WessexColors.deepRoyalBlue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            hintText: 'Ej: Consulta médica, examen académico, etc.',
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
                            prefixIcon: Icon(Icons.description, color: WessexColors.deepRoyalBlue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            hintText: 'Información adicional o detalles relevantes...',
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
                              color: _archivoNombre != null 
                                  ? WessexColors.leafGreen 
                                  : WessexColors.mistyRoseGray,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: _archivoNombre != null 
                                ? WessexColors.leafGreen.withOpacity(0.1)
                                : WessexColors.mistyRoseGray.withOpacity(0.1),
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
                                    color: _archivoNombre != null 
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
                                      color: _archivoNombre != null 
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
                                      color: WessexColors.darkGrape.withOpacity(0.7),
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
                                    side: BorderSide(color: WessexColors.crimsonAlert),
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
                      child: _isUploading
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
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
    
    if (picked != null && picked != _selectedFechaInasistencia) {
      setState(() {
        _selectedFechaInasistencia = picked;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      if (kIsWeb) {
        final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
        uploadInput.accept = 'image/*,.pdf';
        uploadInput.click();
        
        uploadInput.onChange.listen((event) async {
          final files = uploadInput.files;
          if (files!.isNotEmpty) {
            final file = files[0];
            
            // Verificar tamaño (máx 10MB)
            if (file.size > 10 * 1024 * 1024) {
              _showErrorSnackBar('El archivo es muy grande. Máximo 10MB permitido.');
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

    setState(() {
      _isUploading = true;
    });

    try {
      // Buscar el estudiante seleccionado para obtener su información completa
      final estudianteSeleccionado = _misEstudiantes.firstWhere(
        (e) => e['rut'] == _selectedEstudiante,
      );

      // Crear descripción que incluya la información del estudiante
      String descripcionCompleta = 'Estudiante: ${estudianteSeleccionado['nombres']} ${estudianteSeleccionado['apellidos']} (RUT: ${_selectedEstudiante})';
      if (_descripcionController.text.trim().isNotEmpty) {
        descripcionCompleta += '\nDescripción adicional: ${_descripcionController.text.trim()}';
      }

      // Enviar justificante usando el servicio
      String justificanteId = _justificanteService.addJustificante(
        usuario: '${estudianteSeleccionado['nombres']} ${estudianteSeleccionado['apellidos']}',
        rol: 'Estudiante - ${estudianteSeleccionado['curso'] ?? 'Sin curso'}',
        tipoJustificante: _selectedTipoJustificante!,
        fechaInasistencia: _selectedFechaInasistencia!,
        motivo: _motivoController.text.trim(),
        descripcion: descripcionCompleta,
        archivo: _archivoNombre,
        archivoData: _webFile,
      );

      // Notificar a directiva y entrenador
      _justificanteService.notifyDirectiva(justificanteId);
      _justificanteService.notifyEntrenador(justificanteId);
      
      print('Apoderado: ${_userData?['nombreCompleto'] ?? 'Usuario'}');
      print('Estudiante: ${estudianteSeleccionado['nombres']} ${estudianteSeleccionado['apellidos']}');
      print('RUT Estudiante: $_selectedEstudiante');
      print('Justificante ID: $justificanteId');
      print('Archivo seleccionado: ${_archivoNombre ?? 'Ninguno'}');
      if (_webFile != null) {
        print('Tamaño del archivo: ${_webFile!.length} bytes');
      }

      setState(() {
        _isUploading = false;
      });

      // Mostrar diálogo de éxito
      _showSuccessDialog();

    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showErrorSnackBar('Error al enviar justificante: ${e.toString()}');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              '¡Justificante Enviado!',
              style: TextStyle(
                color: WessexColors.darkGrape,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Tu justificante ha sido enviado correctamente a la Directiva y Entrenador del club. Será revisado y procesado. Puedes verificar el estado en tu historial.',
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