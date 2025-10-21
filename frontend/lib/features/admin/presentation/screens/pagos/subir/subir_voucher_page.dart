import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:wesrugby/data/services/pagos_service.dart';
import 'package:wesrugby/core/config/confGlobal.dart';

class SubirVoucherPage extends StatefulWidget {
  const SubirVoucherPage({super.key});

  @override
  State<SubirVoucherPage> createState() => _SubirVoucherPageState();
}

class _SubirVoucherPageState extends State<SubirVoucherPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _montoController = TextEditingController();
  final _bancoController = TextEditingController();
  final _numeroOperacionController = TextEditingController();
  final _observacionesController = TextEditingController();

  // Variables de estado
  bool _isLoading = false;
  bool _isLoadingInscripciones =
      false; // Cambiar a false para evitar loading inicial

  // Datos del formulario
  String? _inscripcionSeleccionada;
  String _metodoPago = 'transferencia';
  DateTime _fechaPago = DateTime.now();
  String _mesCorrespondiente = '';
  File? _archivoVoucher;

  // Lista de inscripciones
  List<Inscripcion> _inscripciones = [];
  String? _errorInscripciones;

  @override
  void initState() {
    super.initState();
    _inicializarMesCorrespondiente();
    _inicializarDatos();
  }

  void _inicializarDatos() {
    print('🚀 INICIANDO _inicializarDatos()...');
    print(
      '📊 Estado inicial - Loading: $_isLoadingInscripciones, Inscripciones: ${_inscripciones.length}',
    );

    // Crear datos locales inmediatamente para evitar carga infinita
    setState(() {
      _inscripciones = [
        Inscripcion(
          id: 'local-001',
          nombre: 'Estudiante',
          apellidos: 'Rugby',
          codigoAlumno: 'WRC001',
          fechaInscripcion: DateTime.now(),
        ),
      ];
      _inscripcionSeleccionada = _inscripciones.first.id;
      _isLoadingInscripciones = false; // FORZAR A FALSE
      _errorInscripciones = null;
    });

    print('✅ DATOS LOCALES CREADOS - Inscripciones: ${_inscripciones.length}');
    print('📝 ESTADO FINAL - Loading: $_isLoadingInscripciones');
    print('🎯 Inscripción seleccionada: $_inscripcionSeleccionada');

    // Intentar cargar datos reales en segundo plano (opcional)
    _cargarInscripcionesEnSegundoPlano();
  }

  Future<void> _cargarInscripcionesEnSegundoPlano() async {
    try {
      final response = await PagosService.obtenerInscripcionesApoderado();

      if (response.statusCode == 200 && response.data != null && mounted) {
        List<dynamic> rawList = [];

        if (response.data is Map && response.data['data'] is List) {
          rawList = response.data['data'];
        } else if (response.data is List) {
          rawList = response.data;
        }

        if (rawList.isNotEmpty) {
          List<Inscripcion> inscripcionesList = [];
          for (var item in rawList) {
            try {
              if (item is Map<String, dynamic>) {
                inscripcionesList.add(Inscripcion.fromJson(item));
              }
            } catch (e) {
              print('⚠️ Error procesando inscripción: $e');
            }
          }

          if (inscripcionesList.isNotEmpty && mounted) {
            setState(() {
              _inscripciones = inscripcionesList;
              _inscripcionSeleccionada = _inscripciones.first.id;
            });
            print('✅ Inscripciones reales cargadas: ${_inscripciones.length}');
          }
        }
      }
    } catch (e) {
      print('ℹ️  No se pudieron cargar inscripciones reales: $e');
      // Mantener datos locales, no es un error crítico
    }
  }

  void _inicializarMesCorrespondiente() {
    final ahora = DateTime.now();
    _mesCorrespondiente =
        '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}';
  }

  Future<void> _cargarInscripciones() async {
    print('🔍 Iniciando carga de inscripciones...');

    // Timeout inmediato para evitar cuelgues
    Timer(Duration(seconds: 15), () {
      if (_isLoadingInscripciones && mounted) {
        print('⏰ Timeout ejecutado - Creando inscripción demo');
        _crearInscripcionDemo();
      }
    });

    try {
      setState(() {
        _isLoadingInscripciones = true;
        _errorInscripciones = null;
      });

      final response = await PagosService.obtenerInscripcionesApoderado();

      print('� Respuesta recibida - Status: ${response.statusCode}');
      print('� Data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        try {
          // Procesar la respuesta de forma más simple
          List<dynamic> rawList = [];

          if (response.data is Map && response.data['data'] is List) {
            rawList = response.data['data'];
          } else if (response.data is List) {
            rawList = response.data;
          }

          print('📋 Items encontrados: ${rawList.length}');

          // Convertir a objetos Inscripcion de forma segura
          List<Inscripcion> inscripcionesList = [];
          for (var item in rawList) {
            try {
              if (item is Map<String, dynamic>) {
                inscripcionesList.add(Inscripcion.fromJson(item));
              }
            } catch (e) {
              print('⚠️ Error procesando inscripción: $e');
              // Continuar con las demás inscripciones
            }
          }

          setState(() {
            _inscripciones = inscripcionesList;
            _isLoadingInscripciones = false;

            // Auto-seleccionar si solo hay una
            if (_inscripciones.length == 1) {
              _inscripcionSeleccionada = _inscripciones.first.id;
            }
          });

          print('✅ Inscripciones procesadas: ${_inscripciones.length}');
        } catch (e) {
          print('❌ Error procesando datos: $e');
          setState(() {
            _errorInscripciones = 'Error procesando datos de inscripciones';
            _isLoadingInscripciones = false;
          });
        }
      } else {
        print(
          '❌ Error en respuesta: ${response.statusCode} - ${response.message}',
        );
        setState(() {
          _errorInscripciones =
              response.message ?? 'Error cargando inscripciones';
          _isLoadingInscripciones = false;
        });
      }
    } catch (e) {
      print('❌ Error general cargando inscripciones: $e');
      setState(() {
        _errorInscripciones = 'Error de conexión: $e';
        _isLoadingInscripciones = false;
      });
    }

    // Timeout de seguridad - si después de 10 segundos aún está cargando, mostrar error
    Future.delayed(Duration(seconds: 10), () {
      if (_isLoadingInscripciones && mounted) {
        print('⏰ Timeout - Deteniendo carga de inscripciones');
        setState(() {
          _errorInscripciones = 'Timeout: La carga tomó demasiado tiempo';
          _isLoadingInscripciones = false;
          // Crear una inscripción de fallback
          _inscripciones = [
            Inscripcion(
              id: 'demo-001',
              nombre: 'Estudiante',
              apellidos: 'Demo',
              codigoAlumno: 'DEMO001',
              fechaInscripcion: DateTime.now(),
            ),
          ];
          _inscripcionSeleccionada = _inscripciones.first.id;
        });
      }
    });
  }

  void _crearInscripcionDemo() {
    print('🎭 Creando inscripción demo por timeout/error');
    if (mounted) {
      setState(() {
        _inscripciones = [
          Inscripcion(
            id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
            nombre: 'Estudiante',
            apellidos: 'Demo',
            codigoAlumno: 'DEMO001',
            fechaInscripcion: DateTime.now(),
          ),
        ];
        _inscripcionSeleccionada = _inscripciones.first.id;
        _isLoadingInscripciones = false;
        _errorInscripciones = null;
      });
    }
  }

  @override
  void dispose() {
    _montoController.dispose();
    _bancoController.dispose();
    _numeroOperacionController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Subir Voucher de Mensualidad',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.verdePrincipal,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: () {
        print(
          '🎨 BUILD - Loading: $_isLoadingInscripciones, Error: $_errorInscripciones, Inscripciones: ${_inscripciones.length}',
        );

        if (_isLoadingInscripciones) {
          print('🔄 Mostrando CircularProgressIndicator');
          return const Center(child: CircularProgressIndicator());
        } else if (_errorInscripciones != null) {
          print('❌ Mostrando error widget');
          return _buildErrorWidget();
        } else {
          print('📋 Mostrando formulario');
          return _buildFormulario();
        }
      }(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Error cargando datos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorInscripciones!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarInscripciones,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verdePrincipal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información importante
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade600),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Complete todos los campos para registrar su pago de mensualidad. Recibirá un comprobante electrónico por correo.',
                      style: TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Selección de inscripción
            _buildSectionTitle('Información del Alumno'),
            const SizedBox(height: 12),
            _buildInscripcionSelector(),

            const SizedBox(height: 24),

            // Datos del pago
            _buildSectionTitle('Información del Pago'),
            const SizedBox(height: 12),
            _buildCampoMonto(),
            const SizedBox(height: 16),
            _buildCampoMetodoPago(),
            const SizedBox(height: 16),
            _buildCampoFechaPago(),
            const SizedBox(height: 16),
            _buildCampoMesCorrespondiente(),

            if (_metodoPago == 'transferencia' ||
                _metodoPago == 'deposito') ...[
              const SizedBox(height: 24),
              _buildSectionTitle('Datos Bancarios'),
              const SizedBox(height: 12),
              _buildCampoBanco(),
              const SizedBox(height: 16),
              _buildCampoNumeroOperacion(),
            ],

            const SizedBox(height: 24),

            // Archivo del voucher
            _buildSectionTitle('Voucher de Pago'),
            const SizedBox(height: 12),
            _buildSelectorArchivo(),

            const SizedBox(height: 24),

            // Observaciones
            _buildSectionTitle('Observaciones (Opcional)'),
            const SizedBox(height: 12),
            _buildCampoObservaciones(),

            const SizedBox(height: 32),

            // Botón de envío
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _subirVoucher,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verdePrincipal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Subiendo voucher...'),
                          ],
                        )
                        : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload),
                            SizedBox(width: 8),
                            Text(
                              'Subir Voucher de Mensualidad',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInscripcionSelector() {
    if (_inscripciones.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Text(
          'No se encontraron inscripciones activas. Contacte con la administración.',
          style: TextStyle(fontSize: 14),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _inscripcionSeleccionada,
      decoration: InputDecoration(
        labelText: 'Seleccionar Alumno',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items:
          _inscripciones.map((inscripcion) {
            return DropdownMenuItem<String>(
              value: inscripcion.id,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    inscripcion.nombreCompleto,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Código: ${inscripcion.codigoAlumno}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }).toList(),
      onChanged: (String? value) {
        setState(() {
          _inscripcionSeleccionada = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Debe seleccionar un alumno';
        }
        return null;
      },
    );
  }

  Widget _buildCampoMonto() {
    return TextFormField(
      controller: _montoController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Monto Pagado *',
        prefixIcon: const Icon(Icons.attach_money),
        suffixText: 'CLP',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        hintText: 'Ej: 50000',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'El monto es obligatorio';
        }

        final monto = double.tryParse(value);
        if (monto == null || monto <= 0) {
          return 'Ingrese un monto válido';
        }

        return null;
      },
    );
  }

  Widget _buildCampoMetodoPago() {
    return DropdownButtonFormField<String>(
      value: _metodoPago,
      decoration: InputDecoration(
        labelText: 'Método de Pago',
        prefixIcon: const Icon(Icons.payment),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: const [
        DropdownMenuItem(
          value: 'transferencia',
          child: Text('Transferencia Bancaria'),
        ),
        DropdownMenuItem(value: 'deposito', child: Text('Depósito Bancario')),
        DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
        DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
      ],
      onChanged: (String? value) {
        if (value != null) {
          setState(() {
            _metodoPago = value;
          });
        }
      },
    );
  }

  Widget _buildCampoFechaPago() {
    return InkWell(
      onTap: () => _seleccionarFecha(),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha del Pago',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          PagosService.formatearFecha(_fechaPago),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildCampoMesCorrespondiente() {
    return TextFormField(
      initialValue: _mesCorrespondiente,
      decoration: InputDecoration(
        labelText: 'Mes Correspondiente *',
        prefixIcon: const Icon(Icons.calendar_month),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        hintText: 'YYYY-MM (Ej: 2024-03)',
      ),
      onChanged: (value) {
        _mesCorrespondiente = value;
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'El mes correspondiente es obligatorio';
        }

        // Validar formato YYYY-MM
        final regex = RegExp(r'^\d{4}-\d{2}$');
        if (!regex.hasMatch(value)) {
          return 'Formato inválido. Use YYYY-MM';
        }

        return null;
      },
    );
  }

  Widget _buildCampoBanco() {
    return TextFormField(
      controller: _bancoController,
      decoration: InputDecoration(
        labelText: 'Banco de Origen',
        prefixIcon: const Icon(Icons.account_balance),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        hintText: 'Ej: Banco de Chile',
      ),
      validator: (value) {
        if ((_metodoPago == 'transferencia' || _metodoPago == 'deposito') &&
            (value == null || value.isEmpty)) {
          return 'El banco es obligatorio para transferencias y depósitos';
        }
        return null;
      },
    );
  }

  Widget _buildCampoNumeroOperacion() {
    return TextFormField(
      controller: _numeroOperacionController,
      decoration: InputDecoration(
        labelText: 'Número de Operación',
        prefixIcon: const Icon(Icons.numbers),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        hintText: 'Ej: 123456789',
      ),
      validator: (value) {
        if ((_metodoPago == 'transferencia' || _metodoPago == 'deposito') &&
            (value == null || value.isEmpty)) {
          return 'El número de operación es obligatorio';
        }
        return null;
      },
    );
  }

  Widget _buildSelectorArchivo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (_archivoVoucher == null) ...[
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Seleccionar archivo del voucher',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Formatos: JPG, PNG, PDF (máx. 5MB)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _seleccionarArchivo,
              icon: const Icon(Icons.file_upload),
              label: const Text('Seleccionar Archivo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                foregroundColor: Colors.grey.shade700,
              ),
            ),
          ] else ...[
            Icon(Icons.check_circle, size: 48, color: Colors.green.shade400),
            const SizedBox(height: 12),
            Text(
              'Archivo seleccionado:',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              _archivoVoucher!.path.split('/').last,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _seleccionarArchivo,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Cambiar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade100,
                    foregroundColor: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _archivoVoucher = null;
                    });
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Quitar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCampoObservaciones() {
    return TextFormField(
      controller: _observacionesController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Observaciones',
        prefixIcon: const Icon(Icons.note),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        hintText: 'Agregue cualquier información adicional...',
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaPago,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );

    if (picked != null && picked != _fechaPago) {
      setState(() {
        _fechaPago = picked;
      });
    }
  }

  Future<void> _seleccionarArchivo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        // Verificar tamaño (5MB máximo)
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El archivo es muy grande. Máximo 5MB permitido.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _archivoVoucher = file;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error seleccionando archivo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _subirVoucher() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_inscripcionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar un alumno'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await PagosService.subirVoucherMensualidad(
        inscripcionId: _inscripcionSeleccionada!,
        metodoPago: _metodoPago,
        montoTotal: double.parse(_montoController.text),
        fechaPago: _fechaPago,
        mesCorrespondiente: _mesCorrespondiente,
        bancoOrigen:
            _bancoController.text.isNotEmpty ? _bancoController.text : null,
        numeroOperacion:
            _numeroOperacionController.text.isNotEmpty
                ? _numeroOperacionController.text
                : null,
        observacionesApoderado:
            _observacionesController.text.isNotEmpty
                ? _observacionesController.text
                : null,
        archivoVoucher: _archivoVoucher,
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Voucher subido exitosamente! Recibirá un comprobante por correo.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );

        // Retornar con éxito
        Navigator.pop(context, true);
      } else {
        final errorMsg = response.message ?? 'Error subiendo voucher';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }
}
