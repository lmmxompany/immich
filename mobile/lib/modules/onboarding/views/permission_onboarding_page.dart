import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/modules/backup/providers/backup.provider.dart';
import 'package:immich_mobile/modules/onboarding/providers/gallery_permission.provider.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/shared/ui/immich_logo.dart';
import 'package:immich_mobile/shared/ui/immich_title_text.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionOnboardingPage extends HookConsumerWidget {
  const PermissionOnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permission = ref.watch(galleryPermissionNotifier);

    goToHome() {
      // Resume backup (if enable) then navigate
      ref.read(backupProvider.notifier).resumeBackup()
        .catchError((error) {
        debugPrint('PermissionOnboardingPage error: $error');
      });
      AutoRouter.of(context).replace(
        const TabControllerRoute(),
      );
    }

    buildRequestPermission() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'permission_onboarding_request',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ).tr(),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () => ref
              .read(galleryPermissionNotifier.notifier)
              .requestGalleryPermission()
              .then((permission) async {
                if (permission.isGranted || permission.isLimited) {
                  goToHome();
                }
              }),
            child: const Text(
              'permission_onboarding_grant_permission',
            ).tr(),
          ),
        ],
      );
    }

    buildPermissionGranted() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'permission_onboarding_permission_granted',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ).tr(),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () => goToHome(),
            child: const Text('permission_onboarding_get_started').tr(),
          ),
        ],
      );
    }

    buildPermissionLimited() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_outlined,
            color: Colors.yellow,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'permission_onboarding_permission_limited',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ).tr(),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () => openAppSettings(),
            child: const Text(
              'permission_onboarding_go_to_settings',
            ).tr(),
          ),
          const SizedBox(height: 8.0),
          TextButton(
            onPressed: () => goToHome(),
            child: const Text(
              'permission_onboarding_continue_anyway',
            ).tr(),
          ),
        ],
      );
    }

    buildPermissionDenied() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_outlined,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'permission_onboarding_permission_denied',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ).tr(),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () => openAppSettings(),
            child: const Text(
              'permission_onboarding_go_to_settings',
            ).tr(),
          ),
        ],
      );
    }

    final Widget child;
    switch (permission) {
      case PermissionStatus.limited:
        child = buildPermissionLimited();
        break;
      case PermissionStatus.denied:
        child = buildRequestPermission();
        break;
      case PermissionStatus.granted:
        child = buildPermissionGranted();
        break;
      case PermissionStatus.restricted:
      case PermissionStatus.permanentlyDenied:
        child = buildPermissionDenied();
        break;
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 380,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ImmichLogo(
                  heroTag: 'logo',
                ),
                const ImmichTitleText(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

