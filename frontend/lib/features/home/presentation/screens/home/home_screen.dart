import 'dart:math';

import 'package:flutter/material.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/features/home/presentation/screens/noticias/noticias_screen.dart';
import 'package:wesrugby/features/home/presentation/screens/merchandising/merchandising_screen.dart';
import 'package:wesrugby/features/home/presentation/screens/auspiciadores/auspiciadores_screen.dart';
import 'package:wesrugby/features/home/presentation/screens/entrenadores/entrenadores_screen.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/data/models/noticia_model.dart';
import 'package:wesrugby/data/models/merchandising_model.dart';
import 'package:wesrugby/data/models/auspiciador_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0;
  static const int _itemsPerPage = 6;

  bool _isNoticiasLoading = true;
  bool _isMerchandisingLoading = true;
  bool _isAuspiciadoresLoading = true;
  bool _isEntrenadoresLoading = true;

  List<NoticiaModel> _noticias = [];
  List<MerchandisingModel> _productos = [];
  List<AuspiciadorModel> _auspiciadores = [];
  List<Map<String, dynamic>> _entrenadores = [];

  int _noticiasPage = 0;
  int _merchandisingPage = 0;
  int _auspiciadoresPage = 0;
  int _entrenadoresPage = 0;

  @override
  void initState() {
    super.initState();
    _loadHomeContent();
  }

  void _loadHomeContent() {
    _loadNoticiasPreview();
    _loadMerchandisingPreview();
    _loadAuspiciadoresPreview();
    _loadEntrenadoresPreview();
  }

  Future<void> _loadNoticiasPreview() async {
    setState(() => _isNoticiasLoading = true);
    try {
      final response = await ApiService.get('/noticias/publicas');

      if (!mounted) return;

      final dataList = _extractDataList(response.data);
      final noticias =
          response.success
              ? dataList.map((json) => NoticiaModel.fromJson(json)).toList()
              : <NoticiaModel>[];

      setState(() {
        _noticias = noticias;
        _noticiasPage = 0;
        _isNoticiasLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      debugPrint('Error cargando noticias públicas: $error');
      setState(() => _isNoticiasLoading = false);
    }
  }

  Future<void> _loadMerchandisingPreview() async {
    setState(() => _isMerchandisingLoading = true);
    try {
      final response = await ApiService.get('/merchandising/publico');

      if (!mounted) return;

      final dataList = _extractDataList(response.data);
      final productos =
          response.success
              ? dataList.map((json) => MerchandisingModel.fromJson(json)).toList()
              : <MerchandisingModel>[];

      setState(() {
        _productos = productos;
        _merchandisingPage = 0;
        _isMerchandisingLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      debugPrint('Error cargando merchandising público: $error');
      setState(() => _isMerchandisingLoading = false);
    }
  }

  Future<void> _loadAuspiciadoresPreview() async {
    setState(() => _isAuspiciadoresLoading = true);
    try {
      final response = await ApiService.get('/auspiciadores/publicos');

      if (!mounted) return;

      final dataList = _extractDataList(response.data);
      final auspiciadores =
          response.success
              ? dataList.map((json) => AuspiciadorModel.fromJson(json)).toList()
              : <AuspiciadorModel>[];

      setState(() {
        _auspiciadores = auspiciadores;
        _auspiciadoresPage = 0;
        _isAuspiciadoresLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      debugPrint('Error cargando auspiciadores públicos: $error');
      setState(() => _isAuspiciadoresLoading = false);
    }
  }

  Future<void> _loadEntrenadoresPreview() async {
    setState(() => _isEntrenadoresLoading = true);
    try {
      final response = await ApiService.get('/users/entrenadores');

      if (!mounted) return;

      final dataList = _extractDataList(response.data);
      final entrenadores =
          response.success
              ? dataList.cast<Map<String, dynamic>>()
              : <Map<String, dynamic>>[];

      setState(() {
        _entrenadores = entrenadores;
        _entrenadoresPage = 0;
        _isEntrenadoresLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      debugPrint('Error cargando entrenadores: $error');
      setState(() => _isEntrenadoresLoading = false);
    }
  }

  List<dynamic> _extractDataList(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map && data['data'] is List) {
      return data['data'] as List<dynamic>;
    }

    return const [];
  }

  List<T> _itemsForPage<T>(List<T> items, int page) {
    if (items.isEmpty) {
      return const [];
    }

    final start = page * _itemsPerPage;

    if (start >= items.length) {
      return const [];
    }

    final end = min(start + _itemsPerPage, items.length);
    return items.sublist(start, end);
  }

  int _pageCount(int itemCount) {
    if (itemCount <= 0) {
      return 0;
    }

    return (itemCount / _itemsPerPage).ceil();
  }

  Widget _buildPagination({
    required int itemCount,
    required int currentPage,
    required ValueChanged<int> onPageSelected,
  }) {
    final totalPages = _pageCount(itemCount);

    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    final canGoBack = currentPage > 0;
    final canGoForward = currentPage < totalPages - 1;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Align(
        alignment: Alignment.center,
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: canGoBack ? () => onPageSelected(currentPage - 1) : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Anterior'),
            ),
            Text(
              'Página ${currentPage + 1} de $totalPages',
              style: const TextStyle(
                color: WessexColors.charcoalGray,
                fontWeight: FontWeight.w500,
              ),
            ),
            OutlinedButton.icon(
              onPressed:
                  canGoForward ? () => onPageSelected(currentPage + 1) : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Siguiente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLoadingIndicator() {
    return SizedBox(
      height: 160,
      child: const Center(
        child: CircularProgressIndicator(color: WessexColors.deepRoyalBlue),
      ),
    );
  }

  Widget _buildEmptySection(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: WessexColors.lightGray.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WessexColors.lightGray.withOpacity(0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: WessexColors.ashGray),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: WessexColors.charcoalGray,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoticiasGrid(
    List<NoticiaModel> items,
    bool isDesktop,
    bool isTablet,
  ) {
    final crossAxisCount = isDesktop
        ? 3
        : isTablet
            ? 3
            : 1;

    final aspectRatio = isDesktop || isTablet ? 0.9 : 0.95;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: aspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildNoticiaPreviewCard(items[index]),
    );
  }

  Widget _buildMerchandisingGrid(
    List<MerchandisingModel> items,
    bool isDesktop,
    bool isTablet,
  ) {
    final crossAxisCount = isDesktop
        ? 3
        : isTablet
            ? 3
            : 1;

    final aspectRatio = isDesktop || isTablet ? 0.85 : 0.9;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: aspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) =>
          _buildMerchandisingPreviewCard(items[index]),
    );
  }

  Widget _buildAuspiciadoresGrid(
    List<AuspiciadorModel> items,
    bool isDesktop,
    bool isTablet,
  ) {
    final crossAxisCount = isDesktop
        ? 3
        : isTablet
            ? 3
            : 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) =>
          _buildAuspiciadorPreviewCard(items[index]),
    );
  }

  Widget _buildEntrenadoresGrid(
    List<Map<String, dynamic>> items,
    bool isDesktop,
    bool isTablet,
  ) {
    final crossAxisCount = isDesktop
        ? 4
        : isTablet
            ? 3
            : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) =>
          _buildEntrenadorPreviewCard(items[index]),
    );
  }

  Widget _buildNoticiaPreviewCard(NoticiaModel noticia) {
    return Container(
      decoration: _homeCardDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: noticia.imagen.isNotEmpty
                  ? Image.network(
                      noticia.imagen,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _cardFallbackIcon(
                        icon: Icons.image_not_supported,
                      ),
                    )
                  : _cardFallbackIcon(icon: Icons.article_outlined),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            noticia.titulo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: WessexColors.deepNavyBlue,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            noticia.descripcion,
            style: const TextStyle(
              fontSize: 12,
              color: WessexColors.charcoalGray,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: WessexColors.ashGray),
              const SizedBox(width: 4),
              Text(
                _formatDate(noticia.fechaPublicacion),
                style: const TextStyle(
                  fontSize: 12,
                  color: WessexColors.ashGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMerchandisingPreviewCard(MerchandisingModel producto) {
    return Container(
      decoration: _homeCardDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: producto.imagen.isNotEmpty
                  ? Image.network(
                      producto.imagen,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _cardFallbackIcon(
                        icon: Icons.shopping_bag,
                      ),
                    )
                  : _cardFallbackIcon(icon: Icons.shopping_bag),
            ),
          ),
          const SizedBox(height: 12),
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
          if (producto.descripcion != null && producto.descripcion!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                producto.descripcion!,
                style: const TextStyle(
                  fontSize: 12,
                  color: WessexColors.charcoalGray,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            producto.precioFormateado,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: WessexColors.deepRoyalBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuspiciadorPreviewCard(AuspiciadorModel auspiciador) {
    return Container(
      decoration: _homeCardDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: WessexColors.lightGray.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: auspiciador.imagen.isNotEmpty
                    ? Image.network(
                        auspiciador.imagen,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => _cardFallbackIcon(
                          icon: Icons.handshake,
                        ),
                      )
                    : _cardFallbackIcon(icon: Icons.handshake),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            auspiciador.titulo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: WessexColors.deepNavyBlue,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (auspiciador.enlace != null && auspiciador.enlace!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                auspiciador.enlace!,
                style: const TextStyle(
                  fontSize: 12,
                  color: WessexColors.deepRoyalBlue,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEntrenadorPreviewCard(Map<String, dynamic> entrenador) {
    final String nombre = entrenador['nombreCompleto'] ?? 'Sin nombre';
    final String? avatar = entrenador['avatar'];
    
    return Container(
      decoration: _homeCardDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar circular
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WessexColors.deepRoyalBlue.withOpacity(0.1),
              border: Border.all(
                color: WessexColors.deepRoyalBlue,
                width: 2,
              ),
            ),
            child: ClipOval(
              child:
                  avatar != null && avatar.isNotEmpty
                      ? Image.network(
                        avatar,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => _buildDefaultAvatarPreview(nombre),
                      )
                      : _buildDefaultAvatarPreview(nombre),
            ),
          ),
          const SizedBox(height: 10),
          // Nombre del entrenador
          Text(
            nombre,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: WessexColors.deepNavyBlue,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          // Badge de entrenador
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: WessexColors.leafGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'ENTRENADOR',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: WessexColors.leafGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatarPreview(String nombre) {
    // Obtener las iniciales del nombre
    final List<String> palabras = nombre.split(' ');
    String iniciales = '';
    if (palabras.isNotEmpty) {
      iniciales = palabras[0][0].toUpperCase();
      if (palabras.length > 1) {
        iniciales += palabras[1][0].toUpperCase();
      }
    }

    return Container(
      color: WessexColors.deepRoyalBlue.withOpacity(0.2),
      child: Center(
        child: Text(
          iniciales,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: WessexColors.deepRoyalBlue,
          ),
        ),
      ),
    );
  }

  Widget _cardFallbackIcon({required IconData icon}) {
    return Container(
      color: WessexColors.lightGray.withOpacity(0.3),
      child: Center(
        child: Icon(icon, color: WessexColors.ashGray, size: 32),
      ),
    );
  }

  BoxDecoration _homeCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: WessexColors.lightGray.withOpacity(0.3),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

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
              label: const Text(
                'Iniciar Sesión',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: WessexBackground(
        opacity: 0.28,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeroSection(context, isDesktop, isTablet),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 48 : (isTablet ? 32 : 20),
                  vertical: isDesktop ? 56 : (isTablet ? 48 : 36),
                ),
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

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
  ) {
    return Container(
      height: isDesktop ? 300 : (isTablet ? 250 : 200),
      width: double.infinity,
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

  Widget _buildMainButtons(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
  ) {
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
              const SizedBox(width: 8),
              _buildTabButton(
                'Entrenadores',
                Icons.sports,
                _selectedTabIndex == 3,
                () => setState(() => _selectedTabIndex = 3),
              ),
              const SizedBox(width: 8),
              _buildTabButton(
                'Club Wessex',
                Icons.info_outline,
                _selectedTabIndex == 4,
                () => setState(() => _selectedTabIndex = 4),
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
            color:
                isSelected
                    ? WessexColors.deepRoyalBlue
                    : WessexColors.white.withOpacity(0.3),
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

  Widget _buildSelectedContent(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
  ) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildNoticiasContent(context, isDesktop, isTablet);
      case 1:
        return _buildMerchandisingContent(context, isDesktop, isTablet);
      case 2:
        return _buildAuspiciadoresContent(context, isDesktop, isTablet);
      case 3:
        return _buildEntrenadoresContent(context, isDesktop, isTablet);
      case 4:
        return _buildClubInfoContent(context, isDesktop, isTablet);
      default:
        return _buildNoticiasContent(context, isDesktop, isTablet);
    }
  }

  Widget _buildNoticiasContent(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
  ) {
    final currentItems = _itemsForPage(_noticias, _noticiasPage);

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
                onPressed:
                    () => Navigator.push(
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
          if (_isNoticiasLoading)
            _buildSectionLoadingIndicator()
          else if (_noticias.isEmpty)
            _buildEmptySection('No hay noticias disponibles', Icons.newspaper)
          else ...[
            _buildNoticiasGrid(currentItems, isDesktop, isTablet),
            _buildPagination(
              itemCount: _noticias.length,
              currentPage: _noticiasPage,
              onPageSelected: (page) => setState(() => _noticiasPage = page),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMerchandisingContent(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
  ) {
    final currentItems = _itemsForPage(_productos, _merchandisingPage);

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
                onPressed:
                    () => Navigator.push(
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
          if (_isMerchandisingLoading)
            _buildSectionLoadingIndicator()
          else if (_productos.isEmpty)
            _buildEmptySection('No hay productos disponibles', Icons.shopping_bag)
          else ...[
            _buildMerchandisingGrid(currentItems, isDesktop, isTablet),
            _buildPagination(
              itemCount: _productos.length,
              currentPage: _merchandisingPage,
              onPageSelected: (page) =>
                  setState(() => _merchandisingPage = page),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuspiciadoresContent(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
  ) {
    final currentItems = _itemsForPage(_auspiciadores, _auspiciadoresPage);

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
                onPressed:
                    () => Navigator.push(
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
          if (_isAuspiciadoresLoading)
            _buildSectionLoadingIndicator()
          else if (_auspiciadores.isEmpty)
            _buildEmptySection('No hay auspiciadores disponibles', Icons.handshake)
          else ...[
            _buildAuspiciadoresGrid(currentItems, isDesktop, isTablet),
            _buildPagination(
              itemCount: _auspiciadores.length,
              currentPage: _auspiciadoresPage,
              onPageSelected: (page) =>
                  setState(() => _auspiciadoresPage = page),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEntrenadoresContent(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
  ) {
    final currentItems = _itemsForPage(_entrenadores, _entrenadoresPage);

    return WessexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nuestros Entrenadores',
                style: TextStyle(
                  color: WessexColors.darkGrape,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EntrenadoresScreen(),
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
          if (_isEntrenadoresLoading)
            _buildSectionLoadingIndicator()
          else if (_entrenadores.isEmpty)
            _buildEmptySection('No hay entrenadores disponibles', Icons.sports)
          else ...[
            _buildEntrenadoresGrid(currentItems, isDesktop, isTablet),
            _buildPagination(
              itemCount: _entrenadores.length,
              currentPage: _entrenadoresPage,
              onPageSelected: (page) =>
                  setState(() => _entrenadoresPage = page),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClubInfoContent(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
  ) {
    final contactDetails = [
      {
        'icon': Icons.mail_outline,
        'title': 'Correo electrónico',
        'detail': 'rugby@wessexschool.cl',
      },
      {
        'icon': Icons.phone_outlined,
        'title': 'Teléfono de contacto',
        'detail': '+56 9 8765 4321',
      },
      {
        'icon': Icons.location_on_outlined,
        'title': 'Dirección',
        'detail': 'The Wessex School, Camino El Venado 950, San Pedro.',
      },
    ];

    final bodyFontSize = isDesktop ? 16.0 : 14.0;

    return WessexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historia de la Rama',
            style: TextStyle(
              color: WessexColors.darkGrape,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'La rama de rugby del Wessex School nació del entusiasmo de las generaciones de 1989 y se ha mantenido como un espacio formativo que transmite los valores del colegio. A través de los años, apoderados, entrenadores y estudiantes han consolidado una comunidad que compite en torneos regionales y nacionales.',
            style: TextStyle(
              color: WessexColors.charcoalGray,
              fontSize: bodyFontSize,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hoy la directiva impulsa proyectos deportivos, académicos y sociales para seguir creciendo. Si tienes recuerdos, fotografías o hitos que desees sumar, comunícate con el equipo y forma parte de nuestra memoria colectiva.',
            style: TextStyle(
              color: WessexColors.charcoalGray,
              fontSize: bodyFontSize,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Contactos Oficiales',
            style: TextStyle(
              color: WessexColors.darkGrape,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          for (final detail in contactDetails) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      detail['icon'] as IconData,
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
                          detail['title'] as String,
                          style: const TextStyle(
                            color: WessexColors.darkGrape,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          detail['detail'] as String,
                          style: TextStyle(
                            color: WessexColors.charcoalGray,
                            fontSize: bodyFontSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WessexColors.deepRoyalBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.edit_note,
                  color: WessexColors.deepRoyalBlue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'La directiva puede actualizar esta información desde su panel administrativo.',
                    style: TextStyle(
                      color: WessexColors.deepRoyalBlue.withOpacity(0.9),
                      fontSize: bodyFontSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.pushNamed(context, '/login');
  }
}
