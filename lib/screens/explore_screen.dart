import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'checkout_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  String _ratingText(dynamic v) {
    final raw = v['avg_rating'];
    if (raw == null) return 'No rating';

    double? rating;

    if (raw is num) {
      rating = raw.toDouble();
    } else if (raw is String) {
      rating = double.tryParse(raw);
    }

    if (rating == null) return 'No rating';

    return '${rating.toStringAsFixed(1)} (${v['review_count'] ?? 0} reviews)';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            height: 220,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueGrey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('Map / Location Placeholder'),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: ApiService.getExploreVenues(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading venues'));
                }

                final venues = snapshot.data ?? [];

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: venues.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (c, i) {
                    final v = venues[i];

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            v['image_url'] ?? '',
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(v['name'] ?? ''),
                        subtitle: Text(_ratingText(v)),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CheckoutScreen(venueId: v['id']),
                              ),
                            );
                          },
                          child: const Text('Select'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
