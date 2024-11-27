import 'package:cloud_firestore/cloud_firestore.dart';

class RidesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get available ride requests for drivers
  Stream<List<Map<String, dynamic>>> getRides(String userId) {
    return _firestore
        .collection('rides')
        .where('passengerID', isNotEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((querySnapshot) async {
      List<Map<String, dynamic>> rides = [];

      for (var document in querySnapshot.docs) {
        final acceptedByDoc = await _firestore
            .collection('rides')
            .doc(document.id)
            .collection('acceptedBy')
            .doc(userId)
            .get();

        if (!acceptedByDoc.exists) {
          final doc = document.data();
          rides.add({
            'id': document.id,
            'passengerName': doc['passengerName'],
            'passengerID': doc['passengerID'],
            'pickupLocation': doc['pickupLocation'],
            'destination': doc['destination'],
            'seats': doc['seats'],
            'offeredFare': doc['offeredFare'],
            'isPrivate': doc['isPrivate'],
            'status': doc['status'],
            'createdAt': doc['createdAt'],
          });
        }
      }

      rides.sort((a, b) => (b['createdAt'] as Timestamp)
          .compareTo(a['createdAt'] as Timestamp));

      return rides;
    });
  }

  // Check if driver has active rides
  Future<bool> _hasActiveRides(String driverId) async {
    try {
      // Check for any rides where driver is selected and ride is not completed/cancelled
      final selectedRidesQuery = await _firestore
          .collection('rides')
          .where('selectedDriverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'accepted')
          .limit(1)
          .get();

      if (selectedRidesQuery.docs.isNotEmpty) {
        return true;
      }

      // Check for any private rides the driver has accepted
      final acceptedPrivateRidesQuery = await _firestore
          .collection('rides')
          .where('isPrivate', isEqualTo: true)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in acceptedPrivateRidesQuery.docs) {
        final acceptedByDoc = await doc.reference
            .collection('acceptedBy')
            .doc(driverId)
            .get();

        if (acceptedByDoc.exists) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking active rides: $e');
      throw Exception('Failed to check active rides');
    }
  }

  Future<void> acceptRide(String rideId, Map<String, dynamic> driverInfo) async {
    try {
      // First get the ride details
      final rideDoc = await _firestore.collection('rides').doc(rideId).get();

      if (!rideDoc.exists) {
        throw Exception('Ride not found');
      }

      final rideData = rideDoc.data() as Map<String, dynamic>;
      final isPrivate = rideData['isPrivate'] as bool;

      // Check if driver has any active rides
      final hasActive = await _hasActiveRides(driverInfo['uid']);

      // If ride is private or driver has an active private ride, don't allow accepting
      if (hasActive) {
        throw Exception(
            'You cannot accept this ride as you already have an active ride'
        );
      }

      // If we get here, driver can accept the ride
      await _firestore
          .collection('rides')
          .doc(rideId)
          .collection('acceptedBy')
          .doc(driverInfo['uid'])
          .set({
        'driverName': "${driverInfo['first_name']} ${driverInfo['last_name']}",
        'distance': 2.0, // You might want to calculate this dynamically
        'calculatedFare': 200, // You might want to calculate this dynamically
        'timestamp': Timestamp.now(),
      });

      print('Driver added to subcollection successfully');
    } catch (e) {
      print('Failed to add driver: $e');
      throw Exception(e.toString());
    }
  }

  // Get rides accepted by a specific driver
  Stream<List<Map<String, dynamic>>> getAcceptedRides(String driverId) {
    return _firestore
        .collection('rides')
        .where('status', whereIn: ['pending', 'accepted'])
        .snapshots()
        .asyncMap((querySnapshot) async {
      List<Map<String, dynamic>> acceptedRides = [];

      for (var document in querySnapshot.docs) {
        final acceptedByDoc = await _firestore
            .collection('rides')
            .doc(document.id)
            .collection('acceptedBy')
            .doc(driverId)
            .get();

        if (acceptedByDoc.exists) {
          final doc = document.data();
          final acceptedData = acceptedByDoc.data() ?? {};

          acceptedRides.add({
            'id': document.id,
            'passengerName': doc['passengerName'],
            'passengerID': doc['passengerID'],
            'pickupLocation': doc['pickupLocation'],
            'destination': doc['destination'],
            'seats': doc['seats'],
            'offeredFare': doc['offeredFare'],
            'isPrivate': doc['isPrivate'],
            'status': doc['status'],
            'calculatedFare': acceptedData['calculatedFare'],
            'distance': acceptedData['distance'],
            'acceptedAt': acceptedData['timestamp'],
          });
        }
      }

      // Sort by acceptance time, newest first
      acceptedRides.sort((a, b) => (b['acceptedAt'] as Timestamp)
          .compareTo(a['acceptedAt'] as Timestamp));

      return acceptedRides;
    });
  }

  // Get active rides for a driver (rides where they were selected by passenger)
  Stream<List<Map<String, dynamic>>> getActiveRides(String driverId) {
    return _firestore
        .collection('rides')
        .where('selectedDriverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        ...data,
      };
    }).toList());
  }

  // Cancel a ride
  Future<void> cancelRide(String rideId, {String? reason}) async {
    await _firestore.collection('rides').doc(rideId).update({
      'status': 'cancelled',
      'cancelReason': reason ?? 'Cancelled by user',
      'cancelledAt': Timestamp.now(),
    });
  }
}