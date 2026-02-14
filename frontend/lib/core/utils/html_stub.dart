// Stub implementation for non-web platforms
// This file provides dummy implementations of dart:html functionality
// for mobile and desktop platforms

import 'dart:typed_data';

class Blob {
  Blob(List<dynamic> parts, [String? type]);
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) {
    throw UnsupportedError('createObjectUrlFromBlob is not supported on this platform');
  }

  static void revokeObjectUrl(String url) {
    throw UnsupportedError('revokeObjectUrl is not supported on this platform');
  }
}

class AnchorElement {
  AnchorElement({String? href});
  
  set download(String value) {}
  set href(String value) {}
  
  void setAttribute(String name, String value) {}
  
  void click() {
    throw UnsupportedError('AnchorElement.click is not supported on this platform');
  }
}

class FileUploadInputElement {
  FileUploadInputElement();
  
  set accept(String value) {}
  set multiple(bool value) {}
  
  List<File>? get files => null;
  
  void click() {
    throw UnsupportedError('FileUploadInputElement.click is not supported on this platform');
  }
  
  Stream<dynamic> get onChange => Stream.empty();
}

class File {
  String get name => '';
  int get size => 0;
  String get type => '';
}

class FileReader {
  FileReader();
  
  void readAsArrayBuffer(dynamic blob) {
    throw UnsupportedError('FileReader.readAsArrayBuffer is not supported on this platform');
  }
  
  void readAsDataUrl(dynamic blob) {
    throw UnsupportedError('FileReader.readAsDataUrl is not supported on this platform');
  }
  
  dynamic get result => null;
  
  Stream<dynamic> get onLoadEnd => Stream.empty();
  Stream<dynamic> get onLoad => Stream.empty();
  Stream<dynamic> get onError => Stream.empty();
}

class IFrameElement {
  IFrameElement();
  
  set src(String value) {}
  set style(dynamic value) {}
  
  dynamic get style => _MockStyle();
}

class _MockStyle {
  set border(String value) {}
  set width(String value) {}
  set height(String value) {}
}
