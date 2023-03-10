import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/shared/models/user.dart';
import 'package:immich_mobile/shared/services/user.service.dart';

final suggestedSharedUsersProvider =
    FutureProvider.autoDispose<List<User>>((ref) async {
  UserService userService = ref.watch(userServiceProvider);

  return await userService.getAllUsers(isAll: false) ?? [];
});
