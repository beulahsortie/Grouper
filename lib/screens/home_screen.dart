import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/venue.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _expanded = false;
  late final Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = Future.wait([ApiService.getCategories(), ApiService.getVenues()]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  height: _expanded ? 200 : 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search),
                      const SizedBox(width: 8),
                      if (!_expanded) const Expanded(child: Text('Search')),
                      if (_expanded)
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(border: InputBorder.none, hintText: 'Search venues, categories...'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Hero(
                tag: 'banner',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=1200',
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Categories', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<dynamic>>(
                future: _dataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    return SizedBox(height: 100, child: Center(child: Text('Error loading categories')));
                  }
                  final categories = snapshot.data![0] as List<Category>;
                  return SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (c, i) {
                        final cat = categories[i];
                        return Column(
                          children: [
                            CircleAvatar(radius: 30, backgroundImage: NetworkImage(cat.imageUrl)),
                            const SizedBox(height: 8),
                            SizedBox(width: 72, child: Text(cat.title, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
                          ],
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemCount: categories.length,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text('Venues', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              FutureBuilder<List<dynamic>>(
                future: _dataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    return SizedBox(height: 220, child: Center(child: Text('Error loading venues')));
                  }
                  final venues = snapshot.data![1] as List<Venue>;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.78, crossAxisSpacing: 12, mainAxisSpacing: 12),
                    itemCount: venues.length,
                    itemBuilder: (c, i) {
                      final v = venues[i];
                      return GestureDetector(
                        onTap: () {},
                        child: Container(
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Image.network(v.imageUrl, height: 110, width: double.infinity, fit: BoxFit.cover),
                              ),
                              const SizedBox(height: 8),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(v.name, style: theme.textTheme.bodyMedium)),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text('\$${v.price.toStringAsFixed(2)} / night', style: theme.textTheme.bodySmall)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
