import 'package:flutter/material.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/data/models/noticia_model.dart';

class NoticiasScreen extends StatefulWidget {
  const NoticiasScreen({super.key});

  @override
  State<NoticiasScreen> createState() => _NoticiasScreenState();
}

class _NoticiasScreenState extends State<NoticiasScreen> {
  List<NoticiaModel> _noticias = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNoticias();
  }

  Future<void> _loadNoticias() async {
    setState(() => _isLoading = true);
    try {
      print('🔍 DEBUG Noticias Públicas - Cargando desde /noticias/publicas');
      final response = await ApiService.get('/noticias/publicas');
      print(
        '🔍 DEBUG Noticias Públicas - Response success: ${response.success}',
      );
      print('🔍 DEBUG Noticias Públicas - Response data: ${response.data}');

      if (response.success && response.data != null) {
        // El backend devuelve {success: true, message: "...", data: [...]}
        final List<dynamic> noticiasData =
            response.data is Map
                ? (response.data['data'] as List? ?? [])
                : (response.data is List ? response.data as List : []);

        print(
          '🔍 DEBUG Noticias Públicas - Noticias count: ${noticiasData.length}',
        );

        setState(() {
          _noticias =
              noticiasData.map((json) => NoticiaModel.fromJson(json)).toList();
        });

        print(
          '✅ DEBUG Noticias Públicas - _noticias final count: ${_noticias.length}',
        );
        if (_noticias.isNotEmpty) {
          print(
            '🔍 DEBUG Noticias Públicas - Primera noticia: ${_noticias.first.titulo}',
          );
        }
      }
    } catch (e) {
      print('❌ Error al cargar noticias públicas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: WessexAppBar(
        title: 'Noticias del Club',
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
                  : _noticias.isEmpty
                  ? _buildEmptyState()
                  : _buildNoticiasList(),
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
              Icon(
                Icons.article_outlined,
                size: 64,
                color: WessexColors.ashGray,
              ),
              const SizedBox(height: 16),
              const Text(
                'No hay noticias disponibles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: WessexColors.charcoalGray,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pronto tendremos novedades que compartir',
                style: TextStyle(fontSize: 14, color: WessexColors.ashGray),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoticiasList() {
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
                    Icons.newspaper,
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
                        'Noticias del Wessex Rugby',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: WessexColors.deepNavyBlue,
                        ),
                      ),
                      Text(
                        'Mantente al día con las últimas novedades del club',
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
          _buildNoticiasGrid(),
        ],
      ),
    );
  }

  Widget _buildNoticiasGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktop = screenWidth > 1200;
        final isTablet = screenWidth > 600;
        
        int crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _noticias.length,
          itemBuilder: (context, index) {
            return _buildNoticiaCard(_noticias[index]);
          },
        );
      },
    );
  }

  Widget _buildNoticiaCard(NoticiaModel noticia) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        border: Border.all(
          color: WessexColors.lightGray.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen de la noticia
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: WessexColors.lightGray,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child:
                      noticia.imagen.isNotEmpty
                          ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.network(
                              noticia.imagen,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Container(
                                    child: const Icon(
                                      Icons.article,
                                      color: WessexColors.ashGray,
                                      size: 48,
                                    ),
                                  ),
                            ),
                          )
                          : const Center(
                            child: Icon(
                              Icons.article,
                              color: WessexColors.ashGray,
                              size: 48,
                            ),
                          ),
                ),
                if (noticia.destacada)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: WessexColors.goldenYellow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.star,
                            color: WessexColors.deepNavyBlue,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'DESTACADA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: WessexColors.deepNavyBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Información de la noticia
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  noticia.titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: WessexColors.deepNavyBlue,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  noticia.descripcion,
                  style: const TextStyle(
                    fontSize: 13,
                    color: WessexColors.charcoalGray,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: WessexColors.ashGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(noticia.fechaCreacion),
                      style: TextStyle(
                        fontSize: 12,
                        color: WessexColors.ashGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '//';
  }
}
