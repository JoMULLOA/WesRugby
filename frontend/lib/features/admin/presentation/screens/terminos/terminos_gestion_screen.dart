import 'package:flutter/material.dart';
import 'package:wesrugby/shared/services/terminos_service.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:intl/intl.dart';

class TerminosGestionScreen extends StatefulWidget {
  const TerminosGestionScreen({Key? key}) : super(key: key);

  @override
  State<TerminosGestionScreen> createState() => _TerminosGestionScreenState();
}

class _TerminosGestionScreenState extends State<TerminosGestionScreen> {
  bool _isLoading = true;
  List<dynamic> _terminos = [];
  Map<String, dynamic>? _terminoActivo;

  @override
  void initState() {
    super.initState();
    _cargarTerminos();
  }

  Future<void> _cargarTerminos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('📋 Cargando términos para directiva...');
      final resultado = await TerminosService.listarTerminos();
      print('📋 Resultado: ${resultado['success']}');
      
      if (resultado['success']) {
        final terminos = resultado['data'] ?? [];
        print('📋 Términos cargados: ${terminos.length}');
        
        setState(() {
          _terminos = terminos;
          _terminoActivo = _terminos.firstWhere(
            (t) => t['activo'] == true,
            orElse: () => null,
          );
          print('📋 Término activo: ${_terminoActivo != null ? _terminoActivo!['version'] : 'ninguno'}');
        });
      } else {
        print('❌ Error en respuesta: ${resultado['message']}');
        _mostrarError(resultado['message']);
      }
    } catch (e) {
      print('❌ Error cargando términos: $e');
      _mostrarError('Error cargando términos: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: WessexColors.leafGreen,
      ),
    );
  }

  Future<void> _crearNuevoTermino() async {
    await showDialog(
      context: context,
      builder: (context) => _FormularioTerminosDialog(
        onGuardado: () {
          _cargarTerminos();
        },
      ),
    );
  }

  Future<void> _editarTermino(Map<String, dynamic> termino) async {
    await showDialog(
      context: context,
      builder: (context) => _FormularioTerminosDialog(
        termino: termino,
        onGuardado: () {
          _cargarTerminos();
        },
      ),
    );
  }

  Future<void> _activarTermino(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Activar Términos'),
        content: const Text(
          'Al activar esta versión, todos los apoderados deberán aceptarla nuevamente. '
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: WessexColors.deepRoyalBlue,
            ),
            child: const Text('Activar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final resultado = await TerminosService.actualizarTerminos(
      id: id,
      activo: true,
    );

    if (resultado['success']) {
      _mostrarExito('Términos activados exitosamente');
      _cargarTerminos();
    } else {
      _mostrarError(resultado['message']);
    }
  }

  Future<void> _eliminarTermino(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Eliminar Términos'),
        content: const Text(
          'Solo se pueden eliminar términos inactivos. '
          '¿Deseas eliminar esta versión?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final resultado = await TerminosService.eliminarTerminos(id);

    if (resultado['success']) {
      _mostrarExito('Términos eliminados exitosamente');
      _cargarTerminos();
    } else {
      _mostrarError(resultado['message']);
    }
  }

  Future<void> _verEstadisticas(Map<String, dynamic> termino) async {
    final id = termino['id'] as int;
    final resultado = await TerminosService.obtenerEstadisticas(id);

    if (!resultado['success']) {
      _mostrarError(resultado['message']);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _EstadisticasDialog(
        termino: termino,
        estadisticas: resultado['data'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
        backgroundColor: WessexColors.deepRoyalBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarTerminos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearNuevoTermino,
        backgroundColor: WessexColors.leafGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Versión'),
      ),
    );
  }

  Widget _buildBody() {
    if (_terminos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay términos creados',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea una versión para comenzar',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Banner de versión activa
        if (_terminoActivo != null) _buildBannerActivo(),
        
        // Lista de términos
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _terminos.length,
            itemBuilder: (context, index) {
              final termino = _terminos[index];
              return _buildTerminoCard(termino);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBannerActivo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            WessexColors.leafGreen,
            WessexColors.leafGreen.withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Versión Activa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_terminoActivo!['titulo']} (v${_terminoActivo!['version']})',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            onPressed: () => _verEstadisticas(_terminoActivo!),
            tooltip: 'Ver estadísticas',
          ),
        ],
      ),
    );
  }

  Widget _buildTerminoCard(Map<String, dynamic> termino) {
    final id = termino['id'] as int;
    final version = termino['version'] ?? 'Sin versión';
    final titulo = termino['titulo'] ?? 'Sin título';
    final activo = termino['activo'] ?? false;
    final fechaCreacion = termino['fechaCreacion'];
    final fechaActivacion = termino['fechaActivacion'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: activo
            ? BorderSide(color: WessexColors.leafGreen, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: activo
                        ? WessexColors.leafGreen
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    activo ? '✓ ACTIVO' : 'INACTIVO',
                    style: TextStyle(
                      color: activo ? Colors.white : Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'v$version',
                    style: TextStyle(
                      color: WessexColors.deepRoyalBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'editar':
                        _editarTermino(termino);
                        break;
                      case 'activar':
                        _activarTermino(id);
                        break;
                      case 'estadisticas':
                        _verEstadisticas(termino);
                        break;
                      case 'eliminar':
                        _eliminarTermino(id);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    if (!activo)
                      const PopupMenuItem(
                        value: 'activar',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 20),
                            SizedBox(width: 8),
                            Text('Activar'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'estadisticas',
                      child: Row(
                        children: [
                          Icon(Icons.bar_chart, size: 20),
                          SizedBox(width: 8),
                          Text('Estadísticas'),
                        ],
                      ),
                    ),
                    if (!activo)
                      const PopupMenuItem(
                        value: 'eliminar',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Creado: ${_formatearFecha(fechaCreacion)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (fechaActivacion != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.check, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Activado: ${_formatearFecha(fechaActivacion)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return 'N/A';
    try {
      final date = DateTime.parse(fecha.toString());
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return 'N/A';
    }
  }
}

// Dialog para crear/editar términos
class _FormularioTerminosDialog extends StatefulWidget {
  final Map<String, dynamic>? termino;
  final VoidCallback onGuardado;

  const _FormularioTerminosDialog({
    this.termino,
    required this.onGuardado,
  });

  @override
  State<_FormularioTerminosDialog> createState() => _FormularioTerminosDialogState();
}

class _FormularioTerminosDialogState extends State<_FormularioTerminosDialog> {
  final _formKey = GlobalKey<FormState>();
  final _versionController = TextEditingController();
  final _tituloController = TextEditingController();
  final _contenidoController = TextEditingController();
  bool _activarInmediatamente = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    if (widget.termino != null) {
      _versionController.text = widget.termino!['version'] ?? '';
      _tituloController.text = widget.termino!['titulo'] ?? '';
      _contenidoController.text = widget.termino!['contenido'] ?? '';
      _activarInmediatamente = widget.termino!['activo'] ?? false;
    }
  }

  @override
  void dispose() {
    _versionController.dispose();
    _tituloController.dispose();
    _contenidoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
    });

    try {
      Map<String, dynamic> resultado;

      if (widget.termino == null) {
        // Crear nuevo
        resultado = await TerminosService.crearTerminos(
          version: _versionController.text,
          titulo: _tituloController.text,
          contenido: _contenidoController.text,
          activarInmediatamente: _activarInmediatamente,
        );
      } else {
        // Actualizar existente
        resultado = await TerminosService.actualizarTerminos(
          id: widget.termino!['id'] as int,
          version: _versionController.text,
          titulo: _tituloController.text,
          contenido: _contenidoController.text,
          activo: _activarInmediatamente,
        );
      }

      if (resultado['success']) {
        widget.onGuardado();
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['message']),
            backgroundColor: WessexColors.leafGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: WessexColors.deepRoyalBlue,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.termino == null ? Icons.add : Icons.edit,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.termino == null
                          ? 'Crear Nueva Versión'
                          : 'Editar Términos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _versionController,
                        decoration: const InputDecoration(
                          labelText: 'Versión *',
                          hintText: 'Ej: 1.0, 2.0, 2.1',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese una versión';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tituloController,
                        decoration: const InputDecoration(
                          labelText: 'Título *',
                          hintText: 'Ej: Términos y Condiciones de Uso',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese un título';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contenidoController,
                        decoration: const InputDecoration(
                          labelText: 'Contenido *',
                          hintText: 'Texto completo de los términos y condiciones...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 10,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese el contenido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        value: _activarInmediatamente,
                        onChanged: (value) {
                          setState(() {
                            _activarInmediatamente = value ?? false;
                          });
                        },
                        title: const Text('Activar inmediatamente'),
                        subtitle: const Text(
                          'Todos los apoderados deberán aceptar esta versión',
                          style: TextStyle(fontSize: 12),
                        ),
                        activeColor: WessexColors.leafGreen,
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
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
                          : Text(widget.termino == null ? 'Crear' : 'Guardar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dialog de estadísticas
class _EstadisticasDialog extends StatelessWidget {
  final Map<String, dynamic> termino;
  final Map<String, dynamic> estadisticas;

  const _EstadisticasDialog({
    required this.termino,
    required this.estadisticas,
  });

  @override
  Widget build(BuildContext context) {
    final totalAceptaciones = estadisticas['totalAceptaciones'] ?? 0;
    final aceptaciones = estadisticas['aceptaciones'] as List? ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: WessexColors.deepRoyalBlue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bar_chart, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estadísticas de Aceptación',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'v${termino['version']} - ${termino['titulo']}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      color: WessexColors.leafGreen.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              '$totalAceptaciones',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: WessexColors.leafGreen,
                              ),
                            ),
                            const Text(
                              'Aceptaciones',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: aceptaciones.isEmpty
                  ? const Center(
                      child: Text('Sin aceptaciones aún'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: aceptaciones.length,
                      itemBuilder: (context, index) {
                        final aceptacion = aceptaciones[index];
                        final rut = aceptacion['apoderadoRut'] ?? 'N/A';
                        final fecha = aceptacion['fechaAceptacion'];
                        final ip = aceptacion['ipAddress'] ?? 'N/A';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: WessexColors.leafGreen,
                            child: const Icon(Icons.check, color: Colors.white),
                          ),
                          title: Text(rut),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_formatearFecha(fecha)),
                              Text('IP: $ip', style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WessexColors.deepRoyalBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return 'N/A';
    try {
      final date = DateTime.parse(fecha.toString());
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return 'N/A';
    }
  }
}
