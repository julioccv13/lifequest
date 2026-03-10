import 'dart:io';

Future<void> writeTextFile(String path, String content) async {
  final file = File(path);
  await file.writeAsString(content);
}

Future<String> readTextFile(String path) async {
  final file = File(path);
  return file.readAsString();
}

Future<bool> fileExists(String path) async {
  final file = File(path);
  return file.exists();
}
