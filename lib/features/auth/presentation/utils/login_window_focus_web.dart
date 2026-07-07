// Web-only: detects when the Google OAuth popup closes without completing.
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

html.EventListener? _listener;

void listenWindowFocus(void Function() onFocus) {
  cancelWindowFocusListener();
  _listener = (_) => onFocus();
  html.window.addEventListener('focus', _listener!);
}

void cancelWindowFocusListener() {
  if (_listener == null) return;
  html.window.removeEventListener('focus', _listener!);
  _listener = null;
}
