import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/nutrition.dart';
import '../../models/horse.dart';
import '../../models/horse_ai_data.dart';
import '../../providers/horses_provider.dart';
import '../../providers/horse_ai_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_view.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  String? _selectedHorseId;

  @override
  Widget build(BuildContext context) {
    final horsesAsync = ref.watch(horsesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: horsesAsync.when(
        data: (horses) => _buildContent(context, horses),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(horsesNotifierProvider),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Horse> horses) {
    if (horses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun cheval',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez un cheval pour gérer sa nutrition',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/horses/add'),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un cheval'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Horse selector
          _buildHorseSelector(context, horses),
          const SizedBox(height: 24),

          // Content based on selection
          if (_selectedHorseId != null) ...[
            _buildNutritionContent(context),
          ] else ...[
            _buildNoSelectionPlaceholder(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHorseSelector(BuildContext context, List<Horse> horses) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sélectionner un cheval',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedHorseId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choisir un cheval',
                prefixIcon: Icon(Icons.pets),
              ),
              items: horses.map((horse) {
                return DropdownMenuItem(
                  value: horse.id,
                  child: Text(horse.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedHorseId = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSelectionPlaceholder(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.restaurant,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Sélectionnez un cheval',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Choisissez un cheval pour voir et gérer son plan nutritionnel personnalisé par IA',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionContent(BuildContext context) {
    final nutritionData = ref.watch(horseNutritionAIProvider(_selectedHorseId!));
    final horseAsync = ref.watch(horseProvider(_selectedHorseId!));

    return horseAsync.when(
      data: (horse) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick stats
          _buildQuickStats(context, horse, nutritionData),
          const SizedBox(height: 16),

          // Body condition
          _buildBodyConditionCard(context, nutritionData),
          const SizedBox(height: 16),

          // Daily needs
          _buildDailyNeedsCard(context, horse, nutritionData),
          const SizedBox(height: 16),

          // Diet type
          _buildDietTypeCard(context, nutritionData),
          const SizedBox(height: 16),

          // Supplements
          _buildSupplementsCard(context, nutritionData),
          const SizedBox(height: 16),

          // Restrictions
          _buildRestrictionsCard(context, nutritionData),
          const SizedBox(height: 16),

          // Generate plan button
          _buildGeneratePlanButton(context),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(message: e.toString()),
    );
  }

  Widget _buildQuickStats(
      BuildContext context, Horse horse, NutritionAIData? data) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.monitor_weight,
            label: 'Poids actuel',
            value: data?.currentWeight != null
                ? '${data!.currentWeight!.toStringAsFixed(0)} kg'
                : horse.weight != null
                    ? '${horse.weight} kg'
                    : 'N/A',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.track_changes,
            label: 'Poids idéal',
            value: data?.idealWeight != null
                ? '${data!.idealWeight!.toStringAsFixed(0)} kg'
                : 'N/A',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildBodyConditionCard(BuildContext context, NutritionAIData? data) {
    final score = data?.bodyConditionScore ?? 5.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Score de condition corporelle',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  score.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(score),
                      ),
                ),
                const Text(' / 9'),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: score / 9,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor:
                              AlwaysStoppedAnimation(_getScoreColor(score)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getScoreLabel(score),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _getScoreColor(score),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _showEditBodyConditionDialog(context),
              child: const Text('Mettre à jour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyNeedsCard(
      BuildContext context, Horse horse, NutritionAIData? data) {
    // Calculate estimated needs if not set
    final weight = data?.currentWeight ?? horse.weight?.toDouble() ?? 500.0;
    final energyNeeds = data?.dailyEnergyNeeds ?? (weight * 0.033);
    final proteinNeeds = data?.dailyProteinNeeds ?? (weight * 1.4);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(
                  'Besoins journaliers estimés',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildNeedRow(
              context,
              'Énergie',
              '${energyNeeds.toStringAsFixed(1)} Mcal',
              Icons.local_fire_department,
              AppColors.error,
            ),
            const Divider(),
            _buildNeedRow(
              context,
              'Protéines',
              '${proteinNeeds.toStringAsFixed(0)} g',
              Icons.egg,
              AppColors.secondary,
            ),
            const Divider(),
            _buildNeedRow(
              context,
              'Fourrage',
              '${(weight * 0.02).toStringAsFixed(1)} kg min',
              Icons.grass,
              AppColors.success,
            ),
            const Divider(),
            _buildNeedRow(
              context,
              'Eau',
              '${(weight * 0.05).toStringAsFixed(0)} L',
              Icons.water_drop,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeedRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietTypeCard(BuildContext context, NutritionAIData? data) {
    final dietType = data?.dietType ?? 'maintenance';
    final dietInfo = _getDietInfo(dietType);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant_menu, color: AppColors.categoryIA),
                const SizedBox(width: 8),
                Text(
                  'Type de régime',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dietInfo['color'].withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: dietInfo['color'].withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    dietInfo['icon'] as IconData,
                    color: dietInfo['color'] as Color,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dietInfo['label'] as String,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          dietInfo['description'] as String,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _showEditDietTypeDialog(context),
              child: const Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplementsCard(BuildContext context, NutritionAIData? data) {
    final supplements = data?.supplements ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.medication, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Suppléments',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showAddSupplementDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (supplements.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Aucun supplément ajouté',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: supplements.map((s) {
                  return Chip(
                    label: Text(s),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeSupplement(s),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestrictionsCard(BuildContext context, NutritionAIData? data) {
    final restrictions = data?.dietaryRestrictions ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text(
                      'Restrictions alimentaires',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showAddRestrictionDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (restrictions.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Aucune restriction alimentaire',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.success,
                            ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...restrictions.map((r) {
                return ListTile(
                  leading: Icon(Icons.do_not_disturb, color: AppColors.error),
                  title: Text(r),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeRestriction(r),
                  ),
                  contentPadding: EdgeInsets.zero,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratePlanButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _generateNutritionPlan(context),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Générer un plan nutritionnel IA'),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score < 3) return AppColors.error;
    if (score < 4) return AppColors.warning;
    if (score < 6) return AppColors.success;
    if (score < 8) return AppColors.warning;
    return AppColors.error;
  }

  String _getScoreLabel(double score) {
    if (score < 3) return 'Très maigre';
    if (score < 4) return 'Maigre';
    if (score < 6) return 'Optimal';
    if (score < 8) return 'Embonpoint';
    return 'Obèse';
  }

  Map<String, dynamic> _getDietInfo(String dietType) {
    switch (dietType) {
      case 'weight_gain':
        return {
          'label': 'Prise de poids',
          'description': 'Régime enrichi pour augmenter la masse',
          'icon': Icons.trending_up,
          'color': AppColors.success,
        };
      case 'weight_loss':
        return {
          'label': 'Perte de poids',
          'description': 'Régime allégé pour réduire la masse',
          'icon': Icons.trending_down,
          'color': AppColors.warning,
        };
      case 'performance':
        return {
          'label': 'Performance',
          'description': 'Régime optimisé pour les compétitions',
          'icon': Icons.speed,
          'color': AppColors.primary,
        };
      default:
        return {
          'label': 'Entretien',
          'description': 'Régime équilibré pour maintenir le poids',
          'icon': Icons.balance,
          'color': AppColors.secondary,
        };
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nutrition IA'),
        content: const Text(
          'Cette fonctionnalité utilise l\'intelligence artificielle pour analyser '
          'les besoins nutritionnels de votre cheval et générer des recommandations '
          'personnalisées basées sur son poids, son âge, son niveau d\'activité '
          'et son état de santé.\n\n'
          'Les données sont synchronisées avec toutes les autres fonctionnalités '
          'IA de l\'application pour une gestion globale optimale.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  void _showEditBodyConditionDialog(BuildContext context) {
    double score = ref.read(horseNutritionAIProvider(_selectedHorseId!))?.bodyConditionScore ?? 5.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Score de condition corporelle'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Slider(
                value: score,
                min: 1,
                max: 9,
                divisions: 16,
                label: score.toStringAsFixed(1),
                onChanged: (value) {
                  setDialogState(() => score = value);
                },
              ),
              Text(_getScoreLabel(score)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              _updateBodyConditionScore(score);
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showEditDietTypeDialog(BuildContext context) {
    String dietType = ref.read(horseNutritionAIProvider(_selectedHorseId!))?.dietType ?? 'maintenance';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Type de régime'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDietOption(
                context,
                'maintenance',
                'Entretien',
                dietType,
                (v) => setDialogState(() => dietType = v),
              ),
              _buildDietOption(
                context,
                'weight_gain',
                'Prise de poids',
                dietType,
                (v) => setDialogState(() => dietType = v),
              ),
              _buildDietOption(
                context,
                'weight_loss',
                'Perte de poids',
                dietType,
                (v) => setDialogState(() => dietType = v),
              ),
              _buildDietOption(
                context,
                'performance',
                'Performance',
                dietType,
                (v) => setDialogState(() => dietType = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              _updateDietType(dietType);
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDietOption(
    BuildContext context,
    String value,
    String label,
    String selected,
    Function(String) onChanged,
  ) {
    return RadioListTile<String>(
      value: value,
      groupValue: selected,
      title: Text(label),
      onChanged: (v) => onChanged(v!),
    );
  }

  void _showAddSupplementDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un supplément'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nom du supplément',
            hintText: 'Ex: Biotine, MSM, Vitamine E...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _addSupplement(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showAddRestrictionDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une restriction'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Restriction alimentaire',
            hintText: 'Ex: Pas de mélasse, Limiter le foin...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _addRestriction(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _updateBodyConditionScore(double score) {
    final current = ref.read(horseNutritionAIProvider(_selectedHorseId!));
    final updated = NutritionAIData(
      bodyConditionScore: score,
      idealWeight: current?.idealWeight,
      currentWeight: current?.currentWeight,
      dietType: current?.dietType,
      dailyEnergyNeeds: current?.dailyEnergyNeeds,
      dailyProteinNeeds: current?.dailyProteinNeeds,
      dietaryRestrictions: current?.dietaryRestrictions ?? [],
      supplements: current?.supplements ?? [],
      currentPlanId: current?.currentPlanId,
      lastAssessment: DateTime.now(),
      feedingSchedule: current?.feedingSchedule,
    );
    ref.read(horseAINotifierProvider.notifier).updateNutritionData(
          _selectedHorseId!,
          updated,
        );
  }

  void _updateDietType(String dietType) {
    final current = ref.read(horseNutritionAIProvider(_selectedHorseId!));
    final updated = NutritionAIData(
      bodyConditionScore: current?.bodyConditionScore,
      idealWeight: current?.idealWeight,
      currentWeight: current?.currentWeight,
      dietType: dietType,
      dailyEnergyNeeds: current?.dailyEnergyNeeds,
      dailyProteinNeeds: current?.dailyProteinNeeds,
      dietaryRestrictions: current?.dietaryRestrictions ?? [],
      supplements: current?.supplements ?? [],
      currentPlanId: current?.currentPlanId,
      lastAssessment: DateTime.now(),
      feedingSchedule: current?.feedingSchedule,
    );
    ref.read(horseAINotifierProvider.notifier).updateNutritionData(
          _selectedHorseId!,
          updated,
        );
  }

  void _addSupplement(String supplement) {
    final current = ref.read(horseNutritionAIProvider(_selectedHorseId!));
    final supplements = List<String>.from(current?.supplements ?? []);
    supplements.add(supplement);

    final updated = NutritionAIData(
      bodyConditionScore: current?.bodyConditionScore,
      idealWeight: current?.idealWeight,
      currentWeight: current?.currentWeight,
      dietType: current?.dietType,
      dailyEnergyNeeds: current?.dailyEnergyNeeds,
      dailyProteinNeeds: current?.dailyProteinNeeds,
      dietaryRestrictions: current?.dietaryRestrictions ?? [],
      supplements: supplements,
      currentPlanId: current?.currentPlanId,
      lastAssessment: DateTime.now(),
      feedingSchedule: current?.feedingSchedule,
    );
    ref.read(horseAINotifierProvider.notifier).updateNutritionData(
          _selectedHorseId!,
          updated,
        );
  }

  void _removeSupplement(String supplement) {
    final current = ref.read(horseNutritionAIProvider(_selectedHorseId!));
    final supplements = List<String>.from(current?.supplements ?? []);
    supplements.remove(supplement);

    final updated = NutritionAIData(
      bodyConditionScore: current?.bodyConditionScore,
      idealWeight: current?.idealWeight,
      currentWeight: current?.currentWeight,
      dietType: current?.dietType,
      dailyEnergyNeeds: current?.dailyEnergyNeeds,
      dailyProteinNeeds: current?.dailyProteinNeeds,
      dietaryRestrictions: current?.dietaryRestrictions ?? [],
      supplements: supplements,
      currentPlanId: current?.currentPlanId,
      lastAssessment: DateTime.now(),
      feedingSchedule: current?.feedingSchedule,
    );
    ref.read(horseAINotifierProvider.notifier).updateNutritionData(
          _selectedHorseId!,
          updated,
        );
  }

  void _addRestriction(String restriction) {
    final current = ref.read(horseNutritionAIProvider(_selectedHorseId!));
    final restrictions = List<String>.from(current?.dietaryRestrictions ?? []);
    restrictions.add(restriction);

    final updated = NutritionAIData(
      bodyConditionScore: current?.bodyConditionScore,
      idealWeight: current?.idealWeight,
      currentWeight: current?.currentWeight,
      dietType: current?.dietType,
      dailyEnergyNeeds: current?.dailyEnergyNeeds,
      dailyProteinNeeds: current?.dailyProteinNeeds,
      dietaryRestrictions: restrictions,
      supplements: current?.supplements ?? [],
      currentPlanId: current?.currentPlanId,
      lastAssessment: DateTime.now(),
      feedingSchedule: current?.feedingSchedule,
    );
    ref.read(horseAINotifierProvider.notifier).updateNutritionData(
          _selectedHorseId!,
          updated,
        );
  }

  void _removeRestriction(String restriction) {
    final current = ref.read(horseNutritionAIProvider(_selectedHorseId!));
    final restrictions = List<String>.from(current?.dietaryRestrictions ?? []);
    restrictions.remove(restriction);

    final updated = NutritionAIData(
      bodyConditionScore: current?.bodyConditionScore,
      idealWeight: current?.idealWeight,
      currentWeight: current?.currentWeight,
      dietType: current?.dietType,
      dailyEnergyNeeds: current?.dailyEnergyNeeds,
      dailyProteinNeeds: current?.dailyProteinNeeds,
      dietaryRestrictions: restrictions,
      supplements: current?.supplements ?? [],
      currentPlanId: current?.currentPlanId,
      lastAssessment: DateTime.now(),
      feedingSchedule: current?.feedingSchedule,
    );
    ref.read(horseAINotifierProvider.notifier).updateNutritionData(
          _selectedHorseId!,
          updated,
        );
  }

  void _generateNutritionPlan(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Génération du plan nutritionnel...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'L\'IA analyse les données de votre cheval',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );

    // Simulate AI processing
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan nutritionnel généré avec succès!'),
          backgroundColor: AppColors.success,
        ),
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
