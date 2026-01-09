import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/planning.dart';
import '../../../theme/app_theme.dart';

/// Widget for configuring event reminders
class ReminderSettingsWidget extends ConsumerStatefulWidget {
  final List<EventReminder> initialReminders;
  final EventType? eventType;
  final Function(List<EventReminder>) onRemindersChanged;

  const ReminderSettingsWidget({
    super.key,
    this.initialReminders = const [],
    this.eventType,
    required this.onRemindersChanged,
  });

  @override
  ConsumerState<ReminderSettingsWidget> createState() =>
      _ReminderSettingsWidgetState();
}

class _ReminderSettingsWidgetState
    extends ConsumerState<ReminderSettingsWidget> {
  late List<_ReminderEntry> _reminders;

  @override
  void initState() {
    super.initState();
    _reminders = widget.initialReminders
        .map((r) => _ReminderEntry(
              minutesBefore: r.minutesBefore,
              method: r.method,
            ))
        .toList();

    // Add default reminders if empty
    if (_reminders.isEmpty) {
      _reminders = _getDefaultReminders();
    }
  }

  List<_ReminderEntry> _getDefaultReminders() {
    // Default reminders based on event type
    switch (widget.eventType) {
      case EventType.competition:
        return [
          _ReminderEntry(minutesBefore: 10080, method: ReminderMethod.push), // 1 week
          _ReminderEntry(minutesBefore: 1440, method: ReminderMethod.push), // 1 day
          _ReminderEntry(minutesBefore: 120, method: ReminderMethod.push), // 2 hours
        ];
      case EventType.veterinary:
      case EventType.farrier:
      case EventType.dentist:
        return [
          _ReminderEntry(minutesBefore: 1440, method: ReminderMethod.push), // 1 day
          _ReminderEntry(minutesBefore: 120, method: ReminderMethod.push), // 2 hours
        ];
      case EventType.training:
      case EventType.lesson:
        return [
          _ReminderEntry(minutesBefore: 60, method: ReminderMethod.push), // 1 hour
        ];
      default:
        return [
          _ReminderEntry(minutesBefore: 1440, method: ReminderMethod.push), // 1 day
        ];
    }
  }

  void _addReminder() {
    setState(() {
      _reminders.add(_ReminderEntry(
        minutesBefore: 60,
        method: ReminderMethod.push,
      ));
    });
    _notifyChange();
  }

  void _removeReminder(int index) {
    setState(() {
      _reminders.removeAt(index);
    });
    _notifyChange();
  }

  void _updateReminder(int index, _ReminderEntry entry) {
    setState(() {
      _reminders[index] = entry;
    });
    _notifyChange();
  }

  void _notifyChange() {
    final reminders = _reminders
        .asMap()
        .entries
        .map((e) => EventReminder(
              id: 'reminder_${e.key}',
              minutesBefore: e.value.minutesBefore,
              method: e.value.method,
            ))
        .toList();
    widget.onRemindersChanged(reminders);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rappels',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton.icon(
              onPressed: _reminders.length < 5 ? _addReminder : null,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_reminders.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.notifications_off, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Text(
                    'Aucun rappel configure',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(_reminders.length, (index) {
            return _ReminderRow(
              entry: _reminders[index],
              onChanged: (entry) => _updateReminder(index, entry),
              onRemove: () => _removeReminder(index),
            );
          }),
      ],
    );
  }
}

class _ReminderEntry {
  final int minutesBefore;
  final ReminderMethod method;

  _ReminderEntry({
    required this.minutesBefore,
    required this.method,
  });

  _ReminderEntry copyWith({
    int? minutesBefore,
    ReminderMethod? method,
  }) {
    return _ReminderEntry(
      minutesBefore: minutesBefore ?? this.minutesBefore,
      method: method ?? this.method,
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final _ReminderEntry entry;
  final Function(_ReminderEntry) onChanged;
  final VoidCallback onRemove;

  const _ReminderRow({
    required this.entry,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Time dropdown
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<int>(
                value: entry.minutesBefore,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                items: _timeOptions.map((option) {
                  return DropdownMenuItem(
                    value: option.minutes,
                    child: Text(option.label, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onChanged(entry.copyWith(minutesBefore: value));
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            // Method dropdown
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<ReminderMethod>(
                value: entry.method,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                items: ReminderMethod.values.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_methodIcon(method), size: 16),
                        const SizedBox(width: 4),
                        Text(_methodLabel(method),
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onChanged(entry.copyWith(method: value));
                  }
                },
              ),
            ),
            const SizedBox(width: 4),
            // Remove button
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _methodIcon(ReminderMethod method) {
    switch (method) {
      case ReminderMethod.push:
        return Icons.notifications;
      case ReminderMethod.email:
        return Icons.email;
      case ReminderMethod.sms:
        return Icons.sms;
    }
  }

  String _methodLabel(ReminderMethod method) {
    switch (method) {
      case ReminderMethod.push:
        return 'Push';
      case ReminderMethod.email:
        return 'Email';
      case ReminderMethod.sms:
        return 'SMS';
    }
  }
}

class _TimeOption {
  final int minutes;
  final String label;

  const _TimeOption(this.minutes, this.label);
}

const _timeOptions = [
  _TimeOption(5, '5 minutes avant'),
  _TimeOption(10, '10 minutes avant'),
  _TimeOption(15, '15 minutes avant'),
  _TimeOption(30, '30 minutes avant'),
  _TimeOption(60, '1 heure avant'),
  _TimeOption(120, '2 heures avant'),
  _TimeOption(180, '3 heures avant'),
  _TimeOption(360, '6 heures avant'),
  _TimeOption(720, '12 heures avant'),
  _TimeOption(1440, '1 jour avant'),
  _TimeOption(2880, '2 jours avant'),
  _TimeOption(4320, '3 jours avant'),
  _TimeOption(10080, '1 semaine avant'),
  _TimeOption(20160, '2 semaines avant'),
];

/// Compact reminder chip for display
class ReminderChip extends StatelessWidget {
  final EventReminder reminder;
  final VoidCallback? onRemove;

  const ReminderChip({
    super.key,
    required this.reminder,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(_methodIcon(reminder.method), size: 16),
      label: Text(reminder.displayText, style: const TextStyle(fontSize: 12)),
      deleteIcon: onRemove != null ? const Icon(Icons.close, size: 16) : null,
      onDeleted: onRemove,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  IconData _methodIcon(ReminderMethod method) {
    switch (method) {
      case ReminderMethod.push:
        return Icons.notifications;
      case ReminderMethod.email:
        return Icons.email;
      case ReminderMethod.sms:
        return Icons.sms;
    }
  }
}
