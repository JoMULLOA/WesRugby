// Stub implementation for non-web platforms
import 'dart:async';
import 'dart:typed_data';

class Blob {
  Blob(List<dynamic> data, [String? type]);
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) =>
      throw UnimplementedError('Not supported on this platform');
  static void revokeObjectUrl(String url) {}
}

class AnchorElement {
  AnchorElement({String? href});
  void setAttribute(String name, String value) {}
  void click() {}
}

class FileUploadInputElement {
  String? accept;
  bool? multiple;
  List<File>? files;
  Stream<dynamic> get onChange => Stream.empty();
  void click() {}
}

class File {
  String get name => '';
  int get size => 0;
  String get type => '';
  Blob slice([int? start, int? end, String? contentType]) => Blob([]);
}

class FileReader {
  dynamic result;
  Stream<dynamic> get onLoadEnd => Stream.empty();
  Stream<dynamic> get onError => Stream.empty();
  void readAsArrayBuffer(Blob blob) {}
  void readAsDataUrl(Blob blob) {}
  void readAsText(Blob blob, [String? encoding]) {}
}
