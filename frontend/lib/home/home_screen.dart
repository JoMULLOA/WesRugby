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
  int _selectedTabIndex = 0;

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
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: WessexColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sports_rugby,
                    color: WessexColors.deepNavyBlue,
                    size: 16,
                  ),
                );
              },
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
                side: const BorderSide(color: WessexColors.white, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.login, size: 16),
              label: const Text('Iniciar Sesión', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
      body: WessexBackground(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeroSection(context, isDesktop, isTablet),
              Container(
                padding: EdgeInsets.all(isDesktop ? 48 : (isTablet ? 32 : 24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                    
                    _buildMainButtons(context, isDesktop, isTablet),
                    
                    const SizedBox(height: 48),
                    
                    _buildInfoSection(context, isDesktop, isTablet),
                  ],
                ),
              ),
            ],
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
                  child: const Icon(
                    Icons.sports_rugby,
                    size: 48,
                    color: WessexColors.deepNavyBlue,
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
              const Text(
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
                child: const Text(
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
          _buildPlaceholderContent('Noticias del club', Icons.newspaper),
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
              const Text(
                'Tienda del Club',
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
                child: const Text(
                  'Ver todo',
                  style: TextStyle(
                    color: WessexColors.deepRoyalBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPlaceholderContent('Productos del club', Icons.shopping_bag),
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
              const Text(
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
                child: const Text(
                  'Ver todos',
                  style: TextStyle(
                    color: WessexColors.deepRoyalBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPlaceholderContent('Empresas que nos apoyan', Icons.handshake),
        ],
      ),
    );
  }

  Widget _buildPlaceholderContent(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WessexColors.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: WessexColors.ashGray,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: WessexColors.charcoalGray,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, bool isDesktop, bool isTablet) {
    return WessexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Sobre Wessex Rugby Club',
            style: TextStyle(
              color: WessexColors.darkGrape,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Rama fundada para promover el deporte entre los estudiantes de The Wessex School.',
            style: TextStyle(
              color: WessexColors.charcoalGray,
              fontSize: isDesktop ? 16 : 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
