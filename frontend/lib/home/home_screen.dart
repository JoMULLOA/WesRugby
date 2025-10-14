import 'package:flutter/material.dart';
import '../auth/login.dart';
import '../widgets/wessex_widgets.dart';
import '../config/colors.dart';
import 'noticias_screen.dart';
import 'merchandising_screen.dart';
import 'auspiciadores_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0; // 0: Noticias, 1: Merchandising, 2: Auspiciadores, 3: Área Privada

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/icon/logosf.png',
              height: 28,
              width: 28,
              fit: BoxFit.contain,
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: () => _navigateToLogin(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: WessexColors.white.withOpacity(0.2),
                foregroundColor: WessexColors.white,
                side: BorderSide(color: WessexColors.white, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              icon: const Icon(Icons.login, size: 18),
              label: const Text(
                'Iniciar Sesión',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: WessexBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Hero Section
                _buildHeroSection(context, isDesktop, isTablet),
                
                // Main Content
                Padding(
                  padding: EdgeInsets.all(isDesktop ? 32 : (isTablet ? 24 : 16)),
                  child: Column(
                    children: [
                      // Título de la sección
                      Text(
                        'Bienvenido al Wessex Rugby Club',
                        style: TextStyle(
                          color: WessexColors.white,
                          fontSize: isDesktop ? 36 : (isTablet ? 28 : 24),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tradición, excelencia y pasión por el rugby',
                        style: TextStyle(
                          color: WessexColors.white.withOpacity(0.9),
                          fontSize: isDesktop ? 18 : (isTablet ? 16 : 14),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      
                      // Botones principales
                      _buildMainButtons(context, isDesktop, isTablet),
                      
                      const SizedBox(height: 48),
                      
                      // Información adicional
                      _buildInfoSection(context, isDesktop, isTablet),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDesktop, bool isTablet) {
    return Container(
      height: isDesktop ? 300 : (isTablet ? 250 : 200),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            WessexColors.darkGrape.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon/logosf.png',
              height: isDesktop ? 200 : (isTablet ? 180 : 160),
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: isDesktop ? 120 : (isTablet ? 100 : 80),
                  width: isDesktop ? 120 : (isTablet ? 100 : 80),
                  decoration: BoxDecoration(
                    color: WessexColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: WessexColors.darkGrape.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.school,
                    size: isDesktop ? 60 : (isTablet ? 50 : 40),
                    color: WessexColors.deepRoyalBlue,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainButtons(BuildContext context, bool isDesktop, bool isTablet) {
    return Column(
      children: [
        // Fila de botones de navegación
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildTabButton(
                'Noticias',
                Icons.newspaper,
                _selectedTabIndex == 0,
                () => setState(() => _selectedTabIndex = 0),
              ),
              const SizedBox(width: 8),
              _buildTabButton(
                'Merchandising',
                Icons.shopping_bag,
                _selectedTabIndex == 1,
                () => setState(() => _selectedTabIndex = 1),
              ),
              const SizedBox(width: 8),
              _buildTabButton(
                'Auspiciadores',
                Icons.handshake,
                _selectedTabIndex == 2,
                () => setState(() => _selectedTabIndex = 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Contenido de la sección seleccionada
        _buildSelectedContent(context, isDesktop, isTablet),
      ],
    );
  }

  Widget _buildTabButton(
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? WessexColors.deepRoyalBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? WessexColors.deepRoyalBlue : WessexColors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : WessexColors.white,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : WessexColors.white,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedContent(BuildContext context, bool isDesktop, bool isTablet) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildNoticiasContent(context, isDesktop, isTablet);
      case 1:
        return _buildMerchandisingContent(context, isDesktop, isTablet);
      case 2:
        return _buildAuspiciadoresContent(context, isDesktop, isTablet);
      default:
        return _buildNoticiasContent(context, isDesktop, isTablet);
    }
  }

  Widget _buildNoticiasContent(BuildContext context, bool isDesktop, bool isTablet) {
    return WessexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Últimas Noticias',
                style: TextStyle(
                  color: WessexColors.darkGrape,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NoticiasScreen(),
                  ),
                ),
                child: Text(
                  'Ver todas',
                  style: TextStyle(
                    color: WessexColors.deepRoyalBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final noticias = [
                {
                  'titulo': 'Victoria en el último partido de la temporada',
                  'fecha': '12 Oct 2025',
                  'categoria': 'Partidos',
                  'icon': Icons.sports_rugby,
                },
                {
                  'titulo': 'Nuevos entrenamientos para menores',
                  'fecha': '10 Oct 2025',
                  'categoria': 'Entrenamientos',
                  'icon': Icons.fitness_center,
                },
                {
                  'titulo': 'Celebración del aniversario del club',
                  'fecha': '8 Oct 2025',
                  'categoria': 'Eventos',
                  'icon': Icons.celebration,
                },
              ];
              
              final noticia = noticias[index];
              
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: WessexColors.deepRoyalBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        noticia['icon'] as IconData,
                        color: WessexColors.deepRoyalBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            noticia['titulo'] as String,
                            style: TextStyle(
                              color: WessexColors.darkGrape,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                noticia['categoria'] as String,
                                style: TextStyle(
                                  color: WessexColors.deepRoyalBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                ' • ${noticia['fecha']}',
                                style: TextStyle(
                                  color: WessexColors.darkGrape.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: WessexColors.darkGrape.withOpacity(0.4),
                      size: 16,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMerchandisingContent(BuildContext context, bool isDesktop, bool isTablet) {
    return WessexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tienda Oficial',
                style: TextStyle(
                  color: WessexColors.darkGrape,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MerchandisingScreen(),
                  ),
                ),
                child: Text(
                  'Ver tienda',
                  style: TextStyle(
                    color: WessexColors.leafGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 3 : (isTablet ? 2 : 1),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildProductCard('Camisetas', 'Desde \$25.000', Icons.checkroom, WessexColors.deepRoyalBlue),
              _buildProductCard('Shorts', 'Desde \$18.000', Icons.sports, WessexColors.crimsonAlert),
              _buildProductCard('Accesorios', 'Desde \$12.000', Icons.shopping_cart, WessexColors.leafGreen),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WessexColors.leafGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: WessexColors.leafGreen.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.store,
                  color: WessexColors.leafGreen,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tienda Online Próximamente',
                        style: TextStyle(
                          color: WessexColors.darkGrape,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Contacta para hacer pedidos',
                        style: TextStyle(
                          color: WessexColors.darkGrape.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.phone,
                  color: WessexColors.leafGreen,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuspiciadoresContent(BuildContext context, bool isDesktop, bool isTablet) {
    return WessexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nuestros Auspiciadores',
                style: TextStyle(
                  color: WessexColors.darkGrape,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AuspiciadoresScreen(),
                  ),
                ),
                child: Text(
                  'Ver todos',
                  style: TextStyle(
                    color: WessexColors.crimsonAlert,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 2 : 1,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildSponsorCard('Empresa Principal S.A.', 'Auspiciador Principal', Icons.business, WessexColors.crimsonAlert),
              _buildSponsorCard('Banco de Chile', 'Servicios Financieros', Icons.account_balance, WessexColors.deepRoyalBlue),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WessexColors.crimsonAlert.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: WessexColors.crimsonAlert.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: WessexColors.crimsonAlert,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Quieres ser nuestro auspiciador?',
                        style: TextStyle(
                          color: WessexColors.darkGrape,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Únete a nuestra familia de empresas',
                        style: TextStyle(
                          color: WessexColors.darkGrape.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.email,
                  color: WessexColors.crimsonAlert,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(String nombre, String precio, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nombre,
            style: TextStyle(
              color: WessexColors.darkGrape,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            precio,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorCard(String nombre, String tipo, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  nombre,
                  style: TextStyle(
                    color: WessexColors.darkGrape,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tipo,
                  style: TextStyle(
                    color: WessexColors.darkGrape.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, bool isDesktop, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 32 : (isTablet ? 24 : 20)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Sobre Wessex Rugby Club',
            style: TextStyle(
              color: WessexColors.white,
              fontSize: isDesktop ? 24 : (isTablet ? 20 : 18),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Rama fundada para promover el deporte entre los estudiantes de The Wessex School',
            style: TextStyle(
              color: WessexColors.white.withOpacity(0.9),
              fontSize: isDesktop ? 16 : (isTablet ? 14 : 13),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                'Jugadores',
                '150+',
                Icons.people,
                isDesktop,
                isTablet,
              ),
              _buildStatItem(
                'Categorías',
                '8',
                Icons.groups,
                isDesktop,
                isTablet,
              ),
              _buildStatItem(
                'Años',
                '25+',
                Icons.timeline,
                isDesktop,
                isTablet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    bool isDesktop,
    bool isTablet,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: WessexColors.white,
          size: isDesktop ? 32 : (isTablet ? 28 : 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: WessexColors.white,
            fontSize: isDesktop ? 24 : (isTablet ? 20 : 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: WessexColors.white.withOpacity(0.8),
            fontSize: isDesktop ? 14 : (isTablet ? 12 : 11),
          ),
        ),
      ],
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }
}