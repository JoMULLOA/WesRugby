import 'dart:convert';
import 'package:universal_html/html.dart' as html;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/models/inventory_product_model.dart';
import 'package:wesrugby/data/models/inventory_sales_summary_model.dart';
import 'package:wesrugby/data/services/inventory_service.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';

const Map<String, String> _categoryLabels = {
  'comestibles': 'Comestibles',
  'otros_productos': 'Otros productos',
  'bebida_latas': 'Bebidas (latas)',
  'pasteleria': 'Pastelería',
  'selladitos': 'Selladitos',
  'cafeteria': 'Cafetería',
  'pastillas': 'Pastillas',
  'papas_fritas_cajita': 'Papas fritas (caja)',
  'bebidas_energeticas': 'Bebidas energéticas',
  'varios': 'Varios',
};

const Map<String, String> _sourceTypeLabels = {
  'compra': 'Compra',
  'donacion': 'Donacion',
};

const Map<String, String> _pricingModeLabels = {
  'fixed': 'Precio fijo',
  'variable': 'Precio variable',
};

const String _allOptionValue = '__all__';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_CL',
    symbol: r'$ ',
    decimalDigits: 0,
  );
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  List<InventoryProductModel> _products = <InventoryProductModel>[];
  List<InventorySalesSummaryModel> _salesSummary = <InventorySalesSummaryModel>[];
  List<dynamic> _eventos = [];

  bool _loadingProducts = false;
  bool _loadingSummary = false;
  bool _loadingEventos = false;
  bool _includeInactive = true;
  String? _productCategoryFilter;
  String? _summaryProductId;
  String? _summaryEventoId;
  DateTime? _summaryFrom;
  DateTime? _summaryTo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _refreshAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadProducts(),
      _loadSalesSummary(),
      _loadEventos(),
    ]);
  }

  Future<void> _loadEventos() async {
    if (mounted) {
      setState(() {
        _loadingEventos = true;
      });
    }
    try {
      final response = await ApiService.obtenerEventosDeportivos();
      final data = response['data'] as List<dynamic>? ?? [];
      
      // Filtrar eventos pasados
      final ahora = DateTime.now();
      final eventosPasados = data.where((evento) {
        final fechaInicio = evento['fechaInicio'];
        if (fechaInicio == null) return false;
        final fecha = DateTime.tryParse(fechaInicio.toString());
        if (fecha == null) return false;
        return fecha.isBefore(ahora);
      }).toList();
      
      if (!mounted) return;
      setState(() {
        _eventos = eventosPasados;
      });
    } catch (error) {
      _showSnackBar('Error al cargar eventos: $error');
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingEventos = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() {
        _loadingProducts = true;
      });
    }
    try {
      final products = await InventoryService.fetchManagementProducts(
        includeInactive: _includeInactive,
      );
      if (!mounted) return;
      setState(() {
        _products = products;
      });
    } catch (error) {
      _showSnackBar('Error al cargar productos: $error');
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingProducts = false;
      });
    }
  }

  Future<void> _loadSalesSummary() async {
    if (mounted) {
      setState(() {
        _loadingSummary = true;
      });
    }
    try {
      final summary = await InventoryService.fetchSalesSummary(
        from: _summaryFrom,
        to: _summaryTo,
        productId: _summaryProductId,
      );
      if (!mounted) return;
      setState(() {
        _salesSummary = summary;
      });
    } catch (error) {
      _showSnackBar('Error al cargar resumen de ventas: $error');
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingSummary = false;
      });
    }
  }

  void _showSnackBar(
    String message, {
    bool success = false,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? WessexColors.leafGreen : WessexColors.alertRed,
      ),
    );
  }

  List<InventoryProductModel> get _visibleProducts {
    final filter = _productCategoryFilter;
    if (filter == null || filter == _allOptionValue) {
      return _products;
    }
    return _products.where((product) => product.category == filter).toList();
  }

  int get _salesTotalAmount {
    return _salesSummary.fold<int>(
      0,
      (acc, item) => acc + item.totalAmountCents,
    );
  }

  int get _salesTotalQuantity {
    return _salesSummary.fold<int>(
      0,
      (acc, item) => acc + item.totalQuantity,
    );
  }

  Future<void> _toggleIncludeInactive(bool value) async {
    if (!mounted) return;
    setState(() {
      _includeInactive = value;
    });
    await _loadProducts();
  }

  Future<void> _pickSummaryDateRange() async {
    final now = DateTime.now();
    final initialRange =
        _summaryFrom != null && _summaryTo != null
            ? DateTimeRange(start: _summaryFrom!, end: _summaryTo!)
            : DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: now,
            );

    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (BuildContext context) {
        DateTime? tempStart;
        DateTime? tempEnd;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              child: Container(
                width: 360,
                constraints: const BoxConstraints(maxHeight: 520),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Rango de fechas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (tempStart != null || tempEnd != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tempStart != null ? _dateFormat.format(tempStart!) : '--',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.arrow_forward, size: 16),
                            ),
                            Text(
                              tempEnd != null ? _dateFormat.format(tempEnd!) : '--',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Flexible(
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          datePickerTheme: DatePickerThemeData(
                            headerBackgroundColor: WessexColors.deepRoyalBlue,
                            headerForegroundColor: Colors.white,
                            dayStyle: const TextStyle(fontSize: 12),
                            yearStyle: const TextStyle(fontSize: 13),
                          ),
                        ),
                        child: CalendarDatePicker(
                          initialDate: tempStart ?? initialRange.start,
                          firstDate: DateTime(now.year - 2),
                          lastDate: DateTime(now.year + 1),
                          onDateChanged: (date) {
                            setDialogState(() {
                              if (tempStart == null || (tempEnd != null)) {
                                // Iniciar nuevo rango
                                tempStart = date;
                                tempEnd = null;
                              } else {
                                // Completar rango
                                if (date.isBefore(tempStart!)) {
                                  tempEnd = tempStart;
                                  tempStart = date;
                                } else {
                                  tempEnd = date;
                                }
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Selecciona fecha inicio y fecha fin',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              tempStart = null;
                              tempEnd = null;
                            });
                          },
                          child: const Text('Limpiar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed:
                              tempStart != null && tempEnd != null
                                  ? () {
                                    Navigator.of(context).pop(
                                      DateTimeRange(start: tempStart!, end: tempEnd!),
                                    );
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WessexColors.deepRoyalBlue,
                          ),
                          child: const Text('Aplicar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _summaryFrom = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        );
        _summaryTo = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
          999,
        );
      });
      await _loadSalesSummary();
    }
  }

  Future<void> _clearSummaryFilters() async {
    if (!mounted) return;
    setState(() {
      _summaryFrom = null;
      _summaryTo = null;
      _summaryProductId = null;
      _summaryEventoId = null;
    });
    await _loadSalesSummary();
  }

  Future<void> _handleReissueBarcode(InventoryProductModel product) async {
    try {
      final barcode = await InventoryService.reissueProductBarcode(product.id);
      if (!mounted) return;
      setState(() {
        _products = _products
            .map(
              (item) => item.id == product.id ? item.copyWith(barcode: barcode) : item,
            )
            .toList();
      });
      _showSnackBar('Codigo regenerado correctamente', success: true);
    } catch (error) {
      _showSnackBar('No se pudo regenerar el codigo: $error');
    }
  }

  Future<void> _downloadSheetForSelection() async {
    try {
      await InventoryService.openBarcodeSheetInBrowser(
        category: _productCategoryFilter == _allOptionValue ? null : _productCategoryFilter,
      );
    } catch (error) {
      _showSnackBar('No se pudo abrir la hoja de codigos: $error');
    }
  }

  Future<void> _downloadSheetForProductId(String productId) async {
    try {
      await InventoryService.openBarcodeSheetInBrowser(productId: productId);
    } catch (error) {
      _showSnackBar('No se pudo abrir la hoja del producto: $error');
    }
  }

  Future<void> _downloadSalesReport() async {
    try {
      // Generar nombre del archivo con fecha
      final now = DateTime.now();
      final fileName = 'reporte_ventas_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}.csv';
      
      // Crear contenido CSV
      final buffer = StringBuffer();
      buffer.writeln('Producto,Categoria,Ventas,Unidades,Total (CLP),Ultima Venta,Codigo');
      
      for (final item in _salesSummary) {
        buffer.writeln(
          '"${item.productName}","${_categoryLabel(item.category)}",${item.totalSales},${item.totalQuantity},'
          '${item.totalAmountCents},"${item.lastSaleAt != null ? _dateFormat.format(item.lastSaleAt!) : 'N/A'}","${item.barcode}"',
        );
      }
      
      // Agregar totales
      buffer.writeln('');
      buffer.writeln('TOTALES');
      buffer.writeln('Total Ventas,${_salesSummary.length}');
      buffer.writeln('Total Unidades,${_salesTotalQuantity}');
      buffer.writeln('Total Monto,${_salesTotalAmount}');
      
      if (_summaryFrom != null && _summaryTo != null) {
        buffer.writeln('');
        buffer.writeln('FILTROS APLICADOS');
        buffer.writeln('Desde,${_dateFormat.format(_summaryFrom!)}');
        buffer.writeln('Hasta,${_dateFormat.format(_summaryTo!)}');
      }
      
      // Descargar archivo
      final bytes = utf8.encode(buffer.toString());
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
      
      _showSnackBar('Reporte descargado: $fileName', success: true);
    } catch (error) {
      _showSnackBar('Error al descargar reporte: $error');
    }
  }

  void _showSalesChart() {
    if (_salesSummary.isEmpty) {
      _showSnackBar('No hay datos para mostrar en el grafico');
      return;
    }
    
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grafico de Ventas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Grafico de barras simple
                          Container(
                            height: 400,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: WessexColors.lightGray.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ventas por Producto (Top 10)',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: _buildSimpleBarChart(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Estadisticas adicionales
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _buildStatCard(
                                'Total Ventas',
                                _salesSummary.length.toString(),
                                Icons.receipt_long,
                                WessexColors.deepRoyalBlue,
                              ),
                              _buildStatCard(
                                'Unidades Vendidas',
                                _salesTotalQuantity.toString(),
                                Icons.shopping_basket,
                                WessexColors.leafGreen,
                              ),
                              _buildStatCard(
                                'Ingresos Totales',
                                _formatPesos(_salesTotalAmount),
                                Icons.attach_money,
                                WessexColors.darkGrape,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSimpleBarChart() {
    final topProducts = _salesSummary.take(10).toList();
    final maxValue = topProducts.isEmpty
        ? 1.0
        : topProducts.map((e) => e.totalAmountCents).reduce((a, b) => a > b ? a : b).toDouble();

    return ListView.builder(
      itemCount: topProducts.length,
      itemBuilder: (context, index) {
        final product = topProducts[index];
        final percentage = (product.totalAmountCents / maxValue);
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      product.productName,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 7,
                    child: Stack(
                      children: [
                        Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: WessexColors.maximumGrayMint.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percentage,
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  WessexColors.leafGreen,
                                  WessexColors.deepRoyalBlue,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: Text(
                      _formatPesos(product.totalAmountCents),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(InventoryProductModel product) async {
    if (product.category == 'varios') {
      _showSnackBar('El producto Varios no puede eliminarse');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Desactivar producto'),
            content: Text(
              'Se desactivara el producto "${product.name}". '
              'Puedes activarlo nuevamente desde esta pantalla. Continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Desactivar'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    try {
      await InventoryService.deleteProduct(product.id);
      await _loadProducts();
      await _loadSalesSummary();
      _showSnackBar('Producto desactivado correctamente', success: true);
    } catch (error) {
      _showSnackBar('No se pudo desactivar el producto: $error');
    }
  }

  Future<void> _toggleProductActive(InventoryProductModel product) async {
    if (product.category == 'varios') {
      _showSnackBar('El producto Varios no puede modificarse');
      return;
    }
    
    final newStatus = !product.active;
    final action = newStatus ? 'activar' : 'desactivar';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('${action.substring(0, 1).toUpperCase()}${action.substring(1)} producto'),
            content: Text(
              '¿Deseas $action el producto "${product.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: newStatus ? WessexColors.leafGreen : WessexColors.maximumGrayMint,
                ),
                child: Text(action.substring(0, 1).toUpperCase() + action.substring(1)),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    try {
      final payload = {
        'id': product.id,
        'name': product.name,
        'category': product.category,
        'sourceType': product.sourceType,
        'pricingMode': product.pricingMode,
        'defaultPriceCents': product.defaultPriceCents,
        'active': newStatus,
      };
      await InventoryService.saveProduct(payload);
      await _loadProducts();
      _showSnackBar('Producto ${newStatus ? "activado" : "desactivado"} correctamente', success: true);
    } catch (error) {
      _showSnackBar('No se pudo $action el producto: $error');
    }
  }

  Future<void> _confirmDeletePermanent(InventoryProductModel product) async {
    if (product.category == 'varios') {
      _showSnackBar('El producto Varios no puede eliminarse');
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar producto permanentemente'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Estas seguro de que deseas eliminar permanentemente el producto "${product.name}"?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: WessexColors.crimsonAlert.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: WessexColors.crimsonAlert.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: WessexColors.crimsonAlert, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Esta accion no se puede deshacer. Se eliminaran todos los registros asociados.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WessexColors.crimsonAlert,
                ),
                child: const Text('Eliminar permanentemente'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    try {
      await InventoryService.deleteProductPermanently(product.id);
      _showSnackBar('Producto eliminado permanentemente', success: true);
      await _loadProducts();
    } catch (error) {
      _showSnackBar('No se pudo eliminar el producto: $error');
    }
  }

  Future<void> _showProductDialog({InventoryProductModel? product}) async {
    if (!mounted) return;
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(
      text:
          product?.defaultPriceCents != null
              ? _formatPriceInput(product!.defaultPriceCents!)
              : '',
    );
    String category = product?.category ?? _categoryLabels.keys.first;
    String sourceType = product?.sourceType ?? _sourceTypeLabels.keys.first;
    String pricingMode = product?.pricingMode ?? 'fixed';
    bool active = product?.active ?? true;
    bool saving = false;

    final formKey = GlobalKey<FormState>();

    bool? result;
    try {
      result = await showDialog<bool>(
        context: context,
        builder:
            (context) => StatefulBuilder(
              builder: (context, setModalState) {
                final isVarios = category == 'varios';
                return AlertDialog(
                  title: Text(
                    product == null ? 'Nuevo producto' : 'Editar producto',
                  ),
                  content: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              hintText: 'Ej: Coca Cola Lata 350ml',
                            ),
                            maxLength: 200,
                            validator:
                                (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Ingresa un nombre valido'
                                        : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: category,
                            decoration: const InputDecoration(labelText: 'Categoria'),
                            items: _categoryLabels.entries
                                .map(
                                  (entry) => DropdownMenuItem<String>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                                )
                                .toList(),
                            onChanged:
                                (value) => setModalState(() {
                                  if (value == null) return;
                                  category = value;
                                  if (category == 'varios') {
                                    pricingMode = 'variable';
                                    priceController.text = '';
                                  }
                                }),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: sourceType,
                            decoration: const InputDecoration(labelText: 'Origen'),
                            items: _sourceTypeLabels.entries
                                .map(
                                  (entry) => DropdownMenuItem<String>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                                )
                                .toList(),
                            onChanged:
                                (value) => setModalState(() {
                                  if (value != null) {
                                    sourceType = value;
                                  }
                                }),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: pricingMode,
                            decoration: const InputDecoration(labelText: 'Modo de precio'),
                            items: _pricingModeLabels.entries
                                .map(
                                  (entry) => DropdownMenuItem<String>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                                )
                                .toList(),
                            onChanged:
                                isVarios
                                    ? null
                                    : (value) => setModalState(() {
                                      if (value != null) {
                                        pricingMode = value;
                                      }
                                    }),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              signed: false,
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Precio base',
                              helperText: 'Ingresa el valor en pesos chilenos',
                              prefixText: r'CLP $ ',
                            ),
                            enabled: pricingMode == 'fixed',
                            validator: (value) {
                              if (pricingMode == 'variable') {
                                return null;
                              }
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa un precio';
                              }
                              final parsed = double.tryParse(
                                value.replaceAll(',', '.'),
                              );
                              if (parsed == null || parsed <= 0) {
                                return 'Precio invalido';
                              }
                              return null;
                            },
                          ),
                          if (product != null) ...[
                            const SizedBox(height: 12),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Producto activo'),
                              value: active,
                              onChanged:
                                  (value) => setModalState(() {
                                    active = value;
                                  }),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              final name = nameController.text.trim();
                              final payload = <String, dynamic>{
                                'name': name,
                                'category': category,
                                'sourceType': sourceType,
                                'pricingMode': pricingMode,
                                'active': active,
                              };
                              if (product != null) {
                                payload['id'] = product.id;
                              }
                              if (pricingMode == 'fixed') {
                                final parsed = double.parse(
                                  priceController.text.replaceAll(',', '.'),
                                );
                                payload['defaultPriceCents'] = parsed.round();
                              } else {
                                payload['defaultPriceCents'] = null;
                              }
                              setModalState(() {
                                saving = true;
                              });
                              try {
                                await InventoryService.saveProduct(payload);
                                if (!mounted) return;
                                Navigator.pop(context, true);
                              } catch (error) {
                                setModalState(() {
                                  saving = false;
                                });
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('No se pudo guardar: $error'),
                                    backgroundColor: WessexColors.alertRed,
                                  ),
                                );
                              }
                            },
                      icon:
                          saving
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                              : const Icon(Icons.save),
                      label: const Text('Guardar'),
                    ),
                  ],
                );
              },
            ),
      );
    } finally {
      nameController.dispose();
      priceController.dispose();
    }

    if (result == true) {
      await _loadProducts();
      await _loadSalesSummary();
      _showSnackBar('Producto guardado correctamente', success: true);
    }
  }

  String _categoryLabel(String value) {
    return _categoryLabels[value] ?? value;
  }

  String _sourceLabel(String value) {
    return _sourceTypeLabels[value] ?? value;
  }

  String _pricingLabel(String value) {
    return _pricingModeLabels[value] ?? value;
  }

  String _formatPrice(int? priceCents) {
    if (priceCents == null) {
      return 'Variable';
    }
    return _formatPesos(priceCents);
  }

  String _formatPriceInput(int priceCents) {
    return priceCents.toString();
  }

  String _formatPesos(num value) {
    return _currencyFormat.format(value);
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }
    return _dateFormat.format(value.toLocal());
  }

  Widget _buildEventoSelector() {
    final TextEditingController searchController = TextEditingController();
    
    return StatefulBuilder(
      builder: (context, setStateLocal) {
        String searchQuery = searchController.text.toLowerCase();
        
        // Filtrar eventos por búsqueda
        final eventosFiltrados = _eventos.where((evento) {
          final titulo = (evento['titulo'] ?? evento['nombre'] ?? '').toString().toLowerCase();
          return titulo.contains(searchQuery);
        }).toList();
        
        // Limitar a 8 eventos
        final eventosLimitados = eventosFiltrados.take(8).toList();
        
        return PopupMenuButton<String>(
          offset: const Offset(0, 50),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Filtrar por evento',
              prefixIcon: Icon(Icons.event),
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              _summaryEventoId == null
                  ? 'Todos los eventos'
                  : _eventos.firstWhere(
                      (e) => e['id'].toString() == _summaryEventoId,
                      orElse: () => {'titulo': 'Evento seleccionado'},
                    )['titulo'] ?? 'Evento seleccionado',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          itemBuilder: (context) {
            return [
              PopupMenuItem<String>(
                enabled: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar evento...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setStateLocal(() {});
                    },
                  ),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: _allOptionValue,
                child: Row(
                  children: const [
                    Icon(Icons.clear_all, size: 18),
                    SizedBox(width: 8),
                    Text('Todos los eventos'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              if (eventosLimitados.isEmpty)
                const PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    'No se encontraron eventos',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                )
              else
                ...eventosLimitados.map((evento) {
                  final titulo = evento['titulo'] ?? evento['nombre'] ?? 'Evento sin título';
                  final fecha = evento['fechaInicio'] != null
                      ? DateTime.tryParse(evento['fechaInicio'].toString())
                      : null;
                  final fechaStr = fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : '';
                  
                  return PopupMenuItem<String>(
                    value: evento['id'].toString(),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 350),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            titulo,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (fechaStr.isNotEmpty)
                            Text(
                              fechaStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: WessexColors.midnightNavy.withOpacity(0.6),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              if (eventosFiltrados.length > 8)
                const PopupMenuItem<String>(
                  enabled: false,
                  child: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Usa la búsqueda para ver más eventos',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ];
          },
          onSelected: (value) async {
            if (!mounted) return;
            setState(() {
              _summaryEventoId = value == _allOptionValue ? null : value;
            });
            await _loadSalesSummary();
          },
        );
      },
    );
  }

  Widget _buildSummaryTab() {
    if (_loadingSummary) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WessexCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtros de ventas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: _buildEventoSelector(),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: DropdownButtonFormField<String>(
                        value: _summaryProductId ?? _allOptionValue,
                        decoration: const InputDecoration(
                          labelText: 'Producto',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: _allOptionValue,
                            child: Text('Todos los productos'),
                          ),
                          ..._products.map(
                            (product) => DropdownMenuItem<String>(
                              value: product.id,
                              child: Text(product.name),
                            ),
                          ),
                        ],
                        onChanged: (value) async {
                          if (!mounted) return;
                          setState(() {
                            _summaryProductId =
                                value == null || value == _allOptionValue ? null : value;
                          });
                          await _loadSalesSummary();
                        },
                      ),
                    ),
                    TextButton(
                      onPressed: _clearSummaryFilters,
                      child: const Text('Limpiar filtros'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _downloadSalesReport,
                      icon: const Icon(Icons.download),
                      label: const Text('Descargar reporte'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WessexColors.leafGreen,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showSalesChart,
                      icon: const Icon(Icons.bar_chart),
                      label: const Text('Ver grafico'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WessexColors.deepRoyalBlue,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Actualizar',
                      onPressed: _loadSalesSummary,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _SummaryStatCard(
                title: 'Ventas registradas',
                value: _salesSummary.length.toString(),
                icon: Icons.receipt_long,
              ),
              _SummaryStatCard(
                title: 'Unidades vendidas',
                value: _salesTotalQuantity.toString(),
                icon: Icons.shopping_basket,
              ),
              _SummaryStatCard(
                title: 'Monto total',
                value: _formatPesos(_salesTotalAmount),
                icon: Icons.attach_money,
              ),
            ],
          ),
          const SizedBox(height: 16),
          WessexCard(
            child:
                _salesSummary.isEmpty
                    ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.info_outline, size: 48, color: WessexColors.maximumGrayMint),
                        SizedBox(height: 12),
                        Text(
                          'No hay ventas registradas para los filtros seleccionados.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                    : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        headingRowColor: MaterialStateProperty.all(
                          WessexColors.midnightNavy.withOpacity(0.08),
                        ),
                        columns: const [
                          DataColumn(label: Text('Producto')),
                          DataColumn(label: Text('Categoria')),
                          DataColumn(label: Text('Ventas')),
                          DataColumn(label: Text('Unidades')),
                          DataColumn(label: Text('Total')),
                          DataColumn(label: Text('Ultima venta')),
                          DataColumn(label: Text('Codigo de barras')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: _salesSummary
                            .map(
                              (item) => DataRow(
                                cells: [
                                  DataCell(Text(item.productName)),
                                  DataCell(Text(_categoryLabel(item.category))),
                                  DataCell(Text(item.totalSales.toString())),
                                  DataCell(Text(item.totalQuantity.toString())),
                                  DataCell(Text(_formatPesos(item.totalAmountCents))),
                                  DataCell(Text(_formatDate(item.lastSaleAt))),
                                  DataCell(Text(item.barcode)),
                                  DataCell(
                                    IconButton(
                                      tooltip: 'Descargar etiqueta',
                                      icon: const Icon(Icons.download),
                                      onPressed: () => _downloadSheetForProductId(item.productId),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_loadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }
    final products = _visibleProducts;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WessexCard(
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: DropdownButtonFormField<String>(
                    value: _productCategoryFilter ?? _allOptionValue,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: _allOptionValue,
                        child: Text('Todas las categorias'),
                      ),
                      ..._categoryLabels.entries.map(
                        (entry) => DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (!mounted) return;
                      setState(() {
                        _productCategoryFilter =
                            value == null || value == _allOptionValue ? null : value;
                      });
                    },
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Mostrar inactivos'),
                    Switch(
                      value: _includeInactive,
                      onChanged: (value) => _toggleIncludeInactive(value),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _downloadSheetForSelection,
                  icon: const Icon(Icons.print),
                  label: const Text('Descargar codigos'),
                ),
                IconButton(
                  tooltip: 'Actualizar',
                  onPressed: _loadProducts,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          WessexCard(
            child:
                products.isEmpty
                    ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: WessexColors.maximumGrayMint,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No hay productos para mostrar con los filtros seleccionados.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                    : LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: DataTable(
                              columnSpacing: 12,
                              horizontalMargin: 12,
                              headingRowColor: MaterialStateProperty.all(
                                WessexColors.midnightNavy.withOpacity(0.08),
                              ),
                              dataRowHeight: 56,
                              columns: const [
                          DataColumn(label: Text('Producto')),
                          DataColumn(label: Text('Categoria')),
                          DataColumn(label: Text('Origen')),
                          DataColumn(label: Text('Modo')),
                          DataColumn(label: Text('Precio base')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Codigo de barras')),
                          DataColumn(
                            label: Center(
                              child: Text('Acciones'),
                            ),
                          ),
                        ],
                              rows: products
                            .map(
                              (product) => DataRow(
                                cells: [
                                  DataCell(Text(product.name)),
                                  DataCell(Text(_categoryLabel(product.category))),
                                  DataCell(Text(_sourceLabel(product.sourceType))),
                                  DataCell(Text(_pricingLabel(product.pricingMode))),
                                  DataCell(Text(_formatPrice(product.defaultPriceCents))),
                                  DataCell(
                                    Chip(
                                      label: Text(product.active ? 'Activo' : 'Inactivo'),
                                      backgroundColor: product.active
                                          ? WessexColors.leafGreen.withOpacity(0.15)
                                          : WessexColors.maximumGrayMint.withOpacity(0.2),
                                    ),
                                  ),
                                  DataCell(Text(product.barcode)),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Editar',
                                          icon: const Icon(Icons.edit, size: 18),
                                          padding: EdgeInsets.all(4),
                                          constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                                          onPressed: () => _showProductDialog(product: product),
                                        ),
                                        IconButton(
                                          tooltip: 'Regenerar codigo',
                                          icon: const Icon(Icons.qr_code, size: 18),
                                          padding: EdgeInsets.all(4),
                                          constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                                          onPressed: () => _handleReissueBarcode(product),
                                        ),
                                        IconButton(
                                          tooltip: 'Descargar etiqueta',
                                          icon: const Icon(Icons.download, size: 18),
                                          padding: EdgeInsets.all(4),
                                          constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                                          onPressed: () => _downloadSheetForProductId(product.id),
                                        ),
                                        IconButton(
                                          tooltip: product.active ? 'Desactivar' : 'Activar',
                                          padding: EdgeInsets.all(4),
                                          constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                                          icon: Icon(
                                            product.active ? Icons.toggle_on : Icons.toggle_off,
                                            size: 18,
                                            color: product.active
                                                ? WessexColors.leafGreen
                                                : WessexColors.maximumGrayMint,
                                          ),
                                          onPressed:
                                              product.category == 'varios'
                                                  ? null
                                                  : () => _toggleProductActive(product),
                                        ),
                                        IconButton(
                                          tooltip: 'Eliminar permanentemente',
                                          padding: EdgeInsets.all(4),
                                          constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                                          icon: const Icon(
                                            Icons.delete_forever, 
                                            size: 18,
                                            color: WessexColors.crimsonAlert,
                                          ),
                                          onPressed:
                                              product.category == 'varios'
                                                  ? null
                                                  : () => _confirmDeletePermanent(product),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WessexAppBar(
        title: 'Gestion de inventario',
        automaticallyImplyLeading: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: WessexColors.white,
          unselectedLabelColor: WessexColors.white.withOpacity(0.6),
          indicatorColor: WessexColors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Ventas'),
            Tab(icon: Icon(Icons.store), text: 'Productos'),
          ],
        ),
      ),
      body: WessexBackground(
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSummaryTab(),
              _buildProductsTab(),
            ],
          ),
        ),
      ),
      floatingActionButton:
          _tabController.index == 1
              ? FloatingActionButton.extended(
                onPressed: () => _showProductDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo producto'),
              )
              : null,
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return WessexCard(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WessexColors.midnightNavy.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: WessexColors.midnightNavy),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: WessexColors.midnightNavy.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
