import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'checkout_screen.dart';
import '../widgets/bg_scaffold.dart';

class ExploreScreen extends StatefulWidget {
  final Map<String, dynamic>? currentUser;
  const ExploreScreen({super.key,this.currentUser,});
  

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final MapController _mapController = MapController();
  final _scrollController = ScrollController();
  final List<GlobalKey> _listItemKeys = [];

  Future<List<dynamic>>? _venuesFuture;
  Position? _userPosition;
  bool _locationLoading = true;
  int? _selectedVenueIndex;

  static const double _radiusKm = 10.0;
  static const LatLng _fallbackCenter = LatLng(25.2048, 55.2708); // Dubai

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          );
          _userPosition = pos;
          // Fly map to user location
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(
              LatLng(pos.latitude, pos.longitude),
              13.0,
            );
          });
        }
      }
    } catch (_) {
      // Silently fall back
    }

    setState(() {
      _locationLoading = false;
      _venuesFuture = ApiService.getExploreVenues(
        lat: _userPosition?.latitude,
        lng: _userPosition?.longitude,
        radius: _radiusKm,
      );
    });
  }

  String _ratingText(dynamic v) {
    final raw = v['avg_rating'];
    if (raw == null) return 'No ratings yet';
    double? rating;
    if (raw is num) {
      rating = raw.toDouble();
    } else if (raw is String) {
      rating = double.tryParse(raw);
    }
    if (rating == null) return 'No ratings yet';
    return rating.toStringAsFixed(1);
  }

  String _distanceText(dynamic v) {
    final raw = v['distance_km'];
    if (raw == null) return '';
    double? d;
    if (raw is num) d = raw.toDouble();
    else if (raw is String) d = double.tryParse(raw);
    if (d == null) return '';
    return '${d.toStringAsFixed(1)} km';
  }

  void _onVenueSelected(int index, dynamic v) {
    setState(() => _selectedVenueIndex = index);

    // Fly map to venue
    final lat = v['latitude'] is num
        ? (v['latitude'] as num).toDouble()
        : double.tryParse('${v['latitude']}');
    final lng = v['longitude'] is num
        ? (v['longitude'] as num).toDouble()
        : double.tryParse('${v['longitude']}');
    if (lat != null && lng != null) {
      _mapController.move(LatLng(lat, lng), 15.0);
    }

    // Scroll list to selected item
    if (index < _listItemKeys.length) {
      final ctx = _listItemKeys[index].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BgScaffold(
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Explore',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5)),
                    Text(
                      _locationLoading
                          ? 'Finding your location...'
                          : _userPosition != null
                              ? 'Venues within ${_radiusKm.toInt()} km of you'
                              : 'All venues',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.55)),
                    ),
                  ],
                ),
                // Re-center button
                GestureDetector(
                  onTap: () {
                    if (_userPosition != null) {
                      _mapController.move(
                        LatLng(_userPosition!.latitude,
                            _userPosition!.longitude),
                        13.0,
                      );
                    }
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _userPosition != null
                          ? AppColors.gold
                          : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.my_location_rounded,
                        color: _userPosition != null
                            ? AppColors.navy
                            : Colors.white54,
                        size: 20),
                  ),
                ),
              ],
            ),
          ),

          // ── Map ───────────────────────────────────────────────────
          SizedBox(
            height: 260,
            child: _locationLoading
                ? Container(
                    color: AppColors.cardBg,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Getting your location...',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                : FutureBuilder<List<dynamic>>(
                    future: _venuesFuture,
                    builder: (context, snapshot) {
                      final venues = snapshot.data ?? [];
                      final markers = <Marker>[];

                      // User location marker
                      if (_userPosition != null) {
                        markers.add(Marker(
                          point: LatLng(_userPosition!.latitude,
                              _userPosition!.longitude),
                          width: 60,
                          height: 60,
                          child: const _UserLocationMarker(),
                        ));
                      }

                      // Venue markers
                      for (int i = 0; i < venues.length; i++) {
                        final v = venues[i];
                        final lat = v['latitude'] is num
                            ? (v['latitude'] as num).toDouble()
                            : double.tryParse('${v['latitude']}');
                        final lng = v['longitude'] is num
                            ? (v['longitude'] as num).toDouble()
                            : double.tryParse('${v['longitude']}');
                        if (lat == null || lng == null) continue;

                        final isSelected = _selectedVenueIndex == i;
                        markers.add(Marker(
                          point: LatLng(lat, lng),
                          width: isSelected ? 150 : 44,
                          height: isSelected ? 60 : 44,
                          child: GestureDetector(
                            onTap: () => _onVenueSelected(i, v),
                            child: isSelected
                                ? _SelectedVenueMarker(name: v['name'] ?? '')
                                : const _VenuePinMarker(),
                          ),
                        ));
                      }

                      return FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _userPosition != null
                              ? LatLng(_userPosition!.latitude,
                                  _userPosition!.longitude)
                              : _fallbackCenter,
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
                      );
                    },
                  ),
          ),

          // ── Venue list ────────────────────────────────────────────
          Expanded(
            child: _locationLoading
                ? const SizedBox.shrink()
                : FutureBuilder<List<dynamic>>(
                    future: _venuesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(
                            child: Text('Error loading venues'));
                      }
                      final venues = snapshot.data ?? [];

                      // Ensure we have enough keys
                      while (_listItemKeys.length < venues.length) {
                        _listItemKeys.add(GlobalKey());
                      }

                      if (venues.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.navy.withOpacity(0.06),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.search_off_rounded,
                                    color: AppColors.textMuted, size: 34),
                              ),
                              const SizedBox(height: 14),
                              const Text('No venues nearby',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 6),
                              const Text(
                                  'Try expanding the radius or check back later',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        controller: _scrollController,
                        padding:
                            const EdgeInsets.fromLTRB(16, 14, 16, 100),
                        itemCount: venues.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final v = venues[i];
                          final isSelected = _selectedVenueIndex == i;
                          final dist = _distanceText(v);
                          final rating = _ratingText(v);

                          return GestureDetector(
                            key: _listItemKeys[i],
                            onTap: () => _onVenueSelected(i, v),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: isSelected
                                    ? Border.all(
                                        color: AppColors.navy, width: 2)
                                    : Border.all(
                                        color: Colors.transparent,
                                        width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.navy.withOpacity(
                                        isSelected ? 0.12 : 0.05),
                                    blurRadius: isSelected ? 16 : 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Thumbnail
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(14),
                                      bottomLeft: Radius.circular(14),
                                    ),
                                    child: Image.network(
                                      v['image_url'] ?? '',
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Container(
                                        width: 90,
                                        height: 90,
                                        color: AppColors.cardBg,
                                        child: const Icon(
                                            Icons.image_not_supported,
                                            color: AppColors.textMuted),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Info
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(v['name'] ?? '',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                  color:
                                                      AppColors.textPrimary),
                                              overflow:
                                                  TextOverflow.ellipsis),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              const Icon(Icons.star_rounded,
                                                  color: AppColors.gold,
                                                  size: 13),
                                              const SizedBox(width: 3),
                                              Text(rating,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .textSecondary)),
                                              if (dist.isNotEmpty) ...[
                                                const SizedBox(width: 8),
                                                const Icon(
                                                    Icons.near_me_rounded,
                                                    size: 11,
                                                    color:
                                                        AppColors.textMuted),
                                                const SizedBox(width: 2),
                                                Text(dist,
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppColors
                                                            .textMuted)),
                                              ],
                                            ],
                                          ),
                                          if (v['address'] != null) ...[
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                const Icon(
                                                    Icons.location_on_rounded,
                                                    size: 11,
                                                    color:
                                                        AppColors.textMuted),
                                                const SizedBox(width: 2),
                                                Expanded(
                                                  child: Text(v['address'],
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppColors
                                                              .textSecondary),
                                                      overflow: TextOverflow
                                                          .ellipsis),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Price + button
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        right: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '\$${v['price']}',
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.navy),
                                        ),
                                        const SizedBox(height: 6),
                                        GestureDetector(
                                          onTap: () =>{print('current user2: ${widget.currentUser}'),
                                              Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => CheckoutScreen(
                                                  venueId: v['id'], currentUser: widget.currentUser),
                                            ),
                                          ),},
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.navy,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      10),
                                            ),
                                            child: const Text('Book',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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

// ── Marker Widgets ────────────────────────────────────────────────────────────

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing outer ring
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.navy.withOpacity(0.15),
          ),
        ),
        // White border ring
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
        // Blue dot
        Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }
}

class _VenuePinMarker extends StatelessWidget {
  const _VenuePinMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.gold,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.stadium_rounded,
          color: AppColors.navy, size: 16),
    );
  }
}

class _SelectedVenueMarker extends StatelessWidget {
  final String name;
  const _SelectedVenueMarker({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            name,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        CustomPaint(
          size: const Size(12, 6),
          painter: _TrianglePainter(color: AppColors.navy),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}