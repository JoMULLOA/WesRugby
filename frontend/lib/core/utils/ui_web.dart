// Conditional import for ui_web library
// Imports dart:ui_web on web, stub on other platforms
export 'ui_web_stub.dart' if (dart.library.html) 'ui_web_web.dart';
