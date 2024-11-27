import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manzil_app_v2/services/chat/chat_services.dart';
import 'package:manzil_app_v2/services/ride/ride_services.dart';

class DriverPassengerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();
  final RidesService _ridesService = RidesService();

  // Stream to get current ride for a passenger
  Stream<Map<String, dynamic>?> getCurrentRide(String passengerId) {
    return _firestore
        .collection('rides')
        .where('passengerID', isEqualTo: passengerId)
        .where('status', isEqualTo: 'pending') // Only get pending rides
        .limit(1) // We only need the most recent one
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return {
        'id': doc.id,
        ...doc.data(),
      };
    });
  }

  // Stream to get all drivers who accepted a specific ride
  Stream<List<Map<String, dynamic>>> getAcceptedDrivers(String rideId) {
    return _firestore
        .collection('rides')
        .doc(rideId)
        .collection('acceptedBy')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'driverId': doc.id,
          'driverName': data['driverName'],
          'distance': data['distance'],
          'calculatedFare': data['calculatedFare'],
          'timestamp': data['timestamp'],
        };
      }).toList();
    });
  }

  // Method to accept a specific driver
  Future<void> acceptDriver({
    required String rideId,
    required Map<String, dynamic> currentUser,
    required Map<String, dynamic> driverInfo,
  }) async {
    try {
      // First check if ride exists and is private
      final rideDoc = await _firestore.collection('rides').doc(rideId).get();
      if (!rideDoc.exists) {
        throw Exception('Ride not found');
      }

      final rideData = rideDoc.data() as Map<String, dynamic>;
      final isPrivate = rideData['isPrivate'] as bool;

      // Check driver's active rides using RideService's method
      if (isPrivate) {
        final hasActive = await _ridesService.hasActiveRides(driverInfo['driverId']);
        if (hasActive) {
          throw Exception(
              'Cannot accept this driver as they already have an active ride'
          );
        }
      }

      // Start a batch write
      final batch = _firestore.batch();

      // Update the main ride document
      final rideRef = _firestore.collection('rides').doc(rideId);
      batch.update(rideRef, {
        'status': 'accepted',
        'selectedDriverId': driverInfo['driverId'],
        'driverName': driverInfo['driverName'],
        'distance': driverInfo['distance'],
        'calculatedFare': driverInfo['calculatedFare'],
        'acceptedAt': Timestamp.now(),
      });

      // Create trip document
      final tripRef = _firestore.collection('trips').doc();
      batch.set(tripRef, {
        'rideId': rideId,
        'driverId': driverInfo['driverId'],
        'driverName': driverInfo['driverName'],
        'passengerId': currentUser['uid'],
        'passengerName': "${currentUser['first_name']} ${currentUser['last_name']}",
        'distance': driverInfo['distance'],
        'calculatedFare': driverInfo['calculatedFare'],
        'status': 'ongoing',
        'startTime': Timestamp.now(),
        'pickupLocation': null,
        'dropoffLocation': null,
        'actualFare': null,
      });

      // Execute batch
      await batch.commit();

      // Create chat room
      await _chatService.createChatRoom(currentUser, driverInfo['driverId']);

      // Cancel other drivers
      await _cancelOtherDrivers(rideId, driverInfo['driverId']);

    } catch (e) {
      print('Error accepting driver: $e');
      throw Exception(e.toString());
    }
  }

  // Private method to cancel other drivers after accepting one
  Future<void> _cancelOtherDrivers(String rideId, String acceptedDriverId) async {
    try {
      final acceptedByRef = _firestore
          .collection('rides')
          .doc(rideId)
          .collection('acceptedBy');

      final snapshot = await acceptedByRef.get();

      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        if (doc.id != acceptedDriverId) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error canceling other drivers: $e');
      throw Exception('Failed to cancel other drivers');
    }
  }

  // Method to complete a ride
  Future<void> completeRide(String tripId, {
    required Map<String, dynamic> dropoffLocation,
    required double actualFare,
  }) async {
    try {
      await _firestore.collection('trips').doc(tripId).update({
        'status': 'completed',
        'endTime': Timestamp.now(),
        'dropoffLocation': dropoffLocation,
        'actualFare': actualFare,
      });
    } catch (e) {
      print('Error completing ride: $e');
      throw Exception('Failed to complete ride');
    }
  }
}