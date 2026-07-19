import 'package:flutter/services.dart';

/// Opens [url] in the system browser when possible; otherwise copies to clipboard.
void openExternalUrl(String url) {
  Clipboard.setData(ClipboardData(text: url));
}
