import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:wesrugby/data/models/inventory_product_model.dart';
import 'package:wesrugby/data/models/inventory_scan_payload.dart';
import 'package:wesrugby/data/services/inventory_service.dart';

class InventorySimulatorScreen extends StatefulWidget {
  const InventorySimulatorScreen({super.key});

  @override
  State<InventorySimulatorScreen> createState() => _InventorySimulatorScreenState();
}

class _InventorySimulatorScreenState extends State<InventorySimulatorScreen> {
  late Future<List<InventoryProductModel>> _productsFuture;
  bool _downloading = false;
  bool _syncing = false;
  final TextEditingController _variosPriceController = TextEditingController();
  final TextEditingController _variosQuantityController = TextEditingController(text: '1');

  static const Map<String, String> _categoryLabels = {
    'bebida_latas': 'Bebidas (Latas)',
    'pasteleria': 'Pastelería',
    'selladitos': 'Selladitos',
    'cafeteria': 'Cafetería',
    'pastillas': 'Pastillas',
    'papas_fritas_cajita': 'Papas Fritas (Cajita)',
    'bebidas_energeticas': 'Bebidas Energéticas',
    'varios': 'Varios',
  };
  @override
  void initState() {
    super.initState();
    _productsFuture = _loadProducts();
  }

  Future<List<InventoryProductModel>> _loadProducts() async {
    return InventoryService.fetchProducts();
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _productsFuture = _loadProducts();
    });
    await _productsFuture;
  }

  @override
  void dispose() {
    _variosPriceController.dispose();
    _variosQuantityController.dispose();
    super.dispose();
  }

  String _formatPrice(int? priceCents) {
    if (priceCents == null) {
      return 'Variable';
    }
    final pesos = priceCents / 100;
    if (pesos % 1 == 0) {
      return '\$' + pesos.toStringAsFixed(0) + ' CLP';
    }
    return '\$' + pesos.toStringAsFixed(2) + ' CLP';
  }
  Future<void> _downloadSheet({String? category}) async {
    setState(() {
      _downloading = true;
    });
    try {
      final bytes = await InventoryService.downloadBarcodeSheet(
        category: category,
        includeAll: category == null,
      );
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/hoja_barcodes_${timestamp}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hoja de códigos guardada en ' + file.path)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generando PDF: ' + error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
        });
      }
    }
  }
  Future<int?> _requestVariablePrice(BuildContext context, InventoryProductModel product) async {
    final TextEditingController controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Precio para "' + product.name + '"'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Precio en pesos chilenos',
              helperText: 'Se convertirá automáticamente a centavos',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(controller.text.replaceAll(',', '.'));
                if (value == null || value <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Ingresa un precio válido')),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop((value * 100).round());
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
    return result;
  }
  Future<void> _simulateScan(InventoryProductModel product) async {
    if (_syncing) {
      return;
    }

    int? priceCents = product.defaultPriceCents;
    if (product.isVariable) {
      priceCents = await _requestVariablePrice(context, product);
      if (priceCents == null) {
        return;
      }
    } else if (priceCents == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El producto "' + product.name + '" no tiene precio configurado.')),
      );
      return;
    }

    setState(() {
      _syncing = true;
    });

    try {
      final payload = InventoryScanPayload(
        id: const Uuid().v4(),
        barcode: product.barcode,
        scannedAt: DateTime.now(),
        deviceId: 'flutter-simulator',
        priceCents: priceCents,
        quantity: 1,
      );
      final result = await InventoryService.syncScans([payload]);
      if (!mounted) return;
      final accepted = (result['acceptedIds'] as List<dynamic>).cast<String>();
      final rejected = (result['rejected'] as List<dynamic>).cast<Map<String, dynamic>>();
      if (accepted.contains(payload.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lectura registrada para ' + product.name)),
        );
      } else if (rejected.isNotEmpty) {
        final reason = rejected.first['reason'] ?? 'Desconocido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lectura rechazada (' + reason.toString() + ')')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar lectura: ' + error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _syncing = false;
        });
      }
    }
  }
  Future<void> _createVariosSale(InventoryProductModel? varios) async {
    if (varios == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto "Varios" no disponible. Refresca e intenta de nuevo.')),
      );
      return;
    }
    final priceInput = _variosPriceController.text.trim();
    final quantityInput = _variosQuantityController.text.trim();
    final pricePesos = double.tryParse(priceInput.replaceAll(',', '.'));
    final quantity = int.tryParse(quantityInput);
    if (pricePesos == null || pricePesos <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un precio válido para Varios.')),
      );
      return;
    }
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una cantidad válida.')),
      );
      return;
    }

    setState(() {
      _syncing = true;
    });

    try {
      final sale = await InventoryService.createVariosSale(
        priceCents: (pricePesos * 100).round(),
        quantity: quantity,
        deviceId: 'flutter-manual',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Venta registrada (ID: ' + sale.id + ')')),
      );
      _variosPriceController.clear();
      _variosQuantityController.text = '1';
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error registrando venta: ' + error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _syncing = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulador Inventario'),
        actions: [
          IconButton(
            tooltip: 'Descargar hoja completa',
            onPressed: _downloading ? null : () => _downloadSheet(),
            icon: _downloading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: FutureBuilder<List<InventoryProductModel>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error al cargar productos: ' + snapshot.error.toString()),
                  ),
                  TextButton(
                    onPressed: _refreshProducts,
                    child: const Text('Reintentar'),
                  ),
                ],
              );
            }
            final products = snapshot.data ?? <InventoryProductModel>[];
            if (products.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Sin productos configurados.'),
                  ),
                ],
              );
            }

            final Map<String, List<InventoryProductModel>> grouped = {};
            for (final product in products.where((p) => p.active)) {
              if (product.category == 'varios') {
                continue;
              }
              grouped.putIfAbsent(product.category, () => <InventoryProductModel>[]).add(product);
            }

            InventoryProductModel? varios;
            try {
              varios = products.firstWhere((product) => product.category == 'varios');
            } catch (_) {
              varios = null;
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Simula la venta del producto "Varios"',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _variosPriceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Precio (pesos)',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: _variosQuantityController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Cantidad'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: _syncing ? null : () => _createVariosSale(varios),
                            icon: _syncing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.check_circle_outline),
                            label: const Text('Registrar venta'),
                          ),
                        ),
                        if (varios != null)
                          Text('Código actual: ' + varios.barcode),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...grouped.entries.map((entry) {
                  final categoryName = _categoryLabels[entry.key] ?? entry.key;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  categoryName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Descargar hoja de esta categoria',
                                onPressed: _downloading
                                    ? null
                                    : () => _downloadSheet(category: entry.key),
                                icon: const Icon(Icons.download),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...entry.value.map((product) => ListTile(
                                leading: const Icon(Icons.inventory_2_outlined),
                                title: Text(product.name),
                                subtitle: Text(
                                  'Código ${product.barcode}\nPrecio: ${_formatPrice(product.defaultPriceCents)}',
                                ),
                                isThreeLine: true,
                                trailing: ElevatedButton(
                                  onPressed: _syncing ? null : () => _simulateScan(product),
                                  child: const Text('Simular lectura'),
                                ),
                              )),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
