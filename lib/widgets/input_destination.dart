import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manzil_app_v2/screens/booking.dart';

import '../providers/booking_inputs_provider.dart';

class InputDestination extends ConsumerStatefulWidget {
  const InputDestination({super.key});

  @override
  ConsumerState<InputDestination> createState() => _InputDestinationState();
}

class _InputDestinationState extends ConsumerState<InputDestination> {
  final _formKey = GlobalKey<FormState>();

  var _enteredDestination = '';

  @override
  void initState() {
    super.initState();
    final bookingInputs = ref.read(bookingInputsProvider);
    _enteredDestination = bookingInputs["destination"] as String? ?? '';
  }

  void _saveDestination() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      ref
          .read(bookingInputsProvider.notifier)
          .setDestination(_enteredDestination);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 100, bottom: 60, right: 30, left: 30),
      child: Column(
        children: [
          const Text(
            "Enter Your Destination",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(200, 255, 255, 255),
            ),
          ),
          const SizedBox(
            height: 60,
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextFormField(
                    initialValue: _enteredDestination.isNotEmpty
                        ? _enteredDestination
                        : null,
                    cursorColor: const Color.fromARGB(255, 255, 170, 42),
                    style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onPrimary),
                    decoration: InputDecoration(
                      label: const Text(
                        'To',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color.fromARGB(160, 255, 255, 255),
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(255, 255, 170, 42), width: 2),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(160, 255, 255, 255),
                            width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                            width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                            width: 2),
                      ),
                      contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          value.trim().length <= 1 ||
                          value.trim().length > 255) {
                        return 'Must be between 1 and 255 characters.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _enteredDestination = value!;
                    },
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => const Booking(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.map_outlined,
                          color: Color.fromARGB(255, 255, 170, 42),
                          size: 30,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _saveDestination,
                        style: ElevatedButton.styleFrom(
                          elevation: 0.0,
                          backgroundColor:
                              const Color.fromARGB(100, 255, 170, 42),
                          foregroundColor:
                              const Color.fromARGB(255, 255, 170, 42),
                          textStyle: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        child: const Text("Set"),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
