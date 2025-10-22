import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:wesrugby/features/admin/presentation/screens/eventos/gestion/widgets/event_multimedia_dialog.dart';
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

  // Función para convertir hora UTC a hora de Chile (UTC-3)
  String _convertirUTCaChile(String horaUTC) {
    if (horaUTC.isEmpty) return horaUTC;

    try {
      // Parsear la hora en formato HH:mm
      final partes = horaUTC.split(':');
      if (partes.length != 2) return horaUTC;

      int horas = int.parse(partes[0]);
      int minutos = int.parse(partes[1]);

      // Restar 3 horas para convertir de UTC a Chile (UTC-3)
      horas -= 3;

      // Manejar el caso donde las horas se vuelven negativas
      if (horas < 0) {
        horas += 24;
      }

      // Formatear de vuelta a HH:mm
      return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}';
    } catch (e) {
      // Si hay error en el parseo, devolver la hora original
      return horaUTC;
    }
  }

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
      print('🔧 DEBUG - Respuesta completa: $response');
      print('🔧 DEBUG - Tipo de response: ${response.runtimeType}');
      print('🔧 DEBUG - Keys en response: ${response.keys}');

      // ✅ CORREGIDO: Acceder a los datos dentro de 'data'
      final data = response['data'];
      print('🔧 DEBUG - data: $data');
      print('🔧 DEBUG - Keys en data: ${data?.keys}');

      final eventosAgrupados = data?['eventosAgrupados'];
      final participaciones = data?['participaciones'];

      print('🔧 DEBUG - eventosAgrupados: $eventosAgrupados');
      print(
        '🔧 DEBUG - Length eventosAgrupados: ${(eventosAgrupados as List?)?.length}',
      );
      print('🔧 DEBUG - participaciones: $participaciones');

      if (eventosAgrupados is List) {
        print(
          '🔧 DEBUG - eventosAgrupados es una Lista con ${eventosAgrupados.length} elementos',
        );
        for (int i = 0; i < eventosAgrupados.length; i++) {
          print('🔧 DEBUG - Evento $i: ${eventosAgrupados[i]}');
        }
      } else {
        print(
          '🔧 DEBUG - eventosAgrupados NO es una Lista, es: ${eventosAgrupados.runtimeType}',
        );
      }

      setState(() => _misParticipaciones = eventosAgrupados ?? []);
      print(
        '🔧 DEBUG - _misParticipaciones después del setState: $_misParticipaciones',
      );
      print(
        '🔧 DEBUG - _misParticipaciones.length: ${_misParticipaciones.length}',
      );
    } catch (e) {
      print('🔴 ERROR cargando participaciones: $e');
      print('🔴 ERROR stackTrace: ${e.toString()}');
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

    // Verificar si ya estoy participando en este evento
    final bool yaParticipando = _verificarParticipacionExistente(evento['id']);
    final List<String> categoriasParticipando = _obtenerCategoriasParticipando(
      evento['id'],
    );

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

            // Fecha y hora
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: WessexColors.midnightNavy,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fechaFormateada,
                    style: TextStyle(
                      fontSize: 14,
                      color: WessexColors.midnightNavy,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            // Horas (si están disponibles)
            if (evento['horaInicio'] != null || evento['horaFin'] != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: WessexColors.midnightNavy,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _formatearHorarios(evento['horaInicio'], evento['horaFin']),
                    style: TextStyle(
                      fontSize: 14,
                      color: WessexColors.midnightNavy,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

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

            // Información de participación existente o botón para participar
            if (yaParticipando) ...[
              // Mostrar información de participación existente
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: WessexColors.leafGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: WessexColors.leafGreen, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: WessexColors.leafGreen,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '¡Ya estás participando!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: WessexColors.leafGreen,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Categorías registradas: ${categoriasParticipando.join(", ")}',
                      style: TextStyle(
                        fontSize: 14,
                        color: WessexColors.darkGrape,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed:
                            () => _mostrarDialogoParticipacionEvento(evento),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: WessexColors.leafGreen),
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: WessexColors.leafGreen),
                            SizedBox(width: 8),
                            Text(
                              'Agregar más categorías',
                              style: TextStyle(color: WessexColors.leafGreen),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Botón normal de participar
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
          ],
        ),
      ),
    );
  }

  Widget _buildParticipacionCard(Map<String, dynamic> eventoAgrupado) {
    final fecha = DateTime.parse(eventoAgrupado['fecha']);
    final fechaFormateada = '${fecha.day}/${fecha.month}/${fecha.year}';
    final participaciones = eventoAgrupado['participaciones'] as List;

    // Determinar el estado del evento basado en la fecha
    final String estadoEvento = _determinarEstadoEvento(eventoAgrupado);
    final Map<String, dynamic> estadoInfo = _getEstadoInfo(estadoEvento);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: estadoInfo['color'] as Color, width: 2),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del evento con estado prominente
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
                  // Indicador de estado del evento
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (estadoInfo['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: estadoInfo['color'] as Color,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          estadoInfo['icon'] as IconData,
                          size: 16,
                          color: estadoInfo['color'] as Color,
                        ),
                        SizedBox(width: 6),
                        Text(
                          estadoInfo['texto'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: estadoInfo['color'] as Color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Información del evento
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
                  SizedBox(width: 16),
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: WessexColors.midnightNavy,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      eventoAgrupado['lugar'] ?? 'Sin ubicación',
                      style: TextStyle(
                        fontSize: 14,
                        color: WessexColors.midnightNavy,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              // Mostrar horas si están disponibles
              if (eventoAgrupado['horaInicio'] != null ||
                  eventoAgrupado['horaFin'] != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: WessexColors.midnightNavy,
                    ),
                    SizedBox(width: 8),
                    Text(
                      _formatearHorarios(
                        eventoAgrupado['horaInicio'],
                        eventoAgrupado['horaFin'],
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: WessexColors.midnightNavy,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: 16),

              // Resumen de participación
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: WessexColors.leafGreen.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: WessexColors.leafGreen.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.groups, size: 20, color: WessexColors.leafGreen),
                    SizedBox(width: 12),
                    Text(
                      'Total registrado: ${eventoAgrupado['totalNinos']} niños',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: WessexColors.leafGreen,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '${participaciones.length} categoría${participaciones.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: WessexColors.darkGrape,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Lista detallada de participaciones por categoría
              Text(
                'Detalles de participación:',
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
                        color: WessexColors.lightGray.withOpacity(0.3),
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
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: WessexColors.darkGrape.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: WessexColors.darkGrape,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  participacion['categoria']
                                      .toString()
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: WessexColors.darkGrape,
                                  ),
                                ),
                              ),
                              Spacer(),
                              Icon(
                                Icons.groups,
                                size: 16,
                                color: WessexColors.leafGreen,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '${participacion['cantidadNinos']} niños',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: WessexColors.leafGreen,
                                ),
                              ),
                              // Botón de editar (solo visible durante 10 minutos)
                              if (_puedeEditarParticipacion(participacion)) ...[
                                SizedBox(width: 8),
                                GestureDetector(
                                  onTap:
                                      () => _mostrarDialogoEditarParticipacion(
                                        participacion,
                                      ),
                                  child: Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.orange,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (participacion['listaInvitados'] != null &&
                              participacion['listaInvitados']
                                  .toString()
                                  .isNotEmpty) ...[
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: WessexColors.midnightNavy.withOpacity(
                                  0.05,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
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
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                  .toList(),

              SizedBox(height: 16),

              if (estadoEvento == 'participado') ...[
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _mostrarMultimediaRama(eventoAgrupado),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Ver multimedia'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: WessexColors.deepRoyalBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _subirImagenesRama(eventoAgrupado),
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Agregar imágenes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WessexColors.leafGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Mensaje informativo basado en el estado
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (estadoInfo['color'] as Color).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (estadoInfo['color'] as Color).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      estadoInfo['icon'] as IconData,
                      size: 18,
                      color: estadoInfo['color'] as Color,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        estadoInfo['mensaje'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: (estadoInfo['color'] as Color),
                        ),
                      ),
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

  Future<void> _mostrarMultimediaRama(Map<String, dynamic> evento) async {
    final String eventoId = evento['id']?.toString() ?? '';
    if (eventoId.isEmpty) {
      _mostrarError('No se pudo identificar el evento.');
      return;
    }

    final titulo = evento['nombre'] ?? evento['titulo'] ?? 'Evento';

    await showDialog(
      context: context,
      builder:
          (_) => EventMultimediaDialog(
            eventoId: eventoId,
            tituloEvento: titulo,
            scaffoldContext: context,
            canUploadShared: true,
          ),
    );
  }

  Future<void> _subirImagenesRama(Map<String, dynamic> evento) async {
    final String eventoId = evento['id']?.toString() ?? '';
    if (eventoId.isEmpty) {
      _mostrarError('No se pudo identificar el evento.');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    int exitosas = 0;
    int fallidas = 0;

    try {
      for (final file in result.files) {
        try {
          final mimeType = _inferMimeType(file.extension);
          if (mimeType == null) {
            fallidas++;
            continue;
          }

          final bytes = await _obtenerBytesArchivo(file);
          await ApiService.subirMultimediaEventoRama(
            eventoId: eventoId,
            bytes: bytes,
            fileName: file.name,
            mimeType: mimeType,
          );
          exitosas++;
        } catch (e) {
          fallidas++;
        }
      }
    } finally {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (!mounted) return;

    if (exitosas > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            exitosas == 1
                ? 'Imagen subida exitosamente.'
                : '${exitosas} imágenes subidas exitosamente.',
          ),
          backgroundColor: WessexColors.leafGreen,
        ),
      );
      await _cargarMisParticipaciones();
    }

    if (fallidas > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fallidas == 1
                ? 'Una imagen no pudo subirse. Verifica el formato.'
                : '${fallidas} imágenes no pudieron subirse.',
          ),
          backgroundColor: WessexColors.crimsonAlert,
        ),
      );
    }
  }

  Future<Uint8List> _obtenerBytesArchivo(PlatformFile file) async {
    if (file.bytes != null) {
      return file.bytes!;
    }

    final stream = file.readStream;
    if (stream != null) {
      final builder = BytesBuilder();
      await for (final chunk in stream) {
        builder.add(chunk);
      }
      return builder.toBytes();
    }

    throw Exception('No fue posible leer el archivo seleccionado.');
  }

  String? _inferMimeType(String? extension) {
    if (extension == null) return null;
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  void _mostrarDialogoParticipacionEvento(Map<String, dynamic> evento) {
    // Extraer las categorías disponibles del evento
    List<String> categoriasDisponibles = [];
    if (evento['categoria'] != null &&
        evento['categoria'].toString().isNotEmpty) {
      // Las categorías vienen separadas por comas: "sub-8,sub-10"
      categoriasDisponibles =
          evento['categoria']
              .toString()
              .split(',')
              .map((cat) => cat.trim())
              .where((cat) => cat.isNotEmpty)
              .toList();
    }

    // Si no hay categorías especificadas, usar todas como fallback
    final categorias =
        categoriasDisponibles.isNotEmpty
            ? categoriasDisponibles
            : ['sub-8', 'sub-10', 'sub-12', 'sub-14', 'sub-16', 'sub-18'];

    // Lista para almacenar múltiples participaciones
    List<Map<String, dynamic>> participaciones = [
      {
        'categoria': categorias.first, // Usar la primera categoría disponible
        'cantidad': TextEditingController(),
        'invitados': TextEditingController(),
      },
    ];

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
                                    'categoria':
                                        categorias
                                            .first, // Usar la primera categoría disponible
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

        // Horas (si están disponibles)
        if (evento['horaInicio'] != null || evento['horaFin'] != null) ...[
          SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: WessexColors.midnightNavy,
              ),
              SizedBox(width: 8),
              Text(
                _formatearHorarios(evento['horaInicio'], evento['horaFin']),
                style: TextStyle(
                  fontSize: 13,
                  color: WessexColors.midnightNavy,
                ),
              ),
            ],
          ),
        ],

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

  String _formatearHorarios(String? horaInicio, String? horaFin) {
    if (horaInicio == null && horaFin == null) {
      return 'Hora no especificada';
    }

    // Priorizar mostrar solo la hora de inicio convertida a hora de Chile
    if (horaInicio != null) {
      return _convertirUTCaChile(horaInicio);
    }

    // Fallback para horaFin (aunque ya no debería usarse)
    if (horaFin != null) {
      return _convertirUTCaChile(horaFin);
    }

    return 'Hora no especificada';
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

  // Determinar el estado del evento basado en fecha y hora
  String _determinarEstadoEvento(Map<String, dynamic> evento) {
    try {
      final fechaEvento = DateTime.parse(evento['fecha']);
      final ahora = DateTime.now();

      // Si hay fecha de fin, usar esa para determinar si ya terminó
      DateTime? fechaFin;
      if (evento['fechaFin'] != null) {
        fechaFin = DateTime.parse(evento['fechaFin']);
      }

      // Si ya pasó la fecha de fin o la fecha del evento, está "participado"
      if (fechaFin != null && ahora.isAfter(fechaFin)) {
        return 'participado';
      } else if (fechaFin == null && ahora.isAfter(fechaEvento)) {
        return 'participado';
      }

      // Si es el día del evento o está en progreso, está "participando"
      if (ahora.year == fechaEvento.year &&
          ahora.month == fechaEvento.month &&
          ahora.day == fechaEvento.day) {
        return 'participando';
      }

      // Si es en el futuro, está "confirmado"
      if (ahora.isBefore(fechaEvento)) {
        return 'confirmado';
      }

      return 'participando'; // Fallback
    } catch (e) {
      return 'confirmado'; // Fallback en caso de error
    }
  }

  // Obtener información visual del estado
  Map<String, dynamic> _getEstadoInfo(String estado) {
    switch (estado) {
      case 'participado':
        return {
          'texto': 'PARTICIPADO',
          'color': WessexColors.midnightNavy,
          'icon': Icons.check_circle,
          'mensaje':
              'Ya participaste en este evento. ¡Gracias por tu participación!',
        };
      case 'participando':
        return {
          'texto': 'PARTICIPANDO',
          'color': WessexColors.leafGreen,
          'icon': Icons.sports,
          'mensaje': '¡Estás participando! El evento está en curso o es hoy.',
        };
      case 'confirmado':
      default:
        return {
          'texto': 'CONFIRMADO',
          'color': WessexColors.darkGrape,
          'icon': Icons.calendar_today,
          'mensaje':
              'Tu participación está confirmada para este evento futuro.',
        };
    }
  }

  // Verificar si ya hay participación en un evento específico
  bool _verificarParticipacionExistente(dynamic eventoId) {
    return _misParticipaciones.any(
      (participacion) => participacion['id'].toString() == eventoId.toString(),
    );
  }

  // Obtener las categorías en las que ya estoy participando para un evento
  List<String> _obtenerCategoriasParticipando(dynamic eventoId) {
    final participacion = _misParticipaciones.firstWhere(
      (p) => p['id'].toString() == eventoId.toString(),
      orElse: () => null,
    );

    if (participacion == null) return [];

    final participaciones = participacion['participaciones'] as List? ?? [];
    return participaciones.map((p) => p['categoria'].toString()).toList();
  }

  // Verificar si se puede editar una participación (solo durante 10 minutos)
  bool _puedeEditarParticipacion(Map<String, dynamic> participacion) {
    try {
      final createdAt = DateTime.parse(participacion['createdAt']);
      final tiempoTranscurrido = DateTime.now().difference(createdAt);
      return tiempoTranscurrido.inMinutes < 10;
    } catch (e) {
      return false;
    }
  }

  // Mostrar diálogo para editar participación
  void _mostrarDialogoEditarParticipacion(Map<String, dynamic> participacion) {
    final TextEditingController cantidadController = TextEditingController(
      text: participacion['cantidadNinos'].toString(),
    );
    final TextEditingController invitadosController = TextEditingController(
      text: participacion['listaInvitados']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Editar Participación',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: WessexColors.darkGrape,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categoría: ${participacion['categoria'].toString().toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: WessexColors.midnightNavy,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Cantidad de niños:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: WessexColors.midnightNavy,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: cantidadController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Ingrese cantidad',
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Lista de invitados (opcional):',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: WessexColors.midnightNavy,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: invitadosController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Nombres de invitados separados por comas',
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Solo puedes editar durante los primeros 10 minutos después de crear la participación.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: WessexColors.midnightNavy),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final cantidadNinos = int.tryParse(cantidadController.text);
                if (cantidadNinos == null || cantidadNinos <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ingrese una cantidad válida de niños'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop();
                await _editarParticipacion(
                  participacion['id'],
                  cantidadNinos,
                  invitadosController.text.trim().isEmpty
                      ? null
                      : invitadosController.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: WessexColors.darkGrape,
                foregroundColor: Colors.white,
              ),
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  // Método para editar la participación
  Future<void> _editarParticipacion(
    int participacionId,
    int cantidadNinos,
    String? listaInvitados,
  ) async {
    try {
      final response = await ApiService.editarParticipacion(
        participacionId,
        cantidadNinos,
        listaInvitados,
      );

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Participación actualizada exitosamente'),
            backgroundColor: WessexColors.leafGreen,
          ),
        );
        // Recargar las participaciones
        await _cargarMisParticipaciones();
      } else {
        throw Exception(
          response['message'] ?? 'Error al actualizar participación',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar participación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
