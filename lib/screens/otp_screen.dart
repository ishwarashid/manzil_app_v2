import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:manzil_app_v2/main.dart';
import 'package:manzil_app_v2/screens/home_screen.dart';
import 'package:manzil_app_v2/screens/get_started_screen.dart';
import 'package:pinput/pinput.dart';
import 'dart:convert';
import 'package:otp_timer_button/otp_timer_button.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen(
      {super.key,
      required this.vid,
      required this.phoneNumber,
      required this.resendToken});

  final String vid;
  final String phoneNumber;
  final int? resendToken;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _pinController = TextEditingController();
  final OtpTimerButtonController _otpController = OtpTimerButtonController();
  bool _isProcessing = false;

  String _vid = '';
  int? _resendToken = 0;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  // void isNumberAlreadyExist() async {}

  // var code = '';
  // void _savePhoneNumber() async {}

  String getPhoneNumber() {
    return widget.phoneNumber;
  }

  String _getVid() {
    if (_vid != '') {
      return _vid;
    }
    return widget.vid;
  }

  int? _getResendToken() {
    if (_resendToken != 0) {
      return _resendToken;
    }
    return widget.resendToken;
  }

  Future<bool> _sendOTP(
      {required String phoneNumber, required int? token}) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error Occurred: ${e.code}"),
            ),
          );
        },
        codeSent: (String vid, int? token) {
          _vid = vid;
          _resendToken = token;
        },
        timeout: const Duration(seconds: 25),
        forceResendingToken: _resendToken,
        codeAutoRetrievalTimeout: (vid) {});
    return true;
  }

  void _signIn() async {
    PhoneAuthCredential credentials = PhoneAuthProvider.credential(
        verificationId: _getVid(), smsCode: _pinController.text);

    try {
      final userCredentials =
          await FirebaseAuth.instance.signInWithCredential(credentials);

      final DocumentSnapshot document = await FirebaseFirestore.instance
          .collection("users")
          .doc(userCredentials.user!.uid)
          .get();
      if (!document.exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const GetStartedScreen(),
          ),
        );
      } else {
        Navigator.pop(context);
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => const MyApp(),
        //   ),
        // );

        // Navigator.popUntil(context, ModalRoute.withName('/'));
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.code),
        ),
      );
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
                            // print(_pinController.text);
                            setState(() {
                              _isProcessing = true;
                            });
                            _signIn();
                          },
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(),
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
                  _sendOTP(
                    phoneNumber: widget.phoneNumber,
                    token: _getResendToken(),
                  );
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

              // TextButton(
              //   onPressed: () {
              //     _sendOTP(phoneNumber: widget.phoneNumber, token: _getResendToken());
              //   },
              //   child: const Text(
              //     "Resend again",
              //     style: TextStyle(
              //       fontSize: 16,
              //       fontWeight: FontWeight.w600,
              //       // color: Color.fromARGB(255, 90, 90, 90),
              //     ),
              //     // style: TextButton.styleFrom(padding: EdgeInsets.zero)
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
