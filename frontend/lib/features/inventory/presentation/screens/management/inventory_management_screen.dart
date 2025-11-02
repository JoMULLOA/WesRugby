import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/models/inventory_product_model.dart';
import 'package:wesrugby/data/models/inventory_sales_summary_model.dart';
import 'package:wesrugby/data/services/inventory_service.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/shared/widgets/navigation/custom_drawer.dart';

const Map<String, String> _categoryLabels = {
  'bebida_latas': 'Bebidas (latas)',
  'pasteleria': 'Pasteleria',
  'selladitos': 'Selladitos',
  'cafeteria': 'Cafeteria',
  'pastillas': 'Pastillas',
  'papas_fritas_cajita': 'Papas fritas (caja)',
  'bebidas_energeticas': 'Bebidas energeticas',
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

  bool _loadingProducts = false;
  bool _loadingSummary = false;
  bool _includeInactive = true;
  String? _productCategoryFilter;
  String? _summaryProductId;
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
    ]);
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

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initialRange,
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
                    OutlinedButton.icon(
                      onPressed: _pickSummaryDateRange,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _summaryFrom == null || _summaryTo == null
                            ? 'Rango de fechas'
                            : '${_dateFormat.format(_summaryFrom!)} - ${_dateFormat.format(_summaryTo!)}',
                      ),
                    ),
                    SizedBox(
                      width: 260,
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
                SizedBox(
                  width: 260,
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
                          DataColumn(label: Text('Origen')),
                          DataColumn(label: Text('Modo')),
                          DataColumn(label: Text('Precio base')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Codigo de barras')),
                          DataColumn(label: Text('Acciones')),
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
                                          icon: const Icon(Icons.edit),
                                          onPressed: () => _showProductDialog(product: product),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          tooltip: 'Regenerar codigo',
                                          icon: const Icon(Icons.qr_code),
                                          onPressed: () => _handleReissueBarcode(product),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          tooltip: 'Descargar etiqueta',
                                          icon: const Icon(Icons.download),
                                          onPressed: () => _downloadSheetForProductId(product.id),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          tooltip: 'Desactivar',
                                          icon: const Icon(Icons.delete_outline),
                                          onPressed:
                                              product.category == 'varios'
                                                  ? null
                                                  : () => _confirmDelete(product),
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
      drawer: const CustomDrawer(),
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
