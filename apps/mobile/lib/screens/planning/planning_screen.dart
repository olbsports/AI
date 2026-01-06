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
        title: Text(event.title),
        subtitle: Text(
          event.isAllDay
              ? 'Toute la journée'
              : '${_formatTime(event.startDate)}${event.horseName != null ? ' - ${event.horseName}' : ''}',
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
                    children: [
                      Text(
                        session.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${session.type.displayName} - ${session.durationMinutes} min',
                        style: TextStyle(color: AppColors.textSecondary),
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
                    children: [
                      Text(
                        plan.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${plan.discipline.displayName} - ${plan.level.displayName}',
                        style: TextStyle(color: AppColors.textSecondary),
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

  void _showAddEventDialog(BuildContext context) {}
  void _showAddGoalDialog(BuildContext context) {}
  void _showCreateTrainingPlanDialog(BuildContext context) {}
  void _showEventDetails(CalendarEvent event) {}
  void _completeSession(TrainingSession session) {}
  void _dismissRecommendation(TrainingRecommendation recommendation) {
    ref.read(planningNotifierProvider.notifier).dismissRecommendation(recommendation.id);
  }
}
