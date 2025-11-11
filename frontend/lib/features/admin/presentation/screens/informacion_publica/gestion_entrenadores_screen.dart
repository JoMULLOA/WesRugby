import 'package:flutter/material.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';

class GestionEntrenadoresScreen extends StatefulWidget {
  const GestionEntrenadoresScreen({super.key});

  @override
  State<GestionEntrenadoresScreen> createState() =>
      _GestionEntrenadoresScreenState();
}

class _GestionEntrenadoresScreenState extends State<GestionEntrenadoresScreen> {
  List<Map<String, dynamic>> _entrenadores = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarEntrenadores();
  }

  Future<void> _cargarEntrenadores() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/entrenadores/gestion');
      if (response.success && response.data != null) {
        final List<dynamic> data = response.data is Map
            ? (response.data['data'] as List? ?? [])
            : (response.data is List ? response.data : []);

        setState(() {
          _entrenadores = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      _mostrarError('Error al cargar entrenadores: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: WessexColors.crimsonAlert,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: WessexColors.leafGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: WessexColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.sports, color: WessexColors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Gestión de Entrenadores',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: WessexColors.white,
                  ),
                ),
                Text(
                  'Administra perfiles públicos de entrenadores',
                  style: TextStyle(
                    fontSize: 12,
                    color: WessexColors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                WessexColors.deepRoyalBlue.withOpacity(0.9),
                WessexColors.darkGrape.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WessexColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entrenadores.isEmpty
              ? _buildEmptyState()
              : _buildEntrenadoresList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports, size: 64, color: WessexColors.ashGray),
          const SizedBox(height: 16),
          const Text(
            'No hay entrenadores registrados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: WessexColors.charcoalGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntrenadoresList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _entrenadores.length,
      itemBuilder: (context, index) {
        return _buildEntrenadorCard(_entrenadores[index]);
      },
    );
  }

  Widget _buildEntrenadorCard(Map<String, dynamic> entrenador) {
    final bool tienePerfil = entrenador['tienePerfil'] == true;
    final Map<String, dynamic>? perfil = entrenador['perfilPublico'];
    final bool visible = perfil?['visible'] ?? false;

    return WessexCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                    border: Border.all(
                      color: WessexColors.deepRoyalBlue,
                      width: 2,
                    ),
                  ),
                  child: entrenador['avatar'] != null
                      ? ClipOval(
                          child: Image.network(
                            entrenador['avatar'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildDefaultAvatar(
                              entrenador['nombreCompleto'] ?? '',
                            ),
                          ),
                        )
                      : _buildDefaultAvatar(
                          entrenador['nombreCompleto'] ?? '',
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entrenador['nombreCompleto'] ?? 'Sin nombre',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: WessexColors.deepNavyBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entrenador['email'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: WessexColors.charcoalGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tienePerfil
                                  ? WessexColors.leafGreen.withOpacity(0.1)
                                  : WessexColors.ashGray.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tienePerfil
                                  ? 'CON PERFIL PÚBLICO'
                                  : 'SIN PERFIL PÚBLICO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: tienePerfil
                                    ? WessexColors.leafGreen
                                    : WessexColors.ashGray,
                              ),
                            ),
                          ),
                          if (tienePerfil) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: visible
                                    ? WessexColors.deepRoyalBlue.withOpacity(0.1)
                                    : WessexColors.crimsonAlert.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                visible ? 'VISIBLE' : 'OCULTO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: visible
                                      ? WessexColors.deepRoyalBlue
                                      : WessexColors.crimsonAlert,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (tienePerfil) ...[
                  TextButton.icon(
                    onPressed: () => _toggleVisibilidad(perfil!),
                    icon: Icon(
                      visible ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                    label: Text(visible ? 'Ocultar' : 'Mostrar'),
                    style: TextButton.styleFrom(
                      foregroundColor: WessexColors.deepRoyalBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton.icon(
                  onPressed: () => _editarPerfil(entrenador),
                  icon: Icon(
                    tienePerfil ? Icons.edit : Icons.add,
                    size: 18,
                  ),
                  label: Text(tienePerfil ? 'Editar' : 'Crear Perfil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WessexColors.leafGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String nombre) {
    final List<String> palabras = nombre.split(' ');
    String iniciales = '';
    if (palabras.isNotEmpty) {
      iniciales = palabras[0][0].toUpperCase();
      if (palabras.length > 1) {
        iniciales += palabras[1][0].toUpperCase();
      }
    }

    return Container(
      color: WessexColors.deepRoyalBlue.withOpacity(0.2),
      child: Center(
        child: Text(
          iniciales,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: WessexColors.deepRoyalBlue,
          ),
        ),
      ),
    );
  }

  Future<void> _toggleVisibilidad(Map<String, dynamic> perfil) async {
    try {
      final int id = perfil['id'];
      final bool visible = perfil['visible'] ?? false;

      final response = await ApiService.patch(
        '/entrenadores/$id/visibilidad',
        {'visible': !visible},
      );

      if (response.success) {
        _mostrarExito('Visibilidad actualizada correctamente');
        _cargarEntrenadores();
      } else {
        _mostrarError('Error al cambiar visibilidad');
      }
    } catch (e) {
      _mostrarError('Error al cambiar visibilidad: $e');
    }
  }

  void _editarPerfil(Map<String, dynamic> entrenador) {
    final perfil = entrenador['perfilPublico'];
    
    showDialog(
      context: context,
      builder: (context) => _FormularioEntrenadorDialog(
        entrenador: entrenador,
        perfilExistente: perfil,
        onGuardado: () {
          _cargarEntrenadores();
          _mostrarExito('Perfil actualizado correctamente');
        },
      ),
    );
  }
}

class _FormularioEntrenadorDialog extends StatefulWidget {
  final Map<String, dynamic> entrenador;
  final Map<String, dynamic>? perfilExistente;
  final VoidCallback onGuardado;

  const _FormularioEntrenadorDialog({
    required this.entrenador,
    this.perfilExistente,
    required this.onGuardado,
  });

  @override
  State<_FormularioEntrenadorDialog> createState() =>
      _FormularioEntrenadorDialogState();
}

class _FormularioEntrenadorDialogState
    extends State<_FormularioEntrenadorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _especialidadController;
  late TextEditingController _aniosExperienciaController;
  late TextEditingController _certificacionesController;
  late TextEditingController _logrosController;
  late TextEditingController _biografiaController;
  late TextEditingController _categoriasController;
  bool _visible = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final perfil = widget.perfilExistente;
    
    _tituloController = TextEditingController(text: perfil?['titulo'] ?? '');
    _especialidadController =
        TextEditingController(text: perfil?['especialidad'] ?? '');
    _aniosExperienciaController = TextEditingController(
      text: perfil?['aniosExperiencia']?.toString() ?? '',
    );
    _certificacionesController =
        TextEditingController(text: perfil?['certificaciones'] ?? '');
    _logrosController = TextEditingController(text: perfil?['logros'] ?? '');
    _biografiaController =
        TextEditingController(text: perfil?['biografia'] ?? '');
    _categoriasController =
        TextEditingController(text: perfil?['categorias'] ?? '');
    _visible = perfil?['visible'] ?? true;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _especialidadController.dispose();
    _aniosExperienciaController.dispose();
    _certificacionesController.dispose();
    _logrosController.dispose();
    _biografiaController.dispose();
    _categoriasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.perfilExistente == null
                            ? 'Crear Perfil Público'
                            : 'Editar Perfil Público',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: WessexColors.darkGrape,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.entrenador['nombreCompleto'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    color: WessexColors.charcoalGray,
                  ),
                ),
                const SizedBox(height: 24),

                _buildTextField(
                  controller: _tituloController,
                  label: 'Título Profesional',
                  hint: 'Ej: Entrenador Nivel 1 World Rugby',
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _especialidadController,
                  label: 'Especialidad',
                  hint: 'Ej: Entrenamiento Físico y Técnico',
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _aniosExperienciaController,
                  label: 'Años de Experiencia',
                  hint: 'Ej: 10',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _categoriasController,
                  label: 'Categorías que Entrena',
                  hint: 'Ej: sub-8, sub-10, sub-12',
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _biografiaController,
                  label: 'Biografía',
                  hint: 'Describe la trayectoria y experiencia del entrenador...',
                  maxLines: 4,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _logrosController,
                  label: 'Logros Destacados',
                  hint: 'Enumera los logros más importantes...',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _certificacionesController,
                  label: 'Certificaciones',
                  hint: 'Lista certificaciones y cursos relevantes...',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  title: const Text('Visible públicamente'),
                  subtitle: const Text(
                    'El perfil será visible en la página pública',
                  ),
                  value: _visible,
                  onChanged: (value) => setState(() => _visible = value),
                  activeColor: WessexColors.leafGreen,
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _guardando ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _guardando ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WessexColors.leafGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: _guardando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final data = {
        'userRut': widget.entrenador['rut'],
        'titulo': _tituloController.text.trim(),
        'especialidad': _especialidadController.text.trim(),
        'aniosExperiencia': int.tryParse(_aniosExperienciaController.text),
        'certificaciones': _certificacionesController.text.trim(),
        'logros': _logrosController.text.trim(),
        'biografia': _biografiaController.text.trim(),
        'categorias': _categoriasController.text.trim(),
        'visible': _visible,
      };

      final response = widget.perfilExistente == null
          ? await ApiService.post('/entrenadores', data)
          : await ApiService.put(
              '/entrenadores/${widget.perfilExistente!['id']}',
              data,
            );

      if (response.success) {
        if (mounted) {
          Navigator.pop(context);
          widget.onGuardado();
        }
      } else {
        throw Exception(response.message ?? 'Error al guardar');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: WessexColors.crimsonAlert,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }
}
