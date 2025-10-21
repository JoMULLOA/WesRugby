import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';

class VisualizarActasReunionScreen extends StatefulWidget {
  const VisualizarActasReunionScreen({super.key});

  @override
  State<VisualizarActasReunionScreen> createState() =>
      _VisualizarActasReunionScreenState();
}

class _VisualizarActasReunionScreenState
    extends State<VisualizarActasReunionScreen> {
  List<Map<String, dynamic>> _actas = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarActas();
  }

  Future<void> _cargarActas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Los apoderados solo ven actas publicadas, los demás ven todas
      final response = await ApiService.obtenerActasReunion(
        estado: 'publicada',
      );

      if (response.success && response.data != null) {
        setState(() {
          _actas = List<Map<String, dynamic>>.from(
            response.data['data'] ?? response.data,
          );
        });
      } else {
        setState(() {
          _error = response.message ?? 'Error al cargar actas';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _mostrarDetalleActa(Map<String, dynamic> acta) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(acta['titulo']),
            content: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información básica
                    _buildInfoRow(
                      'Fecha',
                      DateFormat(
                        'dd/MM/yyyy',
                      ).format(DateTime.parse(acta['fecha'])),
                    ),
                    if (acta['horaInicio'] != null || acta['horaFin'] != null)
                      _buildInfoRow(
                        'Hora',
                        '${acta['horaInicio'] != null ? acta['horaInicio'].substring(0, 5) : ''} - ${acta['horaFin'] != null ? acta['horaFin'].substring(0, 5) : ''}',
                      ),
                    if (acta['lugar'] != null)
                      _buildInfoRow('Lugar', acta['lugar']),

                    const SizedBox(height: 16),
                    const Text(
                      'Descripción:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(acta['descripcion']),

                    if (acta['asistentes'] != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Asistentes:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(acta['asistentes']),
                    ],

                    if (acta['acuerdos'] != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Acuerdos tomados:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(acta['acuerdos']),
                    ],

                    if (acta['proximosCompromiso'] != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Próximos compromisos:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(acta['proximosCompromiso']),
                    ],

                    const SizedBox(height: 16),
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      'Creado por: ${acta['nombreCreador']}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      'Fecha de creación: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(acta['createdAt']))}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildActaCard(Map<String, dynamic> acta) {
    final fecha = DateTime.parse(acta['fecha']);
    final createdAt = DateTime.parse(acta['createdAt']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _mostrarDetalleActa(acta),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          acta['titulo'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: WessexColors.darkGrape,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd/MM/yyyy').format(fecha),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (acta['lugar'] != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  acta['lugar'],
                                  style: TextStyle(color: Colors.grey[600]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: WessexColors.leafGreen.withOpacity(0.1),
                      border: Border.all(color: WessexColors.leafGreen),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.public,
                          size: 16,
                          color: WessexColors.leafGreen,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'PUBLICADA',
                          style: TextStyle(
                            color: WessexColors.leafGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                acta['descripcion'],
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Por: ${acta['nombreCreador']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Text(
                    'Publicado: ${DateFormat('dd/MM/yyyy').format(createdAt)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _mostrarDetalleActa(acta),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Ver detalle'),
                    style: TextButton.styleFrom(
                      foregroundColor: WessexColors.deepRoyalBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(title: 'Actas de Reunión', elevation: 2),
      body: WessexBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header informativo
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: WessexColors.maximumGrayMint.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: WessexColors.maximumGrayMint),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: WessexColors.deepRoyalBlue,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Actas de Reunión Publicadas',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: WessexColors.deepRoyalBlue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Aquí encontrarás las actas de reunión oficiales publicadas por la directiva. Haz clic en cualquier acta para ver todos los detalles.',
                      style: TextStyle(color: WessexColors.darkGrape),
                    ),
                  ],
                ),
              ),

              // Lista de actas
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _cargarActas,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                        : _actas.isEmpty
                        ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No hay actas publicadas',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Las actas de reunión aparecerán aquí cuando sean publicadas',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                        : RefreshIndicator(
                          onRefresh: _cargarActas,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _actas.length,
                            itemBuilder:
                                (context, index) =>
                                    _buildActaCard(_actas[index]),
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
