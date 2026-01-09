/// Complete Planning System for Horse Tempo

import 'package:flutter/material.dart';

// ============================================
// EVENT CATEGORIES
// ============================================

/// Event category with custom colors
class EventCategory {
  final String id;
  final String name;
  final int colorValue;
  final IconData icon;
  final bool isDefault;

  const EventCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.icon,
    this.isDefault = false,
  });

  Color get color => Color(colorValue);

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: json['color'] as int? ?? 0xFF2196F3,
      icon: _iconFromString(json['icon'] as String? ?? 'event'),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': colorValue,
    'icon': _iconToString(icon),
    'isDefault': isDefault,
  };

  static IconData _iconFromString(String name) {
    switch (name) {
      case 'training': return Icons.fitness_center;
      case 'competition': return Icons.emoji_events;
      case 'health': return Icons.local_hospital;
      case 'farrier': return Icons.handyman;
      case 'transport': return Icons.local_shipping;
      case 'lesson': return Icons.school;
      default: return Icons.event;
    }
  }

  static String _iconToString(IconData icon) {
    if (icon == Icons.fitness_center) return 'training';
    if (icon == Icons.emoji_events) return 'competition';
    if (icon == Icons.local_hospital) return 'health';
    if (icon == Icons.handyman) return 'farrier';
    if (icon == Icons.local_shipping) return 'transport';
    if (icon == Icons.school) return 'lesson';
    return 'event';
  }

  /// Predefined categories
  static const List<EventCategory> defaults = [
    EventCategory(
      id: 'training',
      name: 'Entrainement',
      colorValue: 0xFF2196F3,
      icon: Icons.fitness_center,
      isDefault: true,
    ),
    EventCategory(
      id: 'competition',
      name: 'Competition',
      colorValue: 0xFFFF9800,
      icon: Icons.emoji_events,
      isDefault: true,
    ),
    EventCategory(
      id: 'lesson',
      name: 'Cours',
      colorValue: 0xFF4CAF50,
      icon: Icons.school,
      isDefault: true,
    ),
    EventCategory(
      id: 'vet',
      name: 'Veterinaire',
      colorValue: 0xFFF44336,
      icon: Icons.local_hospital,
      isDefault: true,
    ),
    EventCategory(
      id: 'farrier',
      name: 'Marechal',
      colorValue: 0xFF795548,
      icon: Icons.handyman,
      isDefault: true,
    ),
    EventCategory(
      id: 'health_reminder',
      name: 'Rappel sante',
      colorValue: 0xFFFFEB3B,
      icon: Icons.vaccines,
      isDefault: true,
    ),
    EventCategory(
      id: 'transport',
      name: 'Transport',
      colorValue: 0xFF607D8B,
      icon: Icons.local_shipping,
      isDefault: true,
    ),
    EventCategory(
      id: 'personal',
      name: 'Personnel',
      colorValue: 0xFF9E9E9E,
      icon: Icons.person,
      isDefault: true,
    ),
  ];
}

// ============================================
// HEALTH REMINDERS
// ============================================

/// Health reminder for horses (vaccinations, deworming, etc.)
class HealthReminder {
  final String id;
  final String organizationId;
  final String horseId;
  final String? horseName;
  final HealthReminderType type;
  final String? customType;
  final HealthReminderFrequency frequency;
  final DateTime? lastDoneAt;
  final DateTime nextDueAt;
  final int reminderDaysBefore;
  final String? notes;
  final String? vetName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  HealthReminder({
    required this.id,
    required this.organizationId,
    required this.horseId,
    this.horseName,
    required this.type,
    this.customType,
    required this.frequency,
    this.lastDoneAt,
    required this.nextDueAt,
    this.reminderDaysBefore = 7,
    this.notes,
    this.vetName,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Days until due
  int get daysUntilDue => nextDueAt.difference(DateTime.now()).inDays;

  /// Check if upcoming (within reminder period)
  bool get isUpcoming => daysUntilDue <= reminderDaysBefore && daysUntilDue > 0;

  /// Check if due today
  bool get isDueToday => daysUntilDue == 0;

  /// Check if overdue
  bool get isOverdue => daysUntilDue < 0;

  /// Get status for display
  HealthReminderStatus get status {
    if (isOverdue) return HealthReminderStatus.overdue;
    if (isDueToday) return HealthReminderStatus.dueToday;
    if (isUpcoming) return HealthReminderStatus.upcoming;
    return HealthReminderStatus.scheduled;
  }

  factory HealthReminder.fromJson(Map<String, dynamic> json) {
    return HealthReminder(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      horseId: json['horseId'] as String,
      horseName: json['horseName'] as String?,
      type: HealthReminderType.fromString(json['type'] as String),
      customType: json['customType'] as String?,
      frequency: HealthReminderFrequency.fromJson(
        json['frequency'] as Map<String, dynamic>,
      ),
      lastDoneAt: json['lastDoneAt'] != null
          ? DateTime.parse(json['lastDoneAt'] as String)
          : null,
      nextDueAt: DateTime.parse(json['nextDueAt'] as String),
      reminderDaysBefore: json['reminderDaysBefore'] as int? ?? 7,
      notes: json['notes'] as String?,
      vetName: json['vetName'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organizationId': organizationId,
    'horseId': horseId,
    'horseName': horseName,
    'type': type.name,
    'customType': customType,
    'frequency': frequency.toJson(),
    'lastDoneAt': lastDoneAt?.toIso8601String(),
    'nextDueAt': nextDueAt.toIso8601String(),
    'reminderDaysBefore': reminderDaysBefore,
    'notes': notes,
    'vetName': vetName,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  HealthReminder copyWith({
    String? id,
    String? organizationId,
    String? horseId,
    String? horseName,
    HealthReminderType? type,
    String? customType,
    HealthReminderFrequency? frequency,
    DateTime? lastDoneAt,
    DateTime? nextDueAt,
    int? reminderDaysBefore,
    String? notes,
    String? vetName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthReminder(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      horseId: horseId ?? this.horseId,
      horseName: horseName ?? this.horseName,
      type: type ?? this.type,
      customType: customType ?? this.customType,
      frequency: frequency ?? this.frequency,
      lastDoneAt: lastDoneAt ?? this.lastDoneAt,
      nextDueAt: nextDueAt ?? this.nextDueAt,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      notes: notes ?? this.notes,
      vetName: vetName ?? this.vetName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Health reminder types
enum HealthReminderType {
  vaccination,
  deworming,
  dental,
  farrier,
  osteopath,
  checkup,
  other;

  String get displayName {
    switch (this) {
      case HealthReminderType.vaccination:
        return 'Vaccination';
      case HealthReminderType.deworming:
        return 'Vermifuge';
      case HealthReminderType.dental:
        return 'Dentiste';
      case HealthReminderType.farrier:
        return 'Marechal-ferrant';
      case HealthReminderType.osteopath:
        return 'Osteopathe';
      case HealthReminderType.checkup:
        return 'Visite veterinaire';
      case HealthReminderType.other:
        return 'Autre';
    }
  }

  IconData get icon {
    switch (this) {
      case HealthReminderType.vaccination:
        return Icons.vaccines;
      case HealthReminderType.deworming:
        return Icons.bug_report;
      case HealthReminderType.dental:
        return Icons.medical_services;
      case HealthReminderType.farrier:
        return Icons.handyman;
      case HealthReminderType.osteopath:
        return Icons.healing;
      case HealthReminderType.checkup:
        return Icons.local_hospital;
      case HealthReminderType.other:
        return Icons.event_note;
    }
  }

  int get defaultColor {
    switch (this) {
      case HealthReminderType.vaccination:
        return 0xFF4CAF50;
      case HealthReminderType.deworming:
        return 0xFFFF5722;
      case HealthReminderType.dental:
        return 0xFF00BCD4;
      case HealthReminderType.farrier:
        return 0xFF795548;
      case HealthReminderType.osteopath:
        return 0xFF9C27B0;
      case HealthReminderType.checkup:
        return 0xFFF44336;
      case HealthReminderType.other:
        return 0xFF607D8B;
    }
  }

  /// Default frequency for each type
  HealthReminderFrequency get defaultFrequency {
    switch (this) {
      case HealthReminderType.vaccination:
        return const HealthReminderFrequency(type: FrequencyType.months, interval: 6);
      case HealthReminderType.deworming:
        return const HealthReminderFrequency(type: FrequencyType.months, interval: 2);
      case HealthReminderType.dental:
        return const HealthReminderFrequency(type: FrequencyType.years, interval: 1);
      case HealthReminderType.farrier:
        return const HealthReminderFrequency(type: FrequencyType.weeks, interval: 6);
      case HealthReminderType.osteopath:
        return const HealthReminderFrequency(type: FrequencyType.months, interval: 3);
      case HealthReminderType.checkup:
        return const HealthReminderFrequency(type: FrequencyType.years, interval: 1);
      case HealthReminderType.other:
        return const HealthReminderFrequency(type: FrequencyType.months, interval: 1);
    }
  }

  static HealthReminderType fromString(String value) {
    return HealthReminderType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HealthReminderType.other,
    );
  }
}

/// Health reminder frequency
class HealthReminderFrequency {
  final FrequencyType type;
  final int interval;

  const HealthReminderFrequency({
    required this.type,
    required this.interval,
  });

  factory HealthReminderFrequency.fromJson(Map<String, dynamic> json) {
    return HealthReminderFrequency(
      type: FrequencyType.fromString(json['type'] as String),
      interval: json['interval'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'interval': interval,
  };

  String get displayText {
    final unitText = interval == 1
        ? type.singularName
        : type.pluralName;
    return 'Tous les $interval $unitText';
  }

  /// Calculate next due date from a given date
  DateTime nextDueFrom(DateTime date) {
    switch (type) {
      case FrequencyType.days:
        return date.add(Duration(days: interval));
      case FrequencyType.weeks:
        return date.add(Duration(days: interval * 7));
      case FrequencyType.months:
        return DateTime(date.year, date.month + interval, date.day);
      case FrequencyType.years:
        return DateTime(date.year + interval, date.month, date.day);
    }
  }
}

/// Frequency type
enum FrequencyType {
  days,
  weeks,
  months,
  years;

  String get singularName {
    switch (this) {
      case FrequencyType.days: return 'jour';
      case FrequencyType.weeks: return 'semaine';
      case FrequencyType.months: return 'mois';
      case FrequencyType.years: return 'an';
    }
  }

  String get pluralName {
    switch (this) {
      case FrequencyType.days: return 'jours';
      case FrequencyType.weeks: return 'semaines';
      case FrequencyType.months: return 'mois';
      case FrequencyType.years: return 'ans';
    }
  }

  static FrequencyType fromString(String value) {
    return FrequencyType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FrequencyType.months,
    );
  }
}

/// Health reminder status
enum HealthReminderStatus {
  scheduled,
  upcoming,
  dueToday,
  overdue;

  String get displayName {
    switch (this) {
      case HealthReminderStatus.scheduled:
        return 'Planifie';
      case HealthReminderStatus.upcoming:
        return 'A venir';
      case HealthReminderStatus.dueToday:
        return 'Aujourd\'hui';
      case HealthReminderStatus.overdue:
        return 'En retard';
    }
  }

  Color get color {
    switch (this) {
      case HealthReminderStatus.scheduled:
        return const Color(0xFF9E9E9E);
      case HealthReminderStatus.upcoming:
        return const Color(0xFFFFEB3B);
      case HealthReminderStatus.dueToday:
        return const Color(0xFFFF9800);
      case HealthReminderStatus.overdue:
        return const Color(0xFFF44336);
    }
  }
}

// ============================================
// NOTIFICATION SETTINGS
// ============================================

/// User notification preferences for calendar events
class CalendarNotificationSettings {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final int quietHoursStart; // Hour of day (0-23)
  final int quietHoursEnd;
  final Map<String, List<int>> defaultRemindersByType; // EventType -> minutes before

  const CalendarNotificationSettings({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.smsEnabled = false,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 7,
    this.defaultRemindersByType = const {},
  });

  factory CalendarNotificationSettings.fromJson(Map<String, dynamic> json) {
    return CalendarNotificationSettings(
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? true,
      smsEnabled: json['smsEnabled'] as bool? ?? false,
      quietHoursStart: json['quietHoursStart'] as int? ?? 22,
      quietHoursEnd: json['quietHoursEnd'] as int? ?? 7,
      defaultRemindersByType: (json['defaultRemindersByType'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as List).cast<int>())) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'pushEnabled': pushEnabled,
    'emailEnabled': emailEnabled,
    'smsEnabled': smsEnabled,
    'quietHoursStart': quietHoursStart,
    'quietHoursEnd': quietHoursEnd,
    'defaultRemindersByType': defaultRemindersByType,
  };

  /// Get default reminders for an event type
  List<int> getDefaultReminders(EventType type) {
    return defaultRemindersByType[type.name] ?? _fallbackReminders(type);
  }

  List<int> _fallbackReminders(EventType type) {
    switch (type) {
      case EventType.competition:
        return [10080, 1440, 120]; // 1 week, 1 day, 2 hours
      case EventType.veterinary:
      case EventType.farrier:
      case EventType.dentist:
        return [1440, 120]; // 1 day, 2 hours
      case EventType.training:
      case EventType.lesson:
        return [60]; // 1 hour
      case EventType.vaccination:
      case EventType.deworming:
        return [10080, 1440]; // 1 week, 1 day
      default:
        return [1440, 60]; // 1 day, 1 hour
    }
  }

  CalendarNotificationSettings copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    int? quietHoursStart,
    int? quietHoursEnd,
    Map<String, List<int>>? defaultRemindersByType,
  }) {
    return CalendarNotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      defaultRemindersByType: defaultRemindersByType ?? this.defaultRemindersByType,
    );
  }
}

// ============================================
// CALENDAR EVENTS
// ============================================

/// Calendar event
class CalendarEvent {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final EventType type;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isAllDay;
  final String? location;
  final String? horseId;
  final String? horseName;
  final String? riderId;
  final String? riderName;
  final RecurrenceRule? recurrence;
  final List<EventReminder> reminders;
  final EventStatus status;
  final String? color;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CalendarEvent({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.type,
    required this.startDate,
    this.endDate,
    this.isAllDay = false,
    this.location,
    this.horseId,
    this.horseName,
    this.riderId,
    this.riderName,
    this.recurrence,
    this.reminders = const [],
    this.status = EventStatus.scheduled,
    this.color,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  Duration get duration => endDate != null
      ? endDate!.difference(startDate)
      : const Duration(hours: 1);

  bool get isPast => startDate.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return startDate.year == now.year &&
        startDate.month == now.month &&
        startDate.day == now.day;
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: EventType.fromString(json['type'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      isAllDay: json['isAllDay'] as bool? ?? false,
      location: json['location'] as String?,
      horseId: json['horseId'] as String?,
      horseName: json['horseName'] as String?,
      riderId: json['riderId'] as String?,
      riderName: json['riderName'] as String?,
      recurrence: json['recurrence'] != null
          ? RecurrenceRule.fromJson(json['recurrence'] as Map<String, dynamic>)
          : null,
      reminders: (json['reminders'] as List?)
          ?.map((r) => EventReminder.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
      status: EventStatus.fromString(json['status'] as String? ?? 'scheduled'),
      color: json['color'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'type': type.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isAllDay': isAllDay,
      'location': location,
      'horseId': horseId,
      'riderId': riderId,
      'recurrence': recurrence?.toJson(),
      'reminders': reminders.map((r) => r.toJson()).toList(),
      'status': status.name,
      'color': color,
      'metadata': metadata,
    };
  }
}

/// Event types
enum EventType {
  training,       // Entraînement
  lesson,         // Cours
  competition,    // Compétition
  veterinary,     // Vétérinaire
  farrier,        // Maréchal
  dentist,        // Dentiste
  vaccination,    // Vaccination
  deworming,      // Vermifuge
  breeding,       // Saillie/Insémination
  foaling,        // Poulinage
  transport,      // Transport
  show,           // Spectacle/Démonstration
  clinic,         // Stage/Clinic
  maintenance,    // Entretien écurie
  meeting,        // Réunion
  other;

  String get displayName {
    switch (this) {
      case EventType.training: return 'Entraînement';
      case EventType.lesson: return 'Cours';
      case EventType.competition: return 'Compétition';
      case EventType.veterinary: return 'Vétérinaire';
      case EventType.farrier: return 'Maréchal-ferrant';
      case EventType.dentist: return 'Dentiste';
      case EventType.vaccination: return 'Vaccination';
      case EventType.deworming: return 'Vermifuge';
      case EventType.breeding: return 'Reproduction';
      case EventType.foaling: return 'Poulinage';
      case EventType.transport: return 'Transport';
      case EventType.show: return 'Spectacle';
      case EventType.clinic: return 'Stage';
      case EventType.maintenance: return 'Entretien';
      case EventType.meeting: return 'Réunion';
      case EventType.other: return 'Autre';
    }
  }

  IconData get icon {
    switch (this) {
      case EventType.training: return Icons.fitness_center;
      case EventType.lesson: return Icons.school;
      case EventType.competition: return Icons.emoji_events;
      case EventType.veterinary: return Icons.local_hospital;
      case EventType.farrier: return Icons.handyman;
      case EventType.dentist: return Icons.medical_services;
      case EventType.vaccination: return Icons.vaccines;
      case EventType.deworming: return Icons.bug_report;
      case EventType.breeding: return Icons.favorite;
      case EventType.foaling: return Icons.child_care;
      case EventType.transport: return Icons.local_shipping;
      case EventType.show: return Icons.theater_comedy;
      case EventType.clinic: return Icons.groups;
      case EventType.maintenance: return Icons.build;
      case EventType.meeting: return Icons.people;
      case EventType.other: return Icons.event;
    }
  }

  int get defaultColor {
    switch (this) {
      case EventType.training: return 0xFF2196F3;
      case EventType.lesson: return 0xFF4CAF50;
      case EventType.competition: return 0xFFFF9800;
      case EventType.veterinary: return 0xFFF44336;
      case EventType.farrier: return 0xFF795548;
      case EventType.dentist: return 0xFF00BCD4;
      case EventType.vaccination: return 0xFF4CAF50;
      case EventType.deworming: return 0xFFFF5722;
      case EventType.breeding: return 0xFFE91E63;
      case EventType.foaling: return 0xFFFF4081;
      case EventType.transport: return 0xFF607D8B;
      case EventType.show: return 0xFF9C27B0;
      case EventType.clinic: return 0xFF3F51B5;
      case EventType.maintenance: return 0xFF9E9E9E;
      case EventType.meeting: return 0xFF00BCD4;
      case EventType.other: return 0xFF757575;
    }
  }

  static EventType fromString(String value) {
    return EventType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EventType.other,
    );
  }
}

/// Event status
enum EventStatus {
  scheduled,
  confirmed,
  inProgress,
  completed,
  cancelled,
  postponed;

  String get displayName {
    switch (this) {
      case EventStatus.scheduled: return 'Planifié';
      case EventStatus.confirmed: return 'Confirmé';
      case EventStatus.inProgress: return 'En cours';
      case EventStatus.completed: return 'Terminé';
      case EventStatus.cancelled: return 'Annulé';
      case EventStatus.postponed: return 'Reporté';
    }
  }

  static EventStatus fromString(String value) {
    return EventStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EventStatus.scheduled,
    );
  }
}

// ============================================
// RECURRENCE
// ============================================

/// Recurrence rule for repeating events
class RecurrenceRule {
  final RecurrenceFrequency frequency;
  final int interval; // Every X days/weeks/months
  final List<int>? daysOfWeek; // 1=Monday, 7=Sunday
  final int? dayOfMonth;
  final DateTime? endDate;
  final int? occurrences;

  RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.daysOfWeek,
    this.dayOfMonth,
    this.endDate,
    this.occurrences,
  });

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.fromString(json['frequency'] as String),
      interval: json['interval'] as int? ?? 1,
      daysOfWeek: (json['daysOfWeek'] as List?)?.cast<int>(),
      dayOfMonth: json['dayOfMonth'] as int?,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      occurrences: json['occurrences'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency.name,
      'interval': interval,
      'daysOfWeek': daysOfWeek,
      'dayOfMonth': dayOfMonth,
      'endDate': endDate?.toIso8601String(),
      'occurrences': occurrences,
    };
  }

  String get description {
    String desc = '';
    switch (frequency) {
      case RecurrenceFrequency.daily:
        desc = interval == 1 ? 'Tous les jours' : 'Tous les $interval jours';
        break;
      case RecurrenceFrequency.weekly:
        desc = interval == 1 ? 'Chaque semaine' : 'Toutes les $interval semaines';
        break;
      case RecurrenceFrequency.monthly:
        desc = interval == 1 ? 'Chaque mois' : 'Tous les $interval mois';
        break;
      case RecurrenceFrequency.yearly:
        desc = interval == 1 ? 'Chaque année' : 'Tous les $interval ans';
        break;
    }
    return desc;
  }
}

enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  static RecurrenceFrequency fromString(String value) {
    return RecurrenceFrequency.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RecurrenceFrequency.weekly,
    );
  }
}

// ============================================
// REMINDERS
// ============================================

/// Event reminder
class EventReminder {
  final String id;
  final int minutesBefore;
  final ReminderMethod method;
  final bool isSent;

  EventReminder({
    required this.id,
    required this.minutesBefore,
    this.method = ReminderMethod.push,
    this.isSent = false,
  });

  factory EventReminder.fromJson(Map<String, dynamic> json) {
    return EventReminder(
      id: json['id'] as String,
      minutesBefore: json['minutesBefore'] as int,
      method: ReminderMethod.fromString(json['method'] as String? ?? 'push'),
      isSent: json['isSent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'minutesBefore': minutesBefore,
      'method': method.name,
      'isSent': isSent,
    };
  }

  String get displayText {
    if (minutesBefore < 60) {
      return '$minutesBefore min avant';
    } else if (minutesBefore < 1440) {
      return '${minutesBefore ~/ 60}h avant';
    } else {
      return '${minutesBefore ~/ 1440} jour(s) avant';
    }
  }
}

enum ReminderMethod {
  push,
  email,
  sms;

  static ReminderMethod fromString(String value) {
    return ReminderMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReminderMethod.push,
    );
  }
}

// ============================================
// GOALS & OBJECTIVES
// ============================================

/// SMART Goal
class Goal {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final GoalCategory category;
  final GoalType type;
  final String? horseId;
  final String? horseName;
  final double targetValue;
  final double currentValue;
  final String? unit;
  final DateTime startDate;
  final DateTime targetDate;
  final List<Milestone> milestones;
  final GoalStatus status;
  final int? xpReward;
  final DateTime createdAt;
  final DateTime? completedAt;

  Goal({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    required this.type,
    this.horseId,
    this.horseName,
    required this.targetValue,
    this.currentValue = 0,
    this.unit,
    required this.startDate,
    required this.targetDate,
    this.milestones = const [],
    this.status = GoalStatus.active,
    this.xpReward,
    required this.createdAt,
    this.completedAt,
  });
  double get progress => targetValue > 0 ? (currentValue / targetValue).clamp(0, 1) : 0;
  bool get isCompleted => status == GoalStatus.completed;
  bool get isOverdue => DateTime.now().isAfter(targetDate) && !isCompleted;
  int get daysRemaining => targetDate.difference(DateTime.now()).inDays;

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: GoalCategory.fromString(json['category'] as String),
      type: GoalType.fromString(json['type'] as String),
      horseId: json['horseId'] as String?,
      horseName: json['horseName'] as String?,
      targetValue: (json['targetValue'] as num).toDouble(),
      currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      targetDate: DateTime.parse(json['targetDate'] as String),
      milestones: (json['milestones'] as List?)
          ?.map((m) => Milestone.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
      status: GoalStatus.fromString(json['status'] as String? ?? 'active'),
      xpReward: json['xpReward'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category.name,
      'type': type.name,
      'horseId': horseId,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'unit': unit,
      'startDate': startDate.toIso8601String(),
      'targetDate': targetDate.toIso8601String(),
      'milestones': milestones.map((m) => m.toJson()).toList(),
      'status': status.name,
      'xpReward': xpReward,
    };
  }
}

/// Goal categories
enum GoalCategory {
  training,     // Entraînement
  competition,  // Compétition
  health,       // Santé
  breeding,     // Élevage
  learning,     // Apprentissage
  financial,    // Financier
  general;

  String get displayName {
    switch (this) {
      case GoalCategory.training: return 'Entraînement';
      case GoalCategory.competition: return 'Compétition';
      case GoalCategory.health: return 'Santé';
      case GoalCategory.breeding: return 'Élevage';
      case GoalCategory.learning: return 'Apprentissage';
      case GoalCategory.financial: return 'Financier';
      case GoalCategory.general: return 'Général';
    }
  }

  IconData get icon {
    switch (this) {
      case GoalCategory.training: return Icons.fitness_center;
      case GoalCategory.competition: return Icons.emoji_events;
      case GoalCategory.health: return Icons.favorite;
      case GoalCategory.breeding: return Icons.pets;
      case GoalCategory.learning: return Icons.school;
      case GoalCategory.financial: return Icons.attach_money;
      case GoalCategory.general: return Icons.flag;
    }
  }

  static GoalCategory fromString(String value) {
    return GoalCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GoalCategory.general,
    );
  }
}

/// Goal types (quantitative vs qualitative)
enum GoalType {
  count,        // Nombre (ex: 10 compétitions)
  duration,     // Durée (ex: 100h d'entraînement)
  percentage,   // Pourcentage (ex: 90% sans faute)
  achievement,  // Achievement (oui/non)
  level;        // Niveau (ex: Galop 5)

  static GoalType fromString(String value) {
    return GoalType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GoalType.count,
    );
  }
}

/// Goal status
enum GoalStatus {
  active,
  completed,
  paused,
  abandoned,
  overdue;

  String get displayName {
    switch (this) {
      case GoalStatus.active: return 'Actif';
      case GoalStatus.completed: return 'Terminé';
      case GoalStatus.paused: return 'En pause';
      case GoalStatus.abandoned: return 'Abandonné';
      case GoalStatus.overdue: return 'En retard';
    }
  }

  static GoalStatus fromString(String value) {
    return GoalStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GoalStatus.active,
    );
  }
}

/// Milestone within a goal
class Milestone {
  final String id;
  final String title;
  final double targetValue;
  final bool isCompleted;
  final DateTime? completedAt;

  Milestone({
    required this.id,
    required this.title,
    required this.targetValue,
    this.isCompleted = false,
    this.completedAt,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'] as String,
      title: json['title'] as String,
      targetValue: (json['targetValue'] as num).toDouble(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'targetValue': targetValue,
      'isCompleted': isCompleted,
    };
  }
}

// ============================================
// TRAINING PLANS
// ============================================

/// AI-Generated training plan
class TrainingPlan {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? horseId;
  final String? horseName;
  final TrainingDiscipline discipline;
  final TrainingLevel level;
  final DateTime startDate;
  final DateTime endDate;
  final int weeksTotal;
  final int currentWeek;
  final List<TrainingWeek> weeks;
  final TrainingPlanStatus status;
  final String? aiRecommendations;
  final DateTime createdAt;

  TrainingPlan({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.horseId,
    this.horseName,
    required this.discipline,
    required this.level,
    required this.startDate,
    required this.endDate,
    required this.weeksTotal,
    this.currentWeek = 1,
    this.weeks = const [],
    this.status = TrainingPlanStatus.active,
    this.aiRecommendations,
    required this.createdAt,
  });

  double get progress => weeksTotal > 0 ? currentWeek / weeksTotal : 0;
  bool get isActive => status == TrainingPlanStatus.active;

  factory TrainingPlan.fromJson(Map<String, dynamic> json) {
    return TrainingPlan(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      horseId: json['horseId'] as String?,
      horseName: json['horseName'] as String?,
      discipline: TrainingDiscipline.fromString(json['discipline'] as String),
      level: TrainingLevel.fromString(json['level'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      weeksTotal: json['weeksTotal'] as int,
      currentWeek: json['currentWeek'] as int? ?? 1,
      weeks: (json['weeks'] as List?)
          ?.map((w) => TrainingWeek.fromJson(w as Map<String, dynamic>))
          .toList() ?? [],
      status: TrainingPlanStatus.fromString(json['status'] as String? ?? 'active'),
      aiRecommendations: json['aiRecommendations'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'horseId': horseId,
      'horseName': horseName,
      'discipline': discipline.name,
      'level': level.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'weeksTotal': weeksTotal,
      'currentWeek': currentWeek,
      'weeks': weeks.map((w) => w.toJson()).toList(),
      'status': status.name,
      'aiRecommendations': aiRecommendations,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Training week
class TrainingWeek {
  final int weekNumber;
  final String theme;
  final String? focus;
  final List<TrainingSession> sessions;
  final List<String> tips;
  final bool isCompleted;

  TrainingWeek({
    required this.weekNumber,
    required this.theme,
    this.focus,
    this.sessions = const [],
    this.tips = const [],
    this.isCompleted = false,
  });

  factory TrainingWeek.fromJson(Map<String, dynamic> json) {
    return TrainingWeek(
      weekNumber: json['weekNumber'] as int,
      theme: json['theme'] as String,
      focus: json['focus'] as String?,
      sessions: (json['sessions'] as List?)
          ?.map((s) => TrainingSession.fromJson(s as Map<String, dynamic>))
          .toList() ?? [],
      tips: (json['tips'] as List?)?.cast<String>() ?? [],
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekNumber': weekNumber,
      'theme': theme,
      'focus': focus,
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'tips': tips,
      'isCompleted': isCompleted,
    };
  }
}

/// Training session
class TrainingSession {
  final String id;
  final int dayOfWeek; // 1=Monday
  final String title;
  final String? description;
  final SessionType type;
  final int durationMinutes;
  final SessionIntensity intensity;
  final List<Exercise> exercises;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? notes;
  final int? rating; // 1-5 stars

  TrainingSession({
    required this.id,
    required this.dayOfWeek,
    required this.title,
    this.description,
    required this.type,
    required this.durationMinutes,
    this.intensity = SessionIntensity.moderate,
    this.exercises = const [],
    this.isCompleted = false,
    this.completedAt,
    this.notes,
    this.rating,
  });

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    return TrainingSession(
      id: json['id'] as String,
      dayOfWeek: json['dayOfWeek'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: SessionType.fromString(json['type'] as String),
      durationMinutes: json['durationMinutes'] as int,
      intensity: SessionIntensity.fromString(json['intensity'] as String? ?? 'moderate'),
      exercises: (json['exercises'] as List?)
          ?.map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      notes: json['notes'] as String?,
      rating: json['rating'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayOfWeek': dayOfWeek,
      'title': title,
      'description': description,
      'type': type.name,
      'durationMinutes': durationMinutes,
      'intensity': intensity.name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
      'rating': rating,
    };
  }
}

/// Session types
enum SessionType {
  flatwork,     // Travail sur le plat
  jumping,      // Saut d'obstacles
  dressage,     // Dressage
  crossCountry, // Cross
  longe,        // Longe
  liberty,      // Liberté
  trail,        // Extérieur/Balade
  groundwork,   // Travail à pied
  rest;         // Repos

  String get displayName {
    switch (this) {
      case SessionType.flatwork: return 'Travail sur le plat';
      case SessionType.jumping: return 'Saut d\'obstacles';
      case SessionType.dressage: return 'Dressage';
      case SessionType.crossCountry: return 'Cross-country';
      case SessionType.longe: return 'Longe';
      case SessionType.liberty: return 'Liberté';
      case SessionType.trail: return 'Extérieur';
      case SessionType.groundwork: return 'Travail à pied';
      case SessionType.rest: return 'Repos';
    }
  }

  static SessionType fromString(String value) {
    return SessionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SessionType.flatwork,
    );
  }
}

/// Session intensity
enum SessionIntensity {
  veryLight,
  light,
  moderate,
  intense,
  veryIntense;

  String get displayName {
    switch (this) {
      case SessionIntensity.veryLight: return 'Très léger';
      case SessionIntensity.light: return 'Léger';
      case SessionIntensity.moderate: return 'Modéré';
      case SessionIntensity.intense: return 'Intense';
      case SessionIntensity.veryIntense: return 'Très intense';
    }
  }

  int get color {
    switch (this) {
      case SessionIntensity.veryLight: return 0xFF81C784;
      case SessionIntensity.light: return 0xFF4CAF50;
      case SessionIntensity.moderate: return 0xFFFFEB3B;
      case SessionIntensity.intense: return 0xFFFF9800;
      case SessionIntensity.veryIntense: return 0xFFF44336;
    }
  }

  static SessionIntensity fromString(String value) {
    return SessionIntensity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SessionIntensity.moderate,
    );
  }
}

/// Exercise within a session
class Exercise {
  final String id;
  final String name;
  final String? description;
  final int durationMinutes;
  final int? repetitions;
  final String? videoUrl;
  final String? imageUrl;

  Exercise({
    required this.id,
    required this.name,
    this.description,
    required this.durationMinutes,
    this.repetitions,
    this.videoUrl,
    this.imageUrl,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      durationMinutes: json['durationMinutes'] as int,
      repetitions: json['repetitions'] as int?,
      videoUrl: json['videoUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'durationMinutes': durationMinutes,
      'repetitions': repetitions,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
    };
  }
}

/// Training disciplines
enum TrainingDiscipline {
  dressage,
  showJumping,
  eventing,
  endurance,
  western,
  horseball,
  ponyGames,
  trec,
  vaulting,
  general;

  String get displayName {
    switch (this) {
      case TrainingDiscipline.dressage: return 'Dressage';
      case TrainingDiscipline.showJumping: return 'Saut d\'obstacles';
      case TrainingDiscipline.eventing: return 'Concours complet';
      case TrainingDiscipline.endurance: return 'Endurance';
      case TrainingDiscipline.western: return 'Western';
      case TrainingDiscipline.horseball: return 'Horse-ball';
      case TrainingDiscipline.ponyGames: return 'Pony-games';
      case TrainingDiscipline.trec: return 'TREC';
      case TrainingDiscipline.vaulting: return 'Voltige';
      case TrainingDiscipline.general: return 'Général';
    }
  }

  static TrainingDiscipline fromString(String value) {
    return TrainingDiscipline.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TrainingDiscipline.general,
    );
  }
}

/// Training levels
enum TrainingLevel {
  beginner,     // Débutant (Galop 1-2)
  novice,       // Novice (Galop 3-4)
  intermediate, // Intermédiaire (Galop 5-6)
  advanced,     // Avancé (Galop 7)
  competitive,  // Compétiteur
  professional; // Professionnel

  String get displayName {
    switch (this) {
      case TrainingLevel.beginner: return 'Débutant';
      case TrainingLevel.novice: return 'Novice';
      case TrainingLevel.intermediate: return 'Intermédiaire';
      case TrainingLevel.advanced: return 'Avancé';
      case TrainingLevel.competitive: return 'Compétiteur';
      case TrainingLevel.professional: return 'Professionnel';
    }
  }

  static TrainingLevel fromString(String value) {
    return TrainingLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TrainingLevel.intermediate,
    );
  }
}

/// Training plan status
enum TrainingPlanStatus {
  draft,
  active,
  paused,
  completed,
  cancelled;

  static TrainingPlanStatus fromString(String value) {
    return TrainingPlanStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TrainingPlanStatus.active,
    );
  }
}

// ============================================
// AI TRAINING RECOMMENDATIONS
// ============================================

/// AI training recommendation
class TrainingRecommendation {
  final String id;
  final String horseId;
  final String horseName;
  final String title;
  final String description;
  final RecommendationType type;
  final RecommendationPriority priority;
  final List<String> suggestions;
  final String? basedOn; // What analysis/data this is based on
  final DateTime createdAt;
  final bool isDismissed;

  TrainingRecommendation({
    required this.id,
    required this.horseId,
    required this.horseName,
    required this.title,
    required this.description,
    required this.type,
    this.priority = RecommendationPriority.medium,
    this.suggestions = const [],
    this.basedOn,
    required this.createdAt,
    this.isDismissed = false,
  });

  factory TrainingRecommendation.fromJson(Map<String, dynamic> json) {
    return TrainingRecommendation(
      id: json['id'] as String,
      horseId: json['horseId'] as String,
      horseName: json['horseName'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String,
      type: RecommendationType.fromString(json['type'] as String),
      priority: RecommendationPriority.fromString(json['priority'] as String? ?? 'medium'),
      suggestions: (json['suggestions'] as List?)?.cast<String>() ?? [],
      basedOn: json['basedOn'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isDismissed: json['isDismissed'] as bool? ?? false,
    );
  }
}

enum RecommendationType {
  improvement,    // Zone d'amélioration
  strength,       // Point fort à développer
  recovery,       // Récupération
  technique,      // Technique
  conditioning,   // Conditionnement
  behavior;       // Comportement

  String get displayName {
    switch (this) {
      case RecommendationType.improvement: return 'Amélioration';
      case RecommendationType.strength: return 'Point fort';
      case RecommendationType.recovery: return 'Récupération';
      case RecommendationType.technique: return 'Technique';
      case RecommendationType.conditioning: return 'Conditionnement';
      case RecommendationType.behavior: return 'Comportement';
    }
  }

  static RecommendationType fromString(String value) {
    return RecommendationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RecommendationType.improvement,
    );
  }
}

enum RecommendationPriority {
  low,
  medium,
  high;

  static RecommendationPriority fromString(String value) {
    return RecommendationPriority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RecommendationPriority.medium,
    );
  }
}

// ============================================
// PLANNING SUMMARY
// ============================================

/// Overview of planning for a user
class PlanningSummary {
  final String userId;
  final List<CalendarEvent> upcomingEvents;
  final List<Goal> activeGoals;
  final TrainingPlan? activeTrainingPlan;
  final TrainingSession? todaySession;
  final List<TrainingRecommendation> recommendations;
  final int eventsThisWeek;
  final int goalsInProgress;
  final double weeklyProgressPercent;

  PlanningSummary({
    required this.userId,
    this.upcomingEvents = const [],
    this.activeGoals = const [],
    this.activeTrainingPlan,
    this.todaySession,
    this.recommendations = const [],
    this.eventsThisWeek = 0,
    this.goalsInProgress = 0,
    this.weeklyProgressPercent = 0,
  });

  factory PlanningSummary.fromJson(Map<String, dynamic> json) {
    return PlanningSummary(
      userId: json['userId'] as String,
      upcomingEvents: (json['upcomingEvents'] as List?)
          ?.map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      activeGoals: (json['activeGoals'] as List?)
          ?.map((g) => Goal.fromJson(g as Map<String, dynamic>))
          .toList() ?? [],
      activeTrainingPlan: json['activeTrainingPlan'] != null
          ? TrainingPlan.fromJson(json['activeTrainingPlan'] as Map<String, dynamic>)
          : null,
      todaySession: json['todaySession'] != null
          ? TrainingSession.fromJson(json['todaySession'] as Map<String, dynamic>)
          : null,
      recommendations: (json['recommendations'] as List?)
          ?.map((r) => TrainingRecommendation.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
      eventsThisWeek: json['eventsThisWeek'] as int? ?? 0,
      goalsInProgress: json['goalsInProgress'] as int? ?? 0,
      weeklyProgressPercent: (json['weeklyProgressPercent'] as num?)?.toDouble() ?? 0,
    );
  }
}
