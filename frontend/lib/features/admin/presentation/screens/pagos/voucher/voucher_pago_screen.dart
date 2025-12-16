import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/estudiante_service.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/data/services/pagos_service.dart';
import 'package:wesrugby/data/services/configuracion_precio_service.dart';
import 'package:file_picker/file_picker.dart';

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
  String? _selectedTipoPago; // Nuevo: mensualidad o matrícula
  String? _archivoNombre;
  Uint8List? _webFile;
  bool _isUploading = false;
  bool _isLoadingEstudiantes = true;
  bool _isLoadingUserData = true;
  bool _isLoadingMeses = true;
  bool _isLoadingPrecios = true;
  bool _aplicarATodos = true;
  Map<String, dynamic>? _userData;
  final EstudianteService _estudianteService = EstudianteService();
  List<Map<String, dynamic>> _misEstudiantes = [];
  final Set<String> _estudiantesSeleccionados = <String>{};
  
  // Lista de meses disponibles (cargados dinámicamente)
  List<Map<String, dynamic>> _mesesDisponibles = [];
  String? _errorMeses;
  
  // Pago de todos los meses restantes
  bool _pagarTodosLosMeses = false;
  List<Map<String, dynamic>> _estudiantesConMeses = []; // Info detallada por estudiante
  
  // Precios configurados
  double? _precioMensualidad;
  double? _precioMatricula;
  int _descuentoMensualidad2 = 0;
  int _descuentoMensualidad3Plus = 0;
  int _descuentoMatricula2 = 0;
  int _descuentoMatricula3Plus = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserData();
        _loadMisEstudiantes();
        _cargarMesesNoPagados();
        _cargarPrecios();
      }
    });
  }

  Future<void> _cargarPrecios() async {
    setState(() {
      _isLoadingPrecios = true;
    });

    try {
      final anioActual = DateTime.now().year;
      final response = await ConfiguracionPrecioService.obtenerPreciosPorAnio(
        anioActual,
      );

      if (response.statusCode == 200 && mounted) {
        final data = response.data['data'] as Map<String, dynamic>?;
        
        if (data != null) {
          setState(() {
            _precioMensualidad = data['precioMensualidad']?.toDouble();
            _precioMatricula = data['precioMatricula']?.toDouble();
            _descuentoMensualidad2 = data['descuentoMensualidad2'] ?? 0;
            _descuentoMensualidad3Plus = data['descuentoMensualidad3Plus'] ?? 0;
            _descuentoMatricula2 = data['descuentoMatricula2'] ?? 0;
            _descuentoMatricula3Plus = data['descuentoMatricula3Plus'] ?? 0;
            _isLoadingPrecios = false;
          });
          print('✅ Precios cargados: Mensualidad=\$$_precioMensualidad, Matrícula=\$$_precioMatricula');
          print('✅ Descuentos: Men2=$_descuentoMensualidad2%, Men3+=$_descuentoMensualidad3Plus%, Mat2=$_descuentoMatricula2%, Mat3+=$_descuentoMatricula3Plus%');
        } else {
          setState(() {
            _isLoadingPrecios = false;
          });
        }
      }
    } catch (e) {
      print('Error al cargar precios: $e');
      if (mounted) {
        setState(() {
          _isLoadingPrecios = false;
        });
      }
    }
  }

  void _onTipoPagoChanged(String? tipoPago) {
    setState(() {
      _selectedTipoPago = tipoPago;
      
      // Si cambia a matrícula, limpiar mes seleccionado y reset switch (no aplica para matrícula)
      if (tipoPago == 'Matrícula') {
        _selectedMonth = null;
        _pagarTodosLosMeses = false;
      }
      
      _actualizarMontoConDescuento();
    });
    
    // Verificar si la matrícula ya está pagada
    if (tipoPago == 'Matrícula') {
      _verificarMatriculaPagada();
    }
  }
  
  void _verificarMatriculaPagada() {
    // Verificar en los estudiantes seleccionados si alguno ya tiene matrícula pagada
    bool algunaMatriculaPagada = false;
    
    for (final rut in _estudiantesSeleccionados) {
      final estudiante = _misEstudiantes.firstWhere(
        (e) => e['rut'] == rut,
        orElse: () => {},
      );
      
      if (estudiante.isNotEmpty) {
        final pagos = estudiante['pagos'] as Map<String, dynamic>?;
        final matricula = pagos?['matricula']?.toString().toLowerCase() ?? '';
        
        // Considerar pagada si no es "no pagado" o vacío
        if (matricula.isNotEmpty && 
            !matricula.contains('no') && 
            !matricula.contains('pend')) {
          algunaMatriculaPagada = true;
          break;
        }
      }
    }
    
    if (algunaMatriculaPagada && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Uno o más estudiantes ya tienen la matrícula pagada',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: WessexColors.deepRoyalBlue,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Muestra diálogo con desglose de meses a pagar por estudiante
  void _mostrarDesgloseMeses() {
    // Mapear valor (YYYY-MM) a label (Mes Año)
    final mapMeses = Map.fromEntries(
      _mesesDisponibles.map((m) => MapEntry(m['value'] as String, m['label'] as String)),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.calendar_month,
              color: WessexColors.deepRoyalBlue,
            ),
            const SizedBox(width: 12),
            const Text('Desglose de Meses a Pagar'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _estudiantesConMeses.length,
            itemBuilder: (context, index) {
              final estudiante = _estudiantesConMeses[index];
              final rut = estudiante['rut']?.toString() ?? '';
              
              // Solo mostrar estudiantes seleccionados
              if (!_estudiantesSeleccionados.contains(rut)) {
                return const SizedBox.shrink();
              }
              
              final nombre = estudiante['nombre']?.toString() ?? 'Estudiante';
              final mesesNoPagados = (estudiante['mesesNoPagados'] as List? ?? [])
                  .map((m) => mapMeses[m] ?? m.toString())
                  .toList();
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: WessexColors.leafGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: WessexColors.leafGreen.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: TextStyle(
                        color: WessexColors.darkGrape,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mesesNoPagados.join(', '),
                      style: TextStyle(
                        color: WessexColors.darkGrape.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${mesesNoPagados.length} mes${mesesNoPagados.length != 1 ? 'es' : ''}',
                      style: TextStyle(
                        color: WessexColors.deepRoyalBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Calcula el monto total cuando se paga todos los meses
  double _calcularMontoTodosMeses() {
    if (_precioMensualidad == null) return 0;
    
    double total = 0;
    final cantidadEstudiantes = _estudiantesSeleccionados.length;
    
    // Contar total de meses a pagar por todos los estudiantes
    for (final estudiante in _estudiantesConMeses) {
      final rut = estudiante['rut']?.toString() ?? '';
      if (_estudiantesSeleccionados.contains(rut)) {
        final mesesNoPagados = estudiante['mesesNoPagados'] as List? ?? [];
        final cantidadMeses = mesesNoPagados.length;
        
        // Aplicar precio con descuento por estudiante
        final precioConDescuento = _calcularMontoConDescuento(
          _precioMensualidad!,
          cantidadEstudiantes,
          _descuentoMensualidad2,
          _descuentoMensualidad3Plus,
        );
        
        total += precioConDescuento * cantidadMeses;
      }
    }
    
    return total;
  }
  
  /// Calcula el monto total con descuento según cantidad de estudiantes
  double _calcularMontoConDescuento(double precioBase, int cantidadEstudiantes, int descuento2, int descuento3Plus) {
    if (cantidadEstudiantes <= 1) {
      return precioBase * cantidadEstudiantes;
    }
    
    final totalSinDescuento = precioBase * cantidadEstudiantes;
    
    if (cantidadEstudiantes == 2) {
      return totalSinDescuento * (100 - descuento2) / 100;
    }
    
    // cantidadEstudiantes >= 3
    return totalSinDescuento * (100 - descuento3Plus) / 100;
  }

  /// Actualiza el monto del controller según tipo de pago y estudiantes seleccionados
  void _actualizarMontoConDescuento() {
    final cantidadEstudiantes = _estudiantesSeleccionados.length;
    
    if (_selectedTipoPago == 'Mensualidad' && _precioMensualidad != null) {
      double montoTotal;
      
      if (_pagarTodosLosMeses) {
        // Calcular suma de todos los meses pendientes
        montoTotal = _calcularMontoTodosMeses();
      } else {
        // Calcular solo un mes
        montoTotal = _calcularMontoConDescuento(
          _precioMensualidad!,
          cantidadEstudiantes,
          _descuentoMensualidad2,
          _descuentoMensualidad3Plus,
        );
      }
      
      _montoController.text = montoTotal.toStringAsFixed(0);
    } else if (_selectedTipoPago == 'Matrícula' && _precioMatricula != null) {
      final montoTotal = _calcularMontoConDescuento(
        _precioMatricula!,
        cantidadEstudiantes,
        _descuentoMatricula2,
        _descuentoMatricula3Plus,
      );
      _montoController.text = montoTotal.toStringAsFixed(0);
    }
  }

  Future<void> _cargarMesesNoPagados() async {
    print('🔄 [VOUCHER] Cargando meses no pagados...');
    setState(() {
      _isLoadingMeses = true;
      _errorMeses = null;
    });

    try {
      // Pasar los RUTs de estudiantes seleccionados
      final rutSeleccionados = _estudiantesSeleccionados.toList();
      final response = await PagosService.obtenerMesesNoPagados2025(
        rutEstudiantes: rutSeleccionados.isNotEmpty ? rutSeleccionados : null,
      );
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
            final estudiantes = backendData['estudiantes'];
            print('📅 [VOUCHER] mesesComunes type: ${mesesComunes?.runtimeType}');
            print('📅 [VOUCHER] mesesComunes value: $mesesComunes');
            print('👥 [VOUCHER] estudiantes: $estudiantes');
            
            if (mesesComunes is List && mesesComunes.isNotEmpty) {
              print('✅ [VOUCHER] mesesComunes es una Lista con ${mesesComunes.length} elementos');
              setState(() {
                _mesesDisponibles = List<Map<String, dynamic>>.from(
                  mesesComunes.map((m) => m as Map<String, dynamic>)
                );
                // Guardar info de estudiantes con sus meses
                if (estudiantes is List) {
                  _estudiantesConMeses = List<Map<String, dynamic>>.from(
                    estudiantes.map((e) => e as Map<String, dynamic>)
                  );
                }
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

  // Mapear métodos de pago del frontend al backend
  String _mapMetodoPago(String metodoPagoUI) {
    const Map<String, String> metodoPagoMap = {
      'Transferencia Bancaria': 'transferencia',
      'Depósito Bancario': 'deposito',
      'Pago Móvil': 'tarjeta',
      'Efectivo': 'efectivo',
      'Cheque': 'cheque',
    };
    return metodoPagoMap[metodoPagoUI] ?? 'transferencia';
  }

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
                                              _actualizarMontoConDescuento();
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
                                      
                                      // Recalcular el monto con descuento
                                      _actualizarMontoConDescuento();
                                      
                                      // Recargar meses disponibles si está en modo Mensualidad
                                      if (_selectedTipoPago == 'Mensualidad') {
                                        // Limpiar mes seleccionado antes de recargar
                                        _selectedMonth = null;
                                        _cargarMesesNoPagados();
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

                        // Tipo de pago (Mensualidad o Matrícula)
                        DropdownButtonFormField<String>(
                          value: _selectedTipoPago,
                          decoration: InputDecoration(
                            labelText: 'Tipo de Pago',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(
                              Icons.category,
                              color: WessexColors.deepRoyalBlue,
                            ),
                          ),
                          hint: const Text('Selecciona el tipo de pago'),
                          items: const [
                            DropdownMenuItem(
                              value: 'Mensualidad',
                              child: Text('Mensualidad'),
                            ),
                            DropdownMenuItem(
                              value: 'Matrícula',
                              child: Text('Matrícula'),
                            ),
                          ],
                          onChanged: _onTipoPagoChanged,
                          validator: (value) =>
                              value == null ? 'Selecciona el tipo de pago' : null,
                        ),

                        const SizedBox(height: 16),

                        // Mes de pago (solo visible para Mensualidad)
                        if (_selectedTipoPago == 'Mensualidad') ...[
                        
                        // Switch para pagar todos los meses restantes
                        if (!_isLoadingMeses && _mesesDisponibles.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: WessexColors.leafGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: WessexColors.leafGreen.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: WessexColors.leafGreen,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Pagar todos los meses restantes del año',
                                    style: TextStyle(
                                      color: WessexColors.darkGrape,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: _pagarTodosLosMeses,
                                  onChanged: (value) {
                                    setState(() {
                                      _pagarTodosLosMeses = value;
                                      if (value) {
                                        _selectedMonth = null; // Limpiar selección individual
                                      }
                                      _actualizarMontoConDescuento();
                                    });
                                  },
                                  activeColor: WessexColors.leafGreen,
                                ),
                              ],
                            ),
                          ),
                        
                        if (!_isLoadingMeses && _mesesDisponibles.isNotEmpty)
                          const SizedBox(height: 16),
                        
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
                        else if (!_pagarTodosLosMeses) // Solo mostrar dropdown si no paga todos los meses
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
                        ], // Fin del condicional de Mensualidad

                        const SizedBox(height: 16),

                        // Nota informativa de precios configurados
                        if (_precioMensualidad != null || _precioMatricula != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: WessexColors.deepRoyalBlue.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: WessexColors.deepRoyalBlue,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Precios configurados para ${DateTime.now().year}:',
                                        style: TextStyle(
                                          color: WessexColors.deepRoyalBlue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (_precioMensualidad != null)
                                        Text(
                                          'Mensualidad: \$${_precioMensualidad!.toStringAsFixed(0)} (por estudiante)',
                                          style: TextStyle(
                                            color: WessexColors.deepRoyalBlue.withOpacity(0.8),
                                            fontSize: 12,
                                          ),
                                        ),
                                      if (_precioMatricula != null)
                                        Text(
                                          'Matrícula: \$${_precioMatricula!.toStringAsFixed(0)} (por estudiante)',
                                          style: TextStyle(
                                            color: WessexColors.deepRoyalBlue.withOpacity(0.8),
                                            fontSize: 12,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      if (_estudiantesSeleccionados.length >= 2)
                                        Text(
                                          'Descuento por ${_estudiantesSeleccionados.length} estudiantes aplicado automáticamente',
                                          style: TextStyle(
                                            color: WessexColors.leafGreen,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
                            // Botón de información cuando se paga todos los meses
                            suffixIcon: _pagarTodosLosMeses
                                ? IconButton(
                                    icon: Icon(
                                      Icons.info_outline,
                                      color: WessexColors.deepRoyalBlue,
                                    ),
                                    onPressed: _mostrarDesgloseMeses,
                                    tooltip: 'Ver desglose de meses por estudiante',
                                  )
                                : null,
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
                          'Formatos permitidos: JPEG, JPG, PNG, PDF (Máx. 5MB)',
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
                                    'Formatos permitidos: PDF, PNG, JPG, JPEG',
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
        // Para móvil: implementación con FilePicker
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
          withData: true, // Importante para obtener los bytes directamente
        );

        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          
          // Verificar tamaño (máx 10MB) - file.size está en bytes
          if (file.size > 10 * 1024 * 1024) {
            _showErrorSnackBar(
              'El archivo es muy grande. Máximo 10MB permitido.',
            );
            return;
          }

          setState(() {
            _webFile = file.bytes;
            _archivoNombre = file.name;
          });
          
          _showSuccessSnackBar('Archivo seleccionado: ${file.name}');
        }
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

    // Validar mes solo si es Mensualidad y NO se está pagando todos los meses
    if (_selectedTipoPago == 'Mensualidad' && !_pagarTodosLosMeses && _selectedMonth == null) {
      _showErrorSnackBar('Debes seleccionar el mes de pago');
      return;
    }
    
    // Validar que si paga todos los meses, tenga meses disponibles
    if (_selectedTipoPago == 'Mensualidad' && _pagarTodosLosMeses && _mesesDisponibles.isEmpty) {
      _showErrorSnackBar('No hay meses pendientes de pago');
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
      // Obtener datos de estudiantes seleccionados
      final seleccionados = _misEstudiantes
          .where((estudiante) => _estudiantesSeleccionados.contains(
                estudiante['rut']?.toString() ?? '',
              ))
          .toList();

      if (seleccionados.isEmpty) {
        throw Exception('No se encontraron datos de los estudiantes seleccionados');
      }

      // Preparar lista de RUTs seleccionados
      final estudiantesRuts = seleccionados
          .map((e) => e['rut']?.toString() ?? '')
          .where((rut) => rut.isNotEmpty)
          .toList();

      // Usar el primer estudiante disponible como inscripcionId
      final inscripcionId = _misEstudiantes.isNotEmpty 
          ? _misEstudiantes.first['rut']?.toString() ?? ''
          : '';
      
      if (inscripcionId.isEmpty) {
        throw Exception('No se encontró información del estudiante');
      }

      // Si paga todos los meses, enviar UN SOLO comprobante agrupado
      if (_selectedTipoPago == 'Mensualidad' && _pagarTodosLosMeses) {
        // Construir detallesPago: { rutEstudiante: { meses: [...], monto: X }, ... }
        final Map<String, dynamic> detallesPago = {};
        double montoTotalComprobante = 0.0;
        
        for (final estudiante in _estudiantesConMeses) {
          final rut = estudiante['rut']?.toString() ?? '';
          if (!_estudiantesSeleccionados.contains(rut)) continue;
          
          final mesesNoPagados = estudiante['mesesNoPagados'] as List? ?? [];
          if (mesesNoPagados.isEmpty) continue;
          
          // Calcular precio con descuento para este estudiante
          final precioMes = _calcularMontoConDescuento(
            _precioMensualidad!,
            _estudiantesSeleccionados.length,
            _descuentoMensualidad2,
            _descuentoMensualidad3Plus,
          );
          
          // Convertir todos los meses no pagados a labels
          final List<String> mesesLabels = mesesNoPagados.map((mesValue) {
            final mesData = _mesesDisponibles.firstWhere(
              (m) => m['value'] == mesValue,
              orElse: () => {'label': mesValue.toString()},
            );
            return mesData['label'] as String;
          }).toList();
          
          // Calcular monto para este estudiante (precio por mes * cantidad de meses)
          final montoEstudiante = precioMes * mesesNoPagados.length;
          montoTotalComprobante += montoEstudiante;
          
          detallesPago[rut] = {
            'meses': mesesLabels,
            'monto': montoEstudiante,
          };
        }
        
        if (detallesPago.isEmpty) {
          throw Exception('No hay información de pago para procesar');
        }
        
        print('📦 Enviando comprobante agrupado:');
        print('   Estudiantes: ${detallesPago.keys.length}');
        print('   Monto total: \$${montoTotalComprobante.toStringAsFixed(0)}');
        detallesPago.forEach((rut, datos) {
          print('   - $rut: ${datos['meses'].length} meses, \$${datos['monto']}');
        });
        
        // Enviar UN SOLO comprobante con detallesPago
        final response = await PagosService.subirVoucherMensualidadWeb(
          inscripcionId: inscripcionId,
          metodoPago: _mapMetodoPago(_selectedMetodoPago!),
          montoTotal: montoTotalComprobante,
          fechaPago: DateTime.now(),
          mesCorrespondiente: 'Multiple', // Indicador de múltiples meses
          estudiantesSeleccionados: estudiantesRuts,
          aplicarATodos: false,
          bancoOrigen: null,
          numeroOperacion: null,
          observacionesApoderado: _descripcionController.text.isNotEmpty 
              ? '${_descripcionController.text} (Pago agrupado: ${detallesPago.keys.length} estudiantes)' 
              : 'Pago agrupado de múltiples meses para ${detallesPago.keys.length} estudiante(s)',
          archivoBytes: _webFile,
          nombreArchivo: _archivoNombre,
          detallesPago: detallesPago, // Nuevo parámetro con la estructura agrupada
        );
        
        setState(() {
          _isUploading = false;
        });
        
        if (response.success) {
          final totalMeses = detallesPago.values
              .map((d) => (d['meses'] as List).length)
              .reduce((a, b) => a + b);
          print('✅ Comprobante agrupado enviado: ${detallesPago.keys.length} estudiantes, $totalMeses meses');
          _showSuccessDialog(
            mensajeExtra: 'Se creó 1 comprobante agrupado con ${detallesPago.keys.length} estudiante(s) y $totalMeses mes(es) de pago por un total de \$${montoTotalComprobante.toStringAsFixed(0)}.',
          );
        } else {
          throw Exception(response.message ?? 'Error al enviar comprobante agrupado');
        }
      } else {
        // Pago de un solo mes (lógica original)
        final response = await PagosService.subirVoucherMensualidadWeb(
          inscripcionId: inscripcionId,
          // Convertir etiqueta UI al código esperado por backend
          metodoPago: _mapMetodoPago(_selectedMetodoPago!),
          montoTotal: double.parse(_montoController.text),
          fechaPago: DateTime.now(),
          // Solo enviar mes si es Mensualidad
          mesCorrespondiente: _selectedTipoPago == 'Mensualidad' ? _selectedMonth! : null,
          estudiantesSeleccionados: estudiantesRuts,
          aplicarATodos: _aplicarATodos,
          bancoOrigen: null,
          numeroOperacion: null,
          observacionesApoderado: _descripcionController.text.isNotEmpty 
              ? _descripcionController.text 
              : null,
          archivoBytes: _webFile,
          nombreArchivo: _archivoNombre,
        );

        setState(() {
          _isUploading = false;
        });

        if (response.success) {
          print('✅ Voucher enviado al backend exitosamente');
          _showSuccessDialog();
        } else {
          throw Exception(response.message ?? 'Error al enviar voucher');
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      print('❌ Error enviando voucher: $e');
      _showErrorSnackBar('Error al enviar voucher: ${e.toString()}');
    }
  }

  void _showSuccessDialog({String? mensajeExtra}) {
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
                  mensajeExtra ?? 'Tu voucher ha sido enviado correctamente a la Tesorería del club. El voucher será revisado y procesado. Puedes verificar el estado en tu historial de vouchers.',
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
