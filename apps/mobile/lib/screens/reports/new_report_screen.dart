import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/report.dart';
import '../../models/horse.dart';
import '../../models/analysis.dart';
import '../../providers/reports_provider.dart';
import '../../providers/horses_provider.dart';
import '../../providers/analyses_provider.dart';
import '../../widgets/loading_button.dart';

class NewReportScreen extends ConsumerStatefulWidget {
  final String? horseId;

  const NewReportScreen({super.key, this.horseId});

  @override
  ConsumerState<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends ConsumerState<NewReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  String? _selectedHorseId;
  ReportType _selectedType = ReportType.progress;
  List<String> _selectedAnalysisIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedHorseId = widget.horseId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHorseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un cheval'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final report = await ref.read(reportsNotifierProvider.notifier).createReport(
        horseId: _selectedHorseId!,
        type: _selectedType.name.toUpperCase(),
        title: _titleController.text.isNotEmpty ? _titleController.text : null,
        analysisIds: _selectedAnalysisIds.isNotEmpty ? _selectedAnalysisIds : null,
      );

      if (mounted) {
        if (report != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rapport créé avec succès')),
          );
          context.go('/reports/${report.id}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la création'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final horsesAsync = ref.watch(horsesNotifierProvider);
    final analysesAsync = _selectedHorseId != null
        ? ref.watch(horseAnalysesProvider(_selectedHorseId!))
        : const AsyncValue<List<Analysis>>.data([]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau rapport'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Horse selection
              _buildHorseSelection(horsesAsync),
              const SizedBox(height: 16),

              // Report type
              _buildTypeSelection(),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre (optionnel)',
                  prefixIcon: Icon(Icons.title),
                  hintText: 'Ex: Bilan mensuel de Mars',
                ),
              ),
              const SizedBox(height: 24),

              // Analyses selection
              if (_selectedHorseId != null) ...[
                _buildAnalysesSelection(analysesAsync),
                const SizedBox(height: 24),
              ],

              // Submit button
              LoadingButton(
                onPressed: _handleSubmit,
                isLoading: _isLoading,
                text: 'Générer le rapport',
                icon: Icons.description,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorseSelection(AsyncValue<List<Horse>> horsesAsync) {
    return horsesAsync.when(
      data: (horses) {
        if (horses.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.pets,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  const Text('Aucun cheval enregistré'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/horses/add'),
                    child: const Text('Ajouter un cheval'),
                  ),
                ],
              ),
            ),
          );
        }

        return DropdownButtonFormField<String>(
          value: _selectedHorseId,
          decoration: const InputDecoration(
            labelText: 'Cheval *',
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
              _selectedAnalysisIds = [];
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Veuillez sélectionner un cheval';
            }
            return null;
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Erreur de chargement des chevaux'),
    );
  }

  Widget _buildTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de rapport',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ReportType.values.map((type) {
            return _buildTypeChip(type);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTypeChip(ReportType type) {
    final isSelected = _selectedType == type;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getTypeIcon(type),
            size: 18,
            color: isSelected
                ? Theme.of(context).colorScheme.onSecondaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _typeLabel(type),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      onSelected: (_) {
        setState(() => _selectedType = type);
      },
    );
  }

  Widget _buildAnalysesSelection(AsyncValue<List<Analysis>> analysesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analyses à inclure (optionnel)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Sélectionnez les analyses à utiliser pour générer le rapport',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        analysesAsync.when(
          data: (analyses) {
            final completedAnalyses = analyses
                .where((a) => a.status == AnalysisStatus.completed)
                .toList();

            if (completedAnalyses.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Aucune analyse disponible',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: completedAnalyses.map((analysis) {
                final isSelected = _selectedAnalysisIds.contains(analysis.id);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedAnalysisIds.add(analysis.id);
                        } else {
                          _selectedAnalysisIds.remove(analysis.id);
                        }
                      });
                    },
                    secondary: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.analytics,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    title: Text(
                      analysis.type.toString().split('.').last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${analysis.createdAt.day}/${analysis.createdAt.month}/${analysis.createdAt.year}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => const Text('Erreur de chargement'),
        ),
      ],
    );
  }

  IconData _getTypeIcon(ReportType type) {
    switch (type) {
      case ReportType.radiological:
        return Icons.medical_information;
      case ReportType.locomotion:
        return Icons.directions_walk;
      case ReportType.courseAnalysis:
        return Icons.analytics;
      case ReportType.purchaseExam:
        return Icons.fact_check;
      case ReportType.progress:
        return Icons.trending_up;
      case ReportType.veterinary:
        return Icons.medical_services;
      case ReportType.training:
        return Icons.fitness_center;
      case ReportType.competition:
        return Icons.emoji_events;
      case ReportType.health:
        return Icons.favorite;
    }
  }

  String _typeLabel(ReportType type) {
    switch (type) {
      case ReportType.radiological:
        return 'Radiologique';
      case ReportType.locomotion:
        return 'Locomotion';
      case ReportType.courseAnalysis:
        return 'Analyse parcours';
      case ReportType.purchaseExam:
        return 'Visite d\'achat';
      case ReportType.progress:
        return 'Progression';
      case ReportType.veterinary:
        return 'Vétérinaire';
      case ReportType.training:
        return 'Entraînement';
      case ReportType.competition:
        return 'Compétition';
      case ReportType.health:
        return 'Santé';
    }
  }
}
