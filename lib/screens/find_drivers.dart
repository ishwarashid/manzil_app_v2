import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:manzil_app_v2/services/socket_handler.dart';
import 'package:manzil_app_v2/widgets/driver_card.dart';
import 'package:manzil_app_v2/widgets/main_drawer.dart';
import 'package:http/http.dart' as http;

class FindDrivers extends StatefulWidget {
  const FindDrivers({super.key});

  @override
  State<FindDrivers> createState() => _FindDriversState();
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
      // List<dynamic> drivers = requests.map((req) {
      //
      //   List.castFrom(req["acceptedBy"]).map((driver){
      //      return {
      //       "driverId": driver["driver"]["_id"],
      //       "driverName": "${driver["driver"]["firstName"] as String} ${driver["driver"]["lastName"] as String}",
      //       "distance": "2 mins",
      //     };
      //   });
      // }).toList();

      List<dynamic> drivers = [];

      for(var request in requests){
        for(var driver in request["acceptedBy"]){
          drivers.add({
            "driverId": driver["driver"]["_id"],
            "driverName": "${driver["driver"]["firstName"] as String} ${driver["driver"]["lastName"] as String}",
            "distance": "2 mins",
          });
        }
      }

      if (mounted) {
        setState(() {
          _availableDrivers.clear();
          _availableDrivers.addAll(drivers);
        });
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
