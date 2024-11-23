import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:manzil_app_v2/services/socket_handler.dart';
import 'package:manzil_app_v2/widgets/driver_card.dart';
import 'package:manzil_app_v2/widgets/main_drawer.dart';

class FindDrivers extends StatefulWidget {
  const FindDrivers({super.key});

  @override
  State<FindDrivers> createState() => _FindDriversState();
}

Future<Map<String, dynamic>> getDistance(String long1, String lat1, String long2, String lat2) async {

  String url = "https://api.mapbox.com/directions/v5/mapbox/driving/$long1%2C$lat1%3B$long2%2C$lat2?alternatives=false&geometries=geojson&language=en&overview=full&steps=true&access_token=${const String.fromEnvironment("ACCESS_TOKEN")}";

  final response = await http.get(
    Uri.parse(url),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );

  var geocodedData = jsonDecode(response.body) as Map<String, dynamic>;

  return {
  "distance": geocodedData["routes"][0]["distance"],
  "duration": geocodedData["routes"][0]["duration"]
  };
}

Future<List<dynamic>> getAcceptedRequests(String id) async {
  const url = "https://shrimp-select-vertically.ngrok-free.app";

  final response = await http.get(
    Uri.parse("$url/accepted-requests/$id"),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );
  final requestData = jsonDecode(response.body) as Map<String, dynamic>;
  final requests = List.castFrom(requestData['data']);
  return requests;
}


class _FindDriversState extends State<FindDrivers> {
  final box = GetStorage();

  final _availableDrivers = [];

  void getAcceptedRequestsData() {

    getAcceptedRequests(box.read("_id")).then((requests){
      List<dynamic> drivers = [];

      for(var request in requests){
        for(var driver in request["acceptedBy"]){

          String lat1 = box.read("pickup_coordinates")["lat"].toString();
          String lng1 = box.read("pickup_coordinates")["lon"].toString();
          String lat2 = driver["driver"]["startPoint"][0]["lat"].toString();
          String lng2 = driver["driver"]["startPoint"][0]["lon"].toString();

          getDistance(lng1, lat1, lng2, lat2).then((response){
            var minutesAway = response["duration"]/60;
            var distance = response["distance"];

            drivers.add({
              "driverId": driver["driver"]["_id"],
              "driverName": "${driver["driver"]["firstName"] as String} ${driver["driver"]["lastName"] as String}",
              "distance": distance,
              "duration": "$minutesAway"
            });

            if (mounted) {
              setState(() {
                _availableDrivers.clear();
                _availableDrivers.addAll(drivers);
              });
            }
          });
        }
      }
    });
  }

  @override
  void initState() {
    getAcceptedRequestsData();

    SocketHandler.socket.on("Fetch Drivers", (payload){
      getAcceptedRequestsData();
    });

    SocketHandler.socket.on("Remove Driver", (payload){

      if (mounted) {
        setState(() {
          _availableDrivers.clear();
        });
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    Widget content =
    const Center(child: Text("You haven't booked a ride yet!"));

    if (_availableDrivers.isEmpty) {
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "No one accepted your request!",
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: const Color.fromRGBO(30, 60, 87, 1),
                  fontWeight: FontWeight.w500
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10,),
            Text(
              "Please check status again after few mins",
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: const Color.fromRGBO(30, 60, 87, 1),
              ),
            ),
          ],
        ),
      );
    }

    if (_availableDrivers.isNotEmpty) {
      content = ListView.builder(
        itemCount: _availableDrivers.length,
        itemBuilder: (context, index) => DriverCard(_availableDrivers[index]),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Found Drivers"),
      ),
      drawer: const MainDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: content,
      ),
    );
  }
}
