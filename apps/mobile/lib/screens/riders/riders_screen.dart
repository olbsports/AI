import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/rider.dart';
import '../../providers/riders_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';

class RidersScreen extends ConsumerStatefulWidget {
  const RidersScreen({super.key});

  @override
  ConsumerState<RidersScreen> createState() => _RidersScreenState();
}

class _RidersScreenState extends ConsumerState<RidersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    ref.read(ridersNotifierProvider.notifier).loadRiders(
          search: query.isEmpty ? null : query,
        );
  }

  @override
  Widget build(BuildContext context) {
    final ridersAsync = ref.watch(ridersNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cavaliers'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un cavalier...',
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(ridersNotifierProvider.notifier).loadRiders();
              },
              child: ridersAsync.when(
                data: (riders) {
                  if (riders.isEmpty) {
                    return EmptyState(
                      icon: Icons.person,
                      title: 'Aucun cavalier',
                      subtitle: 'Ajoutez votre premier cavalier',
                      actionLabel: 'Ajouter un cavalier',
                      onAction: () => context.push('/riders/add'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: riders.length,
                    itemBuilder: (context, index) {
                      return _RiderCard(
                        rider: riders[index],
                        onTap: () => context.push('/riders/${riders[index].id}'),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorView(
                  message: error.toString(),
                  onRetry: () =>
                      ref.read(ridersNotifierProvider.notifier).loadRiders(),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/riders/add'),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}

class _RiderCard extends StatelessWidget {
  final Rider rider;
  final VoidCallback onTap;

  const _RiderCard({
    required this.rider,
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
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(25),
                  image: rider.photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(rider.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: rider.photoUrl == null
                    ? Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rider.email ?? 'Pas d\'email',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (rider.horseCount > 0)
                      Text(
                        '${rider.horseCount} cheval${rider.horseCount > 1 ? 'x' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                  ],
                ),
              ),
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
}
