import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/services.dart';
import '../../providers/services_provider.dart';
import '../../theme/app_theme.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  final _searchController = TextEditingController();
  ServiceType? _selectedType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annuaire'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emergency),
            color: Colors.red,
            onPressed: () => _showEmergencyContacts(context),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () => _showSavedProviders(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un professionnel...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTypeChip(null, 'Tous'),
                      ...ServiceType.values
                          .where((t) => t != ServiceType.other)
                          .take(8)
                          .map((t) => _buildTypeChip(t, t.displayName)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAppointmentsList(context),
        child: const Icon(Icons.calendar_today),
      ),
    );
  }

  Widget _buildTypeChip(ServiceType? type, String label) {
    final isSelected = _selectedType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type != null) ...[
              Icon(
                type.icon,
                size: 16,
                color: isSelected ? Colors.white : Color(type.defaultColor),
              ),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedType = selected ? type : null);
        },
      ),
    );
  }

  Widget _buildResults() {
    if (_selectedType == null) {
      return _buildServiceCategories();
    }

    final providersAsync = ref.watch(providersByTypeProvider(_selectedType!));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(providersByTypeProvider(_selectedType!)),
      child: providersAsync.when(
        data: (providers) {
          if (providers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_selectedType!.icon, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Aucun ${_selectedType!.displayName.toLowerCase()} trouvé'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              return _buildProviderCard(providers[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildServiceCategories() {
    final categories = [
      (ServiceType.veterinarian, 'Vétérinaires', 'Soins médicaux, urgences'),
      (ServiceType.farrier, 'Maréchaux-ferrants', 'Ferrure, parage'),
      (ServiceType.dentist, 'Dentistes équins', 'Soins dentaires'),
      (ServiceType.osteopath, 'Ostéopathes', 'Thérapie manuelle'),
      (ServiceType.physiotherapist, 'Kinésithérapeutes', 'Rééducation'),
      (ServiceType.nutritionist, 'Nutritionnistes', 'Alimentation'),
      (ServiceType.transporter, 'Transporteurs', 'Transport équin'),
      (ServiceType.instructor, 'Moniteurs', 'Cours, enseignement'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Emergency banner
        Card(
          color: Colors.red.shade50,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(Icons.emergency, color: Colors.white),
            ),
            title: const Text(
              'Urgence ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Accédez rapidement aux contacts d\'urgence'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showEmergencyContacts(context),
          ),
        ),
        const SizedBox(height: 24),

        // Categories
        Text(
          'Catégories',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...categories.map((c) => _buildCategoryCard(c.$1, c.$2, c.$3)),

        const SizedBox(height: 24),

        // Featured providers
        Text(
          'Professionnels en vedette',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Consumer(
          builder: (context, ref, _) {
            final featuredAsync = ref.watch(featuredProvidersProvider);
            return featuredAsync.when(
              data: (providers) => Column(
                children: providers.take(3).map((p) => _buildProviderCard(p)).toList(),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Erreur'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(ServiceType type, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color(type.defaultColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(type.icon, color: Color(type.defaultColor)),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => setState(() => _selectedType = type),
      ),
    );
  }

  Widget _buildProviderCard(ServiceProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showProviderDetails(provider),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: provider.photoUrl != null
                        ? NetworkImage(provider.photoUrl!)
                        : null,
                    backgroundColor: Color(provider.type.defaultColor).withOpacity(0.1),
                    child: provider.photoUrl == null
                        ? Icon(provider.type.icon, color: Color(provider.type.defaultColor))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                provider.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (provider.isVerified)
                              const Icon(Icons.verified, color: Colors.blue, size: 18),
                          ],
                        ),
                        if (provider.businessName != null)
                          Text(
                            provider.businessName!,
                            style: TextStyle(color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          provider.type.displayName,
                          style: TextStyle(
                            color: Color(provider.type.defaultColor),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Location & rating
              Row(
                children: [
                  if (provider.address != null) ...[
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        provider.address!.shortAddress,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (provider.hasRating) ...[
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      provider.displayRating,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      ' (${provider.reviewCount})',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Tags
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (provider.acceptsEmergency)
                    _buildTag('Urgences', Colors.red),
                  if (provider.mobileService)
                    _buildTag('Se déplace', Colors.green),
                  if (provider.priceRange != null)
                    _buildTag(provider.priceRange!.displayRange, Colors.blue),
                ],
              ),

              const SizedBox(height: 12),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (provider.phone != null)
                    IconButton(
                      icon: const Icon(Icons.phone),
                      onPressed: () => _callProvider(provider),
                    ),
                  TextButton.icon(
                    onPressed: () => _bookAppointment(provider),
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Rendez-vous'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _search() {
    // Implement search
  }

  void _showEmergencyContacts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emergency, color: Colors.red, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Contacts d\'urgence',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Vétérinaires disponibles 24h/24',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final contactsAsync = ref.watch(emergencyContactsProvider);
                  return contactsAsync.when(
                    data: (contacts) => ListView.builder(
                      controller: scrollController,
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(contact.type.defaultColor).withOpacity(0.1),
                            child: Icon(contact.type.icon, color: Color(contact.type.defaultColor)),
                          ),
                          title: Text(
                            contact.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(contact.type.displayName),
                          trailing: IconButton(
                            icon: const Icon(Icons.phone, color: Colors.green),
                            onPressed: () {
                              // Call emergency contact
                            },
                          ),
                        );
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Center(child: Text('Erreur')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSavedProviders(BuildContext context) {
    // Show saved providers
  }

  void _showAppointmentsList(BuildContext context) {
    // Show appointments list
  }

  void _showProviderDetails(ServiceProvider provider) {
    // Navigate to provider details
  }

  void _callProvider(ServiceProvider provider) {
    // Call provider
  }

  void _bookAppointment(ServiceProvider provider) {
    // Book appointment
  }
}
