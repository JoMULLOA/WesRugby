import 'package:flutter/material.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/api_service.dart';

class EntrenadoresScreen extends StatefulWidget {
  const EntrenadoresScreen({super.key});

  @override
  State<EntrenadoresScreen> createState() => _EntrenadoresScreenState();
}

class _EntrenadoresScreenState extends State<EntrenadoresScreen> {
  List<Map<String, dynamic>> _entrenadores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntrenadores();
  }

  Future<void> _loadEntrenadores() async {
    setState(() => _isLoading = true);
    try {
      // Obtenemos usuarios con rol "entrenador"
      final response = await ApiService.get('/users/entrenadores');
      if (response.success && response.data != null) {
        final List<dynamic> entrenadoresData =
            response.data is Map
                ? (response.data['data'] as List? ?? [])
                : (response.data is List ? response.data as List : []);

        setState(() {
          _entrenadores = entrenadoresData.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      print('Error al cargar entrenadores: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: WessexAppBar(
        title: 'Nuestros Entrenadores',
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
                  : _entrenadores.isEmpty
                  ? _buildEmptyState()
                  : _buildEntrenadoresList(),
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
              Icon(Icons.sports, size: 64, color: WessexColors.ashGray),
              const SizedBox(height: 16),
              const Text(
                'No hay entrenadores registrados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: WessexColors.charcoalGray,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pronto conocerás a nuestro equipo técnico',
                style: TextStyle(fontSize: 14, color: WessexColors.ashGray),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntrenadoresList() {
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
                    Icons.sports,
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
                        'Equipo Técnico Wessex Rugby',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: WessexColors.deepNavyBlue,
                        ),
                      ),
                      Text(
                        'Conoce a los profesionales que entrenan a nuestros jugadores',
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
          _buildEntrenadoresGrid(),
        ],
      ),
    );
  }

  Widget _buildEntrenadoresGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktop = screenWidth > 1200;
        final isTablet = screenWidth > 600;
        
        int crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _entrenadores.length,
          itemBuilder: (context, index) {
            return _buildEntrenadorCard(_entrenadores[index]);
          },
        );
      },
    );
  }

  Widget _buildEntrenadorCard(Map<String, dynamic> entrenador) {
    final String nombre = entrenador['nombreCompleto'] ?? 'Sin nombre';
    final String? avatar = entrenador['avatar'];
    final String email = entrenador['email'] ?? '';
    
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          // Avatar circular
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WessexColors.deepRoyalBlue.withOpacity(0.1),
              border: Border.all(
                color: WessexColors.deepRoyalBlue,
                width: 3,
              ),
            ),
            child: ClipOval(
              child:
                  avatar != null && avatar.isNotEmpty
                      ? Image.network(
                        avatar,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => _buildDefaultAvatar(nombre),
                      )
                      : _buildDefaultAvatar(nombre),
            ),
          ),
          const SizedBox(height: 12),
          // Nombre del entrenador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              nombre,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: WessexColors.deepNavyBlue,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          // Rol
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: WessexColors.leafGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ENTRENADOR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: WessexColors.leafGreen,
              ),
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.email,
                    size: 12,
                    color: WessexColors.ashGray,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      email,
                      style: TextStyle(
                        fontSize: 11,
                        color: WessexColors.ashGray,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String nombre) {
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
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: WessexColors.deepRoyalBlue,
          ),
        ),
      ),
    );
  }
}
