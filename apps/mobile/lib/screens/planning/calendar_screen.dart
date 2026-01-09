import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/planning.dart';
import '../../providers/planning_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/calendar/calendar_widget.dart';
import '../../widgets/calendar/event_card_widget.dart';
import '../../widgets/calendar/quick_add_event_fab.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';
import 'health_reminders_screen.dart';

/// Main calendar screen with full calendar functionality
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  CalendarViewMode _viewMode = CalendarViewMode.month;
  Set<EventType> _selectedFilters = {};
  bool _showFilterBar = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 2, 0);

    final eventsAsync = ref.watch(
      calendarEventsProvider((start: startOfMonth, end: endOfMonth)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier'),
        actions: [
          // Filter toggle
          IconButton(
            icon: Badge(
              isLabelVisible: _selectedFilters.isNotEmpty,
              label: Text('${_selectedFilters.length}'),
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () {
              setState(() => _showFilterBar = !_showFilterBar);
            },
          ),
          // Health reminders
          IconButton(
            icon: const Icon(Icons.vaccines),
            onPressed: () => _openHealthReminders(context),
          ),
          // More menu
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'agenda':
                  setState(() => _viewMode = CalendarViewMode.agenda);
                  break;
                case 'today':
                  setState(() {
                    _selectedDate = DateTime.now();
                  });
                  break;
                case 'export':
                  _showExportDialog(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'agenda',
                child: Row(
                  children: [
                    Icon(Icons.list),
                    SizedBox(width: 12),
                    Text('Vue agenda'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'today',
                child: Row(
                  children: [
                    Icon(Icons.today),
                    SizedBox(width: 12),
                    Text('Aller a aujourd\'hui'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.ios_share),
                    SizedBox(width: 12),
                    Text('Exporter iCal'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          if (_showFilterBar) ...[
            EventTypeFilterBar(
              selectedTypes: _selectedFilters,
              onTypeToggled: (type) {
                setState(() {
                  if (_selectedFilters.contains(type)) {
                    _selectedFilters.remove(type);
                  } else {
                    _selectedFilters.add(type);
                  }
                });
              },
              onClearAll: () {
                setState(() => _selectedFilters.clear());
              },
            ),
            const Divider(height: 1),
          ],

          // Calendar view
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                final filteredEvents = _selectedFilters.isEmpty
                    ? events
                    : events
                        .where((e) => _selectedFilters.contains(e.type))
                        .toList();

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(calendarEventsProvider);
                  },
                  child: CalendarWidget(
                    initialDate: _selectedDate,
                    initialViewMode: _viewMode,
                    events: filteredEvents,
                    eventTypeFilters: _selectedFilters.isEmpty
                        ? null
                        : _selectedFilters,
                    onDateSelected: (date) {
                      setState(() => _selectedDate = date);
                    },
                    onEventTap: (event) => _openEventDetails(context, event),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Erreur: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(calendarEventsProvider),
                      child: const Text('Reessayer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: QuickAddEventFAB(
        selectedDate: _selectedDate,
        onEventTypeSelected: (type, date) {
          _openEventForm(context, type: type, date: date);
        },
        onHealthReminderTap: () => _openHealthReminders(context),
      ),
    );
  }

  void _openEventDetails(BuildContext context, CalendarEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    ).then((result) {
      if (result == true) {
        ref.invalidate(calendarEventsProvider);
      }
    });
  }

  void _openEventForm(
    BuildContext context, {
    EventType? type,
    DateTime? date,
    CalendarEvent? event,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventFormScreen(
          event: event,
          initialType: type,
          initialDate: date,
        ),
      ),
    ).then((result) {
      if (result != null) {
        ref.invalidate(calendarEventsProvider);
      }
    });
  }

  void _openHealthReminders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HealthRemindersScreen(),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exporter le calendrier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Lien iCal'),
              subtitle: const Text('Synchroniser avec votre calendrier'),
              onTap: () {
                Navigator.pop(context);
                _showICalLinkDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Fichier .ics'),
              subtitle: const Text('Telecharger les evenements'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export en cours...')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showICalLinkDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lien iCal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Copiez ce lien pour synchroniser avec Google Calendar, Apple Calendar ou Outlook.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SelectableText(
                'https://api.horsetempo.com/calendar/feed/xxx-xxx-xxx',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lien copie !')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copier'),
          ),
        ],
      ),
    );
  }
}

/// Calendar agenda view showing events grouped by day
class CalendarAgendaView extends ConsumerWidget {
  final DateTime startDate;
  final int daysToShow;
  final Function(CalendarEvent)? onEventTap;

  const CalendarAgendaView({
    super.key,
    required this.startDate,
    this.daysToShow = 30,
    this.onEventTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final endDate = startDate.add(Duration(days: daysToShow));
    final eventsAsync = ref.watch(
      calendarEventsProvider((start: startDate, end: endDate)),
    );

    return eventsAsync.when(
      data: (events) {
        // Group events by date
        final grouped = <DateTime, List<CalendarEvent>>{};
        for (final event in events) {
          final dateKey = DateTime(
            event.startDate.year,
            event.startDate.month,
            event.startDate.day,
          );
          grouped.putIfAbsent(dateKey, () => []).add(event);
        }

        final sortedDates = grouped.keys.toList()
          ..sort((a, b) => a.compareTo(b));

        if (sortedDates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_note,
                  size: 64,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun evenement a venir',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final dayEvents = grouped[date]!
              ..sort((a, b) => a.startDate.compareTo(b.startDate));

            return _buildDaySection(context, date, dayEvents);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }

  Widget _buildDaySection(
    BuildContext context,
    DateTime date,
    List<CalendarEvent> events,
  ) {
    final isToday = _isSameDay(date, DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isToday ? AppColors.primary : AppColors.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getShortDayName(date),
                      style: TextStyle(
                        color: isToday ? Colors.white70 : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        color: isToday ? Colors.white : null,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'AUJOURD\'HUI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Text(
                      _formatDateHeader(date),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${events.length} evt',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Events
        ...events.map((event) {
          return EventCardWidget(
            event: event,
            showDate: false,
            onTap: () => onEventTap?.call(event),
          );
        }),

        const SizedBox(height: 8),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getShortDayName(DateTime date) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[date.weekday - 1];
  }

  String _formatDateHeader(DateTime date) {
    const months = [
      'janvier', 'fevrier', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'aout', 'septembre', 'octobre', 'novembre', 'decembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

/// Widget showing today's events summary
class TodayEventsWidget extends ConsumerWidget {
  final Function(CalendarEvent)? onEventTap;
  final VoidCallback? onViewAll;

  const TodayEventsWidget({
    super.key,
    this.onEventTap,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(todayEventsProvider);

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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.today,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Aujourd\'hui',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('Voir tout'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            eventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 32,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pas d\'evenement aujourd\'hui',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: events.take(3).map((event) {
                    return EventCardWidget(
                      event: event,
                      showDate: false,
                      compact: true,
                      onTap: () => onEventTap?.call(event),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('Erreur: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget showing upcoming events
class UpcomingEventsWidget extends ConsumerWidget {
  final int maxEvents;
  final Function(CalendarEvent)? onEventTap;
  final VoidCallback? onViewAll;

  const UpcomingEventsWidget({
    super.key,
    this.maxEvents = 5,
    this.onEventTap,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(upcomingEventsProvider);

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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.upcoming,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'A venir',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('Voir tout'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            eventsAsync.when(
              data: (events) {
                final upcoming = events.where((e) => !e.isToday).take(maxEvents).toList();

                if (upcoming.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_note,
                            size: 32,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pas d\'evenement a venir',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: upcoming.map((event) {
                    return EventCardWidget(
                      event: event,
                      compact: true,
                      onTap: () => onEventTap?.call(event),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('Erreur: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
