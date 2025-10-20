import 'package:flutter/material.dart';
import '../widgets/wessex_widgets.dart';
import '../config/colors.dart';
import '../services/api_service.dart';
import '../models/auspiciador_model.dart';

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
        final List<dynamic> auspiciadoresData = response.data is Map 
            ? (response.data['data'] as List? ?? [])
            : (response.data is List ? response.data as List : []);
        
        setState(() {
          _auspiciadores = auspiciadoresData
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
          child: _isLoading
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
              Icon(
                Icons.business,
                size: 64,
                color: WessexColors.ashGray,
              ),
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
          ...(_auspiciadores.map((auspiciador) => _buildAuspiciadorCard(auspiciador))),
        ],
      ),
    );
  }

  Widget _buildAuspiciadorCard(AuspiciadorModel auspiciador) {
    return WessexCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo del auspiciador
          if (auspiciador.imagen.isNotEmpty) ...[
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: WessexColors.lightGray,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  auspiciador.imagen,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    child: const Icon(
                      Icons.business,
                      color: WessexColors.ashGray,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Nombre del auspiciador
          Text(
            auspiciador.titulo,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: WessexColors.deepNavyBlue,
            ),
          ),

          const SizedBox(height: 12),

          // Enlace si existe
          if (auspiciador.enlace != null && auspiciador.enlace!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: WessexColors.lightGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 16,
                    color: WessexColors.deepRoyalBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      auspiciador.enlace!,
                      style: TextStyle(
                        fontSize: 14,
                        color: WessexColors.deepRoyalBlue,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
