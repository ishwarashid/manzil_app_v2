import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manzil_app_v2/main.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({
    super.key,
    required this.phoneNumber,
  });

  final String phoneNumber;

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  final _formKey = GlobalKey<FormState>();
  var _firstName = '';
  var _lastName = '';
  var _emailAddress = '';

  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      print("inside save data");
      // print(FirebaseAuth.instance.currentUser!.uid);
      // print(FirebaseAuth.instance.currentUser!.phoneNumber);
      await FirebaseFirestore.instance.collection("users").add({
        "phone_number": widget.phoneNumber,
        "first_name": _firstName,
        "last_name": _lastName,
        "email": _emailAddress,
      });

      Navigator.of(context).pop();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MyApp(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(),
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
                    padding: EdgeInsets.only(
                        left: 30, bottom: keyboardSpace, right: 30),
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
                            if (value == null || value.isEmpty) {
                              return 'Must not be empty.';
                            }
                            String emailRegex =
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
                            RegExp regex = RegExp(emailRegex);
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
                              _saveData();

                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (ctx) => const MyApp(),
                              //   ),
                              // );
                            },
                            child: const Text("Finish Setup"),
                          ),
                        )
                      ],
                    ),
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
