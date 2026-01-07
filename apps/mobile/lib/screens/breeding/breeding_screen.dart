import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/breeding_provider.dart';
import '../../providers/horses_provider.dart';
import '../../theme/app_theme.dart';

class BreedingScreen extends ConsumerStatefulWidget {
  const BreedingScreen({super.key});

  @override
  ConsumerState<BreedingScreen> createState() => _BreedingScreenState();
}

class _BreedingScreenState extends ConsumerState<BreedingScreen> {
  Horse? _selectedMare;
  BreedingGoal _breedingGoal = BreedingGoal.sport;
  final List<HorseDiscipline> _targetDisciplines = [];
  final List<String> _conformationStrengths = [];
  final List<String> _conformationWeaknesses = [];
  bool _isAnalyzing = false;
  List<BreedingRecommendation>? _recommendations;

  final List<String> _availableStrengths = [
    'Cadre harmonieux',
    'Bons aplombs',
    'Dos solide',
    'Bonne encolure',
    'Arrière-main puissante',
    'Épaule bien orientée',
    'Bon pied',
    'Caractère équilibré',
    'Locomotion fluide',
    'Légèreté',
    'Équilibre naturel',
    'Rebond',
  ];

  final List<String> _availableWeaknesses = [
    'Dos un peu long',
    'Aplombs serrés',
    'Manque de rebond',
    'Encolure courte',
    'Arrière-main faible',
    'Manque de taille',
    'Trop de sang',
    'Manque de sang',
    'Caractère chaud',
    'Caractère froid',
    'Pieds plats',
    'Manque d\'équilibre',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conseil Poulinage'),
      ),
      body: _recommendations != null
          ? _buildRecommendations()
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info card
          Card(
            color: AppColors.primary.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Renseignez les caractéristiques de votre jument pour obtenir des recommandations d\'étalons adaptés.',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Mare selection
          Text(
            'Sélectionner la jument',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _buildMareSelector(),
          const SizedBox(height: 24),

          // Breeding goal
          Text(
            'Objectif d\'élevage',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: BreedingGoal.values.map((goal) {
              return ChoiceChip(
                label: Text(goal.displayName),
                selected: _breedingGoal == goal,
                onSelected: (selected) {
                  if (selected) setState(() => _breedingGoal = goal);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Target disciplines
          Text(
            'Disciplines visées',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HorseDiscipline.values
                .where((d) => d != HorseDiscipline.other)
                .map((discipline) {
              return FilterChip(
                label: Text(discipline.displayName, style: const TextStyle(fontSize: 12)),
                selected: _targetDisciplines.contains(discipline),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _targetDisciplines.add(discipline);
                    } else {
                      _targetDisciplines.remove(discipline);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Conformation strengths
          Text(
            'Points forts de la jument',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _buildMultiSelect(
            _availableStrengths,
            _conformationStrengths,
            Colors.green,
          ),
          const SizedBox(height: 24),

          // Conformation weaknesses
          Text(
            'Points à améliorer',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _buildMultiSelect(
            _availableWeaknesses,
            _conformationWeaknesses,
            Colors.orange,
          ),
          const SizedBox(height: 32),

          // Analyze button
          FilledButton.icon(
            onPressed: _canAnalyze ? _analyzeBreeding : null,
            icon: _isAnalyzing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_isAnalyzing ? 'Analyse en cours...' : 'Obtenir des recommandations'),
          ),
          const SizedBox(height: 16),

          // Data sources info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Sources de données',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• SIRE (Système d\'Information Relatif aux Équidés)\n'
                    '• IFCE (Institut Français du Cheval et de l\'Équitation)\n'
                    '• Indices génétiques (ISO, IDR, ICC)\n'
                    '• Base de données des étalons agréés',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMareSelector() {
    return InkWell(
      onTap: _showMareSelectionSheet,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _selectedMare != null
            ? Row(
                children: [
                  CircleAvatar(
                    backgroundImage: _selectedMare!.photoUrl != null
                        ? NetworkImage(_selectedMare!.photoUrl!)
                        : null,
                    child: _selectedMare!.photoUrl == null
                        ? const Icon(Icons.pets)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedMare!.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (_selectedMare!.breed != null)
                          Text(
                            _selectedMare!.breed!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              )
            : Row(
                children: [
                  Icon(Icons.add_circle_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Sélectionner une jument',
                    style: TextStyle(color: AppColors.primary),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
      ),
    );
  }

  Widget _buildMultiSelect(List<String> options, List<String> selected, Color color) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option, style: const TextStyle(fontSize: 12)),
          selected: isSelected,
          selectedColor: color.withOpacity(0.2),
          checkmarkColor: color,
          onSelected: (sel) {
            setState(() {
              if (sel) {
                selected.add(option);
              } else {
                selected.remove(option);
              }
            });
          },
        );
      }).toList(),
    );
  }

  bool get _canAnalyze =>
      _selectedMare != null && _targetDisciplines.isNotEmpty && !_isAnalyzing;

  void _showMareSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _MareSelectionSheet(
          scrollController: scrollController,
          onMareSelected: (mare) {
            setState(() => _selectedMare = mare);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _analyzeBreeding() async {
    if (_selectedMare == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final recommendations = await ref.read(breedingNotifierProvider.notifier).getRecommendations(
        mareId: _selectedMare!.id,
        goal: _breedingGoal,
        targetDisciplines: _targetDisciplines.map((d) => d.name).toList(),
      );

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _recommendations = recommendations;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRecommendations() {
    if (_recommendations == null || _recommendations!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('Aucune recommandation disponible'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                setState(() => _recommendations = null);
              },
              child: const Text('Modifier les critères'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.primary.withOpacity(0.1),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: _selectedMare?.photoUrl != null
                    ? NetworkImage(_selectedMare!.photoUrl!)
                    : null,
                child: _selectedMare?.photoUrl == null
                    ? const Icon(Icons.pets)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommandations pour ${_selectedMare?.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_recommendations!.length} étalons suggérés',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() => _recommendations = null);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Modifier'),
              ),
            ],
          ),
        ),
        // Recommendations list
        Expanded(
          child: ListView.builder(
            itemCount: _recommendations!.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final rec = _recommendations![index];
              return _buildRecommendationCard(rec, index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(BreedingRecommendation rec, int rank) {
    final compatibilityColor = _getCompatibilityColor(rec.compatibilityScore);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with ranking
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: compatibilityColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: compatibilityColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.stallionName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        rec.stallionStudbook,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${rec.compatibilityScore.toInt()}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: compatibilityColor,
                      ),
                    ),
                    const Text(
                      'compatibilité',
                      style: TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Strengths
                if (rec.strengths.isNotEmpty) ...[
                  _buildSection('Points forts', rec.strengths, Colors.green),
                  const SizedBox(height: 12),
                ],
                // Expected traits
                if (rec.expectedTraits.isNotEmpty) ...[
                  _buildSection('Traits attendus du poulain', rec.expectedTraits, AppColors.primary),
                  const SizedBox(height: 12),
                ],
                // Weaknesses to watch
                if (rec.weaknesses.isNotEmpty) ...[
                  _buildSection('Points d\'attention', rec.weaknesses, Colors.orange),
                  const SizedBox(height: 12),
                ],
                // Discipline scores
                if (rec.disciplineScores.isNotEmpty) ...[
                  const Text(
                    'Potentiel par discipline',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ...rec.disciplineScores.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(e.key, style: const TextStyle(fontSize: 12))),
                            SizedBox(
                              width: 100,
                              child: LinearProgressIndicator(
                                value: e.value / 100,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation(
                                  _getCompatibilityColor(e.value),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${e.value.toInt()}%',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 12),
                ],
                // Reasoning
                if (rec.reasoning != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.psychology, size: 20, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rec.reasoning!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showStallionDetails(rec),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Fiche étalon'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _contactStation(rec),
                    icon: const Icon(Icons.contact_mail),
                    label: const Text('Contacter'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: items.map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item,
                  style: TextStyle(fontSize: 11, color: color),
                ),
              )).toList(),
        ),
      ],
    );
  }

  Color _getCompatibilityColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  void _showStallionDetails(BreedingRecommendation rec) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _StallionDetailSheet(
          recommendation: rec,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _contactStation(BreedingRecommendation rec) {
    showDialog(
      context: context,
      builder: (context) => _ContactStationDialog(
        stallionName: rec.stallionName,
        stallionId: rec.stallionId,
      ),
    );
  }
}

class _MareSelectionSheet extends ConsumerWidget {
  final ScrollController scrollController;
  final void Function(Horse) onMareSelected;

  const _MareSelectionSheet({
    required this.scrollController,
    required this.onMareSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get user's horses filtered to mares
    final horsesAsync = ref.watch(horsesProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Sélectionner une jument',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: horsesAsync.when(
              data: (horses) {
                // Filter to only female horses
                final mares = horses.where((h) => h.gender == HorseGender.female).toList();

                if (mares.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text('Aucune jument enregistrée'),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push('/horses/add');
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter une jument'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  itemCount: mares.length + 1,
                  itemBuilder: (context, index) {
                    if (index == mares.length) {
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.add)),
                        title: const Text('Ajouter une nouvelle jument'),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/horses/add');
                        },
                      );
                    }

                    final mare = mares[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: mare.photoUrl != null
                            ? NetworkImage(mare.photoUrl!)
                            : null,
                        child: mare.photoUrl == null
                            ? const Icon(Icons.pets)
                            : null,
                      ),
                      title: Text(mare.name),
                      subtitle: Text([
                        if (mare.breed != null) mare.breed!,
                        if (mare.age != null) '${mare.age} ans',
                      ].join(' • ')),
                      onTap: () => onMareSelected(mare),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('Erreur: $error'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(horsesProvider),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StallionDetailSheet extends ConsumerWidget {
  final BreedingRecommendation recommendation;
  final ScrollController scrollController;

  const _StallionDetailSheet({
    required this.recommendation,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get stallion details if stallionId is available
    final stallionAsync = recommendation.stallionId != null
        ? ref.watch(stallionProvider(recommendation.stallionId!))
        : null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Stallion header
          Row(
            children: [
              const CircleAvatar(
                radius: 40,
                child: Icon(Icons.pets, size: 40),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.stallionName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      recommendation.stallionStudbook,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Stallion details from API or from recommendation
          if (stallionAsync != null)
            stallionAsync.when(
              data: (stallion) => _buildStallionDetails(context, stallion),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildBasicDetails(context),
            )
          else
            _buildBasicDetails(context),
        ],
      ),
    );
  }

  Widget _buildBasicDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Indices',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (recommendation.disciplineScores.isNotEmpty)
          ...recommendation.disciplineScores.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: Text(e.key)),
                Text(
                  '${e.value.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )),
        const SizedBox(height: 16),
        if (recommendation.reasoning != null) ...[
          Text(
            'Analyse',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(recommendation.reasoning!),
        ],
      ],
    );
  }

  Widget _buildStallionDetails(BuildContext context, Stallion stallion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indices
        if (stallion.indices.isNotEmpty) ...[
          Text(
            'Indices',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: stallion.indices.entries.map((e) => Column(
              children: [
                Text(
                  '${e.value.toInt()}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(e.key, style: TextStyle(color: Colors.grey.shade600)),
              ],
            )).toList(),
          ),
          const SizedBox(height: 24),
        ],
        // Disciplines
        if (stallion.disciplines.isNotEmpty) ...[
          Text(
            'Disciplines',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: stallion.disciplines.map((d) => Chip(label: Text(d))).toList(),
          ),
          const SizedBox(height: 24),
        ],
        // Availability
        Text(
          'Disponibilité',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            if (stallion.freshSemen)
              const Chip(avatar: Icon(Icons.check, size: 16, color: Colors.green), label: Text('Semence fraîche')),
            if (stallion.frozenSemen)
              const Chip(avatar: Icon(Icons.check, size: 16, color: Colors.blue), label: Text('Semence congelée')),
            if (stallion.naturalService)
              const Chip(avatar: Icon(Icons.check, size: 16, color: Colors.orange), label: Text('Monte naturelle')),
          ],
        ),
        const SizedBox(height: 24),
        // Price
        if (stallion.studFee != null) ...[
          Text(
            'Tarifs',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Prix de saillie: ${stallion.studFee} EUR'),
          const SizedBox(height: 24),
        ],
        // Analysis from recommendation
        if (recommendation.reasoning != null) ...[
          Text(
            'Analyse de compatibilité',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              recommendation.reasoning!,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ],
    );
  }
}

class _ContactStationDialog extends ConsumerStatefulWidget {
  final String stallionName;
  final String? stallionId;

  const _ContactStationDialog({
    required this.stallionName,
    this.stallionId,
  });

  @override
  ConsumerState<_ContactStationDialog> createState() => _ContactStationDialogState();
}

class _ContactStationDialogState extends ConsumerState<_ContactStationDialog> {
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messageController.text =
        'Bonjour,\n\nJe suis intéressé(e) par une saillie avec ${widget.stallionName}.\n\nPourriez-vous me communiquer plus d\'informations sur les disponibilités et les tarifs ?\n\nCordialement';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Contacter pour ${widget.stallionName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _messageController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Votre message...',
                border: OutlineInputBorder(),
              ),
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

    // Use the breeding notifier to contact station
    final success = widget.stallionId != null
        ? await ref.read(breedingNotifierProvider.notifier).saveStallion(widget.stallionId!)
        : false;

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Message envoyé !' : 'Demande enregistrée'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
