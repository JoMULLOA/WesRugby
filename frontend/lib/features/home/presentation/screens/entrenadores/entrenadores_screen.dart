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
      // Obtenemos entrenadores con información pública
      final response = await ApiService.get('/entrenadores/publicos');
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
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _entrenadores.length,
      itemBuilder: (context, index) {
        return _buildEntrenadorCard(_entrenadores[index]);
      },
    );
  }

  Widget _buildEntrenadorCard(Map<String, dynamic> entrenador) {
    final String nombre = entrenador['nombreCompleto'] ?? 'Sin nombre';
    final String? avatar = entrenador['avatar'];
    final String? titulo = entrenador['titulo'];
    final String? especialidad = entrenador['especialidad'];
    final int? aniosExperiencia = entrenador['aniosExperiencia'];
    final String? biografia = entrenador['biografia'];
    final String? logros = entrenador['logros'];
    final String? certificaciones = entrenador['certificaciones'];
    final String? categorias = entrenador['categorias'];
    
    return WessexCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con avatar y nombre
          Row(
            children: [
              // Avatar circular
              Container(
                width: 80,
                height: 80,
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: WessexColors.deepNavyBlue,
                      ),
                    ),
                    if (titulo != null && titulo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 14,
                          color: WessexColors.leafGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (especialidad != null && especialidad.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        especialidad,
                        style: TextStyle(
                          fontSize: 13,
                          color: WessexColors.charcoalGray,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Información adicional
          if (aniosExperiencia != null) ...[
            _buildInfoRow(
              icon: Icons.stars,
              label: 'Experiencia',
              value: '$aniosExperiencia años en rugby',
            ),
            const SizedBox(height: 8),
          ],

          if (categorias != null && categorias.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.groups,
              label: 'Categorías',
              value: categorias,
            ),
            const SizedBox(height: 8),
          ],

          if (biografia != null && biografia.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Biografía',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: WessexColors.deepNavyBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              biografia,
              style: TextStyle(
                fontSize: 13,
                color: WessexColors.charcoalGray,
                height: 1.4,
              ),
            ),
          ],

          if (logros != null && logros.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Logros Destacados',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: WessexColors.deepNavyBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              logros,
              style: TextStyle(
                fontSize: 13,
                color: WessexColors.charcoalGray,
                height: 1.4,
              ),
            ),
          ],

          if (certificaciones != null && certificaciones.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Certificaciones',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: WessexColors.deepNavyBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              certificaciones,
              style: TextStyle(
                fontSize: 13,
                color: WessexColors.charcoalGray,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: WessexColors.deepRoyalBlue),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: WessexColors.deepNavyBlue,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: WessexColors.charcoalGray,
            ),
          ),
        ),
      ],
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
