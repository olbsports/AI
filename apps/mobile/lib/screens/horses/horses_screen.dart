import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/horse.dart';
import '../../providers/horses_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../theme/app_theme.dart';

class HorsesScreen extends ConsumerStatefulWidget {
  const HorsesScreen({super.key});

  @override
  ConsumerState<HorsesScreen> createState() => _HorsesScreenState();
}

class _HorsesScreenState extends ConsumerState<HorsesScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    ref.read(horsesNotifierProvider.notifier).loadHorses(
          search: query.isEmpty ? null : query,
          status: _selectedStatus,
        );
  }

  void _onStatusChanged(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    ref.read(horsesNotifierProvider.notifier).loadHorses(
          search: _searchController.text.isEmpty ? null : _searchController.text,
          status: status,
        );
  }

  @override
  Widget build(BuildContext context) {
    final horsesAsync = ref.watch(horsesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes chevaux'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un cheval...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: _onSearch,
            ),
          ),

          // Horses list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(horsesNotifierProvider.notifier).loadHorses();
              },
              child: horsesAsync.when(
                data: (horses) {
                  if (horses.isEmpty) {
                    return EmptyState(
                      icon: Icons.pets,
                      title: 'Aucun cheval',
                      subtitle: 'Ajoutez votre premier cheval pour commencer',
                      actionLabel: 'Ajouter un cheval',
                      onAction: () => context.push('/horses/add'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: horses.length,
                    itemBuilder: (context, index) {
                      return _HorseCard(
                        horse: horses[index],
                        onTap: () => context.push('/horses/${horses[index].id}'),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorView(
                  message: error.toString(),
                  onRetry: () =>
                      ref.read(horsesNotifierProvider.notifier).loadHorses(),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/horses/add'),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtrer par statut',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Tous'),
                      selected: _selectedStatus == null,
                      onSelected: (_) {
                        _onStatusChanged(null);
                        Navigator.pop(context);
                      },
                    ),
                    FilterChip(
                      label: const Text('Actif'),
                      selected: _selectedStatus == 'active',
                      onSelected: (_) {
                        _onStatusChanged('active');
                        Navigator.pop(context);
                      },
                    ),
                    FilterChip(
                      label: const Text('Retraité'),
                      selected: _selectedStatus == 'retired',
                      onSelected: (_) {
                        _onStatusChanged('retired');
                        Navigator.pop(context);
                      },
                    ),
                    FilterChip(
                      label: const Text('Vendu'),
                      selected: _selectedStatus == 'sold',
                      onSelected: (_) {
                        _onStatusChanged('sold');
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HorseCard extends StatelessWidget {
  final Horse horse;
  final VoidCallback onTap;

  const _HorseCard({
    required this.horse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Horse avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: horse.photoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: horse.photoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.pets,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                          ),
                        )
                      : Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.pets,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),

              // Horse info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            horse.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        _buildStatusChip(context, horse.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildSubtitle(horse),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (horse.breed != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        horse.breed!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSubtitle(Horse horse) {
    final parts = <String>[];

    if (horse.gender != null) {
      parts.add(_genderLabel(horse.gender!));
    }

    if (horse.birthDate != null) {
      final age = DateTime.now().year - horse.birthDate!.year;
      parts.add('$age ans');
    }

    return parts.isEmpty ? 'Aucune info' : parts.join(' • ');
  }

  String _genderLabel(HorseGender gender) {
    switch (gender) {
      case HorseGender.male:
        return 'Mâle';
      case HorseGender.female:
        return 'Femelle';
      case HorseGender.gelding:
        return 'Hongre';
    }
  }

  Widget _buildStatusChip(BuildContext context, HorseStatus status) {
    Color color;
    String label;

    switch (status) {
      case HorseStatus.active:
        color = AppColors.success;
        label = 'Actif';
        break;
      case HorseStatus.retired:
        color = AppColors.warning;
        label = 'Retraité';
        break;
      case HorseStatus.sold:
        color = AppColors.textSecondary;
        label = 'Vendu';
        break;
      case HorseStatus.deceased:
        color = AppColors.error;
        label = 'Décédé';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
}
