import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookingInputsNotifier extends StateNotifier<Map<String, Object>> {
  BookingInputsNotifier()
      : super({
    "pickup": 'Tariq Bin Ziad Colony', // will come from map
    "destination": '',
    "seats": 0,
    "fare": 0,
  });

  void setPickup(String pickup) {
    state = {
      ...state,
      "pickup": pickup,
    };
  }

  void setDestination(String destination) {
    state = {
      ...state,
      "destination": destination,
    };
  }

  void setSeats(int seats) {
    state = {
      ...state,
      "seats": seats,
    };
  }

  void setFare(int fare) {
    state = {
      ...state,
      "fare": fare,
    };
  }

  bool areAllFieldsFilled() {
    return state["pickup"] != '' &&
        state["destination"] != '' &&
        state["seats"] != 0 &&
        state["fare"] != 0;
  }

  void resetBookingInputs() {
    state = {
      "pickup": 'Tariq Bin Ziad Colony', // will come from map
      "destination": '',
      "seats": 0,
      "fare": 0,
    };
  }
}

final bookingInputsProvider =
StateNotifierProvider<BookingInputsNotifier, Map<String, Object>>((ref) {
  return BookingInputsNotifier();
});
