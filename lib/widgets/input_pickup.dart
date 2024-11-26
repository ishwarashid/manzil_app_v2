import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/booking_inputs_provider.dart';

class InputPickup extends ConsumerStatefulWidget {
  const InputPickup({super.key});

  @override
  ConsumerState<InputPickup> createState() => _InputPickupState();
}

class _InputPickupState extends ConsumerState<InputPickup> {
  final _formKey = GlobalKey<FormState>();

  var _enteredPickup = '';

  @override
  void initState() {
    super.initState();
    final bookingInputs = ref.read(bookingInputsProvider);
    _enteredPickup = bookingInputs["pickup"] as String? ?? '';
  }

  void _saveDestination() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      ref
          .read(bookingInputsProvider.notifier)
          .setPickup(_enteredPickup);
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
            "Enter Your Pickup Location",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(200, 255, 255, 255),
            ),
          ),
          const SizedBox(height: 60,),
          Expanded(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextFormField(
                    initialValue: _enteredPickup.isNotEmpty ? _enteredPickup : null,
                    cursorColor: const Color.fromARGB(255, 255, 170, 42),
                    style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onPrimary),
                    decoration: InputDecoration(
                      label: const Text(
                        'From',
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
                      _enteredPickup = value!;
                    },
                  ),
                  const SizedBox(height: 30,),
                  ElevatedButton(
                    onPressed: _saveDestination,
                    style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                      backgroundColor:
                      const Color.fromARGB(100, 255, 170, 42),
                      foregroundColor: const Color.fromARGB(255, 255, 170, 42),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    child: const Text("Set"),
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
