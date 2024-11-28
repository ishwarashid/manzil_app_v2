import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manzil_app_v2/screens/map_screen.dart';
import '../providers/booking_inputs_provider.dart';

class InputPickup extends ConsumerStatefulWidget {
  const InputPickup({super.key});

  @override
  ConsumerState<InputPickup> createState() => _InputPickupState();
}

class _InputPickupState extends ConsumerState<InputPickup> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _pickupController;
  List<double>? _selectedCoordinates;

  @override
  void initState() {
    super.initState();
    final bookingInputs = ref.read(bookingInputsProvider);
    _pickupController = TextEditingController(
        text: bookingInputs["pickup"] as String? ?? ''
    );
    _selectedCoordinates = (bookingInputs["pickupCoordinates"] as List?)?.cast<double>();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    super.dispose();
  }

  void _savePickup() {
    if (_formKey.currentState!.validate()) {
      final notifier = ref.read(bookingInputsProvider.notifier);
      notifier.setPickup(_pickupController.text);
      if (_selectedCoordinates != null) {
        notifier.setPickupCoordinates(_selectedCoordinates!);
      }
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
          const SizedBox(height: 60),
          Expanded(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextFormField(
                    controller: _pickupController,
                    cursorColor: const Color.fromARGB(255, 255, 170, 42),
                    style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onPrimary
                    ),
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
                            color: Color.fromARGB(255, 255, 170, 42),
                            width: 2
                        ),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(160, 255, 255, 255),
                            width: 2
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                            width: 2
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                            width: 2
                        ),
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
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          print("here");
                          final result = await Navigator.push<Map<String, dynamic>>(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => const MapScreen('pickup'),
                            ),
                          );
                          print("pickup from map: $result");

                          if (result != null && mounted) {
                            setState(() {
                              _pickupController.text = result['address'];
                              _selectedCoordinates = result['coordinates'] as List<double>;
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.map_outlined,
                          color: Color.fromARGB(255, 255, 170, 42),
                          size: 30,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _savePickup,
                        style: ElevatedButton.styleFrom(
                          elevation: 0.0,
                          backgroundColor: const Color.fromARGB(100, 255, 170, 42),
                          foregroundColor: const Color.fromARGB(255, 255, 170, 42),
                          textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500
                          ),
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