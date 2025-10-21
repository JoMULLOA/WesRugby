import 'package:flutter/material.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/data/models/merchandising_model.dart';

class MerchandisingScreen extends StatefulWidget {
  const MerchandisingScreen({super.key});

  @override
  State<MerchandisingScreen> createState() => _MerchandisingScreenState();
}

class _MerchandisingScreenState extends State<MerchandisingScreen> {
  List<MerchandisingModel> _productos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  Future<void> _loadProductos() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/merchandising/publico');
      if (response.success && response.data != null) {
        // El backend devuelve {success: true, message: "...", data: [...]}
        final List<dynamic> productosData =
            response.data is Map
                ? (response.data['data'] as List? ?? [])
                : (response.data is List ? response.data as List : []);

        setState(() {
          _productos =
              productosData
                  .map((json) => MerchandisingModel.fromJson(json))
                  .toList();
        });
      }
    } catch (e) {
      print('Error al cargar productos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: WessexAppBar(
        title: 'Tienda del Club',
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WessexColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: WessexBackground(
        child: SafeArea(
          child:
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: WessexColors.white),
                  )
                  : _productos.isEmpty
                  ? _buildEmptyState()
                  : _buildProductosList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: WessexCard(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_bag, size: 64, color: WessexColors.ashGray),
              const SizedBox(height: 16),
              const Text(
                'No hay productos disponibles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: WessexColors.charcoalGray,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pronto tendremos merchandising del club',
                style: TextStyle(fontSize: 14, color: WessexColors.ashGray),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductosList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  child: const Icon(
                    Icons.shopping_bag,
                    color: WessexColors.deepRoyalBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tienda del Wessex Rugby',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: WessexColors.deepNavyBlue,
                        ),
                      ),
                      Text(
                        'Lleva la camiseta del club y apoya al equipo',
                        style: TextStyle(
                          fontSize: 14,
                          color: WessexColors.charcoalGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _productos.length,
            itemBuilder: (context, index) {
              return _buildProductoCard(_productos[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductoCard(MerchandisingModel producto) {
    return WessexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del producto
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: WessexColors.lightGray,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child:
                  producto.imagen.isNotEmpty
                      ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          producto.imagen,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                child: const Icon(
                                  Icons.shopping_bag,
                                  color: WessexColors.ashGray,
                                  size: 48,
                                ),
                              ),
                        ),
                      )
                      : const Icon(
                        Icons.shopping_bag,
                        color: WessexColors.ashGray,
                        size: 48,
                      ),
            ),
          ),

          // Información del producto
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: WessexColors.deepNavyBlue,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (producto.descripcion != null)
                    Text(
                      producto.descripcion!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: WessexColors.charcoalGray,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const Spacer(),
                  Text(
                    '\$${producto.precio.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: WessexColors.deepRoyalBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
