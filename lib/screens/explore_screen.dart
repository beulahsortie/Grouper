import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../models/venue.dart';
import 'checkout_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final Future<List<dynamic>> _venuesFuture;
  final MapController _mapController = MapController();
  int? _selectedVenueIndex;

  // Default center — update to your city's coordinates
  static const LatLng _defaultCenter = LatLng(17.3850, 78.4867); // Hyderabad

  @override
  void initState() {
    super.initState();
    _venuesFuture = ApiService.getExploreVenues();
  }

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
    return '${rating.toStringAsFixed(1)} ★  (${v['review_count'] ?? 0} reviews)';
  }

  void _flyToVenue(dynamic v) {
    final lat = v['latitude'] != null
        ? (v['latitude'] is num
            ? (v['latitude'] as num).toDouble()
            : double.tryParse('${v['latitude']}'))
        : null;
    final lng = v['longitude'] != null
        ? (v['longitude'] is num
            ? (v['longitude'] as num).toDouble()
            : double.tryParse('${v['longitude']}'))
        : null;
    if (lat != null && lng != null) {
      _mapController.move(LatLng(lat, lng), 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<dynamic>>(
        future: _venuesFuture,
        builder: (context, snapshot) {
          final venues = snapshot.data ?? [];
          final hasData = snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasError;

          // Build markers from venue data
          final markers = <Marker>[];
          if (hasData) {
            for (int i = 0; i < venues.length; i++) {
              final v = venues[i];
              final lat = v['latitude'] != null
                  ? (v['latitude'] is num
                      ? (v['latitude'] as num).toDouble()
                      : double.tryParse('${v['latitude']}'))
                  : null;
              final lng = v['longitude'] != null
                  ? (v['longitude'] is num
                      ? (v['longitude'] as num).toDouble()
                      : double.tryParse('${v['longitude']}'))
                  : null;

              if (lat != null && lng != null) {
                final isSelected = _selectedVenueIndex == i;
                markers.add(
                  Marker(
                    point: LatLng(lat, lng),
                    width: isSelected ? 140 : 40,
                    height: isSelected ? 56 : 40,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedVenueIndex =
                              isSelected ? null : i;
                        });
                      },
                      child: isSelected
                          ? _SelectedMarker(name: v['name'] ?? '')
                          : const _PinMarker(),
                    ),
                  ),
                );
              }
            }
          }

          return Column(
            children: [
              // ── Map ──────────────────────────────────────────────
              SizedBox(
                height: 240,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _defaultCenter,
                      initialZoom: 13.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.grouper',
                      ),
                      MarkerLayer(markers: markers),
                    ],
                  ),
                ),
              ),

              // ── Venue list ────────────────────────────────────────
              Expanded(
                child: Builder(builder: (_) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading venues'));
                  }
                  if (venues.isEmpty) {
                    return const Center(child: Text('No venues found'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: venues.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final v = venues[i];
                      final isSelected = _selectedVenueIndex == i;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Card(
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                _selectedVenueIndex = isSelected ? null : i;
                              });
                              _flyToVenue(v);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  // Thumbnail
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      v['image_url'] ?? '',
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 64,
                                        height: 64,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image_not_supported),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          v['name'] ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _ratingText(v),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600]),
                                        ),
                                        if (v['address'] != null) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(Icons.location_on,
                                                  size: 12,
                                                  color: Colors.grey[500]),
                                              const SizedBox(width: 2),
                                              Expanded(
                                                child: Text(
                                                  v['address'],
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[500]),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Select button
                                  ElevatedButton(
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
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Custom marker widgets ─────────────────────────────────────────────────────

class _PinMarker extends StatelessWidget {
  const _PinMarker();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.location_pin,
      color: Colors.deepPurple,
      size: 40,
    );
  }
}

class _SelectedMarker extends StatelessWidget {
  final String name;
  const _SelectedMarker({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            name,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Icon(Icons.location_pin, color: Colors.deepPurple, size: 24),
      ],
    );
  }
}