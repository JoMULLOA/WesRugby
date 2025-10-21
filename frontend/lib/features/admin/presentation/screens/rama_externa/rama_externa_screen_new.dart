import 'package:flutter/material.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/data/services/tokenManager.dart';
import 'package:wesrugby/core/config/colors.dart';

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
      await Future.wait([_cargarEventos(), _cargarMisParticipaciones()]);
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
      setState(() => _misParticipaciones = response['eventosAgrupados'] ?? []);
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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              itemBuilder:
                  (context) => [
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
            // Header con título y estado
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
                  child: Text(
                    'DISPONIBLE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: WessexColors.leafGreen,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Fecha
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: WessexColors.midnightNavy,
                ),
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

            // Lugar (si está disponible)
            if (evento['lugar'] != null &&
                evento['lugar'].toString().isNotEmpty) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: WessexColors.midnightNavy,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      evento['lugar'],
                      style: TextStyle(
                        fontSize: 14,
                        color: WessexColors.midnightNavy,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Tipo de evento (si es deportivo)
            if (evento['tipoEvento'] != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.sports_soccer,
                    size: 16,
                    color: WessexColors.midnightNavy,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tipo: ${evento['tipoEvento']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: WessexColors.midnightNavy,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            // Descripción (si está disponible)
            if (evento['descripcion'] != null &&
                evento['descripcion'].toString().isNotEmpty) ...[
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

            // Categorías (si es evento deportivo)
            if (evento['categoria'] != null &&
                evento['categoria'].toString().isNotEmpty) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: WessexColors.darkGrape.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Categorías: ${evento['categoria']}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: WessexColors.darkGrape,
                  ),
                ),
              ),
            ],

            SizedBox(height: 16),

            // Botón de participar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _mostrarDialogoParticipacionEvento(evento),
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

  Widget _buildParticipacionCard(Map<String, dynamic> eventoAgrupado) {
    final fecha = DateTime.parse(eventoAgrupado['fecha']);
    final fechaFormateada = '${fecha.day}/${fecha.month}/${fecha.year}';
    final participaciones = eventoAgrupado['participaciones'] as List;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del evento
            Row(
              children: [
                Expanded(
                  child: Text(
                    eventoAgrupado['nombre'] ?? 'Evento sin nombre',
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
                  child: Text(
                    '${eventoAgrupado['totalNinos']} niños',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: WessexColors.leafGreen,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: WessexColors.midnightNavy,
                ),
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
            SizedBox(height: 16),

            // Lista de participaciones por categoría
            Text(
              'Participaciones por categoría:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: WessexColors.darkGrape,
              ),
            ),
            SizedBox(height: 8),

            ...participaciones
                .map(
                  (participacion) => Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: WessexColors.lightGray.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: WessexColors.darkGrape.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.category,
                              size: 14,
                              color: WessexColors.darkGrape,
                            ),
                            SizedBox(width: 8),
                            Text(
                              participacion['categoria']
                                  .toString()
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: WessexColors.darkGrape,
                              ),
                            ),
                            Spacer(),
                            Icon(
                              Icons.group,
                              size: 14,
                              color: WessexColors.leafGreen,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${participacion['cantidadNinos']} niños',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: WessexColors.leafGreen,
                              ),
                            ),
                          ],
                        ),
                        if (participacion['listaInvitados'] != null &&
                            participacion['listaInvitados']
                                .toString()
                                .isNotEmpty) ...[
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 14,
                                color: WessexColors.midnightNavy,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Invitados: ${participacion['listaInvitados']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: WessexColors.midnightNavy
                                        .withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                )
                .toList(),

            SizedBox(height: 12),

            // Botón para agregar más categorías
            if (eventoAgrupado['estado'] == 'activo') ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed:
                      () => _mostrarDialogoAgregarCategoria(eventoAgrupado),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: WessexColors.darkGrape),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: WessexColors.darkGrape),
                      SizedBox(width: 8),
                      Text(
                        'Agregar otra categoría',
                        style: TextStyle(color: WessexColors.darkGrape),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoParticipacionEvento(Map<String, dynamic> evento) {
    // Lista para almacenar múltiples participaciones
    List<Map<String, dynamic>> participaciones = [
      {
        'categoria': 'sub-12',
        'cantidad': TextEditingController(),
        'invitados': TextEditingController(),
      },
    ];

    final categorias = ['sub-11', 'sub-12', 'sub-13'];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setStateDialog) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: 600,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
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
                          SizedBox(height: 8),

                          // Información detallada del evento
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: WessexColors.lightGray.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: WessexColors.darkGrape.withOpacity(0.2),
                              ),
                            ),
                            child: _buildDetalleEventoDialog(evento),
                          ),
                          SizedBox(height: 24),

                          // Sección de participaciones por categoría
                          Text(
                            'Participaciones por Categoría:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: WessexColors.darkGrape,
                            ),
                          ),
                          SizedBox(height: 16),

                          // Lista de participaciones
                          ...participaciones.asMap().entries.map((entry) {
                            int index = entry.key;
                            Map<String, dynamic> participacion = entry.value;

                            return Container(
                              margin: EdgeInsets.only(bottom: 16),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: WessexColors.darkGrape.withOpacity(
                                    0.3,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Categoría ${index + 1}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: WessexColors.darkGrape,
                                        ),
                                      ),
                                      Spacer(),
                                      if (participaciones.length > 1)
                                        IconButton(
                                          icon: Icon(
                                            Icons.remove_circle,
                                            color: WessexColors.crimsonAlert,
                                          ),
                                          onPressed: () {
                                            setStateDialog(() {
                                              participaciones.removeAt(index);
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 12),

                                  // Dropdown de categoría
                                  DropdownButtonFormField<String>(
                                    value: participacion['categoria'],
                                    onChanged: (value) {
                                      setStateDialog(() {
                                        participacion['categoria'] = value!;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Categoría',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: Icon(Icons.category),
                                    ),
                                    items:
                                        categorias
                                            .map(
                                              (categoria) => DropdownMenuItem(
                                                value: categoria,
                                                child: Text(
                                                  categoria.toUpperCase(),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                  SizedBox(height: 12),

                                  // Campo de cantidad
                                  TextFormField(
                                    controller: participacion['cantidad'],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Cantidad de Niños',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: Icon(Icons.group),
                                      hintText: 'Ej: 15',
                                    ),
                                  ),
                                  SizedBox(height: 12),

                                  // Campo de invitados
                                  TextFormField(
                                    controller: participacion['invitados'],
                                    decoration: InputDecoration(
                                      labelText:
                                          'Lista de Invitados (Opcional)',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: Icon(Icons.people_outline),
                                      hintText: 'Nombres separados por comas',
                                    ),
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),

                          // Botón para agregar más categorías
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                setStateDialog(() {
                                  participaciones.add({
                                    'categoria': 'sub-12',
                                    'cantidad': TextEditingController(),
                                    'invitados': TextEditingController(),
                                  });
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: WessexColors.darkGrape),
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: WessexColors.darkGrape,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Agregar otra categoría',
                                    style: TextStyle(
                                      color: WessexColors.darkGrape,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 24),

                          // Botones de acción
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancelar'),
                              ),
                              SizedBox(width: 16),
                              ElevatedButton(
                                onPressed:
                                    () => _confirmarParticipacionMultiple(
                                      evento,
                                      participaciones,
                                    ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: WessexColors.leafGreen,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: Text('Confirmar Participaciones'),
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

  void _mostrarDialogoAgregarCategoria(
    Map<String, dynamic> eventoAgrupado,
  ) async {
    try {
      // Obtener categorías disponibles del backend
      final response = await ApiService.obtenerCategoriasRegistradas(
        eventoAgrupado['id'],
      );
      final categoriasDisponibles =
          response['categoriasDisponibles'] as List<dynamic>;

      if (categoriasDisponibles.isEmpty) {
        _mostrarError(
          'Ya tienes participaciones registradas en todas las categorías para este evento',
        );
        return;
      }

      final cantidadController = TextEditingController();
      final invitadosController = TextEditingController();
      String categoriaSeleccionada = categoriasDisponibles.first.toString();

      showDialog(
        context: context,
        builder:
            (context) => StatefulBuilder(
              builder:
                  (context, setState) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      width: 500,
                      padding: EdgeInsets.all(24),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Agregar Categoría',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: WessexColors.darkGrape,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              eventoAgrupado['nombre'] ?? 'Sin nombre',
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
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: Icon(Icons.group),
                                hintText: 'Ej: 15',
                              ),
                            ),
                            SizedBox(height: 16),

                            // Categoría (solo categorías disponibles)
                            DropdownButtonFormField<String>(
                              value: categoriaSeleccionada,
                              onChanged: (value) {
                                setState(() {
                                  categoriaSeleccionada = value!;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Categoría Disponible',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: Icon(Icons.category),
                              ),
                              items:
                                  categoriasDisponibles
                                      .map(
                                        (categoria) => DropdownMenuItem<String>(
                                          value: categoria.toString(),
                                          child: Text(
                                            categoria.toString().toUpperCase(),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                            SizedBox(height: 16),

                            // Lista de invitados (opcional)
                            TextFormField(
                              controller: invitadosController,
                              decoration: InputDecoration(
                                labelText: 'Lista de Invitados (Opcional)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                  onPressed:
                                      () => _participarEnEvento(
                                        eventoAgrupado['id'],
                                        cantidadController.text,
                                        categoriaSeleccionada,
                                        invitadosController.text,
                                      ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: WessexColors.leafGreen,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: Text('Agregar Participación'),
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
    } catch (e) {
      _mostrarError('Error al cargar categorías disponibles: $e');
    }
  }

  Widget _buildDetalleEventoDialog(Map<String, dynamic> evento) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalles del Evento:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: WessexColors.darkGrape,
          ),
        ),
        SizedBox(height: 8),

        // Fecha
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: WessexColors.midnightNavy,
            ),
            SizedBox(width: 8),
            Text(
              DateTime.parse(
                evento['fecha'],
              ).toLocal().toString().split(' ')[0],
              style: TextStyle(fontSize: 13, color: WessexColors.midnightNavy),
            ),
          ],
        ),

        // Lugar
        if (evento['lugar'] != null &&
            evento['lugar'].toString().isNotEmpty) ...[
          SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: WessexColors.midnightNavy,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  evento['lugar'],
                  style: TextStyle(
                    fontSize: 13,
                    color: WessexColors.midnightNavy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],

        // Tipo de evento (si es deportivo)
        if (evento['tipoEvento'] != null) ...[
          SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.sports_soccer,
                size: 14,
                color: WessexColors.midnightNavy,
              ),
              SizedBox(width: 8),
              Text(
                'Tipo: ${evento['tipoEvento']}',
                style: TextStyle(
                  fontSize: 13,
                  color: WessexColors.midnightNavy,
                ),
              ),
            ],
          ),
        ],

        // Categorías disponibles (si es deportivo)
        if (evento['categoria'] != null &&
            evento['categoria'].toString().isNotEmpty) ...[
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.category, size: 14, color: WessexColors.midnightNavy),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Categorías disponibles: ${evento['categoria']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: WessexColors.midnightNavy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _confirmarParticipacionMultiple(
    Map<String, dynamic> evento,
    List<Map<String, dynamic>> participaciones,
  ) async {
    // Validar que todas las participaciones tengan datos válidos
    List<String> errores = [];

    for (int i = 0; i < participaciones.length; i++) {
      final participacion = participaciones[i];
      final cantidad = participacion['cantidad'].text.trim();

      if (cantidad.isEmpty) {
        errores.add('La cantidad para la categoría ${i + 1} es obligatoria');
        continue;
      }

      final cantidadNinos = int.tryParse(cantidad);
      if (cantidadNinos == null || cantidadNinos <= 0) {
        errores.add('Cantidad inválida para la categoría ${i + 1}');
      }
    }

    // Validar categorías duplicadas
    Set<String> categoriasUsadas = {};
    for (int i = 0; i < participaciones.length; i++) {
      final categoria = participaciones[i]['categoria'];
      if (categoriasUsadas.contains(categoria)) {
        errores.add('La categoría $categoria está duplicada');
      } else {
        categoriasUsadas.add(categoria);
      }
    }

    if (errores.isNotEmpty) {
      _mostrarError('Errores de validación:\n${errores.join('\n')}');
      return;
    }

    try {
      // Registrar cada participación por separado
      for (final participacion in participaciones) {
        final datos = {
          'eventoId': evento['id'],
          'cantidadNinos': int.parse(participacion['cantidad'].text),
          'categoria': participacion['categoria'],
          'listaInvitados':
              participacion['invitados'].text.trim().isEmpty
                  ? null
                  : participacion['invitados'].text.trim(),
        };

        await ApiService.participarEnEvento(datos);
      }

      Navigator.pop(context);

      // Recargar datos
      await Future.wait([_cargarEventos(), _cargarMisParticipaciones()]);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${participaciones.length} participación(es) registrada(s) exitosamente',
          ),
          backgroundColor: WessexColors.leafGreen,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      _mostrarError('Error al registrar participaciones: $e');
    }
  }

  Future<void> _participarEnEvento(
    int eventoId,
    String cantidad,
    String categoria,
    String invitados,
  ) async {
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

      // Recargar tanto eventos disponibles como participaciones
      await Future.wait([_cargarEventos(), _cargarMisParticipaciones()]);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Participación registrada exitosamente en categoría ${categoria.toUpperCase()}',
          ),
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
      builder:
          (context) => AlertDialog(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: WessexColors.crimsonAlert,
                ),
                child: Text('Cerrar Sesión'),
              ),
            ],
          ),
    );
  }
}
