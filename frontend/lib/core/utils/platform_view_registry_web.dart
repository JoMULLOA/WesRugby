// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

/// Registra un factory de vista HTML para Flutter Web.
void registerViewFactory(String viewType, dynamic Function(int) factory) {
  ui_web.platformViewRegistry.registerViewFactory(viewType, factory);
}
