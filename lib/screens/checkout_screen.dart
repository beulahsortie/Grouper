
import 'package:flutter/material.dart';
import '../models/venue.dart';
import '../services/api_service.dart';

class CheckoutScreen extends StatelessWidget {
  final int venueId;
  CheckoutScreen({required this.venueId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: FutureBuilder<List<Venue>>(
        future: ApiService.getVenues(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading venue'));
          }
          final venue = snapshot.data!.firstWhere((v) => v.id == venueId, orElse: () => Venue(id: 0, name: 'Unknown', price: 0, imageUrl: ''));
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(venue.name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('\$${venue.price.toStringAsFixed(0)} / night', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                const Text('Time'),
                const SizedBox(height: 8),
                Row(children: const [Icon(Icons.schedule), SizedBox(width: 8), Text('02:00 pm | 3 hrs')]),
                const SizedBox(height: 12),
                const Text('Description'),
                const SizedBox(height: 8),
                const Text('This venue is near the Metro Station and at around 200mts walking distance.'),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ApiService.createBooking(
                        userId: 1, // Demo user
                        venueId: venue.id,
                        amount: venue.price,
                        date: DateTime.now().toIso8601String(),
                      );
                      showDialog<void>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Confirmed'),
                          content: const Text('Booking confirmed'),
                          actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK'))],
                        ),
                      );
                    } catch (e) {
                      showDialog<void>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Error'),
                          content: Text('Failed to confirm booking: $e'),
                          actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK'))],
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: const Text('CONFIRM'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
