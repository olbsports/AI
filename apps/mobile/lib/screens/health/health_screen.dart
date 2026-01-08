import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/health.dart';
import '../../providers/health_provider.dart';
import '../../providers/horses_provider.dart';
import '../../theme/app_theme.dart';

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedHorseId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horsesAsync = ref.watch(horsesNotifierProvider);
    final remindersAsync = ref.watch(healthRemindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Santé'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Rappels'),
            Tab(text: 'Carnet'),
            Tab(text: 'Poids'),
            Tab(text: 'Nutrition'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRecordDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Horse selector
          horsesAsync.when(
            data: (horses) => Container(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedHorseId,
                decoration: const InputDecoration(
                  labelText: 'Cheval',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                hint: const Text('Tous les chevaux'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Tous les chevaux'),
                  ),
                  ...horses.map((h) => DropdownMenuItem(
                        value: h.id,
                        child: Text(h.name),
                      )),
                ],
                onChanged: (value) => setState(() => _selectedHorseId = value),
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRemindersTab(remindersAsync),
                _buildHealthRecordsTab(),
                _buildWeightTab(),
                _buildNutritionTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRecordDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }

  Widget _buildRemindersTab(AsyncValue<List<HealthReminder>> remindersAsync) {
    return remindersAsync.when(
      data: (reminders) {
        final overdue = reminders.where((r) => r.isOverdue).toList();
        final upcoming = reminders.where((r) => !r.isOverdue && !r.isCompleted).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(healthRemindersProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (overdue.isNotEmpty) ...[
                _buildSectionHeader('En retard', Icons.warning, Colors.red),
                ...overdue.map((r) => _buildReminderCard(r, isOverdue: true)),
                const SizedBox(height: 24),
              ],
              if (upcoming.isNotEmpty) ...[
                _buildSectionHeader('À venir', Icons.schedule, Colors.blue),
                ...upcoming.map((r) => _buildReminderCard(r)),
              ],
              if (overdue.isEmpty && upcoming.isEmpty)
                _buildEmptyState('Aucun rappel', Icons.check_circle),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }

  Widget _buildHealthRecordsTab() {
    if (_selectedHorseId == null) {
      return _buildSelectHorsePrompt();
    }

    final recordsAsync = ref.watch(healthRecordsProvider(_selectedHorseId!));

    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return _buildEmptyState('Aucun enregistrement', Icons.medical_services);
        }

        // Group by type
        final grouped = <HealthRecordType, List<HealthRecord>>{};
        for (final record in records) {
          grouped.putIfAbsent(record.type, () => []).add(record);
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(healthRecordsProvider(_selectedHorseId!)),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final type = grouped.keys.elementAt(index);
              final typeRecords = grouped[type]!;
              return _buildRecordTypeSection(type, typeRecords);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }

  Widget _buildWeightTab() {
    if (_selectedHorseId == null) {
      return _buildSelectHorsePrompt();
    }

    final weightAsync = ref.watch(weightRecordsProvider(_selectedHorseId!));
    final bcsAsync = ref.watch(bodyConditionRecordsProvider(_selectedHorseId!));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(weightRecordsProvider(_selectedHorseId!));
        ref.invalidate(bodyConditionRecordsProvider(_selectedHorseId!));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Weight chart placeholder
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Évolution du poids',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  weightAsync.when(
                    data: (weights) {
                      if (weights.isEmpty) {
                        return const SizedBox(
                          height: 150,
                          child: Center(child: Text('Aucune donnée')),
                        );
                      }
                      final latest = weights.first;
                      return Column(
                        children: [
                          Text(
                            '${latest.weight.toStringAsFixed(0)} kg',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Dernière mesure: ${_formatDate(latest.date)}',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Erreur'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Body condition
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'État corporel (Henneke)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  bcsAsync.when(
                    data: (records) {
                      if (records.isEmpty) {
                        return const Text('Aucune évaluation');
                      }
                      final latest = records.first;
                      return Row(
                        children: [
                          _buildBodyConditionIndicator(latest.score),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Score: ${latest.score}/9',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  latest.scoreDescription,
                                  style: TextStyle(color: AppColors.textSecondary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Erreur'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Add weight button
          ElevatedButton.icon(
            onPressed: () => _showAddWeightDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une pesée'),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionTab() {
    if (_selectedHorseId == null) {
      return _buildSelectHorsePrompt();
    }

    final nutritionAsync = ref.watch(nutritionPlanProvider(_selectedHorseId!));

    return nutritionAsync.when(
      data: (plan) {
        if (plan == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.restaurant, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Aucun plan nutritionnel'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showCreateNutritionPlanDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Créer un plan'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showNutritionCalculator(context),
                  icon: const Icon(Icons.calculate),
                  label: const Text('Calculateur'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(nutritionPlanProvider(_selectedHorseId!)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              plan.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          if (plan.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Actif',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildNutritionStat('Calories', '${plan.totalCalories} kcal'),
                      _buildNutritionStat('Protéines', '${plan.totalProtein.toStringAsFixed(0)} g'),
                      _buildNutritionStat('Fibres', '${plan.totalFiber.toStringAsFixed(1)} kg'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Rations',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...plan.items.map((item) => _buildFeedingItemCard(item)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(HealthReminder reminder, {bool isOverdue = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(reminder.type.color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            reminder.type.icon,
            color: Color(reminder.type.color),
          ),
        ),
        title: Text(reminder.title),
        subtitle: Text(
          '${reminder.horseName} - ${_formatDate(reminder.dueDate)}',
          style: TextStyle(
            color: isOverdue ? Colors.red : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              color: Colors.green,
              onPressed: () => _completeReminder(reminder),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              color: Colors.grey,
              onPressed: () => _dismissReminder(reminder),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordTypeSection(HealthRecordType type, List<HealthRecord> records) {
    return ExpansionTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(type.color).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(type.icon, color: Color(type.color)),
      ),
      title: Text(type.displayName),
      subtitle: Text('${records.length} enregistrements'),
      children: records.map((r) => _buildRecordCard(r)).toList(),
    );
  }

  Widget _buildRecordCard(HealthRecord record) {
    return ListTile(
      title: Text(record.title),
      subtitle: Text(_formatDate(record.date)),
      trailing: record.isOverdue
          ? const Icon(Icons.warning, color: Colors.orange)
          : record.isDueSoon
              ? const Icon(Icons.schedule, color: Colors.blue)
              : null,
      onTap: () => _showRecordDetails(record),
    );
  }

  Widget _buildBodyConditionIndicator(int score) {
    Color color;
    if (score <= 3) {
      color = Colors.red;
    } else if (score <= 4) {
      color = Colors.orange;
    } else if (score <= 6) {
      color = Colors.green;
    } else if (score <= 7) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
      ),
      child: Center(
        child: Text(
          score.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFeedingItemCard(FeedingItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(item.type.displayName[0]),
        ),
        title: Text(item.name),
        subtitle: Text('${item.feedingTime.displayName} - ${item.quantity} kg'),
        trailing: item.calories != null
            ? Text('${item.calories} kcal')
            : null,
      ),
    );
  }

  Widget _buildSelectHorsePrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pets, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Sélectionnez un cheval'),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddRecordDialog(BuildContext context) {
    final typeController = TextEditingController();
    final notesController = TextEditingController();
    HealthRecordType selectedType = HealthRecordType.vaccination;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ajouter un suivi santé', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<HealthRecordType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: HealthRecordType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                )).toList(),
                onChanged: (value) => setSheetState(() => selectedType = value!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Suivi santé ajouté')),
                    );
                  },
                  child: const Text('Ajouter'),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      typeController.dispose();
      notesController.dispose();
    });
  }

  void _showAddWeightDialog(BuildContext context) {
    final weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ajouter un poids'),
        content: TextField(
          controller: weightController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Poids (kg)',
            suffixText: 'kg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Poids enregistré')),
              );
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    ).then((_) => weightController.dispose());
  }

  void _showCreateNutritionPlanDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Créer un plan nutritionnel', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const Text('Fonctionnalité bientôt disponible'),
            const SizedBox(height: 8),
            const Text('Le plan nutritionnel sera généré automatiquement en fonction du poids, de l\'activité et des besoins de votre cheval.'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Compris'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNutritionCalculator(BuildContext context) {
    final weightController = TextEditingController(text: '500');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Calculateur nutritionnel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Poids du cheval (kg)',
                suffixText: 'kg',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Besoins journaliers estimés:'),
            const SizedBox(height: 8),
            const Text('• Foin: 10-12 kg'),
            const Text('• Eau: 25-35 litres'),
            const Text('• Sel: 30-50 g'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
        ],
      ),
    ).then((_) => weightController.dispose());
  }

  void _showRecordDetails(HealthRecord record) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(record.type.icon, color: Color(record.type.color)),
            const SizedBox(width: 8),
            Expanded(child: Text(record.type.displayName)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${_formatDate(record.date)}'),
            if (record.veterinarian != null) ...[
              const SizedBox(height: 8),
              Text('Vétérinaire: ${record.veterinarian}'),
            ],
            if (record.description != null) ...[
              const SizedBox(height: 8),
              Text('Notes: ${record.description}'),
            ],
            if (record.nextDueDate != null) ...[
              const SizedBox(height: 8),
              Text('Prochain RDV: ${_formatDate(record.nextDueDate!)}'),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _completeReminder(HealthReminder reminder) {
    ref.read(healthNotifierProvider.notifier).completeReminder(reminder.id);
  }

  void _dismissReminder(HealthReminder reminder) {
    ref.read(healthNotifierProvider.notifier).dismissReminder(reminder.id);
  }
}
