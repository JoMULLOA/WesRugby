import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/voucher_service.dart';
import 'package:wesrugby/data/services/estudiante_service.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/data/services/pagos_service.dart';

class VoucherPagoScreen extends StatefulWidget {
  const VoucherPagoScreen({super.key});

  @override
  State<VoucherPagoScreen> createState() => _VoucherPagoScreenState();
}

class _VoucherPagoScreenState extends State<VoucherPagoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  String? _selectedMonth;
  String? _selectedMetodoPago;
  String? _archivoNombre;
  Uint8List? _webFile;
  bool _isUploading = false;
  bool _isLoadingEstudiantes = true;
  bool _isLoadingUserData = true;
  bool _isLoadingMeses = true;
  bool _aplicarATodos = true;
  Map<String, dynamic>? _userData;
  final VoucherService _voucherService = VoucherService();
  final EstudianteService _estudianteService = EstudianteService();
  List<Map<String, dynamic>> _misEstudiantes = [];
  final Set<String> _estudiantesSeleccionados = <String>{};
  
  // Lista de meses disponibles (cargados dinámicamente)
  List<Map<String, dynamic>> _mesesDisponibles = [];
  String? _errorMeses;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserData();
        _loadMisEstudiantes();
        _cargarMesesNoPagados();
      }
    });
  }

  Future<void> _cargarMesesNoPagados() async {
    print('🔄 [VOUCHER] Cargando meses no pagados...');
    setState(() {
      _isLoadingMeses = true;
      _errorMeses = null;
    });

    try {
      final response = await PagosService.obtenerMesesNoPagados2025();
      print('📡 [VOUCHER] Respuesta completa: $response');
      print('📡 [VOUCHER] StatusCode: ${response.statusCode}');
      print('� [VOUCHER] Data type: ${response.data?.runtimeType}');
      print('�📊 [VOUCHER] Data: ${response.data}');

      if (response.statusCode == 200 && mounted) {
        // Verificar si data es un Map
        if (response.data is Map) {
          print('✅ [VOUCHER] Data es un Map');
          final dataMap = response.data as Map<String, dynamic>;
          print('🔑 [VOUCHER] Keys en data: ${dataMap.keys.toList()}');
          
          // El backend envía: { success: true, message: "...", data: { mesesComunes: [...] } }
          // Entonces necesitamos acceder a data.data.mesesComunes
          final backendData = dataMap['data'] as Map<String, dynamic>?;
          print('📦 [VOUCHER] backendData: $backendData');
          
          if (backendData != null) {
            final mesesComunes = backendData['mesesComunes'];
            print('📅 [VOUCHER] mesesComunes type: ${mesesComunes?.runtimeType}');
            print('📅 [VOUCHER] mesesComunes value: $mesesComunes');
            
            if (mesesComunes is List && mesesComunes.isNotEmpty) {
              print('✅ [VOUCHER] mesesComunes es una Lista con ${mesesComunes.length} elementos');
              setState(() {
                _mesesDisponibles = List<Map<String, dynamic>>.from(
                  mesesComunes.map((m) => m as Map<String, dynamic>)
                );
                print('✅ [VOUCHER] ${_mesesDisponibles.length} meses cargados: $_mesesDisponibles');
                _isLoadingMeses = false;
              });
            } else {
              print('⚠️ [VOUCHER] mesesComunes está vacío o no es una lista');
              print('⚠️ [VOUCHER] estudiantes: ${backendData['estudiantes']}');
              setState(() {
                _mesesDisponibles = [];
                _errorMeses = 'Todos los meses de 2025 están pagados';
                _isLoadingMeses = false;
              });
            }
          } else {
            print('❌ [VOUCHER] backendData es null');
            setState(() {
              _errorMeses = 'No se recibieron datos del servidor';
              _isLoadingMeses = false;
            });
          }
        } else {
          print('❌ [VOUCHER] Data NO es un Map: ${response.data?.runtimeType}');
          setState(() {
            _errorMeses = 'Formato de respuesta inválido';
            _isLoadingMeses = false;
          });
        }
      } else {
        print('❌ [VOUCHER] Error en respuesta: ${response.message}');
        setState(() {
          _errorMeses = response.message ?? 'Error al cargar meses';
          _isLoadingMeses = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ [VOUCHER] Excepción: $e');
      print('❌ [VOUCHER] StackTrace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMeses = 'Error de conexión: $e';
          _isLoadingMeses = false;
        });
      }
    }
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
      print('📋 Datos del perfil: ${response.data}');

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
        print('❌ Error en respuesta del perfil');
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
      print(
        '📋 Primer estudiante: ${estudiantes.isNotEmpty ? estudiantes.first : 'N/A'}',
      );

      if (mounted) {
        setState(() {
          _misEstudiantes = estudiantes;
          _isLoadingEstudiantes = false;
          _aplicarATodos = _misEstudiantes.length <= 1
              ? true
              : _aplicarATodos;
          _sincronizarSeleccion();
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

  void _sincronizarSeleccion() {
    final idsDisponibles = _misEstudiantes
        .map((estudiante) => estudiante['rut']?.toString() ?? '')
        .where((rut) => rut.isNotEmpty)
        .toList();

    if (idsDisponibles.isEmpty) {
      _estudiantesSeleccionados.clear();
      return;
    }

    if (_aplicarATodos) {
      _estudiantesSeleccionados
        ..clear()
        ..addAll(idsDisponibles);
    } else {
      _estudiantesSeleccionados
          .removeWhere((rut) => !idsDisponibles.contains(rut));

      if (_estudiantesSeleccionados.isEmpty) {
        _estudiantesSeleccionados.add(idsDisponibles.first);
      }
    }
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  final List<String> _metodosPago = [
    'Transferencia Bancaria',
    'Depósito Bancario',
    'Pago Móvil',
    'Efectivo',
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(title: 'Subir Voucher de Pago', elevation: 2),
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
                            color: WessexColors.leafGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.upload_file,
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
                                'Adjuntar Voucher de Pago',
                                style: TextStyle(
                                  color: WessexColors.darkGrape,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sube tu comprobante de pago mensual para procesar tu solicitud',
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

                  // Información del Voucher
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
                            Icons.receipt_long,
                            color: WessexColors.deepRoyalBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Builder(
                                builder: (context) {
                                  if (_isLoadingUserData) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Cargando datos del apoderado...',
                                          style: TextStyle(
                                            color: WessexColors.darkGrape
                                                .withOpacity(0.6),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  final seleccionados = _misEstudiantes
                                      .where((estudiante) =>
                                          _estudiantesSeleccionados.contains(
                                            estudiante['rut']?.toString() ??
                                                '',
                                          ))
                                      .toList();

                                  if (seleccionados.isEmpty) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Selecciona al menos un estudiante',
                                          style: TextStyle(
                                            color:
                                                WessexColors.darkGrape.withOpacity(
                                              0.5,
                                            ),
                                            fontSize: 16,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        Text(
                                          'Enviado por: ${_userData?['nombreCompleto'] ?? 'Apoderado'}',
                                          style: TextStyle(
                                            color: WessexColors.deepRoyalBlue,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        seleccionados.length == 1
                                            ? 'Voucher para:'
                                            : 'Voucher para ${seleccionados.length} estudiantes:',
                                        style: TextStyle(
                                          color:
                                              WessexColors.darkGrape.withOpacity(
                                            0.7,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: seleccionados.map((item) {
                                          final nombre =
                                              '${item['nombres']} ${item['apellidos']}';
                                          final curso =
                                              item['curso'] ?? 'Sin curso';
                                          return Chip(
                                            label: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  nombre,
                                                  style: TextStyle(
                                                    color:
                                                        WessexColors.darkGrape,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  'Curso: $curso',
                                                  style: TextStyle(
                                                    color:
                                                        WessexColors.darkGrape
                                                            .withOpacity(0.6),
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            backgroundColor:
                                                WessexColors.deepRoyalBlue
                                                    .withOpacity(0.08),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Enviado por: ${_userData?['nombreCompleto'] ?? 'Apoderado'}',
                                        style: TextStyle(
                                          color:
                                              WessexColors.darkGrape.withOpacity(
                                            0.6,
                                          ),
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
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
                                    'Selecciona el estudiante para el cual envías este voucher',
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SwitchListTile(
                                value: _aplicarATodos,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'Aplicar el pago a todos mis hijos',
                                  style: TextStyle(
                                    color: WessexColors.darkGrape,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  _misEstudiantes.length > 1
                                      ? 'Activa esta opción si el comprobante cubre a todos tus estudiantes.'
                                      : 'Solo hay un estudiante registrado para tu cuenta.',
                                  style: TextStyle(
                                    color: WessexColors.darkGrape.withOpacity(0.65),
                                  ),
                                ),
                                onChanged:
                                    _misEstudiantes.length > 1
                                        ? (value) {
                                            setState(() {
                                              _aplicarATodos = value;
                                              _sincronizarSeleccion();
                                            });
                                          }
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _misEstudiantes.length > 1
                                    ? 'Selecciona los estudiantes cubiertos por el pago:'
                                    : 'Este voucher se asociará automáticamente al estudiante disponible:',
                                style: TextStyle(
                                  color: WessexColors.darkGrape,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ..._misEstudiantes.map((estudiante) {
                                final rut = estudiante['rut']?.toString() ?? '';
                                final seleccionado =
                                    _estudiantesSeleccionados.contains(rut);
                                return CheckboxListTile(
                                  value: seleccionado,
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(
                                    '${estudiante['nombres']} ${estudiante['apellidos']}',
                                    style: TextStyle(
                                      color: WessexColors.darkGrape,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Curso: ${estudiante['curso'] ?? 'Sin curso'}',
                                    style: TextStyle(
                                      color: WessexColors.darkGrape.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        if (rut.isNotEmpty) {
                                          _estudiantesSeleccionados.add(rut);
                                        }
                                      } else {
                                        _estudiantesSeleccionados.remove(rut);
                                      }

                                      if (_estudiantesSeleccionados.isEmpty &&
                                          _misEstudiantes.isNotEmpty) {
                                        final primerRut =
                                            _misEstudiantes.first['rut']
                                                ?.toString();
                                        if (primerRut != null &&
                                            primerRut.isNotEmpty) {
                                          _estudiantesSeleccionados
                                              .add(primerRut);
                                        }
                                      }

                                      _aplicarATodos =
                                          _estudiantesSeleccionados.length ==
                                              _misEstudiantes.length;
                                      if (_aplicarATodos) {
                                        _sincronizarSeleccion();
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                              if (_misEstudiantes.length > 1 &&
                                  _estudiantesSeleccionados.length <= 1)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        WessexColors.deepRoyalBlue.withOpacity(
                                      0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Marca todos los estudiantes que están cubiertos por este voucher.',
                                    style: TextStyle(
                                      color: WessexColors.darkGrape,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Formulario de datos del pago
                  WessexCard(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información del Pago',
                          style: TextStyle(
                            color: WessexColors.darkGrape,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Mes de pago
                        if (_isLoadingMeses)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: WessexColors.deepRoyalBlue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('Cargando meses disponibles...'),
                              ],
                            ),
                          )
                        else if (_errorMeses != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.red.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.red.shade50,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMeses!,
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_mesesDisponibles.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.orange.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.orange.shade50,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange.shade700),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'No hay meses pendientes de pago para los estudiantes seleccionados',
                                    style: TextStyle(color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            value: _selectedMonth,
                            decoration: InputDecoration(
                              labelText: 'Mes de Pago',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(
                                Icons.calendar_month,
                                color: WessexColors.deepRoyalBlue,
                              ),
                            ),
                            items: _mesesDisponibles
                                .map(
                                  (mes) => DropdownMenuItem(
                                    value: mes['label'] as String,
                                    child: Text(mes['label'] as String),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setState(() => _selectedMonth = value),
                            validator: (value) =>
                                value == null ? 'Selecciona el mes de pago' : null,
                          ),

                        const SizedBox(height: 16),

                        // Monto
                        TextFormField(
                          controller: _montoController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Monto Pagado (\$)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(
                              Icons.attach_money,
                              color: WessexColors.leafGreen,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa el monto pagado';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Ingresa un monto válido';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Método de pago
                        DropdownButtonFormField<String>(
                          value: _selectedMetodoPago,
                          decoration: InputDecoration(
                            labelText: 'Método de Pago',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(
                              Icons.payment,
                              color: WessexColors.crimsonAlert,
                            ),
                          ),
                          items:
                              _metodosPago
                                  .map(
                                    (metodo) => DropdownMenuItem(
                                      value: metodo,
                                      child: Text(metodo),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) =>
                                  setState(() => _selectedMetodoPago = value),
                          validator:
                              (value) =>
                                  value == null
                                      ? 'Selecciona el método de pago'
                                      : null,
                        ),

                        const SizedBox(height: 16),

                        // Descripción adicional
                        TextFormField(
                          controller: _descripcionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Descripción Adicional (Opcional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(
                              Icons.description,
                              color: WessexColors.darkGrape,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sección de adjuntar archivo
                  WessexCard(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Adjuntar Voucher',
                          style: TextStyle(
                            color: WessexColors.darkGrape,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Formatos permitidos: JPG, PNG, PDF (Máx. 5MB)',
                          style: TextStyle(
                            color: WessexColors.darkGrape.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Botón de seleccionar archivo
                        InkWell(
                          onTap: _pickFile,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    _archivoNombre != null
                                        ? WessexColors.leafGreen
                                        : WessexColors.darkGrape.withOpacity(
                                          0.3,
                                        ),
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color:
                                  _archivoNombre != null
                                      ? WessexColors.leafGreen.withOpacity(0.05)
                                      : Colors.transparent,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _archivoNombre != null
                                      ? Icons.check_circle
                                      : Icons.cloud_upload,
                                  color:
                                      _archivoNombre != null
                                          ? WessexColors.leafGreen
                                          : WessexColors.darkGrape.withOpacity(
                                            0.5,
                                          ),
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _archivoNombre ??
                                      'Toca para seleccionar archivo',
                                  style: TextStyle(
                                    color:
                                        _archivoNombre != null
                                            ? WessexColors.leafGreen
                                            : WessexColors.darkGrape
                                                .withOpacity(0.7),
                                    fontSize: 16,
                                    fontWeight:
                                        _archivoNombre != null
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (_archivoNombre == null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Formatos permitidos: PDF, PNG, JPG',
                                    style: TextStyle(
                                      color: WessexColors.darkGrape.withOpacity(
                                        0.6,
                                      ),
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                if (_archivoNombre != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: WessexColors.leafGreen.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: WessexColors.leafGreen
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: WessexColors.leafGreen,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Archivo seleccionado',
                                              style: TextStyle(
                                                color: WessexColors.leafGreen,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _archivoNombre!,
                                          style: TextStyle(
                                            color: WessexColors.darkGrape,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        if (_webFile != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '${(_webFile!.length / 1024).toStringAsFixed(1)} KB',
                                            style: TextStyle(
                                              color: WessexColors.darkGrape
                                                  .withOpacity(0.7),
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

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
                          onPressed: _isUploading ? null : _submitVoucher,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WessexColors.leafGreen,
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
                                      Text(
                                        'Subiendo...',
                                        style: TextStyle(
                                          color: WessexColors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                  : Text(
                                    'Enviar Voucher',
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      if (kIsWeb) {
        // Para Web: usar html input file
        final html.FileUploadInputElement uploadInput =
            html.FileUploadInputElement();
        uploadInput.accept = 'image/*,.pdf';
        uploadInput.click();

        uploadInput.onChange.listen((event) async {
          final files = uploadInput.files;
          if (files!.isNotEmpty) {
            final file = files[0];
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
        // Para móvil: implementación básica
        _showErrorSnackBar('Funcionalidad disponible solo en web por ahora');
      }
    } catch (e) {
      print('Error al seleccionar archivo: $e');
      _showErrorSnackBar('Error al seleccionar archivo: ${e.toString()}');
    }
  }

  Future<void> _submitVoucher() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_webFile == null || _archivoNombre == null) {
      _showErrorSnackBar('Debes adjuntar un voucher de pago (imagen o PDF)');
      return;
    }

    if (_estudiantesSeleccionados.isEmpty) {
      _showErrorSnackBar('Debes seleccionar al menos un estudiante');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final seleccionados = _misEstudiantes
          .where((estudiante) => _estudiantesSeleccionados.contains(
                estudiante['rut']?.toString() ?? '',
              ))
          .toList();

      if (seleccionados.isEmpty) {
        throw Exception('No se encontraron datos de los estudiantes seleccionados');
      }

      final nombresCompletos = seleccionados
          .map((item) => '${item['nombres']} ${item['apellidos']}')
          .toList();
      final resumenEstudiantes = seleccionados
          .map(
            (item) =>
                '- ${item['nombres']} ${item['apellidos']} (RUT: ${item['rut']}, Curso: ${item['curso'] ?? 'Sin curso'})',
          )
          .join('\n');

      String descripcionCompleta =
          'Estudiantes cubiertos por este voucher:\n$resumenEstudiantes';
      if (_descripcionController.text.isNotEmpty) {
        descripcionCompleta +=
            '\n\nDescripción adicional: ${_descripcionController.text}';
      }

      final etiquetaUsuario = nombresCompletos.length == 1
          ? nombresCompletos.first
          : '${nombresCompletos.first} +${nombresCompletos.length - 1}';

      final etiquetaRol = nombresCompletos.length == 1
          ? 'Estudiante - ${seleccionados.first['curso'] ?? 'Sin curso'}'
          : 'Estudiantes (${nombresCompletos.length})';

      String voucherId = _voucherService.addVoucher(
        usuario: etiquetaUsuario,
        rol: etiquetaRol,
        mes: _selectedMonth!,
        monto: double.parse(_montoController.text),
        metodoPago: _selectedMetodoPago!,
        descripcion: descripcionCompleta,
        archivo: _archivoNombre!,
        archivoData: _webFile,
      );

      // Notificar a tesorería
      _voucherService.notifyTesoreria(voucherId);

      print('Apoderado: ${_userData?['nombreCompleto'] ?? 'Usuario'}');
      print('Estudiantes vinculados: ${nombresCompletos.join(', ')}');
      print('Aplicar a todos: $_aplicarATodos');
      print('Voucher ID: $voucherId');
      print('Archivo seleccionado: $_archivoNombre');
      print('Tamaño del archivo: ${_webFile!.length} bytes');

      setState(() {
        _isUploading = false;
      });

      // Mostrar diálogo de éxito
      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showErrorSnackBar('Error al enviar voucher: ${e.toString()}');
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
                  '¡Voucher Enviado!',
                  style: TextStyle(
                    color: WessexColors.darkGrape,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Tu voucher ha sido enviado correctamente a la Tesorería del club. El voucher será revisado y procesado. Puedes verificar el estado en tu historial de vouchers.',
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

  // Ejemplo de función para envío real al servidor (comentada)
  /*
  Future<Map<String, dynamic>> _uploadVoucherToServer() async {
    if (_archivoSeleccionado == null) throw Exception('No hay archivo seleccionado');
    
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://your-api.com/api/vouchers/upload'),
    );
    
    // Agregar campos del formulario
    request.fields['usuario_nombre'] = _nombreUsuario;
    request.fields['usuario_rol'] = 'apoderado';
    request.fields['mes'] = _selectedMonth!;
    request.fields['monto'] = _montoController.text;
    request.fields['metodo_pago'] = _selectedMetodoPago!;
    request.fields['descripcion'] = _descripcionController.text;
    request.fields['fecha_envio'] = DateTime.now().toIso8601String();
    request.fields['destinatario'] = 'directiva'; // Envío a directiva
    
    // Agregar archivo
    request.files.add(
      await http.MultipartFile.fromPath(
        'voucher_image',
        _archivoSeleccionado!.path,
        filename: _imageFile!.name,
      ),
    );
    
    // Agregar headers de autenticación si es necesario
    request.headers['Authorization'] = 'Bearer YOUR_TOKEN';
    request.headers['Content-Type'] = 'multipart/form-data';
    
    var response = await request.send();
    var responseData = await response.stream.toBytes();
    var responseString = String.fromCharCodes(responseData);
    
    if (response.statusCode == 200) {
      return json.decode(responseString);
    } else {
      throw Exception('Error en servidor: ${response.statusCode}');
    }
  }
  */
}
