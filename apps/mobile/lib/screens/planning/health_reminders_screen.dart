import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/planning.dart';
import '../../providers/planning_provider.dart';
import '../../providers/horses_provider.dart';
import '../../theme/app_theme.dart';

/// Screen for managing health reminders (vaccinations, farrier, etc.)
class HealthRemindersScreen extends ConsumerStatefulWidget {
  final String? horseId; // Optional: filter by horse

  const HealthRemindersScreen({
    super.key,
    this.horseId,
  });

  @override
  ConsumerState<HealthRemindersScreen> createState() =>
      _HealthRemindersScreenState();
}

class _HealthRemindersScreenState extends ConsumerState<HealthRemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedHorseFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedHorseFilter = widget.horseId;
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
        title: const Text('Rappels sante'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'A venir'),
            Tab(text: 'En retard'),
            Tab(text: 'Tous'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingTab(),
          _buildOverdueTab(),
          _buildAllTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateReminderSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }

  Widget _buildUpcomingTab() {
    final remindersAsync = ref.watch(upcomingHealthRemindersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(upcomingHealthRemindersProvider);
      },
      child: remindersAsync.when(
        data: (reminders) {
          final filtered = _filterReminders(reminders);
          if (filtered.isEmpty) {
            return _buildEmptyState(
              icon: Icons.event_available,
              title: 'Aucun rappel a venir',
              subtitle: 'Les rappels des 30 prochains jours apparaitront ici',
            );
          }
          return _buildRemindersList(filtered);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildOverdueTab() {
    final remindersAsync = ref.watch(overdueHealthRemindersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(overdueHealthRemindersProvider);
      },
      child: remindersAsync.when(
        data: (reminders) {
          final filtered = _filterReminders(reminders);
          if (filtered.isEmpty) {
            return _buildEmptyState(
              icon: Icons.check_circle,
              title: 'Aucun rappel en retard',
              subtitle: 'Tout est a jour !',
            );
          }
          return _buildRemindersList(filtered);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildAllTab() {
    final remindersAsync = ref.watch(healthRemindersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(healthRemindersProvider);
      },
      child: remindersAsync.when(
        data: (reminders) {
          final filtered = _filterReminders(reminders);
          if (filtered.isEmpty) {
            return _buildEmptyState(
              icon: Icons.notifications_none,
              title: 'Aucun rappel',
              subtitle: 'Creez des rappels sante pour vos chevaux',
            );
          }
          return _buildRemindersList(filtered);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  List<HealthReminder> _filterReminders(List<HealthReminder> reminders) {
    if (_selectedHorseFilter == null) return reminders;
    return reminders
        .where((r) => r.horseId == _selectedHorseFilter)
        .toList();
  }

  Widget _buildRemindersList(List<HealthReminder> reminders) {
    // Group by horse
    final grouped = <String, List<HealthReminder>>{};
    for (final reminder in reminders) {
      final key = reminder.horseName ?? 'Unknown';
      grouped.putIfAbsent(key, () => []).add(reminder);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final horseName = grouped.keys.elementAt(index);
        final horseReminders = grouped[horseName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryContainer,
                    radius: 16,
                    child: const Icon(Icons.pets, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    horseName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            ...horseReminders.map((r) => _buildReminderCard(r)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildReminderCard(HealthReminder reminder) {
    final statusColor = reminder.status.color;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showReminderDetails(context, reminder),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon and status indicator
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(reminder.type.defaultColor).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  reminder.type.icon,
                  color: Color(reminder.type.defaultColor),
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.type.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(reminder.nextDueAt),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.repeat,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reminder.frequency.displayText,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      reminder.status.displayName,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (reminder.daysUntilDue != 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      reminder.isOverdue
                          ? '${-reminder.daysUntilDue} jours'
                          : '${reminder.daysUntilDue} jours',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppColors.textTertiary),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final horsesAsync = ref.read(horsesProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtrer par cheval',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.all_inclusive),
              ),
              title: const Text('Tous les chevaux'),
              selected: _selectedHorseFilter == null,
              onTap: () {
                setState(() => _selectedHorseFilter = null);
                Navigator.pop(context);
              },
            ),
            horsesAsync.maybeWhen(
              data: (horses) => Column(
                children: horses.map((horse) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryContainer,
                      child: const Icon(Icons.pets, color: AppColors.primary),
                    ),
                    title: Text(horse.name),
                    selected: _selectedHorseFilter == horse.id,
                    onTap: () {
                      setState(() => _selectedHorseFilter = horse.id);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              orElse: () => const LinearProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateReminderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _CreateHealthReminderForm(
          initialHorseId: widget.horseId,
          onCreated: () {
            ref.invalidate(healthRemindersProvider);
            ref.invalidate(upcomingHealthRemindersProvider);
            ref.invalidate(overdueHealthRemindersProvider);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showReminderDetails(BuildContext context, HealthReminder reminder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ReminderDetailsSheet(
        reminder: reminder,
        onMarkDone: () async {
          final notifier = ref.read(planningNotifierProvider.notifier);
          final success = await notifier.markHealthReminderDone(reminder.id);
          if (success && mounted) {
            Navigator.pop(context);
            ref.invalidate(healthRemindersProvider);
            ref.invalidate(upcomingHealthRemindersProvider);
            ref.invalidate(overdueHealthRemindersProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rappel marque comme effectue')),
            );
          }
        },
        onDelete: () async {
          final notifier = ref.read(planningNotifierProvider.notifier);
          final success = await notifier.deleteHealthReminder(reminder.id);
          if (success && mounted) {
            Navigator.pop(context);
            ref.invalidate(healthRemindersProvider);
            ref.invalidate(upcomingHealthRemindersProvider);
            ref.invalidate(overdueHealthRemindersProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rappel supprime')),
            );
          }
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Form for creating a new health reminder
class _CreateHealthReminderForm extends ConsumerStatefulWidget {
  final String? initialHorseId;
  final VoidCallback onCreated;

  const _CreateHealthReminderForm({
    this.initialHorseId,
    required this.onCreated,
  });

  @override
  ConsumerState<_CreateHealthReminderForm> createState() =>
      _CreateHealthReminderFormState();
}

class _CreateHealthReminderFormState
    extends ConsumerState<_CreateHealthReminderForm> {
  String? _selectedHorseId;
  HealthReminderType _type = HealthReminderType.vaccination;
  late HealthReminderFrequency _frequency;
  DateTime _nextDueAt = DateTime.now().add(const Duration(days: 7));
  int _reminderDaysBefore = 7;
  final _notesController = TextEditingController();
  final _vetNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedHorseId = widget.initialHorseId;
    _frequency = _type.defaultFrequency;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _vetNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horsesAsync = ref.watch(horsesProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nouveau rappel sante',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),

          // Horse selector
          horsesAsync.maybeWhen(
            data: (horses) => DropdownButtonFormField<String>(
              value: _selectedHorseId,
              decoration: const InputDecoration(
                labelText: 'Cheval *',
                prefixIcon: Icon(Icons.pets),
                border: OutlineInputBorder(),
              ),
              items: horses.map((horse) {
                return DropdownMenuItem(
                  value: horse.id,
                  child: Text(horse.name),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedHorseId = value),
              validator: (v) => v == null ? 'Requis' : null,
            ),
            orElse: () => const LinearProgressIndicator(),
          ),
          const SizedBox(height: 16),

          // Type selector
          DropdownButtonFormField<HealthReminderType>(
            value: _type,
            decoration: const InputDecoration(
              labelText: 'Type de rappel',
              prefixIcon: Icon(Icons.medical_services),
              border: OutlineInputBorder(),
            ),
            items: HealthReminderType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Row(
                  children: [
                    Icon(type.icon, size: 20, color: Color(type.defaultColor)),
                    const SizedBox(width: 12),
                    Text(type.displayName),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _type = value;
                  _frequency = value.defaultFrequency;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Frequency selector
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _frequency.interval,
                  decoration: const InputDecoration(
                    labelText: 'Frequence',
                    border: OutlineInputBorder(),
                  ),
                  items: [1, 2, 3, 4, 6, 8, 12].map((n) {
                    return DropdownMenuItem(
                      value: n,
                      child: Text('$n'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _frequency = HealthReminderFrequency(
                          type: _frequency.type,
                          interval: value,
                        );
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<FrequencyType>(
                  value: _frequency.type,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: FrequencyType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.pluralName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _frequency = HealthReminderFrequency(
                          type: value,
                          interval: _frequency.interval,
                        );
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Next due date
          OutlinedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _nextDueAt,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 730)),
              );
              if (date != null) {
                setState(() => _nextDueAt = date);
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(
              'Prochaine echeance: ${_formatDate(_nextDueAt)}',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 16),

          // Reminder days before
          DropdownButtonFormField<int>(
            value: _reminderDaysBefore,
            decoration: const InputDecoration(
              labelText: 'Rappel avant (jours)',
              prefixIcon: Icon(Icons.notifications),
              border: OutlineInputBorder(),
            ),
            items: [1, 3, 7, 14, 30].map((days) {
              return DropdownMenuItem(
                value: days,
                child: Text('$days jour${days > 1 ? 's' : ''} avant'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _reminderDaysBefore = value);
              }
            },
          ),
          const SizedBox(height: 16),

          // Vet name (optional)
          TextFormField(
            controller: _vetNameController,
            decoration: const InputDecoration(
              labelText: 'Veterinaire (optionnel)',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Notes (optional)
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optionnel)',
              prefixIcon: Icon(Icons.note),
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Creer le rappel'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _submit() async {
    if (_selectedHorseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez selectionner un cheval')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(planningNotifierProvider.notifier);
      final result = await notifier.createHealthReminder({
        'horseId': _selectedHorseId,
        'type': _type.name,
        'frequency': _frequency.toJson(),
        'nextDueAt': _nextDueAt.toIso8601String(),
        'reminderDaysBefore': _reminderDaysBefore,
        'vetName': _vetNameController.text.isNotEmpty
            ? _vetNameController.text
            : null,
        'notes': _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
      });

      if (result != null) {
        widget.onCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Bottom sheet showing reminder details
class _ReminderDetailsSheet extends StatelessWidget {
  final HealthReminder reminder;
  final VoidCallback onMarkDone;
  final VoidCallback onDelete;

  const _ReminderDetailsSheet({
    required this.reminder,
    required this.onMarkDone,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(reminder.type.defaultColor).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  reminder.type.icon,
                  color: Color(reminder.type.defaultColor),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.type.displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (reminder.horseName != null)
                      Text(
                        reminder.horseName!,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: reminder.status.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  reminder.status.displayName,
                  style: TextStyle(
                    color: reminder.status.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Details
          _buildDetailRow(
            Icons.calendar_today,
            'Prochaine echeance',
            _formatFullDate(reminder.nextDueAt),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.repeat,
            'Frequence',
            reminder.frequency.displayText,
          ),
          if (reminder.lastDoneAt != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.check_circle,
              'Derniere fois',
              _formatFullDate(reminder.lastDoneAt!),
            ),
          ],
          if (reminder.vetName != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(Icons.person, 'Veterinaire', reminder.vetName!),
          ],
          if (reminder.notes != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(Icons.note, 'Notes', reminder.notes!),
          ],
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Supprimer',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onMarkDone,
                  icon: const Icon(Icons.check),
                  label: const Text('Marquer fait'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatFullDate(DateTime date) {
    const months = [
      'janvier', 'fevrier', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'aout', 'septembre', 'octobre', 'novembre', 'decembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
