import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../models/marketplace.dart';
import '../../providers/marketplace_provider.dart';
import '../../theme/app_theme.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ListingType? _selectedSaleType;
  ListingType? _selectedBreedingType;
  RangeValues _priceRange = const RangeValues(0, 100000);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.sell), text: 'Ventes'),
            Tab(icon: Icon(Icons.favorite), text: 'Élevage'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilters(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSalesTab(),
          _buildBreedingTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateListingSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Déposer une annonce'),
      ),
    );
  }

  Widget _buildSalesTab() {
    // Get listings based on selected type filter
    final listingsAsync = _selectedSaleType != null
        ? ref.watch(listingsByTypeProvider(_selectedSaleType!))
        : ref.watch(recentListingsProvider);

    return Column(
      children: [
        // Quick filters
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('Tous', _selectedSaleType == null, () {
                setState(() => _selectedSaleType = null);
              }),
              _buildFilterChip('Chevaux', _selectedSaleType == ListingType.horseForSale, () {
                setState(() => _selectedSaleType = ListingType.horseForSale);
              }),
              _buildFilterChip('Poulains', _selectedSaleType == ListingType.foalForSale, () {
                setState(() => _selectedSaleType = ListingType.foalForSale);
              }),
              _buildFilterChip('Location', _selectedSaleType == ListingType.horseForLease, () {
                setState(() => _selectedSaleType = ListingType.horseForLease);
              }),
            ],
          ),
        ),
        const Divider(height: 1),
        // Listings
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (_selectedSaleType != null) {
                ref.invalidate(listingsByTypeProvider(_selectedSaleType!));
              } else {
                ref.invalidate(recentListingsProvider);
              }
            },
            child: listingsAsync.when(
              data: (listings) {
                // Filter out breeding types for sale tab
                final saleListings = listings.where((l) =>
                  l.type == ListingType.horseForSale ||
                  l.type == ListingType.foalForSale ||
                  l.type == ListingType.horseForLease
                ).toList();

                if (saleListings.isEmpty) {
                  return _buildEmptyState('Aucune annonce disponible');
                }
                return ListView.builder(
                  itemCount: saleListings.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    return _buildSaleListingCard(saleListings[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorWidget(error, () {
                if (_selectedSaleType != null) {
                  ref.invalidate(listingsByTypeProvider(_selectedSaleType!));
                } else {
                  ref.invalidate(recentListingsProvider);
                }
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreedingTab() {
    // Get breeding listings
    final breedingType = _selectedBreedingType ?? ListingType.stallionSemen;
    final listingsAsync = ref.watch(breedingListingsProvider((
      type: breedingType,
      breed: null,
    )));

    return Column(
      children: [
        // Quick filters
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('Étalons', _selectedBreedingType == null || _selectedBreedingType == ListingType.stallionSemen, () {
                setState(() => _selectedBreedingType = ListingType.stallionSemen);
              }),
              _buildFilterChip('Juments', _selectedBreedingType == ListingType.mareForBreeding, () {
                setState(() => _selectedBreedingType = ListingType.mareForBreeding);
              }),
              _buildFilterChip('Embryons', _selectedBreedingType == ListingType.embryo, () {
                setState(() => _selectedBreedingType = ListingType.embryo);
              }),
            ],
          ),
        ),
        const Divider(height: 1),
        // AI Matching banner
        Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Matching IA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Trouvez le croisement idéal basé sur les analyses vidéo',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: () => context.push('/breeding'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('Essayer'),
              ),
            ],
          ),
        ),
        // Listings
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(breedingListingsProvider((
                type: breedingType,
                breed: null,
              )));
            },
            child: listingsAsync.when(
              data: (listings) {
                if (listings.isEmpty) {
                  return _buildEmptyState('Aucune annonce disponible');
                }
                return ListView.builder(
                  itemCount: listings.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    return _buildBreedingListingCard(listings[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorWidget(error, () {
                ref.invalidate(breedingListingsProvider((
                  type: breedingType,
                  breed: null,
                )));
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(Object error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _buildSaleListingCard(MarketplaceListing listing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showListingDetail(listing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Stack(
              children: [
                Container(
                  height: 180,
                  color: Colors.grey.shade200,
                  child: listing.mediaUrls.isNotEmpty
                      ? Image.network(
                          listing.mediaUrls.first,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stack) => const Center(
                            child: Icon(Icons.pets, size: 64, color: Colors.grey),
                          ),
                        )
                      : const Center(child: Icon(Icons.pets, size: 64, color: Colors.grey)),
                ),
                // Badges
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    children: [
                      if (listing.isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PREMIUM',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (listing.isVerified) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, color: Colors.white, size: 12),
                              SizedBox(width: 2),
                              Text(
                                'VÉRIFIÉ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Favorite button
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      listing.isFavorited ? Icons.favorite : Icons.favorite_border,
                      color: listing.isFavorited ? Colors.red : Colors.white,
                    ),
                    onPressed: () => _toggleFavorite(listing.id),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black26,
                    ),
                  ),
                ),
                // Type badge
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      listing.type.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        listing.priceDisplay,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Description
                  if (listing.description.isNotEmpty)
                    Text(
                      listing.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  // Seller info and stats
                  Row(
                    children: [
                      if (listing.sellerLocation != null) ...[
                        Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          listing.sellerLocation!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const Spacer(),
                      ],
                      Icon(Icons.visibility, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${listing.viewCount}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.favorite, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${listing.favoriteCount}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreedingListingCard(BreedingListing listing) {
    final isMare = listing.type == ListingType.mareForBreeding;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showBreedingListingDetail(listing),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: listing.mediaUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            listing.mediaUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Icon(
                              isMare ? Icons.female : Icons.male,
                              size: 32,
                              color: isMare ? Colors.pink : Colors.blue,
                            ),
                          ),
                        )
                      : Icon(
                          isMare ? Icons.female : Icons.male,
                          size: 32,
                          color: isMare ? Colors.pink : Colors.blue,
                        ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isMare ? Colors.pink.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isMare ? '♀ Jument' : '♂ Étalon',
                              style: TextStyle(
                                fontSize: 10,
                                color: isMare ? Colors.pink : Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              listing.priceDisplay,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        listing.horseName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (listing.studbook != null)
                        Text(
                          listing.studbook!,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2),
                      // Indices for stallions
                      if (!isMare && listing.indices != null && listing.indices!.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          children: listing.indices!.entries.take(3).map((e) => Text(
                                '${e.key}: ${e.value.toInt()}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              )).toList(),
                        ),
                      // Availability for stallions
                      if (!isMare)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (listing.freshSemen)
                                _buildAvailabilityChip('Frais', Colors.green),
                              if (listing.frozenSemen)
                                _buildAvailabilityChip('Congelé', Colors.blue),
                              if (listing.naturalService)
                                _buildAvailabilityChip('Monte', Colors.orange),
                            ],
                          ),
                        ),
                      // Mare info
                      if (isMare && listing.previousFoals != null)
                        Text(
                          '${listing.previousFoals} poulains précédents',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, color: color),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _showCreateListingSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Créer une annonce'),
          ),
        ],
      ),
    );
  }

  void _toggleFavorite(String listingId) async {
    final success = await ref.read(marketplaceNotifierProvider.notifier).toggleFavorite(listingId);
    if (success && mounted) {
      // Refresh the listings
      if (_selectedSaleType != null) {
        ref.invalidate(listingsByTypeProvider(_selectedSaleType!));
      } else {
        ref.invalidate(recentListingsProvider);
      }
    }
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _MarketplaceSearchDelegate(ref),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  Text(
                    'Filtres',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _priceRange = const RangeValues(0, 100000);
                      });
                    },
                    child: const Text('Réinitialiser'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Price range
              Text('Budget', style: Theme.of(context).textTheme.titleMedium),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 100000,
                divisions: 20,
                labels: RangeLabels(
                  '${_priceRange.start.toInt()} €',
                  '${_priceRange.end.toInt()} €',
                ),
                onChanged: (values) {
                  setState(() => _priceRange = values);
                },
              ),
              const SizedBox(height: 16),
              // More filters...
              Text('Race', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  'Selle Français',
                  'KWPN',
                  'Holsteiner',
                  'Hanovrien',
                  'Pur-sang',
                  'Anglo-Arabe',
                ].map((breed) => FilterChip(
                      label: Text(breed),
                      selected: false,
                      onSelected: (selected) {},
                    )).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Appliquer les filtres'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateListingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Créer une annonce',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.sell, color: Colors.green),
              ),
              title: const Text('Vendre un cheval'),
              subtitle: const Text('Avec estimation de prix automatique'),
              onTap: () {
                Navigator.pop(context);
                context.push('/marketplace/create/sale');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.female, color: Colors.pink),
              ),
              title: const Text('Proposer une jument'),
              subtitle: const Text('Pour poulinage'),
              onTap: () {
                Navigator.pop(context);
                context.push('/marketplace/create/mare');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.male, color: Colors.blue),
              ),
              title: const Text('Proposer de la semence'),
              subtitle: const Text('Étalon agréé'),
              onTap: () {
                Navigator.pop(context);
                context.push('/marketplace/create/stallion');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showListingDetail(MarketplaceListing listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _SaleListingDetailSheet(
          listing: listing,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showBreedingListingDetail(BreedingListing listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _BreedingListingDetailSheet(
          listing: listing,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _MarketplaceSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  _MarketplaceSearchDelegate(this.ref);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Entrez un terme de recherche'));
    }

    final filters = MarketplaceFilters(
      sortBy: 'recent',
    );

    return Consumer(
      builder: (context, ref, child) {
        final searchAsync = ref.watch(marketplaceSearchProvider(filters));

        return searchAsync.when(
          data: (listings) {
            // Filter by search query locally
            final filtered = listings.where((l) =>
              l.title.toLowerCase().contains(query.toLowerCase()) ||
              l.description.toLowerCase().contains(query.toLowerCase()) ||
              l.sellerName.toLowerCase().contains(query.toLowerCase())
            ).toList();

            if (filtered.isEmpty) {
              return Center(child: Text('Aucun résultat pour "$query"'));
            }

            return ListView.builder(
              itemCount: filtered.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final listing = filtered[index];
                return ListTile(
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: listing.mediaUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              listing.mediaUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          )
                        : const Icon(Icons.pets, color: Colors.grey),
                  ),
                  title: Text(listing.title),
                  subtitle: Text(listing.priceDisplay),
                  trailing: Text(listing.type.displayName, style: const TextStyle(fontSize: 12)),
                  onTap: () {
                    close(context, listing.id);
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Erreur: $error')),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.search),
          title: const Text('Selle Français CSO'),
          onTap: () {
            query = 'Selle Français CSO';
            showResults(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.search),
          title: const Text('Jument dressage'),
          onTap: () {
            query = 'Jument dressage';
            showResults(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.search),
          title: const Text('Poulain'),
          onTap: () {
            query = 'Poulain';
            showResults(context);
          },
        ),
      ],
    );
  }
}

class _SaleListingDetailSheet extends ConsumerWidget {
  final MarketplaceListing listing;
  final ScrollController scrollController;

  const _SaleListingDetailSheet({
    required this.listing,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: ListView(
        controller: scrollController,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Image carousel
          Container(
            height: 250,
            color: Colors.grey.shade200,
            child: listing.mediaUrls.isNotEmpty
                ? PageView.builder(
                    itemCount: listing.mediaUrls.length,
                    itemBuilder: (context, index) => Image.network(
                      listing.mediaUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => const Center(
                        child: Icon(Icons.pets, size: 80, color: Colors.grey),
                      ),
                    ),
                  )
                : const Center(child: Icon(Icons.pets, size: 80, color: Colors.grey)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and price
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        listing.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Text(
                      listing.priceDisplay,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Type and status badges
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text(listing.type.displayName),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    if (listing.isVerified)
                      Chip(
                        avatar: const Icon(Icons.verified, size: 16),
                        label: const Text('Vérifié'),
                        backgroundColor: AppColors.success.withValues(alpha: 0.1),
                      ),
                    if (listing.isPremium)
                      Chip(
                        avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                        label: const Text('Premium'),
                        backgroundColor: Colors.amber.withValues(alpha: 0.1),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  listing.description.isNotEmpty ? listing.description : 'Aucune description',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                // Seller info
                _buildSection(
                  context,
                  'Vendeur',
                  Icons.person,
                  AppColors.primary,
                  Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: listing.sellerPhotoUrl != null
                                ? NetworkImage(listing.sellerPhotoUrl!)
                                : null,
                            child: listing.sellerPhotoUrl == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  listing.sellerName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (listing.sellerLocation != null)
                                  Text(
                                    listing.sellerLocation!,
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(Icons.visibility, '${listing.viewCount}', 'vues'),
                    _buildStat(Icons.favorite, '${listing.favoriteCount}', 'favoris'),
                    _buildStat(Icons.message, '${listing.contactCount}', 'contacts'),
                  ],
                ),
                const SizedBox(height: 24),
                // Contact buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleFavorite(context, ref),
                        icon: Icon(
                          listing.isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: listing.isFavorited ? Colors.red : null,
                        ),
                        label: Text(listing.isFavorited ? 'Favori' : 'Ajouter aux favoris'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _contactSeller(context),
                        icon: const Icon(Icons.message),
                        label: const Text('Contacter'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget content,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  void _toggleFavorite(BuildContext context, WidgetRef ref) async {
    await ref.read(marketplaceNotifierProvider.notifier).toggleFavorite(listing.id);
    if (context.mounted) {
      ref.invalidate(recentListingsProvider);
    }
  }

  void _contactSeller(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ContactSellerDialog(
        listingId: listing.id,
        sellerName: listing.sellerName,
      ),
    );
  }
}

class _BreedingListingDetailSheet extends ConsumerWidget {
  final BreedingListing listing;
  final ScrollController scrollController;

  const _BreedingListingDetailSheet({
    required this.listing,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMare = listing.type == ListingType.mareForBreeding;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: ListView(
        controller: scrollController,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Image
          Container(
            height: 200,
            color: Colors.grey.shade200,
            child: listing.mediaUrls.isNotEmpty
                ? Image.network(
                    listing.mediaUrls.first,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stack) => Center(
                      child: Icon(
                        isMare ? Icons.female : Icons.male,
                        size: 80,
                        color: isMare ? Colors.pink : Colors.blue,
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      isMare ? Icons.female : Icons.male,
                      size: 80,
                      color: isMare ? Colors.pink : Colors.blue,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and price
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.horseName,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (listing.studbook != null)
                            Text(
                              listing.studbook!,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      listing.priceDisplay,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Horse info
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (listing.breed != null)
                      Chip(label: Text(listing.breed!)),
                    if (listing.birthYear != null)
                      Chip(label: Text('Né en ${listing.birthYear}')),
                    if (listing.color != null)
                      Chip(label: Text(listing.color!)),
                  ],
                ),
                const SizedBox(height: 16),
                // Stallion specific info
                if (!isMare) ...[
                  // Indices
                  if (listing.indices != null && listing.indices!.isNotEmpty) ...[
                    Text(
                      'Indices',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      children: listing.indices!.entries.map((e) => Column(
                            children: [
                              Text(
                                '${e.value.toInt()}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(e.key),
                            ],
                          )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Availability
                  Text(
                    'Disponibilité',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (listing.freshSemen)
                        const Chip(
                          avatar: Icon(Icons.check, size: 16, color: Colors.green),
                          label: Text('Semence fraîche'),
                        ),
                      if (listing.frozenSemen)
                        const Chip(
                          avatar: Icon(Icons.check, size: 16, color: Colors.blue),
                          label: Text('Semence congelée'),
                        ),
                      if (listing.naturalService)
                        const Chip(
                          avatar: Icon(Icons.check, size: 16, color: Colors.orange),
                          label: Text('Monte naturelle'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Offspring
                  if (listing.offspringCount != null) ...[
                    Text(
                      'Production',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text('${listing.offspringCount} produits'),
                  ],
                ],
                // Mare specific info
                if (isMare) ...[
                  if (listing.previousFoals != null) ...[
                    Text(
                      'Historique',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text('${listing.previousFoals} poulains précédents'),
                  ],
                  if (listing.embryoTransfer) ...[
                    const SizedBox(height: 8),
                    const Chip(
                      avatar: Icon(Icons.check, size: 16, color: Colors.green),
                      label: Text('Transfert d\'embryon possible'),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                // Origins
                if (listing.sireName != null || listing.damSireName != null) ...[
                  Text(
                    'Origines',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (listing.sireName != null)
                    Text('Père: ${listing.sireName}'),
                  if (listing.damSireName != null)
                    Text('Père de mère: ${listing.damSireName}'),
                  const SizedBox(height: 16),
                ],
                // Description
                if (listing.description.isNotEmpty) ...[
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(listing.description),
                  const SizedBox(height: 16),
                ],
                // Contact button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _contactSeller(context),
                    icon: const Icon(Icons.message),
                    label: const Text('Contacter le vendeur'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _contactSeller(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ContactSellerDialog(
        listingId: listing.id,
        sellerName: listing.sellerName,
      ),
    );
  }
}

class _ContactSellerDialog extends ConsumerStatefulWidget {
  final String listingId;
  final String sellerName;

  const _ContactSellerDialog({
    required this.listingId,
    required this.sellerName,
  });

  @override
  ConsumerState<_ContactSellerDialog> createState() => _ContactSellerDialogState();
}

class _ContactSellerDialogState extends ConsumerState<_ContactSellerDialog> {
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Contacter ${widget.sellerName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Votre message...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _isSending ? null : _sendMessage,
          child: _isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Envoyer'),
        ),
      ],
    );
  }

  void _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    setState(() => _isSending = true);

    final success = await ref
        .read(marketplaceNotifierProvider.notifier)
        .contactSeller(widget.listingId, _messageController.text);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Message envoyé !' : 'Erreur lors de l\'envoi'),
          backgroundColor: success ? AppColors.success : Colors.red,
        ),
      );
    }
  }
}
