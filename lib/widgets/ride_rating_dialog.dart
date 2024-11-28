import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RideRatingDialog extends StatefulWidget {
  final String driverName;

  const RideRatingDialog({
    required this.driverName,
    super.key,
  });

  @override
  State<RideRatingDialog> createState() => _RideRatingDialogState();
}

class _RideRatingDialogState extends State<RideRatingDialog> {
  double _rating = 0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate Your Ride'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How was your ride with ${widget.driverName}?'),
            const SizedBox(height: 20),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () {
            Navigator.of(context).pop(null);
          },
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: _isSubmitting || _rating == 0
              ? null
              : () {
            Navigator.of(context).pop({
              'rating': _rating,
            });
          },
          child: _isSubmitting
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : const Text('Submit'),
        ),
      ],
    );
  }
}