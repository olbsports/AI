import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ListingType? _selectedType;
  String? _searchQuery;
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
    final listings = _getMockSalesListings();

    return Column(
      children: [
        // Quick filters
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('Tous', _selectedType == null, () {
                setState(() => _selectedType = null);
              }),
              _buildFilterChip('Chevaux', _selectedType == ListingType.horseForSale, () {
                setState(() => _selectedType = ListingType.horseForSale);
              }),
              _buildFilterChip('Poulains', _selectedType == ListingType.foalForSale, () {
                setState(() => _selectedType = ListingType.foalForSale);
              }),
              _buildFilterChip('Location', _selectedType == ListingType.horseForLease, () {
                setState(() => _selectedType = ListingType.horseForLease);
              }),
            ],
          ),
        ),
        const Divider(height: 1),
        // Listings
        Expanded(
          child: listings.isEmpty
              ? _buildEmptyState('Aucune annonce disponible')
              : ListView.builder(
                  itemCount: listings.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    return _buildSaleListingCard(listings[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBreedingTab() {
    final listings = _getMockBreedingListings();

    return Column(
      children: [
        // Quick filters
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('Tous', _selectedType == null, () {
                setState(() => _selectedType = null);
              }),
              _buildFilterChip('Juments', _selectedType == ListingType.mareForBreeding, () {
                setState(() => _selectedType = ListingType.mareForBreeding);
              }),
              _buildFilterChip('Semence', _selectedType == ListingType.stallionSemen, () {
                setState(() => _selectedType = ListingType.stallionSemen);
              }),
              _buildFilterChip('Embryons', _selectedType == ListingType.embryo, () {
                setState(() => _selectedType = ListingType.embryo);
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
                  children: const [
                    Text(
                      'Matching IA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Trouvez le croisement idéal basé sur les analyses vidéo',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
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
          child: listings.isEmpty
              ? _buildEmptyState('Aucune annonce disponible')
              : ListView.builder(
                  itemCount: listings.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    return _buildBreedingListingCard(listings[index]);
                  },
                ),
        ),
      ],
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

  Widget _buildSaleListingCard(HorseSaleListing listing) {
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
                      ? Image.network(listing.mediaUrls.first, fit: BoxFit.cover)
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
                // Favorite
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      listing.isFavorited ? Icons.favorite : Icons.favorite_border,
                      color: listing.isFavorited ? Colors.red : Colors.white,
                    ),
                    onPressed: () {},
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black26,
                    ),
                  ),
                ),
                // Argus badge
                if (listing.argus != null)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.analytics, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Argus: ${listing.argus!.priceRange}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                          listing.horseName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
                  // Details
                  Wrap(
                    spacing: 8,
                    children: [
                      if (listing.breed != null)
                        _buildTag(listing.breed!, Icons.pets),
                      if (listing.age != null)
                        _buildTag('${listing.age} ans', Icons.calendar_today),
                      if (listing.gender != null)
                        _buildTag(listing.gender!, Icons.male),
                      if (listing.heightCm != null)
                        _buildTag('${listing.heightCm} cm', Icons.height),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Disciplines
                  if (listing.disciplines.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: listing.disciplines.take(3).map((d) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              d.displayName,
                              style: TextStyle(fontSize: 10, color: AppColors.secondary),
                            ),
                          )).toList(),
                    ),
                  const SizedBox(height: 8),
                  // AI Profile indicator
                  if (listing.aiProfile != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Profil IA disponible',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                                Text(
                                  '${listing.aiProfile!.analysisCount} analyses • Confiance ${listing.aiProfile!.confidenceLevel.toInt()}%',
                                  style: TextStyle(fontSize: 10, color: Colors.purple.shade300),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${listing.aiProfile!.overallScore.toStringAsFixed(1)}/10',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Histovec indicator
                  if (listing.histovec != null)
                    Row(
                      children: [
                        Icon(
                          listing.histovec!.isClean ? Icons.verified_user : Icons.warning,
                          size: 16,
                          color: listing.histovec!.isClean ? AppColors.success : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Histovec: ${listing.histovec!.ownerCount} propriétaire(s)',
                          style: TextStyle(
                            fontSize: 12,
                            color: listing.histovec!.isClean ? AppColors.success : Colors.orange,
                          ),
                        ),
                        if (!listing.histovec!.isClean) ...[
                          const SizedBox(width: 4),
                          Text(
                            '• ${listing.histovec!.alerts.length} alerte(s)',
                            style: const TextStyle(fontSize: 12, color: Colors.orange),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 8),
                  // Location & contact
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: listing.mediaUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(listing.mediaUrls.first, fit: BoxFit.cover),
                      )
                    : Icon(
                        isMare ? Icons.female : Icons.male,
                        size: 40,
                        color: isMare ? Colors.pink : Colors.blue,
                      ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isMare ? Colors.pink.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
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
                        Text(
                          listing.priceDisplay,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.horseName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (listing.studbook != null)
                      Text(
                        listing.studbook!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    const SizedBox(height: 4),
                    // Indices for stallions
                    if (!isMare && listing.indices != null && listing.indices!.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: listing.indices!.entries.take(3).map((e) => Text(
                              '${e.key}: ${e.value.toInt()}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            )).toList(),
                      ),
                    // Availability for stallions
                    if (!isMare)
                      Row(
                        children: [
                          if (listing.freshSemen)
                            _buildAvailabilityChip('Frais', Colors.green),
                          if (listing.frozenSemen)
                            _buildAvailabilityChip('Congelé', Colors.blue),
                          if (listing.naturalService)
                            _buildAvailabilityChip('Monte', Colors.orange),
                        ],
                      ),
                    // AI Profile
                    if (listing.aiProfile != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, size: 12, color: Colors.purple),
                            const SizedBox(width: 4),
                            Text(
                              'Profil IA: ${listing.aiProfile!.overallScore.toStringAsFixed(1)}/10',
                              style: const TextStyle(fontSize: 10, color: Colors.purple),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }

  Widget _buildTag(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade600),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
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
        ],
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _MarketplaceSearchDelegate(),
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
                      // Reset filters
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.sell, color: Colors.green),
              ),
              title: const Text('Vendre un cheval'),
              subtitle: const Text('Avec Argus & Histovec automatique'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to create sale listing
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.female, color: Colors.pink),
              ),
              title: const Text('Proposer une jument'),
              subtitle: const Text('Pour poulinage'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.male, color: Colors.blue),
              ),
              title: const Text('Proposer de la semence'),
              subtitle: const Text('Étalon agréé'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showListingDetail(HorseSaleListing listing) {
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
    // Similar to _showListingDetail but for breeding
  }

  // Mock data
  List<HorseSaleListing> _getMockSalesListings() {
    return [
      HorseSaleListing(
        id: '1',
        type: ListingType.horseForSale,
        sellerId: 's1',
        sellerName: 'Écurie du Parc',
        sellerLocation: 'Normandie',
        title: 'Superbe hongre SF',
        description: 'Cheval polyvalent, gentil et généreux...',
        price: 25000,
        priceNegotiable: true,
        isPremium: true,
        isVerified: true,
        viewCount: 342,
        favoriteCount: 28,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        horseId: 'h1',
        horseName: 'Donatello du Parc',
        breed: 'Selle Français',
        studbook: 'SF',
        birthYear: 2016,
        gender: 'Hongre',
        heightCm: 168,
        color: 'Bai',
        disciplines: [HorseDiscipline.cso, HorseDiscipline.cce],
        level: 'Amateur 2',
        argus: HorseArgus(
          id: 'a1',
          horseId: 'h1',
          estimatedMinPrice: 22000,
          estimatedMaxPrice: 28000,
          marketAveragePrice: 25000,
          confidenceScore: 85,
          factors: ArgusFactors(
            ageImpact: -5,
            breedImpact: 15,
            levelImpact: 20,
            healthImpact: 5,
          ),
          marketTrend: 'stable',
          calculatedAt: DateTime.now(),
        ),
        histovec: HorseHistovec(
          id: 'hv1',
          horseId: 'h1',
          ueln: '250259600123456',
          microchip: '250259600123456',
          ownershipHistory: [
            OwnershipRecord(
              id: 'o1',
              ownerName: 'Élevage Martin',
              location: 'Orne',
              startDate: DateTime(2016),
              endDate: DateTime(2020),
            ),
            OwnershipRecord(
              id: 'o2',
              ownerName: 'Écurie du Parc',
              location: 'Normandie',
              startDate: DateTime(2020),
            ),
          ],
          isClean: true,
          lastUpdated: DateTime.now(),
        ),
        aiProfile: HorseAIProfile(
          id: 'ai1',
          horseId: 'h1',
          character: CharacterProfile(
            temperament: 55,
            sensitivity: 60,
            willingness: 85,
            confidence: 70,
            traits: ['Généreux', 'Attentif', 'Volontaire'],
          ),
          conformation: ConformationProfile(
            frame: 8.0,
            balance: 7.5,
            limbs: 8.0,
          ),
          locomotion: LocomotionProfile(
            walk: 7.0,
            trot: 8.0,
            canter: 8.5,
          ),
          overallScore: 8.2,
          analysisCount: 12,
          confidenceLevel: 88,
          lastAnalysisAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ),
      HorseSaleListing(
        id: '2',
        type: ListingType.horseForSale,
        sellerId: 's2',
        sellerName: 'Particulier',
        sellerLocation: 'Île-de-France',
        title: 'Jument dressage confirmée',
        description: 'Jument exceptionnelle...',
        price: 45000,
        isVerified: true,
        viewCount: 156,
        favoriteCount: 15,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        horseId: 'h2',
        horseName: 'Délice',
        breed: 'KWPN',
        birthYear: 2014,
        gender: 'Jument',
        heightCm: 172,
        disciplines: [HorseDiscipline.dressage],
        level: 'Pro 2',
        aiProfile: HorseAIProfile(
          id: 'ai2',
          horseId: 'h2',
          character: CharacterProfile(
            temperament: 45,
            sensitivity: 75,
            willingness: 90,
          ),
          conformation: ConformationProfile(),
          locomotion: LocomotionProfile(
            walk: 9.0,
            trot: 9.5,
            canter: 8.5,
          ),
          overallScore: 9.0,
          analysisCount: 24,
          confidenceLevel: 95,
          lastAnalysisAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ),
    ];
  }

  List<BreedingListing> _getMockBreedingListings() {
    return [
      BreedingListing(
        id: 'b1',
        type: ListingType.stallionSemen,
        sellerId: 's3',
        sellerName: 'Haras de la Vallée',
        sellerLocation: 'Loire-Atlantique',
        title: 'Semence étalon CSO',
        description: 'Étalon performant...',
        price: 800,
        createdAt: DateTime.now(),
        horseId: 'h3',
        horseName: 'Donatello',
        breed: 'Selle Français',
        studbook: 'SF • Approuvé',
        birthYear: 2010,
        freshSemen: true,
        frozenSemen: true,
        indices: {'ISO': 165, 'IDR': 140},
        offspringCount: 156,
        aiProfile: HorseAIProfile(
          id: 'ai3',
          horseId: 'h3',
          character: CharacterProfile(
            temperament: 60,
            willingness: 85,
            traits: ['Courage', 'Sang-froid', 'Généreux'],
          ),
          conformation: ConformationProfile(
            frame: 8.5,
            hindquarters: 9.0,
          ),
          locomotion: LocomotionProfile(),
          overallScore: 8.8,
          breedingScore: 9.2,
          analysisCount: 8,
          confidenceLevel: 82,
          lastAnalysisAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
      ),
      BreedingListing(
        id: 'b2',
        type: ListingType.mareForBreeding,
        sellerId: 's4',
        sellerName: 'Élevage des Prés',
        sellerLocation: 'Calvados',
        title: 'Jument SF à poulinière',
        description: 'Excellentes origines...',
        price: null,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        horseId: 'h4',
        horseName: 'Belle Étoile',
        breed: 'Selle Français',
        studbook: 'SF',
        birthYear: 2012,
        previousFoals: 3,
        embryoTransfer: true,
        sireName: 'Diamant de Semilly',
        damSireName: 'Quidam de Revel',
      ),
    ];
  }
}

class _MarketplaceSearchDelegate extends SearchDelegate<String> {
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
    return Center(child: Text('Résultats pour "$query"'));
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
      ],
    );
  }
}

class _SaleListingDetailSheet extends StatelessWidget {
  final HorseSaleListing listing;
  final ScrollController scrollController;

  const _SaleListingDetailSheet({
    required this.listing,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
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
            child: const Center(child: Icon(Icons.pets, size: 80)),
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
                        listing.horseName,
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
                const SizedBox(height: 16),
                // Argus section
                if (listing.argus != null) ...[
                  _buildSection(
                    context,
                    'Argus Horse Vision',
                    Icons.analytics,
                    Colors.blue,
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimation'),
                            Text(
                              listing.argus!.priceRange,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Confiance'),
                            Text(
                              '${listing.argus!.confidenceScore.toInt()}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: listing.argus!.confidenceScore > 75
                                    ? AppColors.success
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tendance marché'),
                            Row(
                              children: [
                                Icon(
                                  listing.argus!.marketTrend == 'up'
                                      ? Icons.trending_up
                                      : listing.argus!.marketTrend == 'down'
                                          ? Icons.trending_down
                                          : Icons.trending_flat,
                                  color: listing.argus!.marketTrend == 'up'
                                      ? AppColors.success
                                      : listing.argus!.marketTrend == 'down'
                                          ? Colors.red
                                          : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  listing.argus!.marketTrend == 'up'
                                      ? 'En hausse'
                                      : listing.argus!.marketTrend == 'down'
                                          ? 'En baisse'
                                          : 'Stable',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Histovec section
                if (listing.histovec != null) ...[
                  _buildSection(
                    context,
                    'Histovec',
                    listing.histovec!.isClean ? Icons.verified_user : Icons.warning,
                    listing.histovec!.isClean ? AppColors.success : Colors.orange,
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('UELN'),
                            Text(listing.histovec!.ueln),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Propriétaires'),
                            Text('${listing.histovec!.ownerCount}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Statut'),
                            Row(
                              children: [
                                Icon(
                                  listing.histovec!.isClean
                                      ? Icons.check_circle
                                      : Icons.warning,
                                  color: listing.histovec!.isClean
                                      ? AppColors.success
                                      : Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  listing.histovec!.isClean ? 'Aucune alerte' : 'Alertes présentes',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // AI Profile section
                if (listing.aiProfile != null) ...[
                  _buildSection(
                    context,
                    'Profil IA',
                    Icons.auto_awesome,
                    Colors.purple,
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Score global'),
                            Text(
                              '${listing.aiProfile!.overallScore.toStringAsFixed(1)}/10',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Analyses'),
                            Text('${listing.aiProfile!.analysisCount}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Confiance'),
                            Text('${listing.aiProfile!.confidenceLevel.toInt()}%'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (listing.aiProfile!.character.traits.isNotEmpty)
                          Wrap(
                            spacing: 4,
                            children: listing.aiProfile!.character.traits
                                .map((t) => Chip(
                                      label: Text(t, style: const TextStyle(fontSize: 12)),
                                      padding: EdgeInsets.zero,
                                    ))
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Contact button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {},
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
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
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
}
