import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/planning.dart';
import '../../providers/planning_provider.dart';
import '../../theme/app_theme.dart';

/// Main calendar widget with month/week/day views
class CalendarWidget extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final CalendarViewMode initialViewMode;
  final Function(DateTime)? onDateSelected;
  final Function(CalendarEvent)? onEventTap;
  final List<CalendarEvent> events;
  final bool showViewModeSelector;
  final bool showNavigation;
  final Set<EventType>? eventTypeFilters;

  const CalendarWidget({
    super.key,
    this.initialDate,
    this.initialViewMode = CalendarViewMode.month,
    this.onDateSelected,
    this.onEventTap,
    this.events = const [],
    this.showViewModeSelector = true,
    this.showNavigation = true,
    this.eventTypeFilters,
  });

  @override
  ConsumerState<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends ConsumerState<CalendarWidget> {
  late DateTime _selectedDate;
  late DateTime _focusedDate;
  late CalendarViewMode _viewMode;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _focusedDate = _selectedDate;
    _viewMode = widget.initialViewMode;
    _pageController = PageController(initialPage: 1000);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<CalendarEvent> get _filteredEvents {
    if (widget.eventTypeFilters == null || widget.eventTypeFilters!.isEmpty) {
      return widget.events;
    }
    return widget.events
        .where((e) => widget.eventTypeFilters!.contains(e.type))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with navigation and view mode
        _buildHeader(),
        const SizedBox(height: 8),

        // Calendar body
        Expanded(
          child: _buildCalendarBody(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Navigation buttons
              if (widget.showNavigation)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _previousPeriod,
                    ),
                    GestureDetector(
                      onTap: _goToToday,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getHeaderTitle(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _nextPeriod,
                    ),
                  ],
                )
              else
                Text(
                  _getHeaderTitle(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

              // View mode selector
              if (widget.showViewModeSelector)
                SegmentedButton<CalendarViewMode>(
                  segments: const [
                    ButtonSegment(
                      value: CalendarViewMode.day,
                      icon: Icon(Icons.view_day, size: 18),
                    ),
                    ButtonSegment(
                      value: CalendarViewMode.week,
                      icon: Icon(Icons.view_week, size: 18),
                    ),
                    ButtonSegment(
                      value: CalendarViewMode.month,
                      icon: Icon(Icons.calendar_view_month, size: 18),
                    ),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (selected) {
                    setState(() {
                      _viewMode = selected.first;
                    });
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Today button
          TextButton.icon(
            onPressed: _goToToday,
            icon: const Icon(Icons.today, size: 16),
            label: const Text('Aujourd\'hui'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarBody() {
    switch (_viewMode) {
      case CalendarViewMode.day:
        return _buildDayView();
      case CalendarViewMode.week:
        return _buildWeekView();
      case CalendarViewMode.month:
        return _buildMonthView();
      case CalendarViewMode.agenda:
        return _buildAgendaView();
    }
  }

  Widget _buildMonthView() {
    return Column(
      children: [
        // Weekday headers
        _buildWeekdayHeaders(),
        const SizedBox(height: 8),
        // Calendar grid
        Expanded(
          child: _buildMonthGrid(),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: weekdays
            .map((day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildMonthGrid() {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);

    // Calculate start of calendar grid (Monday of first week)
    int startWeekday = firstDayOfMonth.weekday;
    final startDate = firstDayOfMonth.subtract(Duration(days: startWeekday - 1));

    // Calculate number of weeks needed
    final daysInView = lastDayOfMonth.day + startWeekday - 1;
    final weeksNeeded = ((daysInView + 6) / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: List.generate(weeksNeeded, (weekIndex) {
          return Expanded(
            child: Row(
              children: List.generate(7, (dayIndex) {
                final date = startDate.add(Duration(days: weekIndex * 7 + dayIndex));
                return Expanded(
                  child: _buildDayCell(date),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final isToday = _isSameDay(date, DateTime.now());
    final isSelected = _isSameDay(date, _selectedDate);
    final isCurrentMonth = date.month == _focusedDate.month;
    final dayEvents = _getEventsForDate(date);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
        widget.onDateSelected?.call(date);
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isToday
                  ? AppColors.primaryContainer
                  : null,
          borderRadius: BorderRadius.circular(8),
          border: isToday && !isSelected
              ? Border.all(color: AppColors.primary, width: 1)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isCurrentMonth
                        ? null
                        : AppColors.textTertiary,
                fontWeight: isToday || isSelected ? FontWeight.bold : null,
                fontSize: 14,
              ),
            ),
            if (dayEvents.isNotEmpty) ...[
              const SizedBox(height: 2),
              _buildEventDots(dayEvents),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEventDots(List<CalendarEvent> events) {
    final displayEvents = events.take(3).toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: displayEvents.map((event) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: Color(event.type.defaultColor),
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeekView() {
    final startOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );

    return Column(
      children: [
        // Week day selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: List.generate(7, (index) {
              final date = startOfWeek.add(Duration(days: index));
              final isSelected = _isSameDay(date, _selectedDate);
              final isToday = _isSameDay(date, DateTime.now());
              final dayEvents = _getEventsForDate(date);

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                    widget.onDateSelected?.call(date);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : isToday
                              ? AppColors.primaryContainer
                              : null,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday && !isSelected
                          ? Border.all(color: AppColors.primary)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          _getShortDayName(date),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white70
                                : AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : null,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (dayEvents.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _buildEventDots(dayEvents),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        // Events list for selected day
        Expanded(
          child: _buildDayEventsList(_selectedDate),
        ),
      ],
    );
  }

  Widget _buildDayView() {
    return _buildDayTimeline(_selectedDate);
  }

  Widget _buildDayTimeline(DateTime date) {
    final dayEvents = _getEventsForDate(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _formatFullDate(date),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: dayEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun evenement',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 24,
                  itemBuilder: (context, hour) {
                    final hourEvents = dayEvents.where((e) {
                      return e.startDate.hour == hour;
                    }).toList();

                    return _buildHourRow(hour, hourEvents);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHourRow(int hour, List<CalendarEvent> events) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 60),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.lightDivider,
                    width: 0.5,
                  ),
                ),
              ),
              child: events.isEmpty
                  ? const SizedBox()
                  : Column(
                      children: events
                          .map((event) => _buildTimelineEvent(event))
                          .toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineEvent(CalendarEvent event) {
    return GestureDetector(
      onTap: () => widget.onEventTap?.call(event),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(event.type.defaultColor).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: Color(event.type.defaultColor),
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              event.type.icon,
              size: 16,
              color: Color(event.type.defaultColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.location != null)
                    Text(
                      event.location!,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              _formatTime(event.startDate),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayEventsList(DateTime date) {
    final dayEvents = _getEventsForDate(date)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    if (dayEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun evenement ce jour',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: dayEvents.length,
      itemBuilder: (context, index) {
        final event = dayEvents[index];
        return _buildEventListItem(event);
      },
    );
  }

  Widget _buildEventListItem(CalendarEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => widget.onEventTap?.call(event),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(event.type.defaultColor),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(event.type.defaultColor).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  event.type.icon,
                  color: Color(event.type.defaultColor),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.isAllDay
                              ? 'Toute la journee'
                              : _formatTime(event.startDate),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (event.horseName != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.pets,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.horseName!,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (event.recurrence != null)
                Icon(
                  Icons.repeat,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgendaView() {
    // Group events by date
    final groupedEvents = <DateTime, List<CalendarEvent>>{};
    for (final event in _filteredEvents) {
      final dateKey = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      groupedEvents.putIfAbsent(dateKey, () => []).add(event);
    }

    final sortedDates = groupedEvents.keys.toList()..sort();

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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final events = groupedEvents[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _isSameDay(date, DateTime.now())
                          ? AppColors.primary
                          : AppColors.lightSurfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isSameDay(date, DateTime.now())
                          ? 'Aujourd\'hui'
                          : _formatAgendaDate(date),
                      style: TextStyle(
                        color: _isSameDay(date, DateTime.now())
                            ? Colors.white
                            : null,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...events.map((event) => _buildEventListItem(event)),
          ],
        );
      },
    );
  }

  // Helper methods
  List<CalendarEvent> _getEventsForDate(DateTime date) {
    return _filteredEvents.where((event) {
      return _isSameDay(event.startDate, date);
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getHeaderTitle() {
    switch (_viewMode) {
      case CalendarViewMode.day:
        return _formatFullDate(_selectedDate);
      case CalendarViewMode.week:
        final startOfWeek = _selectedDate.subtract(
          Duration(days: _selectedDate.weekday - 1),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        if (startOfWeek.month == endOfWeek.month) {
          return '${startOfWeek.day}-${endOfWeek.day} ${_getMonthName(startOfWeek.month)}';
        }
        return '${startOfWeek.day} ${_getShortMonthName(startOfWeek.month)} - ${endOfWeek.day} ${_getShortMonthName(endOfWeek.month)}';
      case CalendarViewMode.month:
      case CalendarViewMode.agenda:
        return '${_getMonthName(_focusedDate.month)} ${_focusedDate.year}';
    }
  }

  void _previousPeriod() {
    setState(() {
      switch (_viewMode) {
        case CalendarViewMode.day:
          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
          _focusedDate = _selectedDate;
          break;
        case CalendarViewMode.week:
          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
          _focusedDate = _selectedDate;
          break;
        case CalendarViewMode.month:
        case CalendarViewMode.agenda:
          _focusedDate = DateTime(
            _focusedDate.year,
            _focusedDate.month - 1,
          );
          break;
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      switch (_viewMode) {
        case CalendarViewMode.day:
          _selectedDate = _selectedDate.add(const Duration(days: 1));
          _focusedDate = _selectedDate;
          break;
        case CalendarViewMode.week:
          _selectedDate = _selectedDate.add(const Duration(days: 7));
          _focusedDate = _selectedDate;
          break;
        case CalendarViewMode.month:
        case CalendarViewMode.agenda:
          _focusedDate = DateTime(
            _focusedDate.year,
            _focusedDate.month + 1,
          );
          break;
      }
    });
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _focusedDate = _selectedDate;
    });
    widget.onDateSelected?.call(_selectedDate);
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatFullDate(DateTime date) {
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return '${days[date.weekday - 1]} ${date.day} ${_getMonthName(date.month)}';
  }

  String _formatAgendaDate(DateTime date) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return '${days[date.weekday - 1]} ${date.day} ${_getShortMonthName(date.month)}';
  }

  String _getShortDayName(DateTime date) {
    const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return days[date.weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'Janvier', 'Fevrier', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Aout', 'Septembre', 'Octobre', 'Novembre', 'Decembre'
    ];
    return months[month - 1];
  }

  String _getShortMonthName(int month) {
    const months = [
      'Jan', 'Fev', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Aout', 'Sept', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

/// Mini calendar widget for quick date selection
class MiniCalendarWidget extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final List<DateTime>? highlightedDates;

  const MiniCalendarWidget({
    super.key,
    this.selectedDate,
    required this.onDateSelected,
    this.highlightedDates,
  });

  @override
  State<MiniCalendarWidget> createState() => _MiniCalendarWidgetState();
}

class _MiniCalendarWidgetState extends State<MiniCalendarWidget> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = widget.selectedDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              onPressed: () {
                setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month - 1,
                  );
                });
              },
            ),
            Text(
              '${_getMonthName(_focusedMonth.month)} ${_focusedMonth.year}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              onPressed: () {
                setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month + 1,
                  );
                });
              },
            ),
          ],
        ),
        // Weekday headers
        Row(
          children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        // Calendar grid
        _buildMiniGrid(),
      ],
    );
  }

  Widget _buildMiniGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final startDate = firstDay.subtract(Duration(days: firstDay.weekday - 1));

    return Column(
      children: List.generate(6, (weekIndex) {
        return Row(
          children: List.generate(7, (dayIndex) {
            final date = startDate.add(Duration(days: weekIndex * 7 + dayIndex));
            final isSelected = widget.selectedDate != null &&
                date.year == widget.selectedDate!.year &&
                date.month == widget.selectedDate!.month &&
                date.day == widget.selectedDate!.day;
            final isToday = _isSameDay(date, DateTime.now());
            final isCurrentMonth = date.month == _focusedMonth.month;
            final isHighlighted = widget.highlightedDates?.any(
                  (d) => _isSameDay(d, date),
                ) ??
                false;

            return Expanded(
              child: GestureDetector(
                onTap: () => widget.onDateSelected(date),
                child: Container(
                  height: 28,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isToday
                            ? AppColors.primaryContainer
                            : null,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white
                              : isCurrentMonth
                                  ? null
                                  : AppColors.textTertiary,
                          fontWeight: isToday || isSelected
                              ? FontWeight.bold
                              : null,
                        ),
                      ),
                      if (isHighlighted && !isSelected)
                        Positioned(
                          bottom: 2,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getMonthName(int month) {
    const months = [
      'Janvier', 'Fevrier', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Aout', 'Septembre', 'Octobre', 'Novembre', 'Decembre'
    ];
    return months[month - 1];
  }
}
