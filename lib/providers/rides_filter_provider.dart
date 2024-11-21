import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';

class RidesFilterNotifier extends StateNotifier<String> {
  RidesFilterNotifier() : super('');

  void setDestination(String destination) {
    final box = GetStorage();
    box.write("driver_destination", destination);
    state = destination;
  }
}

final ridesFilterProvider =
StateNotifierProvider<RidesFilterNotifier, String>((ref) {
  return RidesFilterNotifier();
});
