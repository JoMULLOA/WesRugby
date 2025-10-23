import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/data/services/tokenManager.dart';

class MediaUploaderInfo {
  final String? nombreCompleto;
  final String? email;
  final String? rol;
  final String? avatarUrl;
  final int? avatarVersion;

  const MediaUploaderInfo({
    this.nombreCompleto,
    this.email,
    this.rol,
    this.avatarUrl,
    this.avatarVersion,
  });

  String get displayName {
    if (nombreCompleto != null && nombreCompleto!.trim().isNotEmpty) {
      return nombreCompleto!;
    }
    if (email != null && email!.trim().isNotEmpty) {
      return email!;
    }
    if (rol != null && rol!.trim().isNotEmpty) {
      return rol!;
    }
    return 'Sin registro';
  }
}

class MediaLightboxEntry {
  final String id;
  final String imageUrl;
  final String? viewUrl;
  final String? downloadUrl;
  final DateTime? uploadedAt;
  final MediaUploaderInfo uploader;
  final bool isPrivate;
  final String? title;
  final String? originalName;

  const MediaLightboxEntry({
    required this.id,
    required this.imageUrl,
    required this.uploader,
    this.viewUrl,
    this.downloadUrl,
    this.uploadedAt,
    this.isPrivate = false,
    this.title,
    this.originalName,
  });
}

class MediaLightbox extends StatefulWidget {
  final List<MediaLightboxEntry> entries;
  final int initialIndex;

  const MediaLightbox({
    super.key,
    required this.entries,
    this.initialIndex = 0,
  });

  static Future<void> show({
    required BuildContext context,
    required List<MediaLightboxEntry> entries,
    int initialIndex = 0,
  }) {
    if (entries.isEmpty) return Future.value();

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder:
          (_) => MediaLightbox(entries: entries, initialIndex: initialIndex),
    );
  }

  @override
  State<MediaLightbox> createState() => _MediaLightboxState();
}

class _MediaLightboxState extends State<MediaLightbox> {
  late final PageController _pageController;
  late int _currentIndex;
  final FocusNode _focusNode = FocusNode();
  final DateFormat _headerDateFormat = DateFormat('dd/MM/yyyy • HH:mm');

  @override
  void initState() {
    super.initState();
    final maxIndex = widget.entries.length - 1;
    _currentIndex = widget.initialIndex.clamp(0, maxIndex);
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  MediaLightboxEntry get _currentEntry => widget.entries[_currentIndex];

  KeyEventResult _handleKey(FocusNode node, RawKeyEvent event) {
    if (event is! RawKeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _goNext();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _goPrevious();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _goPrevious() {
    if (widget.entries.length <= 1) return;
    final newIndex =
        (_currentIndex - 1 + widget.entries.length) % widget.entries.length;
    _animateToIndex(newIndex);
  }

  void _goNext() {
    if (widget.entries.length <= 1) return;
    final newIndex = (_currentIndex + 1) % widget.entries.length;
    _animateToIndex(newIndex);
  }

  void _animateToIndex(int index) {
    setState(() => _currentIndex = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _launchExternal(String? url) async {
    if (url == null || url.trim().isEmpty) {
      _showMessage('Enlace no disponible');
      return;
    }

    final resolvedUrl = await _withAuthTokenIfNeeded(url);
    final uri = Uri.tryParse(resolvedUrl);
    if (uri == null) {
      _showMessage('Enlace no válido');
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showMessage('No se pudo abrir el enlace');
      }
    } catch (error) {
      _showMessage('No se pudo abrir el enlace');
    }
  }

  Future<String> _withAuthTokenIfNeeded(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      return url;
    }

    final apiUri = Uri.tryParse(ApiService.baseUrl);
    if (apiUri == null) {
      return url;
    }

    final baseHost = apiUri.host.toLowerCase();
    final targetHost = uri.host.toLowerCase();
    final basePort = _effectivePort(apiUri);
    final targetPort = _effectivePort(uri);

    final sameOrigin =
        apiUri.scheme == uri.scheme &&
        baseHost == targetHost &&
        basePort == targetPort;

    if (!sameOrigin) {
      return url;
    }

    if (!uri.path.startsWith('/api/')) {
      return url;
    }

    final token = await TokenManager.getToken();
    if (token == null || token.isEmpty) {
      return url;
    }

    final query = Map<String, String>.from(uri.queryParameters);
    query['token'] = token;

    final updatedUri = uri.replace(queryParameters: query);
    return updatedUri.toString();
  }

  int _effectivePort(Uri uri) {
    if (uri.hasPort) return uri.port;
    return uri.scheme == 'https' ? 443 : 80;
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: Colors.transparent,
      child: Focus(
        focusNode: _focusNode,
        onKey: _handleKey,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1024, maxHeight: 768),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 12,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                Expanded(child: _buildViewer()),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final entry = _currentEntry;
    final uploadedAt = entry.uploadedAt;
    final uploadedText =
        uploadedAt != null
            ? _headerDateFormat.format(uploadedAt.toLocal())
            : 'Fecha no disponible';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarChip(uploader: entry.uploader),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.uploader.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.uploader.email != null &&
                        entry.uploader.email!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          entry.uploader.email!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        uploadedText,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (entry.isPrivate)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock,
                                size: 14,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Contenido privado',
                                style: Theme.of(
                                  context,
                                ).textTheme.labelMedium?.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir en pestaña'),
                  onPressed:
                      entry.viewUrl != null || entry.imageUrl.isNotEmpty
                          ? () =>
                              _launchExternal(entry.viewUrl ?? entry.imageUrl)
                          : null,
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Descargar'),
                  onPressed:
                      entry.downloadUrl != null
                          ? () => _launchExternal(entry.downloadUrl)
                          : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewer() {
    return Stack(
      children: [
        Container(
          color: Colors.black,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.entries.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final entry = widget.entries[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: CachedNetworkImage(
                    imageUrl: entry.imageUrl,
                    fit: BoxFit.contain,
                    placeholder:
                        (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                    errorWidget:
                        (context, url, error) => const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.white70,
                          ),
                        ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.entries.length > 1) ...[
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: _LightboxNavButton(
              icon: Icons.chevron_left,
              onPressed: _goPrevious,
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: _LightboxNavButton(
              icon: Icons.chevron_right,
              onPressed: _goNext,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentEntry.title != null &&
              _currentEntry.title!.trim().isNotEmpty)
            Expanded(
              child: Text(
                _currentEntry.title!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const SizedBox.shrink(),
          Text(
            '${_currentIndex + 1} / ${widget.entries.length}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _AvatarChip extends StatelessWidget {
  final MediaUploaderInfo uploader;

  const _AvatarChip({required this.uploader});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = uploader.avatarUrl;
    final initials = _initialsFor(uploader.displayName);

    return CircleAvatar(
      radius: 28,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child:
          avatarUrl != null && avatarUrl.isNotEmpty
              ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: avatarUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorWidget:
                      (_, __, ___) => Text(
                        initials,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                ),
              )
              : Text(
                initials,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
    );
  }
}

class _LightboxNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _LightboxNavButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      style: IconButton.styleFrom(
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
    );
  }
}

String _initialsFor(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'MM';
  final segments = trimmed
      .split(RegExp(r'\s+'))
      .where((segment) => segment.isNotEmpty);
  final parts = segments.toList();
  if (parts.isEmpty) return 'MM';
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  final first = parts.first.substring(0, 1);
  final last = parts.last.substring(0, 1);
  return (first + last).toUpperCase();
}
