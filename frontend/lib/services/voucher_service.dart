class VoucherService {
  static final VoucherService _instance = VoucherService._internal();
  factory VoucherService() => _instance;
  VoucherService._internal();

  // Lista global de vouchers para simular base de datos
  static List<Map<String, dynamic>> _vouchers = [
    // Iniciar vacía - solo se agregarán vouchers reales enviados por apoderados
  ];

  // Obtener todos los vouchers
  List<Map<String, dynamic>> getAllVouchers() {
    return List.from(_vouchers);
  }

  // Obtener vouchers filtrados
  List<Map<String, dynamic>> getFilteredVouchers({
    String? usuario,
    String? estado,
    String? searchText,
  }) {
    return _vouchers.where((voucher) {
      bool matchesUser = usuario == null || usuario == 'Todos' || voucher['usuario'] == usuario;
      bool matchesStatus = estado == null || estado == 'Todos' || voucher['estado'] == estado;
      bool matchesSearch = searchText == null || searchText.isEmpty || 
                          voucher['usuario'].toLowerCase().contains(searchText.toLowerCase());
      
      return matchesUser && matchesStatus && matchesSearch;
    }).toList();
  }

  // Obtener usuarios únicos
  List<String> getUniqueUsers() {
    Set<String> users = _vouchers.map((v) => v['usuario'] as String).toSet();
    return ['Todos', ...users.toList()..sort()];
  }

  // Obtener estadísticas
  Map<String, int> getStats() {
    int total = _vouchers.length;
    int pendientes = _vouchers.where((v) => v['estado'] == 'Pendiente').length;
    int aprobados = _vouchers.where((v) => v['estado'] == 'Aprobado').length;
    int rechazados = _vouchers.where((v) => v['estado'] == 'Rechazado').length;
    
    return {
      'total': total,
      'pendientes': pendientes,
      'aprobados': aprobados,
      'rechazados': rechazados,
    };
  }

  // Agregar nuevo voucher (desde el apoderado)
  String addVoucher({
    required String usuario,
    required String rol,
    required String mes,
    required double monto,
    required String metodoPago,
    String? descripcion,
    required String archivo,
    required dynamic archivoData,
  }) {
    String newId = 'V${(_vouchers.length + 1).toString().padLeft(3, '0')}';
    DateTime now = DateTime.now();
    String fechaEnvio = '${now.day.toString().padLeft(2, '0')} ${_getMonthName(now.month)} ${now.year} - ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    Map<String, dynamic> newVoucher = {
      'id': newId,
      'usuario': usuario,
      'rol': rol,
      'mes': mes,
      'monto': monto,
      'metodoPago': metodoPago,
      'fechaEnvio': fechaEnvio,
      'estado': 'Pendiente',
      'archivo': archivo,
      'descripcion': descripcion ?? '',
      'archivoData': archivoData,
    };
    
    _vouchers.insert(0, newVoucher); // Agregar al inicio
    return newId;
  }

  // Aprobar voucher
  bool approveVoucher(String voucherId) {
    int index = _vouchers.indexWhere((v) => v['id'] == voucherId);
    if (index != -1) {
      _vouchers[index]['estado'] = 'Aprobado';
      _vouchers[index]['fechaAprobacion'] = DateTime.now().toString();
      return true;
    }
    return false;
  }

  // Rechazar voucher
  bool rejectVoucher(String voucherId, String? motivo) {
    int index = _vouchers.indexWhere((v) => v['id'] == voucherId);
    if (index != -1) {
      _vouchers[index]['estado'] = 'Rechazado';
      _vouchers[index]['fechaRechazo'] = DateTime.now().toString();
      if (motivo != null && motivo.isNotEmpty) {
        _vouchers[index]['motivoRechazo'] = motivo;
      }
      return true;
    }
    return false;
  }

  // Obtener voucher por ID
  Map<String, dynamic>? getVoucherById(String voucherId) {
    try {
      return _vouchers.firstWhere((v) => v['id'] == voucherId);
    } catch (e) {
      return null;
    }
  }

  // Obtener vouchers por usuario (para historial del apoderado)
  List<Map<String, dynamic>> getVouchersByUser(String usuario) {
    return _vouchers.where((v) => v['usuario'] == usuario).toList();
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return months[month];
  }

  // Simular notificación a directiva
  void notifyDirectiva(String voucherId) {
    print('📧 NOTIFICACIÓN A DIRECTIVA: Nuevo voucher recibido');
    print('   - ID del voucher: $voucherId');
    print('   - Estado: Pendiente de revisión');
    print('   - La directiva puede ver este voucher en "Gestión de Vouchers"');
    // TODO: Implementar notificación real (email, push notification, etc.)
  }

  // Simular envío de comprobante electrónico
  void sendElectronicReceipt(String voucherId, String userEmail) {
    print('📧 COMPROBANTE ELECTRÓNICO ENVIADO');
    print('   - Destinatario: $userEmail');
    print('   - Voucher ID: $voucherId');
    print('   - Estado: Aprobado y procesado');
    // TODO: Implementar envío real de comprobante
  }
}