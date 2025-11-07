import 'package:flutter/material.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/data/models/auspiciador_model.dart';

class AuspiciadoresScreen extends StatefulWidget {
  const AuspiciadoresScreen({super.key});

  @override
  State<AuspiciadoresScreen> createState() => _AuspiciadoresScreenState();
}

class _AuspiciadoresScreenState extends State<AuspiciadoresScreen> {
  List<AuspiciadorModel> _auspiciadores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuspiciadores();
  }

  Future<void> _loadAuspiciadores() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/auspiciadores/publicos');
      if (response.success && response.data != null) {
        // El backend devuelve {success: true, message: "...", data: [...]}
        final List<dynamic> auspiciadoresData =
            response.data is Map
                ? (response.data['data'] as List? ?? [])
                : (response.data is List ? response.data as List : []);

        setState(() {
          _auspiciadores =
              auspiciadoresData
                  .map((json) => AuspiciadorModel.fromJson(json))
                  .toList();
        });
      }
    } catch (e) {
      print('Error al cargar auspiciadores: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: WessexAppBar(
        title: 'Nuestros Auspiciadores',
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
                  : _auspiciadores.isEmpty
                  ? _buildEmptyState()
                  : _buildAuspiciadoresList(),
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
              Icon(Icons.business, size: 64, color: WessexColors.ashGray),
              const SizedBox(height: 16),
              const Text(
                'No hay auspiciadores disponibles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: WessexColors.charcoalGray,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pronto tendremos empresas que nos apoyen',
                style: TextStyle(fontSize: 14, color: WessexColors.ashGray),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuspiciadoresList() {
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
                    Icons.business,
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
                        'Nuestros Auspiciadores',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: WessexColors.deepNavyBlue,
                        ),
                      ),
                      Text(
                        'Empresas que apoyan al Wessex Rugby Club',
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
          _buildAuspiciadoresGrid(),
        ],
      ),
    );
  }

  Widget _buildAuspiciadoresGrid() {
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
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _auspiciadores.length,
          itemBuilder: (context, index) {
            return _buildAuspiciadorCard(_auspiciadores[index]);
          },
        );
      },
    );
  }

  Widget _buildAuspiciadorCard(AuspiciadorModel auspiciador) {
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
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo del auspiciador
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child:
                  auspiciador.imagen.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          auspiciador.imagen,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (context, error, stackTrace) => const Icon(
                                Icons.business,
                                color: WessexColors.ashGray,
                                size: 48,
                              ),
                        ),
                      )
                      : const Icon(
                        Icons.business,
                        color: WessexColors.ashGray,
                        size: 48,
                      ),
            ),
          ),

          // Nombre del auspiciador
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  auspiciador.titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: WessexColors.deepNavyBlue,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Enlace si existe
                if (auspiciador.enlace != null &&
                    auspiciador.enlace!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.link,
                        size: 14,
                        color: WessexColors.deepRoyalBlue,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          auspiciador.enlace!,
                          style: TextStyle(
                            fontSize: 12,
                            color: WessexColors.deepRoyalBlue,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
