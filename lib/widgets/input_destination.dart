import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manzil_app_v2/screens/map_screen.dart';
import '../providers/booking_inputs_provider.dart';

class InputDestination extends ConsumerStatefulWidget {
  const InputDestination({super.key});

  @override
  ConsumerState<InputDestination> createState() => _InputDestinationState();
}

class _InputDestinationState extends ConsumerState<InputDestination> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _destinationController;
  List<double>? _selectedCoordinates;

  @override
  void initState() {
    super.initState();
    final bookingInputs = ref.read(bookingInputsProvider);
    _destinationController = TextEditingController(
        text: bookingInputs["destination"] as String? ?? ''
    );
    _selectedCoordinates = (bookingInputs["destinationCoordinates"] as List?)?.cast<double>();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  void _saveDestination() {
    if (_formKey.currentState!.validate()) {
      final notifier = ref.read(bookingInputsProvider.notifier);
      notifier.setDestination(_destinationController.text);
      if (_selectedCoordinates != null) {
        notifier.setDestinationCoordinates(_selectedCoordinates!);
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
            "Enter Your Destination",
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
                    controller: _destinationController,
                    cursorColor: const Color.fromARGB(255, 255, 170, 42),
                    style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onPrimary
                    ),
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
                          final result = await Navigator.push<Map<String, dynamic>>(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => const MapScreen("passengerDestination"),
                            ),
                          );

                          if (result != null && mounted) {
                            setState(() {
                              _destinationController.text = result['address'];
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
                        onPressed: _saveDestination,
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