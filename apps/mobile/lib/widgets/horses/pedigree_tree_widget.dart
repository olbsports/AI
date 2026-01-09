import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/performance.dart';
import '../../providers/horses_provider.dart';
import '../../theme/app_theme.dart';

/// A visual tree widget displaying horse pedigree/genealogy
/// Shows parents and grandparents in a hierarchical view
class PedigreeTreeWidget extends ConsumerWidget {
  final String horseId;
  final bool showOffspring;

  const PedigreeTreeWidget({
    super.key,
    required this.horseId,
    this.showOffspring = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedigreeAsync = ref.watch(horsePedigreeProvider(horseId));

    return pedigreeAsync.when(
      data: (pedigree) => _buildPedigreeTree(context, ref, pedigree),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'Erreur de chargement',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              TextButton(
                onPressed: () => ref.invalidate(horsePedigreeProvider(horseId)),
                child: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPedigreeTree(BuildContext context, WidgetRef ref, PedigreeData pedigree) {
    if (!pedigree.hasPedigree) {
      return _buildEmptyState(context);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ancestors section
            _buildAncestorsSection(context, pedigree),

            if (showOffspring && pedigree.offspring.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              // Offspring section
              _buildOffspringSection(context, pedigree),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_tree_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune origine renseignee',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez les informations sur les parents\net grands-parents du cheval',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAncestorsSection(BuildContext context, PedigreeData pedigree) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Horse (center)
        _buildHorseNode(
          context,
          name: pedigree.horseName,
          label: 'Cheval',
          isMain: true,
        ),
        const SizedBox(width: 24),
        // Parents column
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sire (Father)
            Row(
              children: [
                _buildConnectorLine(context),
                _buildParentNode(
                  context,
                  entry: pedigree.sire,
                  label: 'Pere',
                  isMale: true,
                ),
                const SizedBox(width: 16),
                // Sire's parents
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildGrandparentNode(
                      context,
                      entry: pedigree.siresSire,
                      label: 'GP paternel',
                      isMale: true,
                    ),
                    const SizedBox(height: 8),
                    _buildGrandparentNode(
                      context,
                      entry: pedigree.siresDam,
                      label: 'GM paternelle',
                      isMale: false,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Dam (Mother)
            Row(
              children: [
                _buildConnectorLine(context),
                _buildParentNode(
                  context,
                  entry: pedigree.dam,
                  label: 'Mere',
                  isMale: false,
                ),
                const SizedBox(width: 16),
                // Dam's parents
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildGrandparentNode(
                      context,
                      entry: pedigree.damsSire,
                      label: 'GP maternel',
                      isMale: true,
                    ),
                    const SizedBox(height: 8),
                    _buildGrandparentNode(
                      context,
                      entry: pedigree.damsDam,
                      label: 'GM maternelle',
                      isMale: false,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOffspringSection(BuildContext context, PedigreeData pedigree) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descendants (${pedigree.offspring.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: pedigree.offspring.map((offspring) {
            return _buildOffspringCard(context, offspring);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildConnectorLine(BuildContext context) {
    return Container(
      width: 24,
      height: 2,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
    );
  }

  Widget _buildHorseNode(
    BuildContext context, {
    required String name,
    required String label,
    bool isMain = false,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMain
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMain
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
          width: isMain ? 2 : 1,
        ),
        boxShadow: isMain
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pets,
            size: isMain ? 32 : 24,
            color: isMain
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isMain
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentNode(
    BuildContext context, {
    required PedigreeEntry? entry,
    required String label,
    required bool isMale,
  }) {
    final color = isMale ? AppColors.info : AppColors.categorySocial;

    return InkWell(
      onTap: entry?.isLinked == true && entry?.id != null
          ? () => context.push('/horses/${entry!.id}')
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: entry != null
              ? color.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: entry != null ? color : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMale ? Icons.male : Icons.female,
              size: 24,
              color: entry != null ? color : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              entry?.name ?? 'Inconnu',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: entry != null
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (entry?.breed != null) ...[
              const SizedBox(height: 4),
              Text(
                entry!.breed!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontStyle: FontStyle.italic,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (entry?.isLinked == true)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.link,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrandparentNode(
    BuildContext context, {
    required PedigreeEntry? entry,
    required String label,
    required bool isMale,
  }) {
    final color = isMale ? AppColors.info : AppColors.categorySocial;

    return InkWell(
      onTap: entry?.isLinked == true && entry?.id != null
          ? () => context.push('/horses/${entry!.id}')
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: entry != null
              ? color.withValues(alpha: 0.05)
              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: entry != null
                ? color.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMale ? Icons.male : Icons.female,
              size: 16,
              color: entry != null
                  ? color.withValues(alpha: 0.7)
                  : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              entry?.name ?? 'Inconnu',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: entry != null
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 9,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffspringCard(BuildContext context, PedigreeEntry offspring) {
    return InkWell(
      onTap: offspring.isLinked && offspring.id != null
          ? () => context.push('/horses/${offspring.id}')
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
              child: offspring.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        offspring.photoUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.pets,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.pets,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              offspring.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (offspring.birthYear != null)
              Text(
                '${offspring.birthYear}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A compact version of the pedigree widget for cards/preview
class PedigreePreviewWidget extends StatelessWidget {
  final PedigreeData pedigree;

  const PedigreePreviewWidget({super.key, required this.pedigree});

  @override
  Widget build(BuildContext context) {
    if (!pedigree.hasPedigree) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (pedigree.sire != null) ...[
          Icon(
            Icons.male,
            size: 16,
            color: AppColors.info,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              pedigree.sire!.name,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        if (pedigree.sire != null && pedigree.dam != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'x',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        if (pedigree.dam != null) ...[
          Icon(
            Icons.female,
            size: 16,
            color: AppColors.categorySocial,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              pedigree.dam!.name,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
