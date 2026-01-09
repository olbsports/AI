import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/health.dart';
import '../../theme/app_theme.dart';

/// Health history timeline widget showing all health records chronologically
class HealthTimelineWidget extends StatelessWidget {
  final List<HealthRecord> records;
  final bool showFilters;
  final VoidCallback? onAddRecord;
  final Function(HealthRecord)? onRecordTap;

  const HealthTimelineWidget({
    super.key,
    required this.records,
    this.showFilters = true,
    this.onAddRecord,
    this.onRecordTap,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return _buildEmptyState(context);
    }

    // Group records by date (month/year)
    final groupedRecords = _groupRecordsByMonth(records);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Historique Sante',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (onAddRecord != null)
                TextButton.icon(
                  onPressed: onAddRecord,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter'),
                ),
            ],
          ),
        ),

        // Upcoming reminders
        _buildUpcomingReminders(context),

        // Timeline
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: groupedRecords.length,
            itemBuilder: (context, index) {
              final monthKey = groupedRecords.keys.elementAt(index);
              final monthRecords = groupedRecords[monthKey]!;
              return _buildMonthSection(context, monthKey, monthRecords);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun suivi sante enregistre',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des vaccinations, visites veterinaires,\net autres soins pour suivre la sante du cheval',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (onAddRecord != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddRecord,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un suivi'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpcomingReminders(BuildContext context) {
    final upcomingRecords = records
        .where((r) => r.nextDueDate != null && r.nextDueDate!.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.nextDueDate!.compareTo(b.nextDueDate!));

    final overdueRecords = records.where((r) => r.isOverdue).toList();

    if (upcomingRecords.isEmpty && overdueRecords.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overdue alerts
          if (overdueRecords.isNotEmpty)
            ...overdueRecords.take(3).map((r) => _buildAlertCard(context, r, isOverdue: true)),

          // Upcoming reminders
          if (upcomingRecords.isNotEmpty)
            ...upcomingRecords.take(3).map((r) => _buildAlertCard(context, r, isOverdue: false)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, HealthRecord record, {required bool isOverdue}) {
    final color = isOverdue ? AppColors.error : AppColors.warning;
    final daysText = isOverdue
        ? 'En retard de ${DateTime.now().difference(record.nextDueDate!).inDays} jours'
        : 'Dans ${record.nextDueDate!.difference(DateTime.now()).inDays} jours';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOverdue ? Icons.warning : Icons.schedule,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  daysText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            record.type.icon,
            color: Color(record.type.color),
            size: 20,
          ),
        ],
      ),
    );
  }

  Map<String, List<HealthRecord>> _groupRecordsByMonth(List<HealthRecord> records) {
    final sorted = [...records]..sort((a, b) => b.date.compareTo(a.date));
    final Map<String, List<HealthRecord>> grouped = {};

    for (final record in sorted) {
      final key = DateFormat('MMMM yyyy', 'fr_FR').format(record.date);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(record);
    }

    return grouped;
  }

  Widget _buildMonthSection(
    BuildContext context,
    String monthKey,
    List<HealthRecord> monthRecords,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            monthKey.toUpperCase(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        // Timeline items
        ...monthRecords.asMap().entries.map((entry) {
          final isLast = entry.key == monthRecords.length - 1;
          return _buildTimelineItem(context, entry.value, isLast: isLast);
        }),
      ],
    );
  }

  Widget _buildTimelineItem(BuildContext context, HealthRecord record, {bool isLast = false}) {
    final typeColor = Color(record.type.color);

    return InkWell(
      onTap: onRecordTap != null ? () => onRecordTap!(record) : null,
      borderRadius: BorderRadius.circular(12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line and dot
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  // Dot
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: typeColor, width: 3),
                    ),
                  ),
                  // Line
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            record.type.icon,
                            color: typeColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.title,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                record.type.displayName,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: typeColor,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        // Date
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('dd').format(record.date),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              DateFormat('MMM', 'fr_FR').format(record.date),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Description
                    if (record.description != null && record.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        record.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Footer row
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // Veterinarian
                        if (record.veterinarian != null)
                          _buildInfoChip(
                            context,
                            Icons.person,
                            record.veterinarian!,
                          ),
                        // Cost
                        if (record.cost != null)
                          _buildInfoChip(
                            context,
                            Icons.euro,
                            '${record.cost!.toStringAsFixed(0)} EUR',
                          ),
                        // Next due date
                        if (record.nextDueDate != null)
                          _buildInfoChip(
                            context,
                            Icons.event,
                            'Prochain: ${DateFormat('dd/MM/yy').format(record.nextDueDate!)}',
                            color: record.isOverdue ? AppColors.error : null,
                          ),
                        // Attachments count
                        if (record.attachments.isNotEmpty)
                          _buildInfoChip(
                            context,
                            Icons.attach_file,
                            '${record.attachments.length}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String text, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// Compact health summary widget for horse cards
class HealthSummaryWidget extends StatelessWidget {
  final HealthSummary summary;
  final bool compact;

  const HealthSummaryWidget({
    super.key,
    required this.summary,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactSummary(context);
    }
    return _buildFullSummary(context);
  }

  Widget _buildCompactSummary(BuildContext context) {
    final statusColor = Color(summary.overallStatus.color);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          summary.overallStatus.displayName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
        ),
        if (summary.overdueReminders.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${summary.overdueReminders.length} en retard',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFullSummary(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Etat de sante',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                _buildStatusBadge(context),
              ],
            ),
            const SizedBox(height: 16),

            // Last appointments grid
            _buildLastAppointmentsGrid(context),

            // Overdue reminders
            if (summary.overdueReminders.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildOverdueSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final statusColor = Color(summary.overallStatus.color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(summary.overallStatus),
            color: statusColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            summary.overallStatus.displayName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(HealthStatus status) {
    switch (status) {
      case HealthStatus.excellent:
        return Icons.check_circle;
      case HealthStatus.good:
        return Icons.thumb_up;
      case HealthStatus.needsAttention:
        return Icons.warning;
      case HealthStatus.critical:
        return Icons.error;
    }
  }

  Widget _buildLastAppointmentsGrid(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildAppointmentItem(
          context,
          label: 'Vaccination',
          date: summary.lastVaccination,
          icon: Icons.vaccines,
          color: const Color(0xFF4CAF50),
        ),
        _buildAppointmentItem(
          context,
          label: 'Vermifuge',
          date: summary.lastDeworming,
          icon: Icons.bug_report,
          color: const Color(0xFFFF9800),
        ),
        _buildAppointmentItem(
          context,
          label: 'Marechal',
          date: summary.lastFarrier,
          icon: Icons.handyman,
          color: const Color(0xFF795548),
        ),
        _buildAppointmentItem(
          context,
          label: 'Dentiste',
          date: summary.lastDentist,
          icon: Icons.medical_services,
          color: const Color(0xFF00BCD4),
        ),
      ],
    );
  }

  Widget _buildAppointmentItem(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required IconData icon,
    required Color color,
  }) {
    final dateText = date != null
        ? DateFormat('dd/MM/yy').format(date)
        : 'Non renseigne';

    return Container(
      width: 140,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  dateText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: AppColors.error, size: 18),
              const SizedBox(width: 8),
              Text(
                '${summary.overdueReminders.length} rappel(s) en retard',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...summary.overdueReminders.take(3).map((reminder) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(reminder.type.icon, size: 14, color: AppColors.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reminder.title,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Health record type filter chips
class HealthTypeFilter extends StatelessWidget {
  final Set<HealthRecordType> selectedTypes;
  final ValueChanged<Set<HealthRecordType>> onChanged;

  const HealthTypeFilter({
    super.key,
    required this.selectedTypes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // All chip
          FilterChip(
            label: const Text('Tous'),
            selected: selectedTypes.isEmpty,
            onSelected: (_) => onChanged({}),
          ),
          const SizedBox(width: 8),
          // Type chips
          ...HealthRecordType.values.take(6).map((type) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(type.displayName),
                selected: selectedTypes.contains(type),
                avatar: Icon(
                  type.icon,
                  size: 16,
                  color: selectedTypes.contains(type)
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Color(type.color),
                ),
                onSelected: (selected) {
                  final newSet = {...selectedTypes};
                  if (selected) {
                    newSet.add(type);
                  } else {
                    newSet.remove(type);
                  }
                  onChanged(newSet);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Add health record bottom sheet
class AddHealthRecordBottomSheet extends StatefulWidget {
  final String horseId;
  final String horseName;
  final Function(Map<String, dynamic>) onSave;

  const AddHealthRecordBottomSheet({
    super.key,
    required this.horseId,
    required this.horseName,
    required this.onSave,
  });

  @override
  State<AddHealthRecordBottomSheet> createState() => _AddHealthRecordBottomSheetState();
}

class _AddHealthRecordBottomSheetState extends State<AddHealthRecordBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  HealthRecordType _selectedType = HealthRecordType.veterinaryVisit;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _veterinarianController = TextEditingController();
  final _costController = TextEditingController();
  DateTime _date = DateTime.now();
  DateTime? _nextDueDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _veterinarianController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nouveau suivi sante',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'Pour ${widget.horseName}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),

              // Type selector
              Text(
                'Type de suivi',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HealthRecordType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return ChoiceChip(
                    label: Text(type.displayName),
                    selected: isSelected,
                    avatar: Icon(
                      type.icon,
                      size: 16,
                      color: isSelected ? null : Color(type.color),
                    ),
                    onSelected: (_) => setState(() => _selectedType = type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre *',
                  hintText: 'Ex: Vaccination grippe',
                ),
                validator: (v) => v?.isEmpty == true ? 'Requis' : null,
              ),
              const SizedBox(height: 16),

              // Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_date)),
                onTap: _selectDate,
              ),
              const SizedBox(height: 8),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Details optionnels...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Veterinarian
              TextFormField(
                controller: _veterinarianController,
                decoration: const InputDecoration(
                  labelText: 'Veterinaire / Praticien',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              // Cost
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Cout (EUR)',
                  prefixIcon: Icon(Icons.euro),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Next due date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_repeat),
                title: const Text('Prochain rappel'),
                subtitle: Text(
                  _nextDueDate != null
                      ? DateFormat('dd/MM/yyyy').format(_nextDueDate!)
                      : 'Non defini',
                ),
                trailing: _nextDueDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _nextDueDate = null),
                      )
                    : null,
                onTap: _selectNextDueDate,
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _date = date);
    }
  }

  Future<void> _selectNextDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _nextDueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date != null) {
      setState(() => _nextDueDate = date);
    }
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) return;

    final data = {
      'horseId': widget.horseId,
      'type': _selectedType.name,
      'title': _titleController.text,
      'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
      'date': _date.toIso8601String(),
      'veterinarian': _veterinarianController.text.isEmpty ? null : _veterinarianController.text,
      'cost': _costController.text.isEmpty ? null : double.tryParse(_costController.text),
      'nextDueDate': _nextDueDate?.toIso8601String(),
    };

    widget.onSave(data);
    Navigator.pop(context);
  }
}
