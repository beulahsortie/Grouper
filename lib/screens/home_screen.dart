import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/category.dart';
import '../models/venue.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../screens/checkout_screen.dart';
import '../screens/create_venue_screen.dart';
import '../widgets/bg_scaffold.dart';

// ── Banner data ───────────────────────────────────────────────────────────────

class _BannerItem {
  final String imageUrl;
  final String tag;
  final String title;
  final String cta;
  const _BannerItem({
    required this.imageUrl,
    required this.tag,
    required this.title,
    required this.cta,
  });
}

const _banners = [
  _BannerItem(
    imageUrl: 'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=1200',
    tag: 'Featured',
    title: 'Top Football\nGrounds Near You',
    cta: 'Book Now →',
  ),
  _BannerItem(
    imageUrl: 'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=1200',
    tag: 'Popular',
    title: 'Find a Basketball\nCourt Today',
    cta: 'Explore →',
  ),
  _BannerItem(
    imageUrl: 'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=1200',
    tag: 'New',
    title: 'Padel Courts\nNow Available',
    cta: 'See Venues →',
  ),
  _BannerItem(
    imageUrl: 'https://images.unsplash.com/photo-1560090995-01632a28895b?w=1200',
    tag: 'Hot Deal',
    title: 'Swim Lanes\nAt Great Prices',
    cta: 'View Deals →',
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  final bool isLoggedIn;
  final Map<String, dynamic>? currentUser;
  final VoidCallback? onGoToLogin;

  const HomeScreen({
    super.key,
    this.isLoggedIn = false,
    this.currentUser,
    this.onGoToLogin,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> _dataFuture;
  final _searchController = TextEditingController();
  bool _searchActive = false;
  String _searchQuery = '';
  int? _selectedCategoryId;
  Position? _userPosition;

  // Banner
  final _bannerController = PageController();
  int _bannerPage = 0;
  Timer? _bannerTimer;

  // Cached data for filtering
  List<Venue> _allVenues = [];
  List<Category> _allCategories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _startBannerTimer();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        // Clear category selection when user starts typing
        if (_searchQuery.isNotEmpty) _selectedCategoryId = null;
      });
    });
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final next = (_bannerPage + 1) % _banners.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _loadData() {
    _dataFuture = _fetchWithLocation();
  }

  Future<List<dynamic>> _fetchWithLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          _userPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          );
        }
      }
    } catch (_) {}

    final results = await Future.wait([
      ApiService.getCategories(),
      ApiService.getVenues(
        lat: _userPosition?.latitude,
        lng: _userPosition?.longitude,
      ),
    ]);

    _allCategories = results[0] as List<Category>;
    _allVenues = results[1] as List<Venue>;
    return results;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  Future<void> _openCreateVenue() async {
    if (!widget.isLoggedIn) {
      widget.onGoToLogin?.call();
      return;
    }
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) =>
              CreateVenueScreen(currentUser: widget.currentUser)),
    );
    if (created == true) setState(() => _loadData());
  }

  void _onCategoryTap(int categoryId) {
    setState(() {
      _selectedCategoryId =
          _selectedCategoryId == categoryId ? null : categoryId;
      if (_selectedCategoryId != null) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  List<Category> get _displayCategories {
    if (_searchQuery.isEmpty) return _allCategories;
    return _allCategories
        .where((c) =>
            c.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<Venue> get _displayVenues {
    List<Venue> list = _allVenues;

    // Filter by search query (name or address)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((v) =>
              v.name.toLowerCase().contains(q) ||
              (v.address?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    // Filter by selected category (exact match via categoryId)
    if (_selectedCategoryId != null) {
      list = list.where((v) => v.categoryId == _selectedCategoryId).toList();
    }

    return list;
  }

  String get _venuesSectionTitle {
    if (_selectedCategoryId != null) {
      return _allCategories
              .where((c) => c.id == _selectedCategoryId)
              .firstOrNull
              ?.title ??
          'Venues';
    }
    if (_searchQuery.isNotEmpty) return 'Results for "$_searchQuery"';
    return 'Popular Venues';
  }

  @override
  Widget build(BuildContext context) {
    return BgScaffold(
      body: FutureBuilder<List<dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          final isLoaded = snapshot.connectionState == ConnectionState.done;
          final venues = _displayVenues;
          final categories = _displayCategories;

          return CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
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
                    bottom: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Good morning 👋',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 13)),
                              const SizedBox(height: 2),
                              const Text('Find your venue',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  )),
                            ],
                          ),
                          GestureDetector(
                            onTap: _openCreateVenue,
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.add_rounded,
                                  color: AppColors.navy, size: 24),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Search ─────────────────────────────────
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _searchActive
                                ? AppColors.gold
                                : Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded,
                                color: Colors.white.withOpacity(0.7),
                                size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onTap: () =>
                                    setState(() => _searchActive = true),
                                onTapOutside: (_) =>
                                    setState(() => _searchActive = false),
                                style:
                                    const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText:
                                      'Search venues, categories...',
                                  hintStyle:
                                      TextStyle(color: Colors.white54),
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _searchActive = false;
                                  });
                                },
                                child: Icon(Icons.close_rounded,
                                    color: Colors.white.withOpacity(0.6),
                                    size: 18),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Banner (hidden during search/filter) ─────────────
              if (_searchQuery.isEmpty && _selectedCategoryId == null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 160,
                          child: PageView.builder(
                            controller: _bannerController,
                            onPageChanged: (p) =>
                                setState(() => _bannerPage = p),
                            itemCount: _banners.length,
                            itemBuilder: (_, i) =>
                                _BannerCard(banner: _banners[i]),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _banners.length,
                            (i) => AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 3),
                              width: _bannerPage == i ? 20 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _bannerPage == i
                                    ? AppColors.navy
                                    : AppColors.divider,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],

              // ── Categories header ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Categories',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3)),
                      GestureDetector(
                        onTap: _selectedCategoryId != null
                            ? () => setState(
                                () => _selectedCategoryId = null)
                            : null,
                        child: Text(
                          _selectedCategoryId != null ? 'Clear' : 'See all',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _selectedCategoryId != null
                                  ? AppColors.error
                                  : AppColors.gold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // ── Category list ─────────────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 90,
                  child: !isLoaded
                      ? const Center(child: CircularProgressIndicator())
                      : categories.isEmpty
                          ? const Center(
                              child: Text('No categories found',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)))
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20),
                              itemCount: categories.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 14),
                              itemBuilder: (_, i) {
                                final cat = categories[i];
                                final isSelected =
                                    _selectedCategoryId == cat.id;
                                return GestureDetector(
                                  onTap: () => _onCategoryTap(cat.id),
                                  child: Column(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(
                                            milliseconds: 200),
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.navy
                                                : AppColors.divider,
                                            width:
                                                isSelected ? 2.5 : 1.5,
                                          ),
                                          image: DecorationImage(
                                            image: NetworkImage(
                                                cat.imageUrl),
                                            fit: BoxFit.cover,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors.navy
                                                        .withOpacity(0.25),
                                                    blurRadius: 8,
                                                    offset:
                                                        const Offset(0, 3),
                                                  )
                                                ]
                                              : [],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      SizedBox(
                                        width: 60,
                                        child: Text(
                                          cat.title,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? AppColors.navy
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Venues header ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_venuesSectionTitle,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3)),
                          if (_userPosition != null &&
                              _searchQuery.isEmpty &&
                              _selectedCategoryId == null)
                            const Text('Within 10 km from you',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                        ],
                      ),
                      if (isLoaded)
                        Text('${venues.length} found',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // ── Venues grid ───────────────────────────────────────
              if (!isLoaded)
                const SliverToBoxAdapter(
                  child: SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator())),
                )
              else if (snapshot.hasError)
                const SliverToBoxAdapter(
                  child: SizedBox(
                      height: 200,
                      child:
                          Center(child: Text('Error loading venues'))),
                )
              else if (venues.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        const Icon(Icons.search_off_rounded,
                            color: AppColors.textMuted, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No venues match "$_searchQuery"'
                              : 'No venues in this category',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _VenueCard(venue: venues[i], currentUser: widget.currentUser),
                      childCount: venues.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

// ── Banner Card ───────────────────────────────────────────────────────────────

class _BannerCard extends StatelessWidget {
  final _BannerItem banner;
  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Image.network(
              banner.imageUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppColors.navyLight),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.navy.withOpacity(0.80),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 0,
              bottom: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(banner.tag,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy)),
                  ),
                  const SizedBox(height: 6),
                  Text(banner.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      )),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(banner.cta,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Venue Card ────────────────────────────────────────────────────────────────

class _VenueCard extends StatelessWidget {
  final Venue venue;
  final Map<String, dynamic>? currentUser;  // ADD THIS
  const _VenueCard({required this.venue, this.currentUser});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => CheckoutScreen(venueId: venue.id, currentUser: currentUser)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18)),
                    child: Image.network(
                      venue.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.cardBg,
                        child: const Icon(Icons.image_not_supported,
                            color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.favorite_border_rounded,
                          size: 16, color: AppColors.navy),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(venue.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('\$${venue.price.toStringAsFixed(0)}/hour',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gold)),
                      const Row(children: [
                        Icon(Icons.star_rounded,
                            color: AppColors.gold, size: 13),
                        SizedBox(width: 2),
                        Text('4.8',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ]),
                    ],
                  ),
                  if (venue.distanceKm != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.near_me_rounded,
                          size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text(
                          '${venue.distanceKm!.toStringAsFixed(1)} km away',
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted)),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}