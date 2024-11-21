import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:manzil_app_v2/screens/home_screen.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  var isLoading = false;

  final _formKey = GlobalKey<FormState>();
  var _firstName = '';
  var _lastName = '';
  var _emailAddress = '';

   Future<int> _saveData() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      const url = "https://shrimp-select-vertically.ngrok-free.app";

      final box = GetStorage();

      String payload = jsonEncode(<String, String>{
        'phone': box.read('phoneNumber').toString(),
        'firstName': _firstName,
        'lastName': _lastName,
        'email': _emailAddress
      });

      setState(() => isLoading=true);

      final response = await http.post(
        Uri.parse('$url/users'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: payload
      );

      return response.statusCode;
    }

    return 500;
   }


  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Let's Get Started",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 45, 45, 45),
                  ),
                ),
                const SizedBox(
                  height: 60,
                ),
                Form(
                    key: _formKey,
                    child: Padding(
                      padding: EdgeInsets.only(left: 30, bottom: keyboardSpace, right: 30),
                      child: Column(
                        children: [
                          TextFormField(
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                label: Text(
                                  "First Name",
                                  style: TextStyle(fontSize: 18),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14)),
                            style: const TextStyle(fontSize: 18),
                            textCapitalization: TextCapitalization.sentences,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Must not be empty.';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              _firstName = newValue!;
                            },
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          TextFormField(
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                label: Text("Last Name",
                                    style: TextStyle(fontSize: 18)),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14)),
                            style: const TextStyle(fontSize: 18),
                            textCapitalization: TextCapitalization.sentences,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Must not be empty.';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              _lastName = newValue!;
                            },
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          TextFormField(
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                label: Text("Email Address",
                                    style: TextStyle(fontSize: 18)),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14)),
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 18),
                            validator: (value) {
      
                              String emailRegex =
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
                              RegExp regex = RegExp(emailRegex);
      
                              if(value == null || value.isEmpty){
                                return 'Must not be empty.';
                              }
      
                              if (!regex.hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              _emailAddress = newValue!;
                            },
                          ),
                          const SizedBox(
                            height: 60,
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                textStyle: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w500),
                              ),
                              onPressed: () {
                                _saveData().then((value)=>{
                                  if(value == 200){
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => const HomeScreen(),
                                      )
                                    )
                                  }
                                });
                              },
                              child:  isLoading? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)) : const Text("Finish Setup")
                            ),
                          )
                        ],
                      ),
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
