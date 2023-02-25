import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class GalleryPermissionNotifier extends StateNotifier<PermissionStatus> {
  GalleryPermissionNotifier() 
    : super(PermissionStatus.denied)  // Denied is the intitial state
  {
    // Sets the initial state
    getGalleryPermission();
  }

  get hasPermission => state.isGranted || state.isLimited;

  /// Requests the gallery permission
  Future<PermissionStatus> requestGalleryPermission() async {
    // Android 32 and below uses Permission.storage
    late Future<PermissionStatus> permission;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt <= 32) {
        permission = Permission.storage.request();
      }
    }

    permission = Permission.photos.request();
    state = await permission;
    return state;
  }

  Future<PermissionStatus> getGalleryPermission() async {
    final status = await Permission.photos.status;

    state = status;
    return status;
  }

  /// Either the permission was granted already or else ask for the permission
  Future<bool> hasOrAskForNotificationPermission() {
    return requestGalleryPermission()
        .then((p) => p.isGranted);
  }

}
final galleryPermissionNotifier
  = StateNotifierProvider<GalleryPermissionNotifier, PermissionStatus>
    ((ref) => GalleryPermissionNotifier());
