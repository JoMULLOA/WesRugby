import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import '../widgets/wessex_widgets.dart';
import '../config/colors.dart';
import '../services/voucher_service.dart';

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
  String _nombreUsuario = "Carlos Rodríguez"; // Simular usuario logueado
  final VoucherService _voucherService = VoucherService();

  @override
  void initState() {
    super.initState();
    // Inicializar cualquier configuración necesaria
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Asegurar que el widget está completamente construido
    });
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  final List<String> _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  final List<String> _metodosPago = [
    'Transferencia Bancaria',
    'Depósito Bancario',
    'Pago Móvil',
    'Efectivo'
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(
        title: 'Subir Voucher de Pago',
        elevation: 2,
      ),
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
                                  color: WessexColors.darkGrape.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                  // Información del Usuario
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
                            Icons.person,
                            color: WessexColors.deepRoyalBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enviando como:',
                                style: TextStyle(
                                  color: WessexColors.darkGrape.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _nombreUsuario,
                                style: TextStyle(
                                  color: WessexColors.darkGrape,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Apoderado - Sub-16',
                                style: TextStyle(
                                  color: WessexColors.deepRoyalBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
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
                        DropdownButtonFormField<String>(
                          value: _selectedMonth,
                          decoration: InputDecoration(
                            labelText: 'Mes de Pago',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.calendar_month, color: WessexColors.deepRoyalBlue),
                          ),
                          items: _meses.map((mes) => DropdownMenuItem(
                            value: mes,
                            child: Text(mes),
                          )).toList(),
                          onChanged: (value) => setState(() => _selectedMonth = value),
                          validator: (value) => value == null ? 'Selecciona el mes de pago' : null,
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
                            prefixIcon: Icon(Icons.attach_money, color: WessexColors.leafGreen),
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
                            prefixIcon: Icon(Icons.payment, color: WessexColors.crimsonAlert),
                          ),
                          items: _metodosPago.map((metodo) => DropdownMenuItem(
                            value: metodo,
                            child: Text(metodo),
                          )).toList(),
                          onChanged: (value) => setState(() => _selectedMetodoPago = value),
                          validator: (value) => value == null ? 'Selecciona el método de pago' : null,
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
                            prefixIcon: Icon(Icons.description, color: WessexColors.darkGrape),
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
                                color: _archivoNombre != null 
                                  ? WessexColors.leafGreen 
                                  : WessexColors.darkGrape.withOpacity(0.3),
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: _archivoNombre != null 
                                ? WessexColors.leafGreen.withOpacity(0.05)
                                : Colors.transparent,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _archivoNombre != null ? Icons.check_circle : Icons.cloud_upload,
                                  color: _archivoNombre != null 
                                    ? WessexColors.leafGreen 
                                    : WessexColors.darkGrape.withOpacity(0.5),
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _archivoNombre ?? 'Toca para seleccionar archivo',
                                  style: TextStyle(
                                    color: _archivoNombre != null 
                                      ? WessexColors.leafGreen 
                                      : WessexColors.darkGrape.withOpacity(0.7),
                                    fontSize: 16,
                                    fontWeight: _archivoNombre != null 
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
                                      color: WessexColors.darkGrape.withOpacity(0.6),
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
                                      color: WessexColors.leafGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: WessexColors.leafGreen.withOpacity(0.3),
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
                                              color: WessexColors.darkGrape.withOpacity(0.7),
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
                          child: _isUploading
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
        final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
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

    setState(() {
      _isUploading = true;
    });

    try {
      // Enviar voucher usando el servicio
      String voucherId = _voucherService.addVoucher(
        usuario: _nombreUsuario,
        rol: 'Apoderado - Sub-16',
        mes: _selectedMonth!,
        monto: double.parse(_montoController.text),
        metodoPago: _selectedMetodoPago!,
        descripcion: _descripcionController.text,
        archivo: _archivoNombre!,
        archivoData: _webFile,
      );

      // Notificar a directiva
      _voucherService.notifyDirectiva(voucherId);
      
      print('Usuario: $_nombreUsuario');
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              'Tu voucher ha sido enviado correctamente a la Directiva del club. El voucher será revisado y procesado. Puedes verificar el estado en tu historial de vouchers.',
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
                      'Enviado por: $_nombreUsuario\nFecha: ${DateTime.now().toString().substring(0, 10)}',
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