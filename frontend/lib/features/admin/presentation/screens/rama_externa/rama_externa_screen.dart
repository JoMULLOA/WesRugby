import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:wesrugby/features/admin/presentation/screens/eventos/gestion/widgets/event_multimedia_dialog.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/data/services/tokenManager.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/shared/widgets/effects/pulse_on_tap.dart';
import 'package:wesrugby/shared/widgets/event/event_date_time_row.dart';

class RamaExternaScreen extends StatefulWidget {
  @override
  _RamaExternaScreenState createState() => _RamaExternaScreenState();
}

class _RamaExternaScreenState extends State<RamaExternaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _eventos = [];
  List<dynamic> _misParticipaciones = [];
  List<dynamic> _misParticipacionesFiltradas = [];
  Map<String, dynamic>? _perfil;
  bool _isLoading = false;
  bool _subiendoAvatarPerfil = false;
  String _nombreUsuario = 'Usuario RamaExterna';
  String? _avatarUrl;
  bool _profileCollapsed = true;
  DateTimeRange? _participacionesRango;

  final ScrollController _eventosScrollController = ScrollController();
  final ScrollController _participacionesScrollController = ScrollController();

  String _extractEventDate(String raw) {
    if (raw.isEmpty) return raw;
    final parts = raw.split('T');
    return parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : raw;
  }

  String _normalizeEventTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    var value = raw.trim();
    if (value.isEmpty) return '';
    if (value.contains(' ')) {
      value = value.split(' ').first;
    }
    if (value.endsWith('Z') || value.endsWith('z')) {
      value = value.substring(0, value.length - 1);
    }
    if (value.contains('.')) {
      value = value.split('.').first;
    }
    final plusIndex = value.indexOf('+', 1);
    final minusIndex = value.indexOf('-', 1);
    int offsetIndex;
    if (plusIndex == -1) {
      offsetIndex = minusIndex;
    } else if (minusIndex == -1) {
      offsetIndex = plusIndex;
    } else {
      offsetIndex = plusIndex < minusIndex ? plusIndex : minusIndex;
    }
    if (offsetIndex != -1) {
      value = value.substring(0, offsetIndex);
    }
    final segments =
        value.split(':').where((segment) => segment.isNotEmpty).toList();
    if (segments.isEmpty) return '';
    final hh = segments[0].padLeft(2, '0');
    final mm = (segments.length > 1 ? segments[1] : '00').padLeft(2, '0');
    final ss = (segments.length > 2 ? segments[2] : '00').padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  DateTime? _parseEventDateTime(String dateRaw, String? timeRaw) {
    final normalized = _normalizeEventTime(timeRaw);
    if (normalized.isEmpty) return null;
    final baseDate = _extractEventDate(dateRaw);
    final candidates = <String>[
      '${baseDate}T${normalized}Z',
      '${baseDate}T$normalized',
    ];

    for (final candidate in candidates) {
      try {
        final parsed = DateTime.parse(candidate);
        return parsed.toLocal();
      } catch (_) {
        continue;
      }
    }

    try {
      final backupDate = DateTime.parse(dateRaw);
      final hour = int.parse(normalized.substring(0, 2));
      final minute = int.parse(normalized.substring(3, 5));
      final second = int.parse(normalized.substring(6, 8));
      return DateTime(
        backupDate.year,
        backupDate.month,
        backupDate.day,
        hour,
        minute,
        second,
      );
    } catch (_) {
      return null;
    }
  }

  String _formatHourMinute(DateTime dt) {
    String pad(int value) => value.toString().padLeft(2, '0');
    final local = dt.toLocal();
    return '${pad(local.hour)}:${pad(local.minute)}';
  }

  DateTime? _resolveEventStartAt(Map<String, dynamic> e) {
    final fechaStr =
        (e['fecha'] ?? e['fechaEvento'] ?? e['fecha_evento'] ?? '')
            .toString()
            .trim();
    if (fechaStr.isEmpty) return null;

    final hIniRaw =
        (e['horaInicio'] ?? e['hora'] ?? e['hora_evento'])?.toString().trim();
    final hFinRaw =
        (e['horaFin'] ?? e['horaTermino'] ?? e['hora_fin'])?.toString().trim();

    final inicio = _parseEventDateTime(fechaStr, hIniRaw);
    if (inicio != null) return inicio;

    final fin = _parseEventDateTime(fechaStr, hFinRaw);
    if (fin != null) return fin;

    try {
      return DateTime.parse(fechaStr).toLocal();
    } catch (_) {
      return null;
    }
  }

  // Helper para formatear hora del evento (UTC -> horario local)
  String _formatEventTimeLocal(Map<String, dynamic> e) {
    final fechaStr =
        (e['fecha'] ?? e['fechaEvento'] ?? e['fecha_evento'] ?? '')
            .toString()
            .trim();
    final hIniRaw =
        (e['horaInicio'] ?? e['hora'] ?? e['hora_evento'])?.toString().trim();
    final hFinRaw =
        (e['horaFin'] ?? e['horaTermino'] ?? e['hora_fin'])?.toString().trim();

    if (fechaStr.isEmpty || (hIniRaw == null && hFinRaw == null)) return '';

    final ini = _parseEventDateTime(fechaStr, hIniRaw);
    final fin = _parseEventDateTime(fechaStr, hFinRaw);

    if (ini != null && fin != null) {
      return '${_formatHourMinute(ini)} - ${_formatHourMinute(fin)}';
    }
    if (ini != null) return _formatHourMinute(ini);
    if (fin != null) return _formatHourMinute(fin);
    return '';
  }

  List<dynamic> _filtrarParticipacionesPorRango(
    List<dynamic> source,
    DateTimeRange? range,
  ) {
    if (range == null) return List<dynamic>.from(source);

    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
      999,
    );

    return source.where((evento) {
      final fechaRaw =
          evento['fecha'] ?? evento['fechaEvento'] ?? evento['fecha_evento'];
      if (fechaRaw == null) return false;

      final fechaStr = fechaRaw.toString();
      if (fechaStr.isEmpty) return false;

      try {
        final fecha = DateTime.parse(fechaStr).toLocal();
        return !fecha.isBefore(start) && !fecha.isAfter(end);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _eventosScrollController.dispose();
    _participacionesScrollController.dispose();
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

  Future<void> _cargarPerfil() async {
    try {
      final response = await ApiService.getProfile();
      final payload = response.data;
      final data =
          response.success && payload is Map<String, dynamic>
              ? payload['data'] ?? payload
              : null;
      if (mounted && data is Map<String, dynamic>) {
        final avatarUrl = _resolveAvatarUrl(data);
        setState(() {
          _perfil = Map<String, dynamic>.from(data);
          _nombreUsuario = data['nombreCompleto']?.toString() ?? _nombreUsuario;
          _avatarUrl = avatarUrl;
        });
        await TokenManager.saveUserInfo(data);
        return;
      }
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
    }

    final storedUser = await TokenManager.getUserInfo();
    if (mounted && storedUser != null) {
      final avatarUrl = _resolveAvatarUrl(storedUser);
      setState(() {
        _perfil = Map<String, dynamic>.from(storedUser);
        _nombreUsuario =
            storedUser['nombreCompleto']?.toString() ??
            storedUser['nombre']?.toString() ??
            _nombreUsuario;
        _avatarUrl = avatarUrl;
      });
    }
  }

  String? _resolveAvatarUrl(Map<String, dynamic>? data) {
    if (data == null) return null;
    final providedUrl = data['avatarUrl']?.toString();
    if (providedUrl != null && providedUrl.isNotEmpty) {
      return providedUrl;
    }
    final path = data['avatarPath']?.toString();
    if (path == null || path.isEmpty) {
      return null;
    }
    return ApiService.buildUploadUrl(path);
  }

  Future<void> _cargarEventos() async {
    try {
      final response = await ApiService.obtenerEventosDisponibles();
      setState(() => _eventos = response['data'] ?? []);
    } catch (e) {
      debugPrint('Error cargando eventos: $e');
    }
  }

  Future<void> _cargarMisParticipaciones() async {
    try {
      final response = await ApiService.obtenerMisParticipacionesEvento();
      final payload = response['data'];
      List<dynamic> eventosAgrupados = [];

      if (payload is Map<String, dynamic>) {
        final rawEventos = payload['eventosAgrupados'];
        if (rawEventos is List) {
          eventosAgrupados = List<dynamic>.from(rawEventos);
        }
      }

      setState(() {
        _misParticipaciones = eventosAgrupados;
        _misParticipacionesFiltradas = _filtrarParticipacionesPorRango(
          eventosAgrupados,
          _participacionesRango,
        );
      });
    } catch (e, stackTrace) {
      debugPrint('[ERROR] cargar participaciones: $e');
      debugPrint(stackTrace.toString());
    }
  }

  String _mimeTypeFromExtension(String? extension) {
    switch (extension?.toLowerCase()) {
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
        return 'image/jpeg';
    }
  }

  Future<void> _cambiarFotoPerfil() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo leer el archivo seleccionado.'),
            backgroundColor: WessexColors.crimsonAlert,
          ),
        );
      }
      return;
    }

    setState(() {
      _subiendoAvatarPerfil = true;
    });

    try {
      final response = await ApiService.uploadAvatar(
        bytes: bytes,
        fileName: file.name,
        mimeType: _mimeTypeFromExtension(file.extension),
      );

      final avatarUrl =
          response['avatarUrl']?.toString() ??
          (response['avatarPath'] != null
              ? ApiService.buildUploadUrl(response['avatarPath'].toString())
              : null);

      if (mounted) {
        setState(() {
          _avatarUrl = avatarUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil actualizada.'),
            backgroundColor: WessexColors.leafGreen,
          ),
        );
      }

      await _cargarPerfil();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo actualizar la foto: $e'),
            backgroundColor: WessexColors.crimsonAlert,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _subiendoAvatarPerfil = false;
        });
      }
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
      appBar: WessexAppBar(
        title: 'Portal Ramas Externas',
        centerTitle: false,
        automaticallyImplyLeading: false,
        toolbarHeight: 68,
        titleSpacing: 24,
        padding: const EdgeInsets.symmetric(vertical: 8),
        actions: [
          // Boton de logout con tooltip y accesibilidad
          Semantics(
            label: 'Cerrar sesion',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesion',
              onPressed: _cerrarSesion,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          // Avatar del usuario
          Semantics(
            label: 'Perfil de $_nombreUsuario',
            button: true,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                backgroundImage:
                    _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                child:
                    _avatarUrl == null
                        ? const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        )
                        : null,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(92),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                // Eliminar linea divisoria debajo de las tabs
                dividerColor: Colors.transparent,
                // Desactivar indicador persistente por completo
                indicatorColor: Colors.transparent,
                indicator: const BoxDecoration(),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.75),
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
                // Desactivar efectos de ripple nativos
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                tabs: [
                  PulseOnTap(
                    duration: 260,
                    pulseColor: Colors.white.withOpacity(0.25),
                    child: const Tab(
                      icon: Icon(Icons.event_available),
                      text: 'Eventos disponibles',
                    ),
                  ),
                  PulseOnTap(
                    duration: 260,
                    pulseColor: Colors.white.withOpacity(0.25),
                    child: const Tab(
                      icon: Icon(Icons.assignment_turned_in),
                      text: 'Mis participaciones',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: WessexBackground(
        child: SafeArea(
          bottom: true,
          child: Column(
            children: [
              _buildProfileSection(),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: WessexColors.mistyRoseGray.withOpacity(0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildEventosDisponiblesTab(),
                          _buildMisParticipacionesTab(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final profile = _perfil ?? const <String, dynamic>{};
    final nombre = profile['nombreCompleto']?.toString() ?? _nombreUsuario;
    final email = profile['email']?.toString() ?? '';
    final rut = profile['rut']?.toString() ?? '';
    final rol = (profile['rol'] ?? 'RamaExterna').toString();
    final collapsed = _profileCollapsed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [WessexColors.deepRoyalBlue, WessexColors.midnightNavy],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: WessexColors.midnightNavy.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: collapsed ? 18 : 24,
          vertical: collapsed ? 14 : 26,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  setState(() {
                    _profileCollapsed = !_profileCollapsed;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: collapsed ? 26 : 34,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            _avatarUrl != null
                                ? NetworkImage(_avatarUrl!)
                                : null,
                        child:
                            _avatarUrl == null
                                ? const Icon(
                                  Icons.person,
                                  size: 28,
                                  color: WessexColors.deepRoyalBlue,
                                )
                                : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.mail_outline,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      email,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (rut.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.badge,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    rut,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (!collapsed) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  rol.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                            if (collapsed) ...[
                              const SizedBox(height: 6),
                              const Text(
                                'Toca para ver mas detalles',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedRotation(
                        turns: collapsed ? 0 : 0.5,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.expand_more,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!collapsed) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _buildProfileMetric(
                      icon: Icons.event_available,
                      label: 'Eventos disponibles',
                      value: _eventos.length.toString(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      width: 1.5,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.4),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildProfileMetric(
                      icon: Icons.emoji_events,
                      label: 'Mis participaciones',
                      value: _misParticipaciones.length.toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _subiendoAvatarPerfil ? null : _cambiarFotoPerfil,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label:
                          _subiendoAvatarPerfil
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text('Actualizar foto'),
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

  Widget _buildProfileMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
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
              color: WessexColors.deepRoyalBlue.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'No hay eventos disponibles',
              style: TextStyle(
                fontSize: 18,
                color: WessexColors.deepRoyalBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Los eventos creados por la directiva apareceran aqui',
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

    return Scrollbar(
      controller: _eventosScrollController,
      thumbVisibility: true,
      child: RefreshIndicator(
        onRefresh: () => _cargarEventos(),
        color: WessexColors.deepRoyalBlue,
        backgroundColor: Colors.transparent,
        child: ListView.builder(
          controller: _eventosScrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 22),
          itemCount: _eventos.length,
          itemBuilder: (context, index) {
            return _buildEventoCard(_eventos[index]);
          },
        ),
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
              color: WessexColors.deepRoyalBlue.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'No tienes participaciones registradas',
              style: TextStyle(
                fontSize: 18,
                color: WessexColors.deepRoyalBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Participa en eventos desde la pestana disponibles',
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

    final itemCount =
        _misParticipacionesFiltradas.isEmpty
            ? 1
            : _misParticipacionesFiltradas.length + 1;

    return Scrollbar(
      controller: _participacionesScrollController,
      thumbVisibility: true,
      child: RefreshIndicator(
        onRefresh: () => _cargarMisParticipaciones(),
        color: WessexColors.deepRoyalBlue,
        backgroundColor: Colors.transparent,
        child: ListView.builder(
          controller: _participacionesScrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 22),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildParticipacionesFilterHeader();
            }
            final participacion = _misParticipacionesFiltradas[index - 1];
            return _buildParticipacionCard(participacion);
          },
        ),
      ),
    );
  }

  Widget _buildParticipacionesFilterHeader() {
    final range = _participacionesRango;
    final hasFilter = range != null;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final rangeLabel =
        range == null
            ? 'Todas las fechas'
            : '${dateFormat.format(range.start)} - ${dateFormat.format(range.end)}';
    final noResults =
        _misParticipacionesFiltradas.isEmpty && _misParticipaciones.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _seleccionarRangoParticipaciones,
                  icon: const Icon(Icons.date_range),
                  label: Text(rangeLabel),
                ),
              ),
              if (hasFilter) ...[
                const SizedBox(width: 12),
                Tooltip(
                  message: 'Limpiar filtro',
                  child: IconButton(
                    onPressed: _limpiarFiltroParticipaciones,
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ],
          ),
          if (noResults) ...[
            const SizedBox(height: 8),
            Text(
              'No hay participaciones en el rango seleccionado.',
              style: TextStyle(
                fontSize: 13,
                color: WessexColors.midnightNavy.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _seleccionarRangoParticipaciones() async {
    if (_misParticipaciones.isEmpty) return;

    final now = DateTime.now();
    final defaultStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 30));
    final defaultRange = DateTimeRange(
      start: defaultStart,
      end: DateTime(now.year, now.month, now.day),
    );

    final rangeSeleccionado = await showDateRangePicker(
      context: context,
      initialDateRange: _participacionesRango ?? defaultRange,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: constraints.maxHeight * 0.9,
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (rangeSeleccionado != null) {
      setState(() {
        _participacionesRango = rangeSeleccionado;
        _misParticipacionesFiltradas = _filtrarParticipacionesPorRango(
          _misParticipaciones,
          rangeSeleccionado,
        );
      });
    }
  }

  void _limpiarFiltroParticipaciones() {
    if (_participacionesRango == null) return;
    setState(() {
      _participacionesRango = null;
      _misParticipacionesFiltradas = List<dynamic>.from(_misParticipaciones);
    });
  }

  Widget _buildEventoCard(Map<String, dynamic> evento) {
    final DateTime? startAt = _resolveEventStartAt(evento);

    final bool yaParticipando = _verificarParticipacionExistente(evento['id']);
    final List<String> categoriasParticipando = _obtenerCategoriasParticipando(
      evento['id'],
    );
    final String descripcion = evento['descripcion']?.toString() ?? '';
    final String categoria = evento['categoria']?.toString() ?? '';
    final String tipoEvento = evento['tipoEvento']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      elevation: 4,
      shadowColor: WessexColors.midnightNavy.withOpacity(0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF5F0F4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      evento['nombre']?.toString() ?? 'Evento sin nombre',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: WessexColors.deepRoyalBlue,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: WessexColors.leafGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: WessexColors.leafGreen),
                    ),
                    child: const Text(
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
              const SizedBox(height: 12),
              EventDateTimeRow(startAt),
              // Mostrar hora del evento
              Builder(
                builder: (context) {
                  final horaFmt = _formatEventTimeLocal(evento);
                  if (horaFmt.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: WessexColors.midnightNavy,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            horaFmt,
                            style: const TextStyle(
                              fontSize: 14,
                              color: WessexColors.midnightNavy,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              if (evento['lugar'] != null &&
                  evento['lugar'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: WessexColors.midnightNavy,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        evento['lugar'].toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: WessexColors.midnightNavy,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (tipoEvento.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.sports_soccer,
                      size: 16,
                      color: WessexColors.midnightNavy,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tipo: $tipoEvento',
                      style: const TextStyle(
                        fontSize: 14,
                        color: WessexColors.midnightNavy,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              if (descripcion.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  descripcion,
                  style: TextStyle(
                    fontSize: 14,
                    color: WessexColors.midnightNavy.withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (categoria.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: WessexColors.deepRoyalBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Categorias: $categoria',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: WessexColors.deepRoyalBlue,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              if (yaParticipando) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: WessexColors.leafGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: WessexColors.leafGreen),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.check_circle,
                            color: WessexColors.leafGreen,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '!Ya estas participando!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: WessexColors.leafGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Categorias registradas: ${categoriasParticipando.join(", ")}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: WessexColors.deepRoyalBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed:
                              () => _mostrarDialogoParticipacionEvento(evento),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: WessexColors.leafGreen,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: WessexColors.leafGreen),
                              SizedBox(width: 8),
                              Text(
                                'Agregar mas categorias',
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _mostrarDialogoParticipacionEvento(evento),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WessexColors.leafGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline),
                        SizedBox(width: 8),
                        Text('Participar en evento'),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipacionCard(Map<String, dynamic> eventoAgrupado) {
    final DateTime? startAt = _resolveEventStartAt(eventoAgrupado);
    final participaciones = eventoAgrupado['participaciones'] as List;

    final String estadoEvento = _determinarEstadoEvento(eventoAgrupado);
    final Map<String, dynamic> estadoInfo = _getEstadoInfo(estadoEvento);
    final Color colorEstado = estadoInfo['color'] as Color;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, colorEstado.withOpacity(0.08)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorEstado.withOpacity(0.45), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
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
                        color: WessexColors.deepRoyalBlue,
                      ),
                    ),
                  ),
                  // Indicador de estado del evento
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorEstado.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorEstado, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          estadoInfo['icon'] as IconData,
                          size: 16,
                          color: colorEstado,
                        ),
                        SizedBox(width: 6),
                        Text(
                          estadoInfo['texto'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorEstado,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Informacion del evento
              EventDateTimeRow(startAt),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: WessexColors.midnightNavy,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      eventoAgrupado['lugar'] ?? 'Sin ubicacion',
                      style: const TextStyle(
                        fontSize: 14,
                        color: WessexColors.midnightNavy,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              // Mostrar hora del evento si esta disponible
              Builder(
                builder: (context) {
                  final horaFmt = _formatEventTimeLocal(eventoAgrupado);
                  if (horaFmt.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: WessexColors.midnightNavy,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            horaFmt,
                            style: const TextStyle(
                              fontSize: 14,
                              color: WessexColors.midnightNavy,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: 16),

              // Resumen de participacion
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
                      'Total registrado: ${eventoAgrupado['totalNinos']} ninos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: WessexColors.leafGreen,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '${participaciones.length} categoria${participaciones.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: WessexColors.deepRoyalBlue,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Lista detallada de participaciones por categoria
              Text(
                'Detalles de participacion:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: WessexColors.deepRoyalBlue,
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
                          color: WessexColors.deepRoyalBlue.withOpacity(0.2),
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
                                  color: WessexColors.deepRoyalBlue.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: WessexColors.deepRoyalBlue,
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
                                    color: WessexColors.deepRoyalBlue,
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
                                '${participacion['cantidadNinos']} ninos',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: WessexColors.leafGreen,
                                ),
                              ),
                              // Boton de editar (solo visible durante 10 minutos)
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
                      label: const Text('Agregar imagenes'),
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
                  color: colorEstado.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorEstado.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      estadoInfo['icon'] as IconData,
                      size: 18,
                      color: colorEstado,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        estadoInfo['mensaje'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colorEstado,
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

  Future<void> _importarParticipantesDesdeCsv(
    List<Map<String, dynamic>> participaciones,
    List<String> categoriasDisponibles,
    StateSetter setStateDialog,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );

    if (result == null || result.files.isEmpty) return;

    try {
      final file = result.files.first;
      final bytes = await _obtenerBytesArchivo(file);
      final contenido = utf8.decode(bytes, allowMalformed: true);
      final datosCsv = _mapearParticipantesDesdeCsv(contenido);

      if (datosCsv.isEmpty) {
        _mostrarError(
          'El archivo CSV no contiene filas válidas. Usa columnas "categoria" y "participantes".',
        );
        return;
      }

      final categoriasReferencia =
          categoriasDisponibles.isEmpty
              ? ['sub-8', 'sub-10', 'sub-12', 'sub-14', 'sub-16', 'sub-18']
              : categoriasDisponibles;

      final Map<String, String> lookup = {
        for (final categoria in categoriasReferencia)
          categoria.toLowerCase(): categoria,
      };

      int categoriasActualizadas = 0;
      final desconocidas = <String>[];

      setStateDialog(() {
        datosCsv.forEach((categoriaCsv, participantes) {
          final clave = categoriaCsv.toLowerCase();
          final categoriaOficial = lookup[clave];
          if (categoriaOficial == null) {
            desconocidas.add(categoriaCsv);
            return;
          }

          final indiceExistente = participaciones.indexWhere(
            (participacion) =>
                (participacion['categoria'] as String).toLowerCase() == clave,
          );

          final Map<String, dynamic> registro;
          if (indiceExistente == -1) {
            registro = {
              'categoria': categoriaOficial,
              'cantidad': TextEditingController(),
              'invitados': TextEditingController(),
            };
            participaciones.add(registro);
          } else {
            registro = participaciones[indiceExistente];
            registro['categoria'] = categoriaOficial;
          }

          final formatted = _formatearParticipantes(participantes);
          (registro['cantidad'] as TextEditingController).text =
              participantes.length.toString();
          (registro['invitados'] as TextEditingController).text = formatted;
          categoriasActualizadas++;
        });
      });

      if (!mounted) return;

      final mensajes = <String>[];
      if (categoriasActualizadas > 0) {
        mensajes.add(
          categoriasActualizadas == 1
              ? 'Se actualizó 1 categoría desde el CSV.'
              : 'Se actualizaron $categoriasActualizadas categorías desde el CSV.',
        );
      }
      if (desconocidas.isNotEmpty) {
        mensajes.add('Categorías no reconocidas: ${desconocidas.join(', ')}');
      }
      if (mensajes.isEmpty) {
        mensajes.add('No se encontraron categorías compatibles en el CSV.');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajes.join(' ')),
          backgroundColor:
              categoriasActualizadas > 0
                  ? WessexColors.leafGreen
                  : WessexColors.crimsonAlert,
        ),
      );
    } catch (error) {
      _mostrarError('Error al procesar el CSV: $error');
    }
  }

  void _descargarCsvEjemplo(List<String> categoriasDisponibles) {
    // Crear contenido del CSV de ejemplo
    final ejemplos = [
      'categoria,participantes',
      '',
      '# Ejemplo 1: Una categoría con varios participantes separados por comas',
    ];
    
    // Usar las categorías disponibles o valores por defecto
    final categorias = categoriasDisponibles.isNotEmpty
        ? categoriasDisponibles
        : ['sub-8', 'sub-10', 'sub-12', 'sub-14', 'sub-16', 'sub-18'];
    
    // Agregar ejemplos con las primeras 3 categorías
    if (categorias.isNotEmpty) {
      ejemplos.add('${categorias[0]},Luis Pereira,Joaquin Muñoz,Martin Silva');
    }
    if (categorias.length > 1) {
      ejemplos.add('${categorias[1]},Ana Torres,Pedro González');
    }
    if (categorias.length > 2) {
      ejemplos.add('${categorias[2]},Carlos Rojas,María Fernández,Juan López');
    }
    
    ejemplos.addAll([
      '',
      '# Notas importantes:',
      '# - La primera columna debe ser la categoría (ej: ${categorias.isNotEmpty ? categorias[0] : 'sub-8'})',
      '# - Los nombres de participantes van después, separados por comas',
      '# - Las líneas que comienzan con # son comentarios y serán ignoradas',
      '# - Puedes usar todas las categorías disponibles: ${categorias.join(", ")}',
      '# - El orden de las filas no importa',
      '# - Asegúrate de no dejar espacios extra al inicio o final de los nombres',
    ]);
    
    final csvContent = ejemplos.join('\n');
    
    // Crear el archivo y descargarlo con BOM UTF-8 para correcta visualización de acentos
    // BOM (Byte Order Mark) para UTF-8: 0xEF, 0xBB, 0xBF
    final utf8Bom = [0xEF, 0xBB, 0xBF];
    final contentBytes = utf8.encode(csvContent);
    final bytes = Uint8List.fromList([...utf8Bom, ...contentBytes]);
    
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'participantes_ejemplo_$timestamp.csv';
    
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    
    html.Url.revokeObjectUrl(url);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Archivo CSV de ejemplo descargado: $fileName'),
          backgroundColor: WessexColors.leafGreen,
        ),
      );
    }
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
                : '${exitosas} imagenes subidas exitosamente.',
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
                : '${fallidas} imagenes no pudieron subirse.',
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

  List<String> _parseParticipantesDesdeTexto(String raw) {
    if (raw.isEmpty) return const [];
    final sanitized = raw.replaceAll(RegExp('[;|]'), ',');
    return sanitized
        .split(',')
        .map((nombre) => nombre.replaceAll(RegExp('\\s+'), ' ').trim())
        .where((nombre) => nombre.isNotEmpty)
        .toList();
  }

  String _formatearParticipantes(List<String> participantes) {
    return participantes.map((nombre) => nombre.trim()).join(', ');
  }

  List<String> _splitCsvRow(String row, {String delimiter = ','}) {
    final values = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    final sanitizedRow = row.replaceAll('\ufeff', '');

    for (int i = 0; i < sanitizedRow.length; i++) {
      final char = sanitizedRow[i];
      if (char == '"') {
        if (inQuotes && i + 1 < sanitizedRow.length && sanitizedRow[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }

      if (char == delimiter && !inQuotes) {
        values.add(buffer.toString());
        buffer.clear();
        continue;
      }

      buffer.write(char);
    }

    values.add(buffer.toString());
    return values;
  }

  Map<String, List<String>> _mapearParticipantesDesdeCsv(String content) {
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lineSplitter = const LineSplitter();
    final lines = lineSplitter
        .convert(normalized)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) return const {};

    final delimiter =
        lines.first.contains(';') && !lines.first.contains(',') ? ';' : ',';

    final Map<String, List<String>> resultado = {};
    for (final rawLine in lines) {
      final cells = _splitCsvRow(rawLine, delimiter: delimiter);
      if (cells.isEmpty) continue;

      final categoria = cells.first.trim();
      if (categoria.isEmpty || categoria.toLowerCase() == 'categoria') {
        continue;
      }

      final participantesRaw =
          cells.length > 1 ? cells.sublist(1).join(',').trim() : '';
      if (participantesRaw.isEmpty) continue;

      final participantes = _parseParticipantesDesdeTexto(participantesRaw);
      if (participantes.isEmpty) continue;

      resultado[categoria] = participantes;
    }

    return resultado;
  }

  void _mostrarDialogoParticipacionEvento(Map<String, dynamic> evento) {
    // Extraer las categorias disponibles del evento
    List<String> categoriasDisponibles = [];
    if (evento['categoria'] != null &&
        evento['categoria'].toString().isNotEmpty) {
      // Las categorias vienen separadas por comas: "sub-8,sub-10"
      categoriasDisponibles =
          evento['categoria']
              .toString()
              .split(',')
              .map((cat) => cat.trim())
              .where((cat) => cat.isNotEmpty)
              .toList();
    }

    // Si no hay categorias especificadas, usar todas como fallback
    final categorias =
        categoriasDisponibles.isNotEmpty
            ? categoriasDisponibles
            : ['sub-8', 'sub-10', 'sub-12', 'sub-14', 'sub-16', 'sub-18'];

    // Lista para almacenar multiples participaciones
    List<Map<String, dynamic>> participaciones = [
      {
        'categoria': categorias.first, // Usar la primera categoria disponible
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
                              color: WessexColors.deepRoyalBlue,
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

                          // Informacion detallada del evento
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: WessexColors.lightGray.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: WessexColors.deepRoyalBlue.withOpacity(
                                  0.2,
                                ),
                              ),
                            ),
                            child: _buildDetalleEventoDialog(evento),
                          ),
                          SizedBox(height: 24),

                          // Seccion de participaciones por categoria
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Participaciones por Categoria:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: WessexColors.deepRoyalBlue,
                                  ),
                                ),
                              ),
                              Tooltip(
                                message: 'Descarga un archivo CSV de ejemplo',
                                child: TextButton.icon(
                                  onPressed: () => _descargarCsvEjemplo(categorias),
                                  icon: Icon(
                                    Icons.download,
                                    color: WessexColors.leafGreen,
                                    size: 20,
                                  ),
                                  label: Text(
                                    'Ejemplo CSV',
                                    style: TextStyle(
                                      color: WessexColors.leafGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              Tooltip(
                                message:
                                    'Importa un archivo CSV con columnas categoria y participantes',
                                child: TextButton.icon(
                                  onPressed: () => _importarParticipantesDesdeCsv(
                                    participaciones,
                                    categorias,
                                    setStateDialog,
                                  ),
                                  icon: Icon(
                                    Icons.upload_file,
                                    color: WessexColors.darkGrape,
                                  ),
                                  label: Text(
                                    'Importar CSV',
                                    style: TextStyle(
                                      color: WessexColors.darkGrape,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Formato esperado: categoria,nombre1,nombre2... (los nombres se guardan separados por comas).',
                            style: TextStyle(
                              fontSize: 12,
                              color: WessexColors.midnightNavy,
                            ),
                          ),
                          SizedBox(height: 16),

                          // Lista de participaciones
                          ...participaciones.asMap().entries.map((entry) {
                            int index = entry.key;
                            Map<String, dynamic> participacion = entry.value;

                            return Container(
                              margin: EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 6,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: WessexColors.deepRoyalBlue.withOpacity(
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
                                        'Categoria ${index + 1}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: WessexColors.deepRoyalBlue,
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

                                  // Dropdown de categoria
                                  DropdownButtonFormField<String>(
                                    value: participacion['categoria'],
                                    onChanged: (value) {
                                      setStateDialog(() {
                                        participacion['categoria'] = value!;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Categoria',
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
                                      labelText: 'Cantidad de Ninos',
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
                                          'Nombres de participantes (obligatorio)',
                                      helperText:
                                          'Ej: Ana Pérez, Juan Soto, Martina Ríos',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: Icon(Icons.people_outline),
                                      hintText: 'Escribe los nombres separados por comas',
                                    ),
                                    minLines: 2,
                                    maxLines: 3,
                                    textCapitalization: TextCapitalization.words,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),

                          // Boton para agregar mas categorias
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                setStateDialog(() {
                                  participaciones.add({
                                    'categoria':
                                        categorias
                                            .first, // Usar la primera categoria disponible
                                    'cantidad': TextEditingController(),
                                    'invitados': TextEditingController(),
                                  });
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: WessexColors.deepRoyalBlue,
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: WessexColors.deepRoyalBlue,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Agregar otra categoria',
                                    style: TextStyle(
                                      color: WessexColors.deepRoyalBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 24),

                          // Botones de accion
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
            color: WessexColors.deepRoyalBlue,
          ),
        ),
        SizedBox(height: 8),

        // Fecha y hora
        EventDateTimeRow(_resolveEventStartAt(evento)),

        // Horas (si estan disponibles)
        Builder(
          builder: (context) {
            final horaFmt = _formatEventTimeLocal(evento);
            if (horaFmt.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: WessexColors.midnightNavy,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      horaFmt,
                      style: const TextStyle(
                        fontSize: 13,
                        color: WessexColors.midnightNavy,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
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

        // Categorias disponibles (si es deportivo)
        if (evento['categoria'] != null &&
            evento['categoria'].toString().isNotEmpty) ...[
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.category, size: 14, color: WessexColors.midnightNavy),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Categorias disponibles: ${evento['categoria']}',
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
    // Validar que todas las participaciones tengan datos validos
    List<String> errores = [];

    final participacionesValidadas = <Map<String, dynamic>>[];

    for (int i = 0; i < participaciones.length; i++) {
      final participacion = participaciones[i];
      final categoria = (participacion['categoria'] as String?) ?? 'sin categoria';
      final cantidadTexto =
          (participacion['cantidad'] as TextEditingController).text.trim();
      final invitadosTexto =
          (participacion['invitados'] as TextEditingController).text.trim();

      if (cantidadTexto.isEmpty) {
        errores.add('La cantidad para la categoria ${categoria.toUpperCase()} es obligatoria');
        continue;
      }

      final cantidadNinos = int.tryParse(cantidadTexto);
      if (cantidadNinos == null || cantidadNinos <= 0) {
        errores.add('Cantidad invalida para la categoria ${categoria.toUpperCase()}');
        continue;
      }

      if (invitadosTexto.isEmpty) {
        errores.add('Ingresa los nombres de los participantes para ${categoria.toUpperCase()}');
        continue;
      }

      final participantesNormalizados =
          _parseParticipantesDesdeTexto(invitadosTexto);
      if (participantesNormalizados.isEmpty) {
        errores.add('La lista de nombres para ${categoria.toUpperCase()} no es válida');
        continue;
      }

      if (participantesNormalizados.length != cantidadNinos) {
        errores.add(
          'La cantidad ingresada (${cantidadNinos}) no coincide con los ${participantesNormalizados.length} nombres en ${categoria.toUpperCase()}',
        );
        continue;
      }

      participacionesValidadas.add({
        'categoria': categoria,
        'cantidad': cantidadNinos,
        'listaInvitados': _formatearParticipantes(participantesNormalizados),
      });
    }

    // Validar categorias duplicadas
    final Set<String> categoriasUsadas = {};
    for (final participacion in participacionesValidadas) {
      final categoria = (participacion['categoria'] as String).toLowerCase();
      if (categoriasUsadas.contains(categoria)) {
        errores.add('La categoria ${participacion['categoria']} esta duplicada');
      } else {
        categoriasUsadas.add(categoria);
      }
    }

    if (errores.isNotEmpty) {
      _mostrarError('Errores de validacion:\n${errores.join('\n')}');
      return;
    }

    try {
      // Registrar cada participacion por separado
      for (final participacion in participacionesValidadas) {
        final datos = {
          'eventoId': evento['id'],
          'cantidadNinos': participacion['cantidad'],
          'categoria': participacion['categoria'],
          'listaInvitados': participacion['listaInvitados'],
        };

        await ApiService.participarEnEvento(datos);
      }

      Navigator.pop(context);

      // Recargar datos
      await Future.wait([_cargarEventos(), _cargarMisParticipaciones()]);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${participacionesValidadas.length} participacion(es) registrada(s) exitosamente',
          ),
          backgroundColor: WessexColors.leafGreen,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      _mostrarError('Error al registrar participaciones: $e');
    }
  }

  void _cerrarSesion() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Cerrar Sesion'),
            content: Text('Estas seguro de que deseas cerrar sesion?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Limpiar el token y datos de sesion
                  await TokenManager.clearAuthData();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: WessexColors.crimsonAlert,
                ),
                child: Text('Cerrar Sesion'),
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

      // Si hay fecha de fin, usar esa para determinar si ya termino
      DateTime? fechaFin;
      if (evento['fechaFin'] != null) {
        fechaFin = DateTime.parse(evento['fechaFin']);
      }

      // Si ya paso la fecha de fin o la fecha del evento, esta "participado"
      if (fechaFin != null && ahora.isAfter(fechaFin)) {
        return 'participado';
      } else if (fechaFin == null && ahora.isAfter(fechaEvento)) {
        return 'participado';
      }

      // Si es el dia del evento o esta en progreso, esta "participando"
      if (ahora.year == fechaEvento.year &&
          ahora.month == fechaEvento.month &&
          ahora.day == fechaEvento.day) {
        return 'participando';
      }

      // Si es en el futuro, esta "confirmado"
      if (ahora.isBefore(fechaEvento)) {
        return 'confirmado';
      }

      return 'participando'; // Fallback
    } catch (e) {
      return 'confirmado'; // Fallback en caso de error
    }
  }

  // Obtener informacion visual del estado
  Map<String, dynamic> _getEstadoInfo(String estado) {
    switch (estado) {
      case 'participado':
        return {
          'texto': 'PARTICIPADO',
          'color': WessexColors.midnightNavy,
          'icon': Icons.check_circle,
          'mensaje':
              'Ya participaste en este evento. !Gracias por tu participacion!',
        };
      case 'participando':
        return {
          'texto': 'PARTICIPANDO',
          'color': WessexColors.leafGreen,
          'icon': Icons.sports,
          'mensaje': '!Estas participando! El evento esta en curso o es hoy.',
        };
      case 'confirmado':
      default:
        return {
          'texto': 'CONFIRMADO',
          'color': WessexColors.darkGrape,
          'icon': Icons.calendar_today,
          'mensaje':
              'Tu participacion esta confirmada para este evento futuro.',
        };
    }
  }

  // Verificar si ya hay participacion en un evento especifico
  bool _verificarParticipacionExistente(dynamic eventoId) {
    return _misParticipaciones.any(
      (participacion) => participacion['id'].toString() == eventoId.toString(),
    );
  }

  // Obtener las categorias en las que ya estoy participando para un evento
  List<String> _obtenerCategoriasParticipando(dynamic eventoId) {
    final participacion = _misParticipaciones.firstWhere(
      (p) => p['id'].toString() == eventoId.toString(),
      orElse: () => null,
    );

    if (participacion == null) return [];

    final participaciones = participacion['participaciones'] as List? ?? [];
    return participaciones.map((p) => p['categoria'].toString()).toList();
  }

  // Verificar si se puede editar una participacion (solo durante 10 minutos)
  bool _puedeEditarParticipacion(Map<String, dynamic> participacion) {
    try {
      final createdAt = DateTime.parse(participacion['createdAt']);
      final tiempoTranscurrido = DateTime.now().difference(createdAt);
      return tiempoTranscurrido.inMinutes < 10;
    } catch (e) {
      return false;
    }
  }

  // Mostrar dialogo para editar participacion
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
            'Editar Participacion',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: WessexColors.deepRoyalBlue,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categoria: ${participacion['categoria'].toString().toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: WessexColors.midnightNavy,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Cantidad de ninos:',
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
                  'Nombres de participantes (obligatorio):',
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
                    hintText: 'Ej: Ana Pérez, Juan Soto, Martina Ríos',
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
                          'Solo puedes editar durante los primeros 10 minutos despues de crear la participacion.',
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
                      content: Text('Ingrese una cantidad valida de ninos'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final participantesNormalizados =
                    _parseParticipantesDesdeTexto(invitadosController.text);
                if (participantesNormalizados.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Debes ingresar los nombres de los participantes separados por comas',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (participantesNormalizados.length != cantidadNinos) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'La cantidad ingresada no coincide con los ${participantesNormalizados.length} nombres registrados',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop();
                await _editarParticipacion(
                  participacion['id'],
                  cantidadNinos,
                  _formatearParticipantes(participantesNormalizados),
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

  // Metodo para editar la participacion
  Future<void> _editarParticipacion(
    int participacionId,
    int cantidadNinos,
    String listaInvitados,
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
            content: Text('Participacion actualizada exitosamente'),
            backgroundColor: WessexColors.leafGreen,
          ),
        );
        // Recargar las participaciones
        await _cargarMisParticipaciones();
      } else {
        throw Exception(
          response['message'] ?? 'Error al actualizar participacion',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar participacion: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
