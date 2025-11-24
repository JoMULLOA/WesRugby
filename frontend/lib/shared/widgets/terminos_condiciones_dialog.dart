import 'package:flutter/material.dart';
import 'package:wesrugby/shared/services/terminos_service.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/tokenManager.dart';

class TerminosCondicionesDialog extends StatefulWidget {
  final Map<String, dynamic> terminoActivo;
  final VoidCallback onAceptado;

  const TerminosCondicionesDialog({
    Key? key,
    required this.terminoActivo,
    required this.onAceptado,
  }) : super(key: key);

  @override
  State<TerminosCondicionesDialog> createState() => _TerminosCondicionesDialogState();
}

class _TerminosCondicionesDialogState extends State<TerminosCondicionesDialog> {
  bool _aceptando = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _aceptarTerminos() async {
    setState(() {
      _aceptando = true;
    });

    try {
      // Parsear el ID como entero (puede venir como String o int del JSON)
      final dynamic idValue = widget.terminoActivo['id'];
      final int terminoId = idValue is int ? idValue : int.parse(idValue.toString());
      
      print('📤 Enviando aceptación para término ID: $terminoId');
      final resultado = await TerminosService.aceptarTerminos(terminoId);

      if (resultado['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Términos y Condiciones aceptados'),
            backgroundColor: WessexColors.leafGreen,
          ),
        );
        
        widget.onAceptado();
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${resultado['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _aceptando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final version = widget.terminoActivo['version'] ?? 'Sin versión';
    final titulo = widget.terminoActivo['titulo'] ?? 'Términos y Condiciones';
    final contenido = widget.terminoActivo['contenido'] ?? '';

    return WillPopScope(
      onWillPop: () async => false, // No permitir cerrar sin aceptar
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: WessexColors.deepRoyalBlue,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.description,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Versión $version',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Mensaje importante
              Container(
                padding: const EdgeInsets.all(16),
                color: WessexColors.leafGreen.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: WessexColors.deepRoyalBlue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Por favor, lee y acepta nuestros términos y condiciones para continuar usando la aplicación.',
                        style: TextStyle(
                          color: WessexColors.darkGrape,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido scrolleable
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: SelectableText(
                        contenido,
                        style: TextStyle(
                          color: WessexColors.darkGrape,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Footer con botones
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Debes aceptar para continuar',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _aceptando ? null : _aceptarTerminos,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WessexColors.leafGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _aceptando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Acepto los Términos y Condiciones',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
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
}

/// Función helper para mostrar el dialog si es necesario
Future<bool> verificarYMostrarTerminos(BuildContext context) async {
  try {
    // Verificar rol del usuario antes de hacer la petición
    final userRole = await TokenManager.getUserRole();
    print('🔍 Verificando términos para rol: $userRole');
    
    // Solo mostrar términos a apoderados
    if (userRole != null && userRole != 'apoderado') {
      print('✅ Usuario con rol "$userRole" exento de términos');
      return true; // Usuario exento, permitir continuar
    }

    final resultado = await TerminosService.verificarAceptacion();
    
    if (!resultado['success']) {
      print('❌ Error verificando términos: ${resultado['message']}');
      return true; // Permitir continuar en caso de error
    }

    final requiereAceptacion = resultado['requiereAceptacion'] ?? false;
    
    if (requiereAceptacion && resultado['terminoActivo'] != null) {
      // Mostrar dialog modal
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return TerminosCondicionesDialog(
            terminoActivo: resultado['terminoActivo'],
            onAceptado: () {
              print('✅ Términos aceptados por el usuario');
            },
          );
        },
      );
      return true;
    }

    return true; // Ya aceptó o no hay términos activos
  } catch (e) {
    print('❌ Error en verificarYMostrarTerminos: $e');
    return true; // Permitir continuar en caso de error
  }
}
