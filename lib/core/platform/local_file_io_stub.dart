Future<void> writeTextFile(String path, String content) {
  throw UnsupportedError('File IO is not supported on this platform.');
}

Future<String> readTextFile(String path) {
  throw UnsupportedError('File IO is not supported on this platform.');
}

Future<bool> fileExists(String path) async {
  return false;
}
