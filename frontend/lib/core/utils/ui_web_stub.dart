// Stub implementation for non-web platforms
// This file provides dummy implementations of dart:ui_web functionality

class PlatformViewRegistry {
  void registerViewFactory(String viewId, dynamic Function(int) factory) {
    throw UnsupportedError('platformViewRegistry is not supported on this platform');
  }
}

final platformViewRegistry = PlatformViewRegistry();
