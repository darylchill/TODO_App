import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class PermissionUtil {
  static Future<void> requestPermissions(List<Permission> permissions) async {
    for (var permission in permissions) {
      final status = await permission.status; //
      debugPrint('Permission $permission status: $status.');

      if (status.isDenied || status.isRestricted || status.isPermanentlyDenied) {
        debugPrint('Requesting permission $permission...');
        final res = await permission.request();
        debugPrint('Permission $permission ${res.isGranted ? 'granted' : 'not granted'}.');
      }
    }
  }
}