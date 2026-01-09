import 'package:flutter/material.dart';
import '../../../models/planning.dart';
import '../../../theme/app_theme.dart';

/// Widget for selecting recurrence rules for events
class RecurringEventSelector extends StatefulWidget {
  final RecurrenceRule? initialRule;
  final Function(RecurrenceRule?) onRuleChanged;

  const RecurringEventSelector({
    super.key,
    this.initialRule,
    required this.onRuleChanged,
  });

  @override
  State<RecurringEventSelector> createState() => _RecurringEventSelectorState();
}

class _RecurringEventSelectorState extends State<RecurringEventSelector> {
  bool _isRecurring = false;
  RecurrenceFrequency _frequency = RecurrenceFrequency.weekly;
  int _interval = 1;
  List<int> _selectedDays = [];
  int? _dayOfMonth;
  DateTime? _endDate;
  int? _occurrences;
  bool _useEndDate = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialRule != null) {
      _isRecurring = true;
      _frequency = widget.initialRule!.frequency;
      _interval = widget.initialRule!.interval;
      _selectedDays = widget.initialRule!.daysOfWeek ?? [];
      _dayOfMonth = widget.initialRule!.dayOfMonth;
      _endDate = widget.initialRule!.endDate;
      _occurrences = widget.initialRule!.occurrences;
      _useEndDate = _endDate != null;
    }
  }

  void _notifyChange() {
    if (!_isRecurring) {
      widget.onRuleChanged(null);
      return;
    }

    widget.onRuleChanged(RecurrenceRule(
      frequency: _frequency,
      interval: _interval,
      daysOfWeek: _frequency == RecurrenceFrequency.weekly && _selectedDays.isNotEmpty
          ? _selectedDays
          : null,
      dayOfMonth: _frequency == RecurrenceFrequency.monthly ? _dayOfMonth : null,
      endDate: _useEndDate ? _endDate : null,
      occurrences: !_useEndDate ? _occurrences : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle recurrence
        SwitchListTile(
          title: const Text('Evenement recurrent'),
          subtitle: _isRecurring
              ? Text(_getRecurrenceSummary())
              : const Text('Repeter cet evenement'),
          value: _isRecurring,
          onChanged: (value) {
            setState(() {
              _isRecurring = value;
            });
            _notifyChange();
          },
          contentPadding: EdgeInsets.zero,
        ),

        if (_isRecurring) ...[
          const SizedBox(height: 16),

          // Frequency selector
          Row(
            children: [
              const Text('Repeter '),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: DropdownButtonFormField<int>(
                  value: _interval,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: List.generate(12, (i) => i + 1)
                      .map((n) => DropdownMenuItem(
                            value: n,
                            child: Text('$n'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _interval = value);
                      _notifyChange();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<RecurrenceFrequency>(
                  value: _frequency,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: RecurrenceFrequency.values.map((f) {
                    return DropdownMenuItem(
                      value: f,
                      child: Text(_frequencyLabel(f, _interval)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _frequency = value;
                        // Reset day selection when frequency changes
                        _selectedDays = [];
                        _dayOfMonth = null;
                      });
                      _notifyChange();
                    }
                  },
                ),
              ),
            ],
          ),

          // Weekly day selector
          if (_frequency == RecurrenceFrequency.weekly) ...[
            const SizedBox(height: 16),
            Text(
              'Jours de la semaine',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            _buildWeekdaySelector(),
          ],

          // Monthly day selector
          if (_frequency == RecurrenceFrequency.monthly) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Le jour '),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: DropdownButtonFormField<int>(
                    value: _dayOfMonth ?? DateTime.now().day,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    items: List.generate(31, (i) => i + 1)
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text('$d'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _dayOfMonth = value);
                      _notifyChange();
                    },
                  ),
                ),
                const Text(' du mois'),
              ],
            ),
          ],

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // End condition
          Text(
            'Fin de la recurrence',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),

          // End type toggle
          Row(
            children: [
              ChoiceChip(
                label: const Text('Date'),
                selected: _useEndDate,
                onSelected: (selected) {
                  setState(() => _useEndDate = true);
                  _notifyChange();
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Occurrences'),
                selected: !_useEndDate,
                onSelected: (selected) {
                  setState(() => _useEndDate = false);
                  _notifyChange();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_useEndDate)
            // End date picker
            OutlinedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now().add(const Duration(days: 90)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                );
                if (date != null) {
                  setState(() => _endDate = date);
                  _notifyChange();
                }
              },
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(_endDate != null
                  ? 'Jusqu\'au ${_formatDate(_endDate!)}'
                  : 'Choisir une date de fin'),
            )
          else
            // Occurrences input
            Row(
              children: [
                const Text('Apres '),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: (_occurrences ?? 10).toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() => _occurrences = int.tryParse(value));
                      _notifyChange();
                    },
                  ),
                ),
                const Text(' occurrences'),
              ],
            ),
        ],
      ],
    );
  }

  Widget _buildWeekdaySelector() {
    const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return Wrap(
      spacing: 8,
      children: List.generate(7, (index) {
        final dayNumber = index + 1; // 1 = Monday
        final isSelected = _selectedDays.contains(dayNumber);
        return FilterChip(
          label: Text(days[index]),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(dayNumber);
              } else {
                _selectedDays.remove(dayNumber);
              }
              _selectedDays.sort();
            });
            _notifyChange();
          },
        );
      }),
    );
  }

  String _frequencyLabel(RecurrenceFrequency frequency, int interval) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return interval == 1 ? 'jour' : 'jours';
      case RecurrenceFrequency.weekly:
        return interval == 1 ? 'semaine' : 'semaines';
      case RecurrenceFrequency.monthly:
        return 'mois';
      case RecurrenceFrequency.yearly:
        return interval == 1 ? 'an' : 'ans';
    }
  }

  String _getRecurrenceSummary() {
    if (!_isRecurring) return '';

    String summary = '';
    switch (_frequency) {
      case RecurrenceFrequency.daily:
        summary = _interval == 1 ? 'Tous les jours' : 'Tous les $_interval jours';
        break;
      case RecurrenceFrequency.weekly:
        summary = _interval == 1 ? 'Chaque semaine' : 'Toutes les $_interval semaines';
        if (_selectedDays.isNotEmpty) {
          summary += ' (${_formatDays(_selectedDays)})';
        }
        break;
      case RecurrenceFrequency.monthly:
        summary = _interval == 1 ? 'Chaque mois' : 'Tous les $_interval mois';
        if (_dayOfMonth != null) {
          summary += ' le $_dayOfMonth';
        }
        break;
      case RecurrenceFrequency.yearly:
        summary = _interval == 1 ? 'Chaque annee' : 'Tous les $_interval ans';
        break;
    }

    if (_useEndDate && _endDate != null) {
      summary += ' jusqu\'au ${_formatDate(_endDate!)}';
    } else if (_occurrences != null) {
      summary += ' ($_occurrences fois)';
    }

    return summary;
  }

  String _formatDays(List<int> days) {
    const dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days.map((d) => dayNames[d - 1]).join(', ');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Compact recurrence badge for display
class RecurrenceBadge extends StatelessWidget {
  final RecurrenceRule rule;

  const RecurrenceBadge({
    super.key,
    required this.rule,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.repeat, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            rule.description,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
