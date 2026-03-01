import 'package:flutter/material.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/configuracion_precio_service.dart';

class ConfiguracionPreciosScreen extends StatefulWidget {
  const ConfiguracionPreciosScreen({super.key});

  @override
  State<ConfiguracionPreciosScreen> createState() =>
      _ConfiguracionPreciosScreenState();
}

class _ConfiguracionPreciosScreenState
    extends State<ConfiguracionPreciosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mensualidadController = TextEditingController();
  final _matriculaController = TextEditingController();
  final _descuentoMensualidad2Controller = TextEditingController(text: '0');
  final _descuentoMensualidad3PlusController = TextEditingController(text: '0');
  final _descuentoMatricula2Controller = TextEditingController(text: '0');
  final _descuentoMatricula3PlusController = TextEditingController(text: '0');
  
  int _anioSeleccionado = DateTime.now().year;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasExistingConfig = false;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  @override
  void dispose() {
    _mensualidadController.dispose();
    _matriculaController.dispose();
    _descuentoMensualidad2Controller.dispose();
    _descuentoMensualidad3PlusController.dispose();
    _descuentoMatricula2Controller.dispose();
    _descuentoMatricula3PlusController.dispose();
    super.dispose();
  }

  Future<void> _cargarConfiguracion() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ConfiguracionPrecioService.obtenerPreciosPorAnio(
        _anioSeleccionado,
      );

      if (response.statusCode == 200 && mounted) {
        final data = response.data['data'] as Map<String, dynamic>?;
        
        if (data != null &&
            data['precioMensualidad'] != null &&
            data['precioMatricula'] != null) {
          setState(() {
            _mensualidadController.text = data['precioMensualidad'].toString();
            _matriculaController.text = data['precioMatricula'].toString();
            _descuentoMensualidad2Controller.text = (data['descuentoMensualidad2'] ?? 0).toString();
            _descuentoMensualidad3PlusController.text = (data['descuentoMensualidad3Plus'] ?? 0).toString();
            _descuentoMatricula2Controller.text = (data['descuentoMatricula2'] ?? 0).toString();
            _descuentoMatricula3PlusController.text = (data['descuentoMatricula3Plus'] ?? 0).toString();
            _hasExistingConfig = true;
            _isLoading = false;
          });
        } else {
          setState(() {
            _mensualidadController.clear();
            _matriculaController.clear();
            _descuentoMensualidad2Controller.text = '0';
            _descuentoMensualidad3PlusController.text = '0';
            _descuentoMatricula2Controller.text = '0';
            _descuentoMatricula3PlusController.text = '0';
            _hasExistingConfig = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error al cargar configuración: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _guardarConfiguracion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await ConfiguracionPrecioService.guardarPrecios(
        anio: _anioSeleccionado,
        precioMensualidad: double.parse(_mensualidadController.text),
        precioMatricula: double.parse(_matriculaController.text),
        descuentoMensualidad2: int.parse(_descuentoMensualidad2Controller.text),
        descuentoMensualidad3Plus: int.parse(_descuentoMensualidad3PlusController.text),
        descuentoMatricula2: int.parse(_descuentoMatricula2Controller.text),
        descuentoMatricula3Plus: int.parse(_descuentoMatricula3PlusController.text),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _hasExistingConfig
                    ? 'Precios actualizados correctamente'
                    : 'Precios configurados correctamente',
              ),
              backgroundColor: WessexColors.leafGreen,
            ),
          );
          _cargarConfiguracion();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Error al guardar precios'),
              backgroundColor: WessexColors.crimsonAlert,
            ),
          );
        }
      }
    } catch (e) {
      print('Error al guardar configuración: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error de conexión'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 1200;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(
        title: 'Configuración de Precios',
        elevation: 2,
      ),
      body: WessexBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título y descripción
                      WessexCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: WessexColors.deepRoyalBlue
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.attach_money,
                                    color: WessexColors.deepRoyalBlue,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Configuración de Precios',
                                        style: TextStyle(
                                          color: WessexColors.darkGrape,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Define los precios anuales de mensualidades y matrícula',
                                        style: TextStyle(
                                          color: WessexColors.darkGrape
                                              .withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Selector de año
                      WessexCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Año',
                              style: TextStyle(
                                color: WessexColors.darkGrape,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<int>(
                              value: _anioSeleccionado,
                              decoration: InputDecoration(
                                labelText: 'Selecciona el año',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(
                                  Icons.calendar_today,
                                  color: WessexColors.deepRoyalBlue,
                                ),
                              ),
                              items: List.generate(
                                11,
                                (index) {
                                  final year = DateTime.now().year - 1 + index;
                                  return DropdownMenuItem(
                                    value: year,
                                    child: Text(year.toString()),
                                  );
                                },
                              ),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _anioSeleccionado = value;
                                  });
                                  _cargarConfiguracion();
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Formulario de precios
                      if (_isLoading)
                        WessexCard(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: WessexColors.deepRoyalBlue,
                            ),
                          ),
                        )
                      else
                        WessexCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Precios para el año $_anioSeleccionado',
                                style: TextStyle(
                                  color: WessexColors.darkGrape,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Precio Mensualidad
                              TextFormField(
                                controller: _mensualidadController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Precio Mensualidad (\$)',
                                  hintText: 'Ej: 22000',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.calendar_month,
                                    color: WessexColors.leafGreen,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Ingresa el precio de la mensualidad';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Ingresa un número válido';
                                  }
                                  if (double.parse(value) <= 0) {
                                    return 'El precio debe ser mayor a 0';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Precio Matrícula
                              TextFormField(
                                controller: _matriculaController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Precio Matrícula (\$)',
                                  hintText: 'Ej: 50000',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.school,
                                    color: WessexColors.deepRoyalBlue,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Ingresa el precio de la matrícula';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Ingresa un número válido';
                                  }
                                  if (double.parse(value) <= 0) {
                                    return 'El precio debe ser mayor a 0';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 24),

                              // Sección de descuentos
                              Divider(color: WessexColors.darkGrape.withOpacity(0.2)),
                              const SizedBox(height: 16),
                              
                              Text(
                                'Descuentos por Cantidad de Estudiantes',
                                style: TextStyle(
                                  color: WessexColors.darkGrape,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Configura descuentos para apoderados con múltiples estudiantes a cargo',
                                style: TextStyle(
                                  color: WessexColors.darkGrape.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Descuentos Mensualidad
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: WessexColors.leafGreen.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: WessexColors.leafGreen.withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_month,
                                          color: WessexColors.leafGreen,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Descuentos en Mensualidad',
                                          style: TextStyle(
                                            color: WessexColors.darkGrape,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _descuentoMensualidad2Controller,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: '2 estudiantes (%)',
                                              hintText: 'Ej: 20',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              filled: true,
                                              fillColor: WessexColors.white,
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Ingresa un valor';
                                              }
                                              final val = int.tryParse(value);
                                              if (val == null) {
                                                return 'Número inválido';
                                              }
                                              if (val < 0 || val > 100) {
                                                return 'Debe estar entre 0 y 100';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _descuentoMensualidad3PlusController,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: '3 o más estudiantes (%)',
                                              hintText: 'Ej: 30',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              filled: true,
                                              fillColor: WessexColors.white,
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Ingresa un valor';
                                              }
                                              final val = int.tryParse(value);
                                              if (val == null) {
                                                return 'Número inválido';
                                              }
                                              if (val < 0 || val > 100) {
                                                return 'Debe estar entre 0 y 100';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Descuentos Matrícula
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: WessexColors.deepRoyalBlue.withOpacity(0.05),
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
                                        Icon(
                                          Icons.school,
                                          color: WessexColors.deepRoyalBlue,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Descuentos en Matrícula',
                                          style: TextStyle(
                                            color: WessexColors.darkGrape,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _descuentoMatricula2Controller,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: '2 estudiantes (%)',
                                              hintText: 'Ej: 20',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              filled: true,
                                              fillColor: WessexColors.white,
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Ingresa un valor';
                                              }
                                              final val = int.tryParse(value);
                                              if (val == null) {
                                                return 'Número inválido';
                                              }
                                              if (val < 0 || val > 100) {
                                                return 'Debe estar entre 0 y 100';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _descuentoMatricula3PlusController,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: '3 o más estudiantes (%)',
                                              hintText: 'Ej: 30',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              filled: true,
                                              fillColor: WessexColors.white,
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Ingresa un valor';
                                              }
                                              final val = int.tryParse(value);
                                              if (val == null) {
                                                return 'Número inválido';
                                              }
                                              if (val < 0 || val > 100) {
                                                return 'Debe estar entre 0 y 100';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Botón guardar
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _guardarConfiguracion,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: WessexColors.leafGreen,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _isSaving
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: WessexColors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              _hasExistingConfig
                                                  ? Icons.update
                                                  : Icons.save,
                                              color: WessexColors.white,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _hasExistingConfig
                                                  ? 'Actualizar Precios'
                                                  : 'Guardar Precios',
                                              style: TextStyle(
                                                color: WessexColors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Información adicional
                      WessexCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: WessexColors.deepRoyalBlue,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Estos precios se aplicarán automáticamente al formulario de vouchers de los apoderados',
                                    style: TextStyle(
                                      color: WessexColors.darkGrape
                                          .withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  color: WessexColors.leafGreen,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Los descuentos se aplican sobre el total según la cantidad de estudiantes a cargo del apoderado',
                                    style: TextStyle(
                                      color: WessexColors.darkGrape
                                          .withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
