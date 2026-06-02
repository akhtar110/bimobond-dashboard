import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoService {
  static final _deviceInfo = DeviceInfoPlugin();

  static Future<Map<String, String>> collect() async {
    String deviceId = 'unknown';
    String osVersion = 'unknown';
    String deviceType = 'unknown';

    if (kIsWeb) {
      final web = await _deviceInfo.webBrowserInfo;
      deviceType = 'web';
      deviceId = '${web.vendor ?? 'web'}-${web.userAgent ?? 'unknown'}';
      osVersion = web.platform ?? 'unknown';
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          final ios = await _deviceInfo.iosInfo;
          deviceType = 'ios';
          deviceId = ios.identifierForVendor ?? ios.name ?? 'unknown';
          osVersion = ios.systemVersion ?? 'unknown';
          break;
        case TargetPlatform.android:
          final android = await _deviceInfo.androidInfo;
          deviceType = 'android';
          deviceId = android.id;
          osVersion = android.version.release;
          break;
        default:
          deviceType = defaultTargetPlatform.name;
          break;
      }
    }

    final packageInfo = await PackageInfo.fromPlatform();
    // FCM is not configured in this dashboard build.
    const fcmToken = '';
    return {
      "deviceId": deviceId,
      "deviceType": deviceType,
      "osVersion": osVersion,
      "appVersion": packageInfo.version,
      "fcmToken": fcmToken,
    };
  }
}