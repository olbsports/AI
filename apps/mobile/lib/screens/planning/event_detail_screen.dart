import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/planning.dart';
import '../../providers/planning_provider.dart';
import '../../theme/app_theme.dart';
import 'widgets/recurring_event_selector.dart';

/// Screen showing detailed view of a calendar event
class EventDetailScreen extends ConsumerStatefulWidget {
  final CalendarEvent event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  late CalendarEvent _event;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  @override
  Widget build(BuildContext context) {
    final eventColor = Color(_event.type.defaultColor);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with colored header
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: eventColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      eventColor,
                      eventColor.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _event.type.icon,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _event.type.displayName,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _event.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editEvent(context),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'delete':
                      _showDeleteConfirmation(context);
                      break;
                    case 'delete_series':
                      _showDeleteSeriesConfirmation(context);
                      break;
                    case 'duplicate':
                      _duplicateEvent(context);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy),
                        SizedBox(width: 12),
                        Text('Dupliquer'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  if (_event.recurrence != null)
                    const PopupMenuItem(
                      value: 'delete_series',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Supprimer la serie',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  _buildStatusSection(),
                  const SizedBox(height: 24),

                  // Date and time section
                  _buildDateTimeSection(),
                  const SizedBox(height: 24),

                  // Location section
                  if (_event.location != null) ...[
                    _buildLocationSection(),
                    const SizedBox(height: 24),
                  ],

                  // Horse section
                  if (_event.horseName != null) ...[
                    _buildHorseSection(),
                    const SizedBox(height: 24),
                  ],

                  // Recurrence section
                  if (_event.recurrence != null) ...[
                    _buildRecurrenceSection(),
                    const SizedBox(height: 24),
                  ],

                  // Reminders section
                  _buildRemindersSection(),
                  const SizedBox(height: 24),

                  // Description section
                  if (_event.description != null) ...[
                    _buildDescriptionSection(),
                    const SizedBox(height: 24),
                  ],

                  // Action buttons
                  _buildActionButtons(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Row(
      children: [
        _buildStatusBadge(_event.status),
        const Spacer(),
        Text(
          'Cree le ${_formatDate(_event.createdAt)}',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(EventStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case EventStatus.scheduled:
        color = Colors.grey;
        label = 'Planifie';
        icon = Icons.schedule;
        break;
      case EventStatus.confirmed:
        color = Colors.green;
        label = 'Confirme';
        icon = Icons.check_circle;
        break;
      case EventStatus.inProgress:
        color = AppColors.primary;
        label = 'En cours';
        icon = Icons.play_circle;
        break;
      case EventStatus.completed:
        color = AppColors.secondary;
        label = 'Termine';
        icon = Icons.task_alt;
        break;
      case EventStatus.cancelled:
        color = Colors.red;
        label = 'Annule';
        icon = Icons.cancel;
        break;
      case EventStatus.postponed:
        color = Colors.orange;
        label = 'Reporte';
        icon = Icons.update;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return _buildInfoCard(
      icon: Icons.calendar_today,
      title: 'Date et heure',
      children: [
        Row(
          children: [
            const Icon(Icons.event, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatFullDate(_event.startDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (!_event.isAllDay)
                  Text(
                    _formatTimeRange(_event),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  Text(
                    'Toute la journee',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (_event.endDate != null &&
            !_isSameDay(_event.startDate, _event.endDate!)) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.arrow_forward, size: 20, color: Colors.grey),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatFullDate(_event.endDate!),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (!_event.isAllDay)
                    Text(
                      _formatTime(_event.endDate!),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLocationSection() {
    return _buildInfoCard(
      icon: Icons.location_on,
      title: 'Lieu',
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _event.location!,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.map_outlined),
              onPressed: () {
                // Open maps app
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHorseSection() {
    return _buildInfoCard(
      icon: Icons.pets,
      title: 'Cheval',
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryContainer,
              child: const Icon(Icons.pets, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _event.horseName!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (_event.riderName != null)
                    Text(
                      'Cavalier: ${_event.riderName}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ],
    );
  }

  Widget _buildRecurrenceSection() {
    return _buildInfoCard(
      icon: Icons.repeat,
      title: 'Recurrence',
      children: [
        RecurrenceBadge(rule: _event.recurrence!),
        const SizedBox(height: 8),
        Text(
          _event.recurrence!.description,
          style: TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
        if (_event.recurrence!.endDate != null)
          Text(
            'Jusqu\'au ${_formatDate(_event.recurrence!.endDate!)}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        if (_event.recurrence!.occurrences != null)
          Text(
            '${_event.recurrence!.occurrences} occurrences',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
      ],
    );
  }

  Widget _buildRemindersSection() {
    return _buildInfoCard(
      icon: Icons.notifications,
      title: 'Rappels',
      trailing: TextButton.icon(
        onPressed: () => _editReminders(context),
        icon: const Icon(Icons.edit, size: 16),
        label: const Text('Modifier'),
      ),
      children: [
        if (_event.reminders.isEmpty)
          Text(
            'Aucun rappel configure',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _event.reminders.map((reminder) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getReminderMethodIcon(reminder.method), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      reminder.displayText,
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (reminder.isSent) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.check, size: 14, color: Colors.green),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return _buildInfoCard(
      icon: Icons.description,
      title: 'Description',
      children: [
        Text(
          _event.description!,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Status update buttons
        if (_event.status == EventStatus.scheduled ||
            _event.status == EventStatus.confirmed)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _updateStatus(EventStatus.completed),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Marquer termine'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _updateStatus(EventStatus.cancelled),
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text('Annuler', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _editEvent(context),
            icon: const Icon(Icons.edit),
            label: const Text('Modifier l\'evenement'),
          ),
        ),
      ],
    );
  }

  IconData _getReminderMethodIcon(ReminderMethod method) {
    switch (method) {
      case ReminderMethod.push:
        return Icons.notifications;
      case ReminderMethod.email:
        return Icons.email;
      case ReminderMethod.sms:
        return Icons.sms;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatFullDate(DateTime date) {
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    const months = [
      'janvier', 'fevrier', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'aout', 'septembre', 'octobre', 'novembre', 'decembre'
    ];
    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeRange(CalendarEvent event) {
    final start = _formatTime(event.startDate);
    if (event.endDate != null) {
      return '$start - ${_formatTime(event.endDate!)}';
    }
    return start;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _editEvent(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/calendar/edit',
      arguments: _event,
    ).then((result) {
      if (result is CalendarEvent) {
        setState(() => _event = result);
      }
    });
  }

  void _editReminders(BuildContext context) {
    // Show reminder edit dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ReminderEditSheet(
        event: _event,
        onSaved: (reminders) async {
          final notifier = ref.read(planningNotifierProvider.notifier);
          final success = await notifier.updateEventReminders(
            _event.id,
            reminders,
          );
          if (success && mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rappels mis a jour')),
            );
          }
        },
      ),
    );
  }

  void _updateStatus(EventStatus status) async {
    final notifier = ref.read(planningNotifierProvider.notifier);
    final success = await notifier.updateEvent(_event.id, {
      'status': status.name,
    });

    if (success && mounted) {
      setState(() {
        _event = CalendarEvent(
          id: _event.id,
          userId: _event.userId,
          title: _event.title,
          description: _event.description,
          type: _event.type,
          startDate: _event.startDate,
          endDate: _event.endDate,
          isAllDay: _event.isAllDay,
          location: _event.location,
          horseId: _event.horseId,
          horseName: _event.horseName,
          riderId: _event.riderId,
          riderName: _event.riderName,
          recurrence: _event.recurrence,
          reminders: _event.reminders,
          status: status,
          color: _event.color,
          metadata: _event.metadata,
          createdAt: _event.createdAt,
          updatedAt: DateTime.now(),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Statut mis a jour: ${status.displayName}')),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'evenement ?'),
        content: Text('Voulez-vous vraiment supprimer "${_event.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final notifier = ref.read(planningNotifierProvider.notifier);
              final success = await notifier.deleteEvent(_event.id);
              if (success && mounted) {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Evenement supprime')),
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

  void _showDeleteSeriesConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la serie ?'),
        content: const Text(
          'Voulez-vous supprimer tous les evenements de cette serie recurrente ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final notifier = ref.read(planningNotifierProvider.notifier);
              final success = await notifier.deleteEventSeries(_event.id);
              if (success && mounted) {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Serie supprimee')),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer la serie'),
          ),
        ],
      ),
    );
  }

  void _duplicateEvent(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/calendar/new',
      arguments: {
        'title': '${_event.title} (copie)',
        'type': _event.type,
        'description': _event.description,
        'location': _event.location,
        'horseId': _event.horseId,
        'isAllDay': _event.isAllDay,
      },
    );
  }
}

/// Bottom sheet for editing reminders
class _ReminderEditSheet extends StatefulWidget {
  final CalendarEvent event;
  final Function(List<EventReminder>) onSaved;

  const _ReminderEditSheet({
    required this.event,
    required this.onSaved,
  });

  @override
  State<_ReminderEditSheet> createState() => _ReminderEditSheetState();
}

class _ReminderEditSheetState extends State<_ReminderEditSheet> {
  late List<EventReminder> _reminders;

  @override
  void initState() {
    super.initState();
    _reminders = List.from(widget.event.reminders);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rappels',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: _addReminder,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _reminders.length,
                  itemBuilder: (context, index) {
                    return _buildReminderItem(_reminders[index], index);
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => widget.onSaved(_reminders),
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReminderItem(EventReminder reminder, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(_getReminderMethodIcon(reminder.method)),
        title: Text(reminder.displayText),
        subtitle: Text(_getReminderMethodLabel(reminder.method)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
            setState(() {
              _reminders.removeAt(index);
            });
          },
        ),
      ),
    );
  }

  void _addReminder() {
    setState(() {
      _reminders.add(EventReminder(
        id: 'new_${DateTime.now().millisecondsSinceEpoch}',
        minutesBefore: 60,
        method: ReminderMethod.push,
      ));
    });
  }

  IconData _getReminderMethodIcon(ReminderMethod method) {
    switch (method) {
      case ReminderMethod.push:
        return Icons.notifications;
      case ReminderMethod.email:
        return Icons.email;
      case ReminderMethod.sms:
        return Icons.sms;
    }
  }

  String _getReminderMethodLabel(ReminderMethod method) {
    switch (method) {
      case ReminderMethod.push:
        return 'Notification push';
      case ReminderMethod.email:
        return 'Email';
      case ReminderMethod.sms:
        return 'SMS';
    }
  }
}
