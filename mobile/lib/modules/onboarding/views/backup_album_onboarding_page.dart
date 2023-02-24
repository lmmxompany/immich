import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class BackupAlbumOnboardingPage extends HookConsumerWidget {
  const BackupAlbumOnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Text('Select your backup albums below');
  }
}
