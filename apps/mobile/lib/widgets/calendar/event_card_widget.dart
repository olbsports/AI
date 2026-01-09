import 'package:flutter/material.dart';
import '../../models/planning.dart';
import '../../theme/app_theme.dart';

/// Compact event card for lists
class EventCardWidget extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showDate;
  final bool showHorse;
  final bool compact;

  const EventCardWidget({
    super.key,
    required this.event,
    this.onTap,
    this.onLongPress,
    this.showDate = true,
    this.showHorse = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactCard(context);
    }
    return _buildFullCard(context);
  }

  Widget _buildFullCard(BuildContext context) {
    final eventColor = Color(event.type.defaultColor);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: eventColor,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: eventColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  event.type.icon,
                  color: eventColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Date and time row
                    Row(
                      children: [
                        if (showDate) ...[
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(event.startDate),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.isAllDay
                              ? 'Toute la journee'
                              : _formatTimeRange(event),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    // Optional info row
                    if (showHorse && (event.horseName != null || event.location != null)) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (event.horseName != null) ...[
                            Icon(
                              Icons.pets,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                event.horseName!,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (event.horseName != null && event.location != null)
                            const SizedBox(width: 8),
                          if (event.location != null) ...[
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                event.location!,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Status and recurrence indicators
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusChip(event.status),
                  if (event.recurrence != null) ...[
                    const SizedBox(height: 4),
                    Icon(
                      Icons.repeat,
                      size: 16,
                      color: AppColors.textSecondary,
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

  Widget _buildCompactCard(BuildContext context) {
    final eventColor = Color(event.type.defaultColor);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: eventColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                event.isAllDay ? 'Journee' : _formatTime(event.startDate),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(EventStatus status) {
    Color color;
    String label;

    switch (status) {
      case EventStatus.scheduled:
        color = Colors.grey;
        label = 'Planifie';
        break;
      case EventStatus.confirmed:
        color = Colors.green;
        label = 'Confirme';
        break;
      case EventStatus.inProgress:
        color = AppColors.primary;
        label = 'En cours';
        break;
      case EventStatus.completed:
        color = AppColors.secondary;
        label = 'Termine';
        break;
      case EventStatus.cancelled:
        color = Colors.red;
        label = 'Annule';
        break;
      case EventStatus.postponed:
        color = Colors.orange;
        label = 'Reporte';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
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
}

/// Large event card with more details for featured display
class FeaturedEventCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback? onTap;

  const FeaturedEventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final eventColor = Color(event.type.defaultColor);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: eventColor,
              child: Row(
                children: [
                  Icon(
                    event.type.icon,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.type.displayName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          event.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Date row
                  _buildInfoRow(
                    Icons.calendar_today,
                    _formatFullDate(event.startDate),
                  ),
                  const SizedBox(height: 8),

                  // Time row
                  _buildInfoRow(
                    Icons.access_time,
                    event.isAllDay
                        ? 'Toute la journee'
                        : _formatTimeRange(event),
                  ),

                  if (event.location != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.location_on, event.location!),
                  ],

                  if (event.horseName != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.pets, event.horseName!),
                  ],

                  if (event.description != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      event.description!,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Bottom row with status and reminders
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusBadge(event.status),
                      Row(
                        children: [
                          if (event.recurrence != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lightSurfaceVariant,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.repeat, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    event.recurrence!.description,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          if (event.reminders.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lightSurfaceVariant,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.notifications, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${event.reminders.length}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(EventStatus status) {
    Color color;
    String label;

    switch (status) {
      case EventStatus.scheduled:
        color = Colors.grey;
        label = 'Planifie';
        break;
      case EventStatus.confirmed:
        color = Colors.green;
        label = 'Confirme';
        break;
      case EventStatus.inProgress:
        color = AppColors.primary;
        label = 'En cours';
        break;
      case EventStatus.completed:
        color = AppColors.secondary;
        label = 'Termine';
        break;
      case EventStatus.cancelled:
        color = Colors.red;
        label = 'Annule';
        break;
      case EventStatus.postponed:
        color = Colors.orange;
        label = 'Reporte';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    const months = [
      'janvier', 'fevrier', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'aout', 'septembre', 'octobre', 'novembre', 'decembre'
    ];
    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTimeRange(CalendarEvent event) {
    final start = '${event.startDate.hour.toString().padLeft(2, '0')}:${event.startDate.minute.toString().padLeft(2, '0')}';
    if (event.endDate != null) {
      final end = '${event.endDate!.hour.toString().padLeft(2, '0')}:${event.endDate!.minute.toString().padLeft(2, '0')}';
      return '$start - $end';
    }
    return start;
  }
}

/// Event type filter chip
class EventTypeFilterChip extends StatelessWidget {
  final EventType type;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const EventTypeFilterChip({
    super.key,
    required this.type,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(type.defaultColor);

    return FilterChip(
      selected: selected,
      onSelected: onSelected,
      avatar: Icon(
        type.icon,
        size: 16,
        color: selected ? Colors.white : color,
      ),
      label: Text(type.displayName),
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
        fontSize: 12,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Horizontal scrollable event type filter bar
class EventTypeFilterBar extends StatelessWidget {
  final Set<EventType> selectedTypes;
  final ValueChanged<EventType> onTypeToggled;
  final VoidCallback? onClearAll;

  const EventTypeFilterBar({
    super.key,
    required this.selectedTypes,
    required this.onTypeToggled,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (selectedTypes.isNotEmpty && onClearAll != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: const Icon(Icons.clear, size: 16),
                label: const Text('Tout'),
                onPressed: onClearAll,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ...EventType.values.map((type) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: EventTypeFilterChip(
                type: type,
                selected: selectedTypes.contains(type),
                onSelected: (_) => onTypeToggled(type),
              ),
            );
          }),
        ],
      ),
    );
  }
}
