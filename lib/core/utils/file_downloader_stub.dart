import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<void> saveAndDownloadFile({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
}) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
  } catch (_) {
    // Non-web fallback
  }
}
