import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/tokenManager.dart';
import '../config/colors.dart';

class RamaExternaScreen extends StatefulWidget {
  @override
  _RamaExternaScreenState createState() => _RamaExternaScreenState();
}

class _RamaExternaScreenState extends State<RamaExternaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _eventos = [];
  List<dynamic> _misParticipaciones = [];
  bool _isLoading = false;
  String _nombreUsuario = 'Usuario RamaExterna';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
    _cargarInfoUsuario();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _cargarEventos(),
        _cargarMisParticipaciones(),
      ]);
    } catch (e) {
      _mostrarError('Error al cargar datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarInfoUsuario() async {
    try {
      final userInfo = await TokenManager.getUserInfo();
      if (userInfo != null && mounted) {
        setState(() {
          _nombreUsuario = userInfo['nombre'] ?? 'Usuario RamaExterna';
        });
      }
    } catch (e) {
      print('Error cargando info usuario: $e');
    }
  }

  Future<void> _cargarEventos() async {
    try {
      final response = await ApiService.obtenerEventosDisponibles();
      setState(() => _eventos = response['data'] ?? []);
    } catch (e) {
      print('Error cargando eventos: $e');
    }
  }

  Future<void> _cargarMisParticipaciones() async {
    try {
      final response = await ApiService.obtenerMisParticipacionesEvento();
      setState(() => _misParticipaciones = response['data'] ?? []);
    } catch (e) {
      print('Error cargando participaciones: $e');
    }
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: WessexColors.crimsonAlert,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rama Externa - Eventos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: WessexColors.darkGrape,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.event), text: 'Eventos Disponibles'),
            Tab(icon: Icon(Icons.assignment), text: 'Mis Participaciones'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  _cerrarSesion();
                }
              },
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    _nombreUsuario,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: WessexColors.crimsonAlert),
                      SizedBox(width: 8),
                      Text('Cerrar Sesión'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: WessexColors.lightGray,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventosDisponiblesTab(),
          _buildMisParticipacionesTab(),
        ],
      ),
    );
  }

  Widget _buildEventosDisponiblesTab() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(WessexColors.darkGrape),
        ),
      );
    }

    if (_eventos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: WessexColors.darkGrape.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'No hay eventos disponibles',
              style: TextStyle(
                fontSize: 18,
                color: WessexColors.darkGrape,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Los eventos creados por la directiva aparecerán aquí',
              style: TextStyle(
                fontSize: 14,
                color: WessexColors.midnightNavy.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _cargarEventos(),
      color: WessexColors.darkGrape,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _eventos.length,
        itemBuilder: (context, index) {
          return _buildEventoCard(_eventos[index]);
        },
      ),
    );
  }

  Widget _buildMisParticipacionesTab() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(WessexColors.darkGrape),
        ),
      );
    }

    if (_misParticipaciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: WessexColors.darkGrape.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'No tienes participaciones registradas',
              style: TextStyle(
                fontSize: 18,
                color: WessexColors.darkGrape,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Participa en eventos desde la pestaña disponibles',
              style: TextStyle(
                fontSize: 14,
                color: WessexColors.midnightNavy.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _cargarMisParticipaciones(),
      color: WessexColors.darkGrape,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _misParticipaciones.length,
        itemBuilder: (context, index) {
          return _buildParticipacionCard(_misParticipaciones[index]);
        },
      ),
    );
  }

  Widget _buildEventoCard(Map<String, dynamic> evento) {
    final fecha = DateTime.parse(evento['fecha']);
    final fechaFormateada = '${fecha.day}/${fecha.month}/${fecha.year}';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    evento['nombre'] ?? 'Sin nombre',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: WessexColors.darkGrape,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: WessexColors.leafGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: WessexColors.leafGreen, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_available, size: 16, color: WessexColors.leafGreen),
                      SizedBox(width: 4),
                      Text(
                        'DISPONIBLE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: WessexColors.leafGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: WessexColors.midnightNavy),
                SizedBox(width: 8),
                Text(
                  fechaFormateada,
                  style: TextStyle(
                    fontSize: 14,
                    color: WessexColors.midnightNavy,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (evento['descripcion'] != null && evento['descripcion'].toString().isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                evento['descripcion'],
                style: TextStyle(
                  fontSize: 14,
                  color: WessexColors.midnightNavy.withOpacity(0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _mostrarDialogoParticipacion(evento),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WessexColors.leafGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline),
                    SizedBox(width: 8),
                    Text('Participar en Evento'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipacionCard(Map<String, dynamic> participacion) {
    final evento = participacion['evento'];
    final fecha = evento != null ? DateTime.parse(evento['fecha']) : DateTime.now();
    final fechaFormateada = '${fecha.day}/${fecha.month}/${fecha.year}';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              evento?['nombre'] ?? 'Evento sin nombre',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: WessexColors.darkGrape,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: WessexColors.midnightNavy),
                SizedBox(width: 8),
                Text(
                  fechaFormateada,
                  style: TextStyle(
                    fontSize: 14,
                    color: WessexColors.midnightNavy,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.group, size: 16, color: WessexColors.leafGreen),
                SizedBox(width: 8),
                Text(
                  '${participacion['cantidadNinos'] ?? 0} niños participantes',
                  style: TextStyle(
                    fontSize: 14,
                    color: WessexColors.leafGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: WessexColors.darkGrape),
                SizedBox(width: 8),
                Text(
                  'Categoría: ${participacion['categoria'] ?? 'No especificada'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: WessexColors.darkGrape,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (participacion['listaInvitados'] != null && participacion['listaInvitados'].toString().isNotEmpty) ...[
              SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.people_outline, size: 16, color: WessexColors.midnightNavy),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Invitados: ${participacion['listaInvitados']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: WessexColors.midnightNavy.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoParticipacion(Map<String, dynamic> evento) {
    final cantidadController = TextEditingController();
    final invitadosController = TextEditingController();
    String categoriaSeleccionada = 'sub-12';
    
    final categorias = ['sub-8', 'sub-10', 'sub-12', 'sub-14', 'sub-16', 'sub-18'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 500,
            padding: EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Participar en Evento',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: WessexColors.darkGrape,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    evento['nombre'] ?? 'Sin nombre',
                    style: TextStyle(
                      fontSize: 16,
                      color: WessexColors.midnightNavy,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Cantidad de niños
                  TextFormField(
                    controller: cantidadController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Cantidad de Niños Participantes',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.group),
                      hintText: 'Ej: 15',
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Categoría
                  DropdownButtonFormField<String>(
                    value: categoriaSeleccionada,
                    onChanged: (value) {
                      setState(() {
                        categoriaSeleccionada = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: categorias.map((categoria) => DropdownMenuItem(
                      value: categoria,
                      child: Text(categoria.toUpperCase()),
                    )).toList(),
                  ),
                  SizedBox(height: 16),
                  
                  // Lista de invitados (opcional)
                  TextFormField(
                    controller: invitadosController,
                    decoration: InputDecoration(
                      labelText: 'Lista de Invitados (Opcional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.people_outline),
                      hintText: 'Nombres separados por comas',
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 24),
                  
                  // Botones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancelar'),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => _participarEnEvento(
                          evento['id'],
                          cantidadController.text,
                          categoriaSeleccionada,
                          invitadosController.text,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WessexColors.leafGreen,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text('Confirmar Participación'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _participarEnEvento(int eventoId, String cantidad, String categoria, String invitados) async {
    if (cantidad.trim().isEmpty) {
      _mostrarError('La cantidad de niños es obligatoria');
      return;
    }

    final cantidadNinos = int.tryParse(cantidad);
    if (cantidadNinos == null || cantidadNinos <= 0) {
      _mostrarError('Ingrese una cantidad válida de niños');
      return;
    }

    try {
      final datos = {
        'eventoId': eventoId,
        'cantidadNinos': cantidadNinos,
        'categoria': categoria,
        'listaInvitados': invitados.trim().isEmpty ? null : invitados.trim(),
      };

      await ApiService.participarEnEvento(datos);
      
      Navigator.pop(context);
      await _cargarMisParticipaciones();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Participación registrada exitosamente'),
          backgroundColor: WessexColors.leafGreen,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      _mostrarError('Error al registrar participación: $e');
    }
  }

  void _cerrarSesion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cerrar Sesión'),
        content: Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Limpiar el token y datos de sesión
              await TokenManager.clearAuthData();
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: WessexColors.crimsonAlert),
            child: Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
