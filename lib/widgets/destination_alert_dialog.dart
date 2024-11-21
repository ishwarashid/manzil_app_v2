import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:manzil_app_v2/providers/rides_filter_provider.dart';

class DestinationAlertDialog extends ConsumerStatefulWidget {
  const DestinationAlertDialog({super.key});

  @override
  ConsumerState<DestinationAlertDialog> createState() =>
      _DestinationAlertDialogState();
}

class _DestinationAlertDialogState
    extends ConsumerState<DestinationAlertDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _destinationController;
  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    final destination = ref.read(ridesFilterProvider);
    _destinationController = TextEditingController(text: destination);
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  void _filterRides() {
    ref
        .read(ridesFilterProvider.notifier)
        .setDestination(_destinationController.text);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final destination = ref.watch(ridesFilterProvider);

    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.primary,
      title: const Text(
        'Where are you going?',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color.fromARGB(200, 255, 255, 255),
        ),
      ),
      content: SizedBox(
        height: 120,
        child: Container(
          margin: const EdgeInsets.only(top: 15),
          child: Form(
            key: _formKey,
            child: TextFormField(
              controller: _destinationController,
              style: TextStyle(
                  fontSize: 18, color: Theme.of(context).colorScheme.onPrimary),
              decoration: const InputDecoration(
                label: Text(
                  'To',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color.fromARGB(160, 255, 255, 255),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Color.fromARGB(255, 255, 170, 42), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Color.fromARGB(160, 255, 255, 255), width: 2),
                ),
                contentPadding: EdgeInsets.fromLTRB(12, 16, 12, 16),
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (destination.isNotEmpty) {
              ref.read(ridesFilterProvider.notifier).setDestination('');
              _destinationController.clear();
              box.remove("driver_destination");
            } else {
              Navigator.of(context).pop();
            }
          },
          child: Text(
            destination.isNotEmpty ? 'Reset' : 'Cancel',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary, fontSize: 16),
          ),
        ),
        ElevatedButton(
          onPressed: _filterRides,
          style: ElevatedButton.styleFrom(
              elevation: 0.0,
              backgroundColor: const Color.fromARGB(100, 255, 170, 42),
              foregroundColor: const Color.fromARGB(255, 255, 170, 42)),
          child: const Text(
            'Submit',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
