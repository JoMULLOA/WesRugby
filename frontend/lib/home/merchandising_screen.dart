import 'package:flutter/material.dart';
import '../widgets/wessex_widgets.dart';
import '../config/colors.dart';

class MerchandisingScreen extends StatelessWidget {
  const MerchandisingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: WessexAppBar(
        title: 'Merchandising',
        elevation: 2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: WessexColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: WessexBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
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
                          Icons.shopping_bag,
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
                              'Tienda Oficial',
                              style: TextStyle(
                                color: WessexColors.darkGrape,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Productos exclusivos del Wessex Rugby Club',
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

                // Categorías de productos
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isDesktop ? 3 : (isTablet ? 2 : 1),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildProductCategory(
                      'Camisetas',
                      'Camisetas oficiales del club',
                      Icons.checkroom,
                      WessexColors.deepRoyalBlue,
                      '\$25.000',
                    ),
                    _buildProductCategory(
                      'Shorts',
                      'Shorts de entrenamiento',
                      Icons.sports,
                      WessexColors.crimsonAlert,
                      '\$18.000',
                    ),
                    _buildProductCategory(
                      'Accesorios',
                      'Gorras, bufandas y más',
                      Icons.shopping_cart,
                      WessexColors.leafGreen,
                      '\$12.000',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Coming soon
                WessexCard(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.store,
                          color: WessexColors.leafGreen,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tienda Online Próximamente',
                          style: TextStyle(
                            color: WessexColors.darkGrape,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Estamos trabajando en nuestra tienda online. Mientras tanto, puedes contactarnos para hacer pedidos.',
                          style: TextStyle(
                            color: WessexColors.darkGrape.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _contactarVentas(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WessexColors.leafGreen,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.phone, color: Colors.white),
                          label: const Text(
                            'Contactar Ventas',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCategory(
    String nombre,
    String descripcion,
    IconData icon,
    Color color,
    String precio,
  ) {
    return WessexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nombre,
            style: TextStyle(
              color: WessexColors.darkGrape,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            descripcion,
            style: TextStyle(
              color: WessexColors.darkGrape.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Desde $precio',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _contactarVentas(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.contact_phone,
              color: WessexColors.leafGreen,
            ),
            const SizedBox(width: 12),
            Text(
              'Contacto Ventas',
              style: TextStyle(
                color: WessexColors.darkGrape,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para realizar pedidos, contacta con nosotros:',
              style: TextStyle(
                color: WessexColors.darkGrape.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.phone, color: WessexColors.deepRoyalBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  '+56 9 1234 5678',
                  style: TextStyle(
                    color: WessexColors.darkGrape,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.email, color: WessexColors.deepRoyalBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'ventas@wessexrugby.cl',
                  style: TextStyle(
                    color: WessexColors.darkGrape,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: TextStyle(
                color: WessexColors.deepRoyalBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}