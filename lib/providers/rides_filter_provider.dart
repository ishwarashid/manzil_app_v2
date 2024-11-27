import 'package:flutter_riverpod/flutter_riverpod.dart';

class RidesFilterNotifier extends StateNotifier<String> {
  RidesFilterNotifier() : super('');

  void setDestination(String destination) {
    state = destination;
  }

  void clearDestination() {
    state = '';
  }
}

final ridesFilterProvider =
    StateNotifierProvider<RidesFilterNotifier, String>((ref) {
  return RidesFilterNotifier();
});
