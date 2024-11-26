import 'package:flutter_riverpod/flutter_riverpod.dart';

class CurrentUserNotifier extends StateNotifier<Map<String, dynamic>> {
  CurrentUserNotifier()
      : super({
          "uid": '',
          "email": '',
          "first_name": '',
          "last_name": '',
          "phone_number": ''
        });

  void setUser(Map<String, dynamic> user) {
    state = user;
  }

  void clearUser() {
    state = {
      "uid": '',
      "email": '',
      "first_name": '',
      "last_name": '',
      "phone_number": ''
    };
  }
}

final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, Map<String, dynamic>>((ref) {
  return CurrentUserNotifier();
});
