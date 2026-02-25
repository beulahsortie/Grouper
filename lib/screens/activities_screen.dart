import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<dynamic>>(
        future: ApiService.getOrderHistory(1), // Demo: userId=1
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading activities'));
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('No activities found'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final order = orders[i];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(order['venue_name'] ?? 'Venue'),
                subtitle: Text(order['time'] ?? ''),           // ← 'time' not 'date'
                trailing: Text('₹${order['amount'] ?? ''}'),   // ← 'amount' comes from v.price now
              );
            },
          );
        },
      ),
    );
  }
}
