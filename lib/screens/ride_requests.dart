import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:manzil_app_v2/providers/rides_filter_provider.dart';
import 'package:manzil_app_v2/screens/user_chat_screen.dart';
import 'package:manzil_app_v2/services/socket_handler.dart';
import 'package:manzil_app_v2/widgets/destination_alert_dialog.dart';

class RideRequestsScreen extends ConsumerStatefulWidget {
  const RideRequestsScreen({super.key});

  @override
  RideRequestsScreenState createState() => RideRequestsScreenState();
}

class RideRequestsScreenState extends ConsumerState<RideRequestsScreen> {
  ////////////////////////////////////////////
  ///////// GET THIS DYNAMICALLY TOO ////////
  //////////////////////////////////////////
  final List<dynamic> ridesData = [];

  final box = GetStorage();

  Future<List<dynamic>> getRequests() async {
      final box = GetStorage();
      String destination = box.read("driver_destination").toString().trim();

      const url = "https://shrimp-select-vertically.ngrok-free.app";

      final response = await http.get(
          Uri.parse("$url/requests?destination=$destination"),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
      );
      final requestData = jsonDecode(response.body) as Map<String, dynamic>;
      final requests = List.castFrom(requestData['data']);
      return requests;
  }

  void acceptRequest(String id, String userId) async {
    const url = "https://shrimp-select-vertically.ngrok-free.app";

    await http.patch(
      Uri.parse("$url/accept-request/$id"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "acceptedBy": userId
      })
    );
  }

  void getRidesData() {

    getRequests().then((requests){
      if (mounted) {
        setState(() {
          ridesData.clear();
          ridesData.addAll(requests);
        });
      }
    });
  }

  void _showDestinationInputDialog() {
    if(box.read('driver_destination')!=null){
      ref.read(ridesFilterProvider.notifier).setDestination(box.read('driver_destination'));
    }
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return const DestinationAlertDialog();
      },
    );
  }

  void getCoordinatesForDriverDestination(String searchText) async {
    final box = GetStorage();
    String url = "https://nominatim.openstreetmap.org/search.php?q=%27${searchText.trim()}%27&format=jsonv2";

    final response = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        });
    var geocodedData = jsonDecode(response.body) as List<dynamic>;

    box.write("driver_destination_coordinates", {"lat": geocodedData[0]["lat"], "lon": geocodedData[0]["lon"]});
  }

  void updateUserPoints(String id, dynamic payload) async {
    const url = "https://shrimp-select-vertically.ngrok-free.app";

    await http.patch(
        Uri.parse("$url/users/$id"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(payload)
    );
  }

  @override
  void initState() {
    super.initState();
    final enteredDestination = ref.read(ridesFilterProvider);
    if (enteredDestination.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDestinationInputDialog();
      });
    }

    getRidesData();
  }

  @override
  Widget build(BuildContext context) {
    var filteredRequests = ridesData;

    SocketHandler.socket.on("Fetch Requests", (payload){
      getRidesData();
      filteredRequests = ridesData;
    });

    box.listenKey("driver_destination", (value){
      if(value == null || value.toString().isEmpty){
        return;
      }

      getCoordinatesForDriverDestination(value);

      Map<String, dynamic> payload = {
        "startPoint": null,
        "endPoint": box.read("driver_destination_coordinates")
      };

      updateUserPoints(box.read("_id"), payload);

      getRidesData();
      filteredRequests = ridesData;
    });

    String driverId = box.read("_id").toString();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ride Requests Near You",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color.fromRGBO(30, 60, 87, 1),
                    ),
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Container(
                    width: 165,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(30, 60, 87, 1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),

              const Spacer(),
              // Icon(Icons.filter_alt_outlined)
              InkWell(
                onTap: () {
                  _showDestinationInputDialog();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.only(
                      left: 6, right: 6, top: 6, bottom: 5),
                  decoration: BoxDecoration(
                    // color: const Color.fromARGB(255, 255, 107, 74),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const ImageIcon(
                    size: 20,
                    color: Color.fromRGBO(30, 60, 87, 1),
                    ResizeImage(
                        AssetImage('assets/icons/filter_rides_icon.png'),
                        width: 48,
                        height: 48),
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          (filteredRequests.isEmpty) ?
            const Padding(
            padding: EdgeInsets.only(top: 250),
            child: Center(
            child: Text("No ride requests found\nTry changing the filter", style: TextStyle(fontSize: 18), textAlign: TextAlign.center)),)
              :
          Expanded(
            child: ListView.builder(
              itemCount: filteredRequests.length,
              itemBuilder: (context, index) {

                if(filteredRequests.isEmpty){
                  return const Padding(
                    padding: EdgeInsets.only(top: 250),
                    child: Center(
                          child: Text("No ride requests found\nTry changing the filter", style: TextStyle(fontSize: 18), textAlign: TextAlign.center)),
                  );
                }
                final request = filteredRequests[index];
                if(request["requestedBy"]["_id"] == box.read("_id")){
                  return null;
                }
                bool isAccepted = false;

                List.castFrom(request["acceptedBy"]).forEach((driver){
                  if(driver["driver"]["_id"] == driverId){
                    isAccepted = true;
                    filteredRequests.remove(request);
                    return;
                  }
                });

                if(isAccepted){
                  return const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 250),
                          child: Text("No ride requests found\nTry changing the filter", style: TextStyle(fontSize: 18), textAlign: TextAlign.center),
                        ));
                }

                return Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 10, right: 10, bottom: 15, top: 5),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ("${request["requestedBy"]["firstName"] as String} ${request["requestedBy"]["lastName"] as String}"),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color.fromRGBO(30, 60, 87, 1),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.message,
                                color: Color.fromARGB(255, 255, 170, 42),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserChatScreen(
                                      fullName: "${request["requestedBy"]["firstName"] as String} ${request["requestedBy"]["lastName"] as String}",
                                      receiverId: request["requestedBy"]["_id"],
                                    ),
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Color.fromARGB(255, 255, 107, 74),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Flexible(
                              child: Text(
                                (request["pickup"] as String),
                                style: const TextStyle(fontSize: 14),
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.navigation,
                              color: Color.fromARGB(255, 255, 107, 74),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Flexible(
                              child: Text(
                                (request["destination"] as String),
                                style: const TextStyle(fontSize: 14),
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.currency_exchange,
                                    color: Color.fromARGB(255, 255, 170, 42),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Flexible(
                                    child: Text(
                                      (request["fare"].toString()),
                                      style: const TextStyle(fontSize: 14),
                                      softWrap: true,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.event_seat,
                                    color: Color.fromARGB(255, 255, 107, 74),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Flexible(
                                    child: Text(
                                      (request["seats"].toString()),
                                      style: const TextStyle(fontSize: 14),
                                      softWrap: true,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: 60,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 10.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  if(isAccepted){
                                    return;
                                  }
                                  acceptRequest(request['_id'], box.read("_id"));
                                  setState(() {
                                    ridesData.remove(request);
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  textStyle: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                                child: const Text("Accept"),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
