import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:manzil_app_v2/screens/otp_screen.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  String _phoneNumber = '';
  final _phoneNumberController = TextEditingController();
  bool _isProcessing = false;

  String _formatPhoneNumber() {
    final userPhoneNo = _phoneNumberController.text;
    if (userPhoneNo[0] == '0') {
      return "+92${userPhoneNo.substring(1)}";
    }
    return "+92$userPhoneNo";
  }

  Future<int> _sendCode() async {
      const url = "https://shrimp-select-vertically.ngrok-free.app";
      final response = await http.post(
        Uri.parse('$url/sendotp'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'phone': _phoneNumber,
        }),
      );

      return response.statusCode;
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          // mainAxisSize: MainAxisSize.max,
          children: [
            Image.asset(
              'assets/images/phone_screen_illustration.png',
              width: 300,
            ),
            const SizedBox(
              height: 24,
            ),
            const Text(
              "Verify Your Phone",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(255, 45, 45, 45),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  TextField(
                    controller: _phoneNumberController,
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                    decoration: const InputDecoration(
                      label: Text("Enter Phone Number",
                          style: TextStyle(fontSize: 18)),
                      prefixIcon: Icon(
                        Icons.phone,
                      ),
                      prefix: Padding(
                        padding: EdgeInsets.fromLTRB(0, 0, 8, 0),
                        child: Text(
                          "+92",
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(
                    height: 60,
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        textStyle: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      onPressed: _isProcessing
                          ? null
                          : () {
                              // print(_phoneNumberController.text);
                              setState(() {
                                _isProcessing = true;
                              });
                              // FocusScope.of(context).requestFocus(FocusNode());
                              FocusScope.of(context).unfocus();
                              _phoneNumber = _formatPhoneNumber();
                              _sendCode().then((statusCode){
                                if (statusCode == 200) {
                                  setState(() {
                                    _isProcessing = false;
                                  });
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          OtpScreen(phoneNumber: _phoneNumber),
                                    ),
                                  );
                                } else {
                                  setState(() {
                                    _isProcessing = false;
                                  });
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Error Occurred: Failed to send otp."),
                                    ),
                                  );
                                }
                              });
                            },
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  // color: Theme.of(context).colorScheme.onPrimary,
                                  // backgroundColor: Theme.of(context).colorScheme.primary,
                                  ),
                            )
                          : const Text("Receive OTP"),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
