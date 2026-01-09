import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/planning.dart';
import '../../providers/planning_provider.dart';
import '../../providers/horses_provider.dart';
import '../../theme/app_theme.dart';
import 'widgets/recurring_event_selector.dart';
import 'widgets/reminder_settings_widget.dart';

/// Screen for creating or editing calendar events
class EventFormScreen extends ConsumerStatefulWidget {
  final CalendarEvent? event; // Null for new event, non-null for edit
  final DateTime? initialDate;
  final EventType? initialType;

  const EventFormScreen({
    super.key,
    this.event,
    this.initialDate,
    this.initialType,
  });

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  late EventType _type;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _isAllDay = false;
  String? _selectedHorseId;
  String? _selectedHorseName;
  RecurrenceRule? _recurrence;
  List<EventReminder> _reminders = [];
  bool _isLoading = false;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (_isEditing) {
      final event = widget.event!;
      _titleController.text = event.title;
      _descriptionController.text = event.description ?? '';
      _locationController.text = event.location ?? '';
      _type = event.type;
      _startDate = event.startDate;
      _startTime = TimeOfDay.fromDateTime(event.startDate);
      _endDate = event.endDate;
      _endTime = event.endDate != null
          ? TimeOfDay.fromDateTime(event.endDate!)
          : null;
      _isAllDay = event.isAllDay;
      _selectedHorseId = event.horseId;
      _selectedHorseName = event.horseName;
      _recurrence = event.recurrence;
      _reminders = List.from(event.reminders);
    } else {
      _type = widget.initialType ?? EventType.training;
      _startDate = widget.initialDate ?? DateTime.now();
      _startTime = TimeOfDay.now();
      _endTime = TimeOfDay.fromDateTime(
        DateTime.now().add(const Duration(hours: 1)),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier l\'evenement' : 'Nouvel evenement'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(context),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Event type selector
            _buildTypeSelector(),
            const SizedBox(height: 20),

            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                hintText: 'Ex: Seance de dressage',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le titre est requis';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Date and time section
            _buildDateTimeSection(),
            const SizedBox(height: 16),

            // Location field
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Lieu',
                hintText: 'Ex: Manege principal',
                prefixIcon: Icon(Icons.location_on),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Horse selector
            _buildHorseSelector(),
            const SizedBox(height: 20),

            // Recurrence section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: RecurringEventSelector(
                  initialRule: _recurrence,
                  onRuleChanged: (rule) {
                    setState(() => _recurrence = rule);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Reminders section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ReminderSettingsWidget(
                  initialReminders: _reminders,
                  eventType: _type,
                  onRemindersChanged: (reminders) {
                    _reminders = reminders;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Details supplementaires...',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEditing ? 'Enregistrer' : 'Creer l\'evenement'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type d\'evenement',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: EventType.values.take(8).map((type) {
              final isSelected = _type == type;
              final color = Color(type.defaultColor);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _type = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : color.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          type.icon,
                          size: 18,
                          color: isSelected ? Colors.white : color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          type.displayName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // All day toggle
            SwitchListTile(
              title: const Text('Journee entiere'),
              value: _isAllDay,
              onChanged: (value) => setState(() => _isAllDay = value),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Start date/time
            Text(
              'Debut',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(isStart: true),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_formatDate(_startDate)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (!_isAllDay) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectTime(isStart: true),
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(_formatTimeOfDay(_startTime)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // End date/time
            Text(
              'Fin',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(isStart: false),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_formatDate(_endDate ?? _startDate)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (!_isAllDay) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectTime(isStart: false),
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(_formatTimeOfDay(
                        _endTime ?? _startTime,
                      )),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorseSelector() {
    final horsesAsync = ref.watch(horsesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pets, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Cheval associe',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            horsesAsync.when(
              data: (horses) {
                return DropdownButtonFormField<String?>(
                  value: _selectedHorseId,
                  decoration: const InputDecoration(
                    hintText: 'Selectionner un cheval (optionnel)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Aucun'),
                    ),
                    ...horses.map((horse) {
                      return DropdownMenuItem<String?>(
                        value: horse.id,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.primaryContainer,
                              child: const Icon(Icons.pets, size: 12),
                            ),
                            const SizedBox(width: 8),
                            Text(horse.name),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedHorseId = value;
                      _selectedHorseName = value != null
                          ? horses.firstWhere((h) => h.id == value).name
                          : null;
                    });
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Erreur de chargement'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate({required bool isStart}) async {
    final initialDate = isStart ? _startDate : (_endDate ?? _startDate);
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          // Update end date if it's before start date
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _selectTime({required bool isStart}) async {
    final initialTime = isStart ? _startTime : (_endTime ?? _startTime);
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (time != null) {
      setState(() {
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Fev', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Aout', 'Sept', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _isAllDay ? 0 : _startTime.hour,
        _isAllDay ? 0 : _startTime.minute,
      );

      final endDateTime = _endDate != null || _endTime != null
          ? DateTime(
              (_endDate ?? _startDate).year,
              (_endDate ?? _startDate).month,
              (_endDate ?? _startDate).day,
              _isAllDay ? 23 : (_endTime ?? _startTime).hour,
              _isAllDay ? 59 : (_endTime ?? _startTime).minute,
            )
          : null;

      final eventData = {
        'title': _titleController.text,
        'description': _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        'type': _type.name,
        'startDate': startDateTime.toIso8601String(),
        'endDate': endDateTime?.toIso8601String(),
        'isAllDay': _isAllDay,
        'location': _locationController.text.isNotEmpty
            ? _locationController.text
            : null,
        'horseId': _selectedHorseId,
        'recurrence': _recurrence?.toJson(),
        'reminders': _reminders.map((r) => r.toJson()).toList(),
      };

      final notifier = ref.read(planningNotifierProvider.notifier);

      if (_isEditing) {
        final success = await notifier.updateEvent(widget.event!.id, eventData);
        if (success && mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evenement mis a jour')),
          );
        }
      } else {
        final result = _recurrence != null
            ? await notifier.createRecurringEvent(
                eventData: eventData,
                recurrence: _recurrence!,
              )
            : await notifier.createEvent(eventData);

        if (result != null && mounted) {
          Navigator.pop(context, result);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evenement cree')),
          );
        }
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

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'evenement ?'),
        content: Text(
          'Voulez-vous vraiment supprimer "${widget.event!.title}" ?',
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
              final success = await notifier.deleteEvent(widget.event!.id);
              if (success && mounted) {
                Navigator.pop(context, 'deleted');
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
}

/// Quick event type selector dialog
class QuickEventTypeSelector extends StatelessWidget {
  final Function(EventType) onTypeSelected;

  const QuickEventTypeSelector({
    super.key,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type d\'evenement',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: EventType.values.take(9).map((type) {
              final color = Color(type.defaultColor);
              return InkWell(
                onTap: () => onTypeSelected(type),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(type.icon, color: color, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        type.displayName,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
