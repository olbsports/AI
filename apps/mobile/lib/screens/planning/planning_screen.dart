import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/planning.dart';
import '../../providers/planning_provider.dart';
import '../../theme/app_theme.dart';

class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Planning'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Calendrier'),
            Tab(text: 'Objectifs'),
            Tab(text: 'Entraînement'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEventDialog(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarTab(),
          _buildGoalsTab(),
          _buildTrainingTab(),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    final eventsAsync = ref.watch(upcomingEventsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(upcomingEventsProvider);
        ref.invalidate(todayEventsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Date selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setState(() {
                          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                        }),
                      ),
                      Text(
                        _getMonthYear(_selectedDate),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setState(() {
                          _selectedDate = _selectedDate.add(const Duration(days: 7));
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildWeekSelector(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Today's events
          Text(
            'Aujourd\'hui',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, _) {
              final todayAsync = ref.watch(todayEventsProvider);
              return todayAsync.when(
                data: (events) => events.isEmpty
                    ? _buildEmptyState('Aucun événement aujourd\'hui')
                    : Column(
                        children: events.map((e) => _buildEventCard(e)).toList(),
                      ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Erreur'),
              );
            },
          ),
          const SizedBox(height: 24),

          // Upcoming events
          Text(
            'À venir',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          eventsAsync.when(
            data: (events) => events.isEmpty
                ? _buildEmptyState('Aucun événement à venir')
                : Column(
                    children: events
                        .where((e) => !e.isToday)
                        .take(10)
                        .map((e) => _buildEventCard(e))
                        .toList(),
                  ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Erreur'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsTab() {
    final goalsAsync = ref.watch(activeGoalsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(activeGoalsProvider),
      child: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flag, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Aucun objectif en cours'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddGoalDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Créer un objectif'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddGoalDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvel objectif'),
                  ),
                );
              }
              return _buildGoalCard(goals[index - 1]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildTrainingTab() {
    final planAsync = ref.watch(activeTrainingPlanProvider);
    final sessionAsync = ref.watch(todaySessionProvider);
    final recommendationsAsync = ref.watch(trainingRecommendationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activeTrainingPlanProvider);
        ref.invalidate(todaySessionProvider);
        ref.invalidate(trainingRecommendationsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Today's session
          Text(
            'Séance du jour',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          sessionAsync.when(
            data: (session) {
              if (session == null) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.fitness_center, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('Pas de séance prévue'),
                        const SizedBox(height: 16),
                        if (planAsync.value == null)
                          OutlinedButton.icon(
                            onPressed: () => _showCreateTrainingPlanDialog(context),
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Générer un plan IA'),
                          ),
                      ],
                    ),
                  ),
                );
              }
              return _buildSessionCard(session);
            },
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Erreur'),
          ),
          const SizedBox(height: 24),

          // Active plan
          planAsync.when(
            data: (plan) {
              if (plan == null) return const SizedBox();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan d\'entraînement',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildTrainingPlanCard(plan),
                ],
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 24),

          // Recommendations
          Text(
            'Recommandations IA',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          recommendationsAsync.when(
            data: (recommendations) => recommendations.isEmpty
                ? _buildEmptyState('Aucune recommandation')
                : Column(
                    children: recommendations.map((r) => _buildRecommendationCard(r)).toList(),
                  ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Erreur'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector() {
    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final day = startOfWeek.add(Duration(days: index));
        final isSelected = day.day == _selectedDate.day;
        final isToday = _isSameDay(day, DateTime.now());

        return GestureDetector(
          onTap: () => setState(() => _selectedDate = day),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : isToday ? AppColors.primary.withOpacity(0.1) : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  _getDayName(day),
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  day.day.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : null,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(event.type.defaultColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(event.type.icon, color: Color(event.type.defaultColor)),
        ),
        title: Text(
          event.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          event.isAllDay
              ? 'Toute la journée'
              : '${_formatTime(event.startDate)}${event.horseName != null ? ' - ${event.horseName}' : ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _buildEventStatusChip(event.status),
        onTap: () => _showEventDetails(event),
      ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(goal.category.icon, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    goal.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (goal.isOverdue)
                  const Icon(Icons.warning, color: Colors.orange),
              ],
            ),
            if (goal.description != null) ...[
              const SizedBox(height: 8),
              Text(
                goal.description!,
                style: TextStyle(color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: goal.progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(goal.progress * 100).toInt()}%',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${goal.currentValue.toInt()}/${goal.targetValue.toInt()} ${goal.unit ?? ''}',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  '${goal.daysRemaining} jours restants',
                  style: TextStyle(
                    color: goal.isOverdue ? Colors.red : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(TrainingSession session) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(session.intensity.color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: Color(session.intensity.color),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        session.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${session.type.displayName} - ${session.durationMinutes} min',
                        style: TextStyle(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(session.intensity.color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    session.intensity.displayName,
                    style: TextStyle(
                      color: Color(session.intensity.color),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (session.exercises.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Exercices',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...session.exercises.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 16),
                        const SizedBox(width: 8),
                        Text(e.name),
                        const Spacer(),
                        Text('${e.durationMinutes} min'),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: session.isCompleted ? null : () => _completeSession(session),
                child: Text(session.isCompleted ? 'Terminé' : 'Marquer comme fait'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingPlanCard(TrainingPlan plan) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        plan.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${plan.discipline.displayName} - ${plan.level.displayName}',
                        style: TextStyle(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  'Semaine ${plan.currentWeek}/${plan.weeksTotal}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: plan.progress,
                minHeight: 8,
                backgroundColor: Colors.grey.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(TrainingRecommendation recommendation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.lightbulb, color: AppColors.primary),
        ),
        title: Text(recommendation.title),
        subtitle: Text(
          recommendation.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _dismissRecommendation(recommendation),
        ),
      ),
    );
  }

  Widget _buildEventStatusChip(EventStatus status) {
    Color color;
    switch (status) {
      case EventStatus.scheduled:
        color = Colors.grey;
        break;
      case EventStatus.confirmed:
        color = Colors.green;
        break;
      case EventStatus.cancelled:
        color = Colors.red;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(message)),
      ),
    );
  }

  String _getMonthYear(DateTime date) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _getDayName(DateTime date) {
    const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return days[date.weekday - 1];
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showAddEventDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AddEventForm(
          onSubmit: (data) async {
            final notifier = ref.read(planningNotifierProvider.notifier);
            final result = await notifier.createEvent(data);
            if (result != null && context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Événement créé !')),
              );
            }
          },
        ),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AddGoalForm(
          onSubmit: (data) async {
            final notifier = ref.read(planningNotifierProvider.notifier);
            final result = await notifier.createGoal(data);
            if (result != null && context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Objectif créé !')),
              );
            }
          },
        ),
      ),
    );
  }

  void _showCreateTrainingPlanDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _CreateTrainingPlanForm(
          onSubmit: (data) async {
            final notifier = ref.read(planningNotifierProvider.notifier);
            final result = await notifier.createTrainingPlan(data);
            if (result != null && context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Plan d\'entraînement créé !')),
              );
            }
          },
        ),
      ),
    );
  }

  void _showEventDetails(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(event.type.icon, color: Color(event.type.defaultColor)),
            const SizedBox(width: 8),
            Expanded(child: Text(event.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(Icons.category, event.type.displayName),
              _buildDetailRow(Icons.calendar_today, _formatEventDate(event)),
              if (event.location != null)
                _buildDetailRow(Icons.location_on, event.location!),
              if (event.horseName != null)
                _buildDetailRow(Icons.pets, event.horseName!),
              if (event.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(event.description!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final notifier = ref.read(planningNotifierProvider.notifier);
              await notifier.deleteEvent(event.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Événement supprimé')),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  String _formatEventDate(CalendarEvent event) {
    final date = '${event.startDate.day}/${event.startDate.month}/${event.startDate.year}';
    if (event.isAllDay) return '$date (Journée)';
    return '$date à ${_formatTime(event.startDate)}';
  }

  void _completeSession(TrainingSession session) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CompleteSessionDialog(session: session),
    );

    if (result != null) {
      final plan = await ref.read(activeTrainingPlanProvider.future);
      if (plan != null) {
        final notifier = ref.read(planningNotifierProvider.notifier);
        await notifier.completeSession(
          plan.id,
          session.id,
          rating: result['rating'],
          notes: result['notes'],
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Séance terminée !')),
          );
        }
      }
    }
  }

  void _dismissRecommendation(TrainingRecommendation recommendation) {
    ref.read(planningNotifierProvider.notifier).dismissRecommendation(recommendation.id);
  }
}

// ==================== FORMS ====================

class _AddEventForm extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  const _AddEventForm({required this.onSubmit});

  @override
  State<_AddEventForm> createState() => _AddEventFormState();
}

class _AddEventFormState extends State<_AddEventForm> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  EventType _type = EventType.training;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  bool _isAllDay = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nouvel événement', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Titre *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<EventType>(
            value: _type,
            decoration: const InputDecoration(
              labelText: 'Type',
              border: OutlineInputBorder(),
            ),
            items: EventType.values.map((t) => DropdownMenuItem(
              value: t,
              child: Row(
                children: [
                  Icon(t.icon, size: 20),
                  const SizedBox(width: 8),
                  Text(t.displayName),
                ],
              ),
            )).toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setState(() => _startDate = date);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isAllDay ? null : () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (time != null) setState(() => _startTime = time);
                  },
                  icon: const Icon(Icons.access_time),
                  label: Text('${_startTime.hour}:${_startTime.minute.toString().padLeft(2, '0')}'),
                ),
              ),
            ],
          ),
          CheckboxListTile(
            title: const Text('Journée entière'),
            value: _isAllDay,
            onChanged: (v) => setState(() => _isAllDay = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Lieu',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre est requis')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final startDateTime = DateTime(
      _startDate.year, _startDate.month, _startDate.day,
      _startTime.hour, _startTime.minute,
    );
    await widget.onSubmit({
      'title': _titleController.text,
      'type': _type.name,
      'startDate': startDateTime.toIso8601String(),
      'isAllDay': _isAllDay,
      'location': _locationController.text.isNotEmpty ? _locationController.text : null,
      'description': _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
    });
    setState(() => _isLoading = false);
  }
}

class _AddGoalForm extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  const _AddGoalForm({required this.onSubmit});

  @override
  State<_AddGoalForm> createState() => _AddGoalFormState();
}

class _AddGoalFormState extends State<_AddGoalForm> {
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  GoalCategory _category = GoalCategory.training;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nouvel objectif', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Objectif *',
              hintText: 'Ex: Passer le Galop 5',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<GoalCategory>(
            value: _category,
            decoration: const InputDecoration(
              labelText: 'Catégorie',
              border: OutlineInputBorder(),
            ),
            items: GoalCategory.values.map((c) => DropdownMenuItem(
              value: c,
              child: Row(
                children: [
                  Icon(c.icon, size: 20),
                  const SizedBox(width: 8),
                  Text(c.displayName),
                ],
              ),
            )).toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Valeur cible',
              hintText: 'Ex: 10 (séances)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _targetDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 730)),
              );
              if (date != null) setState(() => _targetDate = date);
            },
            icon: const Icon(Icons.flag),
            label: Text('Date cible: ${_targetDate.day}/${_targetDate.month}/${_targetDate.year}'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('L\'objectif est requis')),
      );
      return;
    }
    setState(() => _isLoading = true);
    await widget.onSubmit({
      'title': _titleController.text,
      'category': _category.name,
      'type': 'count',
      'targetValue': double.tryParse(_targetController.text) ?? 1,
      'startDate': DateTime.now().toIso8601String(),
      'targetDate': _targetDate.toIso8601String(),
    });
    setState(() => _isLoading = false);
  }
}

class _CreateTrainingPlanForm extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  const _CreateTrainingPlanForm({required this.onSubmit});

  @override
  State<_CreateTrainingPlanForm> createState() => _CreateTrainingPlanFormState();
}

class _CreateTrainingPlanFormState extends State<_CreateTrainingPlanForm> {
  final _titleController = TextEditingController();
  TrainingDiscipline _discipline = TrainingDiscipline.general;
  TrainingLevel _level = TrainingLevel.intermediate;
  int _weeks = 4;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nouveau plan d\'entraînement', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Nom du plan *',
              hintText: 'Ex: Préparation concours',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TrainingDiscipline>(
            value: _discipline,
            decoration: const InputDecoration(
              labelText: 'Discipline',
              border: OutlineInputBorder(),
            ),
            items: TrainingDiscipline.values.map((d) => DropdownMenuItem(
              value: d,
              child: Text(d.displayName),
            )).toList(),
            onChanged: (v) => setState(() => _discipline = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TrainingLevel>(
            value: _level,
            decoration: const InputDecoration(
              labelText: 'Niveau',
              border: OutlineInputBorder(),
            ),
            items: TrainingLevel.values.map((l) => DropdownMenuItem(
              value: l,
              child: Text(l.displayName),
            )).toList(),
            onChanged: (v) => setState(() => _level = v!),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Durée: '),
              Expanded(
                child: Slider(
                  value: _weeks.toDouble(),
                  min: 1,
                  max: 12,
                  divisions: 11,
                  label: '$_weeks semaines',
                  onChanged: (v) => setState(() => _weeks = v.round()),
                ),
              ),
              Text('$_weeks sem.'),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom est requis')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final now = DateTime.now();
    await widget.onSubmit({
      'title': _titleController.text,
      'discipline': _discipline.name,
      'level': _level.name,
      'weeksTotal': _weeks,
      'startDate': now.toIso8601String(),
      'endDate': now.add(Duration(days: _weeks * 7)).toIso8601String(),
    });
    setState(() => _isLoading = false);
  }
}

class _CompleteSessionDialog extends StatefulWidget {
  final TrainingSession session;

  const _CompleteSessionDialog({required this.session});

  @override
  State<_CompleteSessionDialog> createState() => _CompleteSessionDialogState();
}

class _CompleteSessionDialogState extends State<_CompleteSessionDialog> {
  int _rating = 3;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Terminer la séance'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.session.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          const Text('Comment s\'est passée la séance ?'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => IconButton(
              icon: Icon(
                index < _rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 32,
              ),
              onPressed: () => setState(() => _rating = index + 1),
            )),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optionnel)',
              hintText: 'Commentaires sur la séance...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
            'rating': _rating,
            'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
          }),
          child: const Text('Terminer'),
        ),
      ],
    );
  }
}
