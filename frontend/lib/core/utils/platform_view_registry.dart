/// Exportación condicional: en web usa dart:ui_web, en otras plataformas es un stub.
export 'platform_view_registry_stub.dart'
    if (dart.library.ui_web) 'platform_view_registry_web.dart';
