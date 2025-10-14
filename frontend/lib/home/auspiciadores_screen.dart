import 'package:flutter/material.dart';
import '../widgets/wessex_widgets.dart';
import '../config/colors.dart';

class AuspiciadoresScreen extends StatelessWidget {
  const AuspiciadoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: WessexAppBar(
        title: 'Auspiciadores',
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
                          color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.handshake,
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
                              'Nuestros Auspiciadores',
                              style: TextStyle(
                                color: WessexColors.darkGrape,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Empresas que apoyan al rugby chileno',
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

                // Categorías de auspiciadores
                _buildSponsorCategory(
                  'Auspiciador Principal',
                  'Principal',
                  [
                    SponsorInfo(
                      'Empresa Principal S.A.',
                      'Construcción y Desarrollo',
                      Icons.business,
                      WessexColors.crimsonAlert,
                    ),
                  ],
                  isTablet,
                  isDesktop,
                ),

                const SizedBox(height: 24),

                _buildSponsorCategory(
                  'Auspiciadores Oficiales',
                  'Oficiales',
                  [
                    SponsorInfo(
                      'Banco de Chile',
                      'Servicios Financieros',
                      Icons.account_balance,
                      WessexColors.deepRoyalBlue,
                    ),
                    SponsorInfo(
                      'Empresa Deportiva',
                      'Equipamiento Deportivo',
                      Icons.sports,
                      WessexColors.leafGreen,
                    ),
                    SponsorInfo(
                      'Clínica Deportiva',
                      'Salud y Bienestar',
                      Icons.local_hospital,
                      WessexColors.crimsonAlert,
                    ),
                  ],
                  isTablet,
                  isDesktop,
                ),

                const SizedBox(height: 24),

                _buildSponsorCategory(
                  'Colaboradores',
                  'Colaboradores',
                  [
                    SponsorInfo(
                      'Restaurant Local',
                      'Gastronomía',
                      Icons.restaurant,
                      WessexColors.darkGrape,
                    ),
                    SponsorInfo(
                      'Transporte Rugby',
                      'Transporte y Logística',
                      Icons.directions_bus,
                      WessexColors.leafGreen,
                    ),
                  ],
                  isTablet,
                  isDesktop,
                ),

                const SizedBox(height: 24),

                // Llamada a ser auspiciador
                WessexCard(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: WessexColors.crimsonAlert,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '¿Quieres ser nuestro auspiciador?',
                          style: TextStyle(
                            color: WessexColors.darkGrape,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Únete a nuestra familia de empresas que apoyan el desarrollo del rugby en Chile.',
                          style: TextStyle(
                            color: WessexColors.darkGrape.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _contactarAuspicio(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: WessexColors.deepRoyalBlue,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.email, color: Colors.white),
                              label: const Text(
                                'Contactar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () => _verBeneficios(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: WessexColors.deepRoyalBlue,
                                side: BorderSide(color: WessexColors.deepRoyalBlue),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.info_outline),
                              label: const Text(
                                'Beneficios',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
      ),
    );
  }

  Widget _buildSponsorCategory(
    String titulo,
    String categoria,
    List<SponsorInfo> sponsors,
    bool isTablet,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            color: WessexColors.darkGrape,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 3 : (isTablet ? 2 : 1),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.3,
          ),
          itemCount: sponsors.length,
          itemBuilder: (context, index) {
            final sponsor = sponsors[index];
            return _buildSponsorCard(sponsor);
          },
        ),
      ],
    );
  }

  Widget _buildSponsorCard(SponsorInfo sponsor) {
    return WessexCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sponsor.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              sponsor.icon,
              color: sponsor.color,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            sponsor.nombre,
            style: TextStyle(
              color: WessexColors.darkGrape,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            sponsor.sector,
            style: TextStyle(
              color: WessexColors.darkGrape.withOpacity(0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _contactarAuspicio(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.email,
              color: WessexColors.deepRoyalBlue,
            ),
            const SizedBox(width: 12),
            Text(
              'Contacto Auspicios',
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
              'Para información sobre auspicios y patrocinios:',
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
                  '+56 9 8765 4321',
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
                  'auspicios@wessexrugby.cl',
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

  void _verBeneficios(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.star,
              color: WessexColors.leafGreen,
            ),
            const SizedBox(width: 12),
            Text(
              'Beneficios de Auspiciar',
              style: TextStyle(
                color: WessexColors.darkGrape,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBeneficio('Visibilidad en eventos deportivos'),
              _buildBeneficio('Logo en camisetas oficiales'),
              _buildBeneficio('Presencia en redes sociales'),
              _buildBeneficio('Networking con la comunidad rugby'),
              _buildBeneficio('Responsabilidad social empresarial'),
              _buildBeneficio('Acceso a eventos exclusivos del club'),
            ],
          ),
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

  Widget _buildBeneficio(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: WessexColors.leafGreen,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: WessexColors.darkGrape,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SponsorInfo {
  final String nombre;
  final String sector;
  final IconData icon;
  final Color color;

  SponsorInfo(this.nombre, this.sector, this.icon, this.color);
}