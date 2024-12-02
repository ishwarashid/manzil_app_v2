import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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
            'passengerNumber': doc['passengerNumber'],
            'pickupLocation': doc['pickupLocation'],
            'destination': doc['destination'],
            'seats': doc['seats'],
            'offeredFare': doc['offeredFare'],
            'paymentMethod': doc['paymentMethod'],
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
  Future<bool> hasActiveRides(String driverId) async {
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

      return false;
    } catch (e) {
      print('Error checking active rides: $e');
      throw Exception('Failed to check active rides');
    }
  }


  Future<bool> hasPrivateRide(String driverId) async {
    try {
      // Get all rides where this user is the selected driver
      final driverRidesQuery = await _firestore
          .collection('rides')
          .where('selectedDriverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'accepted')
          .get();

      // Check if any of these rides are private
      return driverRidesQuery.docs.any((doc) {
        final data = doc.data();
        return data['isPrivate'] == true;
      });

    } catch (e) {
      print('Error checking private rides: $e');
      throw Exception('Failed to check private rides');
    }
  }

  Future<void> acceptRide(String rideId, Map<String, dynamic> driverInfo) async {
    try {
      // First get the ride details
      final rideDoc = await _firestore.collection('rides').doc(rideId).get();
      final controlsDoc = await _firestore.collection('controls').get();

      if (!rideDoc.exists) {
        throw Exception('Ride not found');
      }

      final rideData = rideDoc.data() as Map<String, dynamic>;
      print(rideData);
      final controlData = controlsDoc.docs.first.data();;
      print(controlData);
      final isPrivate = rideData['isPrivate'] as bool;

      if (isPrivate) {
        final hasActive = await hasActiveRides(driverInfo['uid']);
        if (hasActive) {
          throw Exception(
              'You cannot accept this ride as you already have an active ride. And the ride you are going to accept is private.'
          );
        }
      }

      final hasPrivateRides = await hasPrivateRide(driverInfo['uid']);
      if (hasPrivateRides) {
        throw Exception(
            'You cannot accept this ride as you already have an private ride.'
        );
      }

      // Get coordinates for calculations
      final driverCoordinates = driverInfo['coordinates'] as List;
      final pickupCoordinates = rideData['pickupCoordinates'] as List;
      final destinationCoordinates = rideData['destinationCoordinates'] as List;

      // Calculate distances using Geolocator
      final distanceFromPassenger = await Geolocator.distanceBetween(
          driverCoordinates[0],
          driverCoordinates[1],
          pickupCoordinates[0],
          pickupCoordinates[1]
      );

      final distanceFromDestination = await Geolocator.distanceBetween(
          driverCoordinates[0],
          driverCoordinates[1],
          destinationCoordinates[0],
          destinationCoordinates[1]
      );

      // Get rates from controls
      final petrolRate = controlData['petrolRate'] as double;
      final litersPerMeter = controlData['litersPerMeter'] as double;
      int calculatedFare;

      // Calculate fare
      if (isPrivate) {
        calculatedFare = ((litersPerMeter * petrolRate * distanceFromDestination) * 2.5).ceil();
      } else {
        calculatedFare = (litersPerMeter * petrolRate * distanceFromDestination).ceil();
      }

      await _firestore
          .collection('rides')
          .doc(rideId)
          .collection('acceptedBy')
          .doc(driverInfo['uid'])
          .set({
        'driverName': "${driverInfo['first_name']} ${driverInfo['last_name']}",
        'driverNumber': driverInfo['phone_number'],
        'driverRatings': driverInfo['overallRating'] ?? 0,
        'driverLocation': driverInfo['location_text'],
        'driverCoordinates': driverCoordinates,
        'distanceFromPassenger': distanceFromPassenger,
        'calculatedFare': calculatedFare,
        'driverDistanceFromDestination': distanceFromDestination,
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
            'passengerNumber': doc['passengerNumber'],
            'pickupLocation': doc['pickupLocation'],
            'destination': doc['destination'],
            'seats': doc['seats'],
            'offeredFare': doc['offeredFare'],
            'paymentMethod': doc['paymentMethod'],
            'isPrivate': doc['isPrivate'],
            'status': doc['status'],
            'calculatedFare': acceptedData['calculatedFare'],
            'distanceFromPassenger': acceptedData['distanceFromPassenger'],
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

  Future<void> addRatingAndUpdateDriver({
    required String rideId,
    required String driverId,
    required double rating
  }) async {
    try {
      // Start a batch write
      final batch = _firestore.batch();

      // Add rating to ride document
      final rideRef = _firestore.collection('rides').doc(rideId);
      batch.update(rideRef, {
          'rating': rating,
      });

      // Get all completed rides for this driver with reviews
      final driverRidesQuery = await _firestore
          .collection('rides')
          .where('selectedDriverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'completed')
          .get();

      // Calculate new average rating
      double totalRating = rating;
      int ratingCount = 1;

      for (var doc in driverRidesQuery.docs) {
        final data = doc.data();
        if (data['rating'] != null ) {
          totalRating += data['rating'];
          ratingCount++;
        }
      }

      final averageRating = totalRating / ratingCount;

      // Update driver's overall rating
      final driverRef = _firestore.collection('users').doc(driverId);
      batch.update(driverRef, {
        'overallRating': averageRating,
        // 'totalRatings': ratingCount,
      });

      await batch.commit();
    } catch (e) {
      print('Error adding rating: $e');
      throw Exception('Failed to add rating');
    }
  }

}