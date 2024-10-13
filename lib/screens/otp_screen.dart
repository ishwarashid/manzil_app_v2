import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:otp_timer_button/otp_timer_button.dart';
import 'package:pinput/pinput.dart';

import '../main.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen(
      {super.key,
      required this.phoneNumber,
      });

  final String phoneNumber;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _pinController = TextEditingController();
  final OtpTimerButtonController _otpController = OtpTimerButtonController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  String getPhoneNumber() {
    return widget.phoneNumber;
  }

  void _sendCode() async {
    try {
      const url = "https://shrimp-select-vertically.ngrok-free.app";
      final response = await http.post(
        Uri.parse('$url/sendotp'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'phone': getPhoneNumber(),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isProcessing = false;
        });
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                OtpScreen(phoneNumber: getPhoneNumber()),
          ),
        );
      } else {
        throw Exception('Failed to send otp.');
      }

    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error Occurred: ${e.toString()}"),
        ),
      );
    }
  }

  void _signIn() async {
    try {
      const url = "https://shrimp-select-vertically.ngrok-free.app";
      final response = await http.post(
        Uri.parse('$url/verifyotp'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'phone': getPhoneNumber(),
          'otp': _pinController.text
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isProcessing = false;
        });

        final box = GetStorage();
        box.write('phoneNumber', getPhoneNumber());

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MyApp(),
          ),
        );
      } else {
        throw Exception('Failed to verify OTP. Please try again.');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Color.fromRGBO(30, 60, 87, 1),
      ),
      decoration: BoxDecoration(
        // color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.primary),
      ),
    );

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Phone verification",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 45, 45, 45),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              const Text(
                "Enter your OTP code",
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 160, 160, 160),
                ),
              ),
              const SizedBox(
                height: 32,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Pinput(
                  length: 6,
                  controller: _pinController,
                  defaultPinTheme: defaultPinTheme,
                ),
              ),
              const SizedBox(
                height: 60,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      textStyle: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    onPressed: _isProcessing
                        ? null
                        : () {
                            setState(() {
                              _isProcessing = true;
                            });
                            _signIn();
                          },
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : const Text("Verify"),
                  ),
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              OtpTimerButton(
                controller: _otpController,
                onPressed: () {
                  _sendCode();
                },
                text: const Text(
                  'Resend OTP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                duration: 30,
              )
            ],
          ),
        ),
      ),
    );
  }
}
