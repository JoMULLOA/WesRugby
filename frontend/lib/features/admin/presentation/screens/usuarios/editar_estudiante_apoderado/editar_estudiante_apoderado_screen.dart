import 'package:flutter/material.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/estudiante_service.dart';
import 'package:wesrugby/data/services/api_service.dart';

class EditarEstudianteApoderadoScreen extends StatefulWidget {
  const EditarEstudianteApoderadoScreen({super.key});

  @override
  State<EditarEstudianteApoderadoScreen> createState() =>
      _EditarEstudianteApoderadoScreenState();
}

class _EditarEstudianteApoderadoScreenState
    extends State<EditarEstudianteApoderadoScreen> {
  final EstudianteService _estudianteService = EstudianteService();
  
  List<Map<String, dynamic>> _misEstudiantes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEstudiantes();
  }

  Future<void> _loadEstudiantes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final estudiantes = await _estudianteService.getMisEstudiantes();
      setState(() {
        _misEstudiantes = estudiantes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar estudiantes: $e';
        _isLoading = false;
      });
    }
  }

  void _editarEstudiante(Map<String, dynamic> estudiante) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _FormularioEditarEstudiante(estudiante: estudiante),
      ),
    ).then((_) => _loadEstudiantes());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1200;
    final isTablet = size.width > 600 && size.width <= 1200;

    return Scaffold(
      backgroundColor: WessexColors.crestShadow,
      appBar: AppBar(
        backgroundColor: WessexColors.deepRoyalBlue,
        title: const Text('Mis Estudiantes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: WessexColors.white),
          tooltip: 'Volver al inicio',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.home, color: WessexColors.white, size: 18),
            label: const Text(
              'Volver al inicio',
              style: TextStyle(color: WessexColors.white),
            ),
            style: TextButton.styleFrom(
              foregroundColor: WessexColors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: WessexBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WessexCard(
                  margin: const EdgeInsets.only(bottom: 24),
                  backgroundColor: WessexColors.deepRoyalBlue,
                  opacity: 0.9,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Mis Estudiantes',
                        style: TextStyle(
                          color: WessexColors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Información y edición de estudiantes asignados',
                        style: TextStyle(
                          color: WessexColors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(
                        color: WessexColors.crimsonAlert,
                      ),
                    ),
                  )
                else if (_errorMessage != null)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: WessexColors.crimsonAlert),
                      ),
                    ),
                  )
                else if (_misEstudiantes.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No tiene estudiantes asignados',
                        style: TextStyle(color: WessexColors.white),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _misEstudiantes.length,
                    itemBuilder: (context, index) {
                      final estudiante = _misEstudiantes[index];
                      return _buildEstudianteCard(estudiante, isDesktop, isTablet);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatFecha(dynamic fecha) {
    if (fecha == null) return 'N/A';
    try {
      DateTime dt;
      if (fecha is DateTime) {
        dt = fecha;
      } else if (fecha is String) {
        dt = DateTime.parse(fecha);
      } else if (fecha is List) {
        if (fecha.length >= 3) {
          dt = DateTime(fecha[0] as int, fecha[1] as int, fecha[2] as int);
        } else {
          return fecha.toString();
        }
      } else {
        return fecha.toString();
      }
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return fecha.toString();
    }
  }

  Widget _buildEstudianteCard(
    Map<String, dynamic> estudiante,
    bool isDesktop,
    bool isTablet,
  ) {
    return WessexCard(
      margin: const EdgeInsets.only(bottom: 16),
      backgroundColor: WessexColors.deepRoyalBlue,
      opacity: 0.85,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: WessexColors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estudiante['nombre'] ?? 'Sin nombre',
                        style: const TextStyle(
                          color: WessexColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'RUT: ${estudiante['rut'] ?? 'N/A'}',
                        style: TextStyle(
                          color: WessexColors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      if (estudiante['curso'] != null)
                        Text(
                          'Curso: ${estudiante['curso']}',
                          style: TextStyle(
                            color: WessexColors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _editarEstudiante(estudiante),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Editar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WessexColors.crimsonAlert,
                    foregroundColor: WessexColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: WessexColors.white, height: 24, thickness: 0.5),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (estudiante['fechaNacimiento'] != null)
                  _buildInfoChip('Fecha Nac.', _formatFecha(estudiante['fechaNacimiento'])),
                if (estudiante['talla'] != null)
                  _buildInfoChip('Talla', estudiante['talla'].toString()),
                if (estudiante['categoria'] != null)
                  _buildInfoChip('Categoría', estudiante['categoria'].toString()),
                if (estudiante['enfermedad'] != null && estudiante['enfermedad'].toString().isNotEmpty)
                  _buildInfoChip('Enfermedad', estudiante['enfermedad'].toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: WessexColors.crestNavyBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: WessexColors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: WessexColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// Formulario de edición
class _FormularioEditarEstudiante extends StatefulWidget {
  final Map<String, dynamic> estudiante;

  const _FormularioEditarEstudiante({required this.estudiante});

  @override
  State<_FormularioEditarEstudiante> createState() =>
      _FormularioEditarEstudianteState();
}

class _FormularioEditarEstudianteState
    extends State<_FormularioEditarEstudiante> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  String _stringify(dynamic value) {
    if (value == null) return '';
    if (value is List) {
      return value
          .where((element) => element != null)
          .map((element) => element.toString())
          .where((text) => text.trim().isNotEmpty)
          .join(', ');
    }
    return value.toString();
  }

  // Controladores de texto
  late TextEditingController _nombreController;
  late TextEditingController _rutController;
  late TextEditingController _cursoController;
  late TextEditingController _categoriaController;
  late TextEditingController _tallaController;
  late TextEditingController _enfermedadController;
  late TextEditingController _hermanosController;
  late TextEditingController _dorsalNombreController;
  late TextEditingController _nombreMadreController;
  late TextEditingController _telefonoMadreController;
  late TextEditingController _emailMadreController;
  late TextEditingController _nombrePadreController;
  late TextEditingController _telefonoPadreController;
  late TextEditingController _emailPadreController;
  
  DateTime? _fechaNacimiento;

  @override
  void initState() {
    super.initState();
    final est = widget.estudiante;
    
    _nombreController = TextEditingController(text: _stringify(est['nombre']));
    _rutController = TextEditingController(text: _stringify(est['rut']));
    _cursoController = TextEditingController(text: _stringify(est['curso']));
    _categoriaController = TextEditingController(text: _stringify(est['categoria']));
    _tallaController = TextEditingController(text: _stringify(est['talla']));
    _enfermedadController = TextEditingController(text: _stringify(est['enfermedad']));
    _hermanosController = TextEditingController(text: _stringify(est['hermanos']));
    _dorsalNombreController = TextEditingController(text: _stringify(est['dorsalNombre']));
    _nombreMadreController = TextEditingController(text: _stringify(est['nombreMadre']));
    _telefonoMadreController = TextEditingController(text: _stringify(est['telefonoMadre']));
    _emailMadreController = TextEditingController(text: _stringify(est['emailMadre']));
    _nombrePadreController = TextEditingController(text: _stringify(est['nombrePadre']));
    _telefonoPadreController = TextEditingController(text: _stringify(est['telefonoPadre']));
    _emailPadreController = TextEditingController(text: _stringify(est['emailPadre']));
    
    if (est['fechaNacimiento'] != null) {
      try {
        if (est['fechaNacimiento'] is DateTime) {
          _fechaNacimiento = est['fechaNacimiento'] as DateTime;
        } else if (est['fechaNacimiento'] is String) {
          _fechaNacimiento = DateTime.parse(est['fechaNacimiento']);
        } else if (est['fechaNacimiento'] is List) {
          // Formato [año, mes, día]
          final lista = est['fechaNacimiento'] as List;
          if (lista.length >= 3) {
            _fechaNacimiento = DateTime(
              lista[0] as int,
              lista[1] as int,
              lista[2] as int,
            );
          }
        }
      } catch (e) {
        // Si hay error, dejar null
        _fechaNacimiento = null;
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _rutController.dispose();
    _cursoController.dispose();
    _categoriaController.dispose();
    _tallaController.dispose();
    _enfermedadController.dispose();
    _hermanosController.dispose();
    _dorsalNombreController.dispose();
    _nombreMadreController.dispose();
    _telefonoMadreController.dispose();
    _emailMadreController.dispose();
    _nombrePadreController.dispose();
    _telefonoPadreController.dispose();
    _emailPadreController.dispose();
    super.dispose();
  }

  Future<void> _selectFechaNacimiento() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(2010, 1, 1),
      firstDate: DateTime(1990, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: WessexColors.crimsonAlert,
              onPrimary: WessexColors.white,
              surface: WessexColors.crestShadow,
              onSurface: WessexColors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null) {
      setState(() {
        _fechaNacimiento = selected;
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final rutEstudiante = widget.estudiante['rut'];
      
      if (rutEstudiante == null || rutEstudiante.toString().isEmpty) {
        throw Exception('RUT del estudiante no disponible');
      }
      
      final datosActualizados = {
        'nombre': _nombreController.text.trim(),
        'rut': _rutController.text.trim(),
        'curso': _cursoController.text.trim(),
        'categoria': _categoriaController.text.trim(),
        'talla': _tallaController.text.trim(),
        'enfermedad': _enfermedadController.text.trim(),
        'hermanos': _hermanosController.text.trim(),
        'dorsalNombre': _dorsalNombreController.text.trim(),
        'nombreMadre': _nombreMadreController.text.trim(),
        'telefonoMadre': _telefonoMadreController.text.trim(),
        'emailMadre': _emailMadreController.text.trim(),
        'nombrePadre': _nombrePadreController.text.trim(),
        'telefonoPadre': _telefonoPadreController.text.trim(),
        'emailPadre': _emailPadreController.text.trim(),
        'fechaNacimiento': _fechaNacimiento?.toIso8601String(),
      };

      final response = await ApiService.put(
        '/estudiantes/$rutEstudiante',
        datosActualizados,
      );

      if (mounted) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estudiante actualizado exitosamente'),
              backgroundColor: WessexColors.leafGreen,
            ),
          );
          Navigator.pop(context);
        } else {
          throw Exception(response.message ?? 'Error al actualizar');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: WessexColors.crimsonAlert,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1200;

    return Scaffold(
      backgroundColor: WessexColors.crestShadow,
      appBar: AppBar(
        backgroundColor: WessexColors.deepRoyalBlue,
        title: const Text('Editar Estudiante'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.home, color: WessexColors.white, size: 18),
            label: const Text(
              'Volver al inicio',
              style: TextStyle(color: WessexColors.white),
            ),
            style: TextButton.styleFrom(
              foregroundColor: WessexColors.white,
            ),
          ),
        ],
      ),
      body: WessexBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: WessexCard(
                  margin: EdgeInsets.zero,
                  backgroundColor: WessexColors.deepRoyalBlue,
                  opacity: 0.92,
                  padding: EdgeInsets.all(isDesktop ? 32 : 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información Personal',
                          style: TextStyle(
                            color: WessexColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField('Nombre Completo', _nombreController, required: true),
                        _buildTextField('RUT', _rutController, required: true),

                        InkWell(
                          onTap: _selectFechaNacimiento,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: WessexColors.midnightNavy.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: WessexColors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _fechaNacimiento == null
                                      ? 'Fecha de Nacimiento'
                                      : 'Fecha Nac: ${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
                                  style: TextStyle(
                                    color: _fechaNacimiento == null
                                        ? WessexColors.white.withOpacity(0.7)
                                        : WessexColors.white,
                                  ),
                                ),
                                const Icon(Icons.calendar_today, color: WessexColors.white),
                              ],
                            ),
                          ),
                        ),

                        _buildTextField('Curso', _cursoController),
                        _buildTextField('Categoría', _categoriaController),
                        _buildTextField('Talla', _tallaController),
                        _buildTextField('Nombre Dorsal', _dorsalNombreController),
                        _buildTextField('Hermanos en el club', _hermanosController),
                        _buildTextField(
                          'Enfermedades o condiciones médicas',
                          _enfermedadController,
                          maxLines: 3,
                        ),

                        const SizedBox(height: 32),
                        const Text(
                          'Información de la Madre',
                          style: TextStyle(
                            color: WessexColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField('Nombre Madre', _nombreMadreController),
                        _buildTextField('Teléfono Madre', _telefonoMadreController),
                        _buildTextField('Email Madre', _emailMadreController),

                        const SizedBox(height: 32),
                        const Text(
                          'Información del Padre',
                          style: TextStyle(
                            color: WessexColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField('Nombre Padre', _nombrePadreController),
                        _buildTextField('Teléfono Padre', _telefonoPadreController),
                        _buildTextField('Email Padre', _emailPadreController),

                        const SizedBox(height: 32),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: WessexColors.white,
                                side: BorderSide(color: WessexColors.white.withOpacity(0.4)),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                              ),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _isSubmitting ? null : _guardarCambios,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: WessexColors.crimsonAlert,
                                foregroundColor: WessexColors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: WessexColors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Guardar Cambios'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: WessexColors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: WessexColors.white.withOpacity(0.7)),
          filled: true,
          fillColor: WessexColors.midnightNavy.withOpacity(0.4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: WessexColors.white.withOpacity(0.25)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: WessexColors.white.withOpacity(0.25)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: WessexColors.crimsonAlert),
          ),
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Este campo es obligatorio';
                }
                return null;
              }
            : null,
      ),
    );
  }
}
