import 'package:flutter/material.dart';
import '../widgets/wessex_widgets.dart';
import '../config/colors.dart';
import '../services/api_service.dart';
import '../models/noticia_model.dart';

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
      print('🔍 DEBUG Noticias Públicas - Response success: ${response.success}');
      print('🔍 DEBUG Noticias Públicas - Response data: ${response.data}');
      
      if (response.success && response.data != null) {
        // El backend devuelve {success: true, message: "...", data: [...]}
        final List<dynamic> noticiasData = response.data is Map 
            ? (response.data['data'] as List? ?? [])
            : (response.data is List ? response.data as List : []);
        
        print('🔍 DEBUG Noticias Públicas - Noticias count: ${noticiasData.length}');
        
        setState(() {
          _noticias = noticiasData
              .map((json) => NoticiaModel.fromJson(json))
              .toList();
        });
        
        print('✅ DEBUG Noticias Públicas - _noticias final count: ${_noticias.length}');
        if (_noticias.isNotEmpty) {
          print('🔍 DEBUG Noticias Públicas - Primera noticia: ${_noticias.first.titulo}');
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
          child: _isLoading
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
                style: TextStyle(
                  fontSize: 14,
                  color: WessexColors.ashGray,
                ),
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
          ...(_noticias.map((noticia) => _buildNoticiaCard(noticia))),
        ],
      ),
    );
  }

  Widget _buildNoticiaCard(NoticiaModel noticia) {
    return WessexCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (noticia.destacada) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: WessexColors.goldenYellow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star,
                    color: WessexColors.deepNavyBlue,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'DESTACADA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: WessexColors.deepNavyBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (noticia.imagen.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                noticia.imagen,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 200,
                  color: WessexColors.lightGray,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: WessexColors.ashGray,
                    size: 48,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            noticia.titulo,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: WessexColors.deepNavyBlue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            noticia.descripcion,
            style: const TextStyle(
              fontSize: 14,
              color: WessexColors.charcoalGray,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: WessexColors.ashGray,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(noticia.fechaCreacion),
                style: TextStyle(
                  fontSize: 14,
                  color: WessexColors.ashGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '//';
  }
}
