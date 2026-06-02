import 'package:flutter/widgets.dart';

import 'localization.dart';

/// Decodes bloc/UI messages encoded as `l10nKey` or `l10nKey::argValue`.
String localizeMessage(BuildContext context, String message) {
  if (!message.startsWith('l10n:')) return message;
  final payload = message.substring(5);
  final parts = payload.split('::');
  final key = parts.first;
  if (parts.length == 1) return context.l10n.t(key);
  return context.tr(key, {'name': parts.sublist(1).join('::')});
}

String l10nMsg(String key, [String? name]) =>
    name == null ? 'l10n:$key' : 'l10n:$key::$name';
