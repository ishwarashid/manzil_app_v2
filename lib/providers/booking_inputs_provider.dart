import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookingInputsNotifier extends StateNotifier<Map<String, Object>> {
  BookingInputsNotifier()
      : super({
    "pickup": '',
    "pickupCoordinates": <double>[], // Changed from List<int>
    "destination": '',
    "destinationCoordinates": <double>[], // Changed from List<int>
    "seats": 0,
    "fare": 0,
    "private": false
  });

  void setPickup(String pickup) {
    state = {
      ...state,
      "pickup": pickup,
    };
  }

  void setPickupCoordinates(List<double> coordinates) {
    state = {
      ...state,
      "pickupCoordinates": coordinates,
    };
  }

  void setDestination(String destination) {
    state = {
      ...state,
      "destination": destination,
    };
  }

  void setDestinationCoordinates(List<double> coordinates) {
    state = {
      ...state,
      "destinationCoordinates": coordinates,
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

  void setPrivate(bool private) {
    state = {
      ...state,
      "private": private,
    };
  }

  bool areAllFieldsFilled() {
    print(state["pickup"]);
    print(state["destination"]);
    print(state["seats"]);
    print( state["fare"]);
    print(state["pickupCoordinates"]);
    print(state["destinationCoordinates"]);

    return state["pickup"] != '' &&
        state["destination"] != '' &&
        state["seats"] != 0 &&
        state["fare"] != 0 &&
        (state["pickupCoordinates"] as List).isNotEmpty &&
        (state["destinationCoordinates"] as List).isNotEmpty;
  }

  void resetBookingInputs() {
    state = {
      "pickup": '',
      "pickupCoordinates": [],
      "destination": '',
      "destinationCoordinates": [],
      "seats": 0,
      "fare": 0,
      "private": false,
    };
  }
}

final bookingInputsProvider =
StateNotifierProvider<BookingInputsNotifier, Map<String, Object>>((ref) {
  return BookingInputsNotifier();
});
