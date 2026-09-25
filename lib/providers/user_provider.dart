// Import Third Party Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import App Files
import 'app_provider.dart';

// User Notifier
class UserNotifier extends Notifier<Map<String, dynamic>> {
  @override
  Map<String, dynamic> build() {
    return ref.watch(appProvider).value?['user'] ?? {};
  }

  void set(Map<String, dynamic> user) {
    state = user;
  }

  void update(String key, dynamic value) {
    state = {...state, key: value};
  }

  void clear() {
    state = {};
  }
}

// User Provider
final userProvider = NotifierProvider<UserNotifier, Map<String, dynamic>>(() => UserNotifier());
