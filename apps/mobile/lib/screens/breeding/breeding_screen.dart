import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
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
    // This would fetch mares from the API
    // For now, showing a placeholder
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sélectionner une jument',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // Mock mare for demo
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.pets)),
              title: const Text('Belle Étoile'),
              subtitle: const Text('Selle Français • 8 ans'),
              onTap: () {
                setState(() {
                  _selectedMare = Horse(
                    id: 'mock-mare',
                    name: 'Belle Étoile',
                    gender: HorseGender.female,
                    breed: 'Selle Français',
                    status: HorseStatus.active,
                    organizationId: '',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Ajouter une nouvelle jument'),
              onTap: () {
                Navigator.pop(context);
                context.push('/horses/add');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeBreeding() async {
    setState(() => _isAnalyzing = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // Mock recommendations
    setState(() {
      _isAnalyzing = false;
      _recommendations = _getMockRecommendations();
    });
  }

  Widget _buildRecommendations() {
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
                    onPressed: () {},
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Fiche étalon'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
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

  List<BreedingRecommendation> _getMockRecommendations() {
    return [
      BreedingRecommendation(
        id: '1',
        mareId: _selectedMare!.id,
        mareName: _selectedMare!.name,
        stallionName: 'Diamant de Semilly',
        stallionStudbook: 'Selle Français • ISO 178',
        compatibilityScore: 92,
        strengths: ['Force', 'Respect des barres', 'Équilibre', 'Caractère'],
        weaknesses: ['Surveiller la taille'],
        expectedTraits: ['Puissance', 'Scope', 'Bon mental'],
        disciplineScores: {
          'CSO': 95,
          'CCE': 78,
          'Dressage': 65,
        },
        reasoning:
            'Diamant de Semilly apporte de la puissance et du respect. Ses origines complètent bien les points faibles de votre jument en renforçant l\'arrière-main.',
        createdAt: DateTime.now(),
      ),
      BreedingRecommendation(
        id: '2',
        mareId: _selectedMare!.id,
        mareName: _selectedMare!.name,
        stallionName: 'Sandro Boy',
        stallionStudbook: 'Holsteiner • ISO 165',
        compatibilityScore: 85,
        strengths: ['Locomotion', 'Cadre', 'Sang'],
        weaknesses: ['Tempérament vif'],
        expectedTraits: ['Élégance', 'Allures fluides', 'Réactivité'],
        disciplineScores: {
          'Dressage': 88,
          'CSO': 82,
          'CCE': 72,
        },
        reasoning:
            'Sandro Boy transmet d\'excellentes allures et un cadre harmonieux. Idéal si vous souhaitez un poulain polyvalent avec un potentiel dressage.',
        createdAt: DateTime.now(),
      ),
      BreedingRecommendation(
        id: '3',
        mareId: _selectedMare!.id,
        mareName: _selectedMare!.name,
        stallionName: 'Kannan',
        stallionStudbook: 'KWPN • ISO 170',
        compatibilityScore: 78,
        strengths: ['Rusticité', 'Longévité', 'Mental'],
        weaknesses: ['Peut manquer de sang'],
        expectedTraits: ['Solidité', 'Courage', 'Bon pied'],
        disciplineScores: {
          'CSO': 88,
          'CCE': 85,
          'Hunter': 70,
        },
        reasoning:
            'Kannan est reconnu pour transmettre du courage et de la solidité. Recommandé pour un poulain destiné au CCE ou au CSO de haut niveau.',
        createdAt: DateTime.now(),
      ),
    ];
  }
}
