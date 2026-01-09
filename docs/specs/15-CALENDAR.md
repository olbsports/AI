# 📅 MODULE CALENDAR - Calendrier & Événements

## Description
Gestion centralisée des événements équestres: compétitions, entraînements, rendez-vous vétérinaires, rappels santé, cours et événements personnalisés.

## Objectif Business
Centraliser toute la planification équestre pour améliorer l'organisation et l'engagement quotidien des utilisateurs.

---

## 📱 Écrans/Pages

### 1. Vue Calendrier (`/calendar`)
- Vues: Jour, Semaine, Mois
- Filtres par type, cheval, catégorie
- Code couleur par type
- Navigation rapide
- Bouton "+ Nouvel événement"

### 2. Vue Agenda (`/calendar/agenda`)
- Liste chronologique des événements
- Groupés par jour
- Scroll infini
- Actions rapides

### 3. Détail Événement (`/calendar/:id`)
- Informations complètes
- Participants
- Lieu et carte
- Documents attachés
- Actions: modifier, supprimer

### 4. Création Événement (`/calendar/new`)
- Type d'événement
- Formulaire adaptatif
- Récurrence
- Rappels
- Invitations

### 5. Rappels Santé (`/calendar/health-reminders`)
- Vue dédiée aux rappels santé
- Vaccins à venir
- Vermifuges
- Rendez-vous véto

---

## 🎨 Types d'Événements

| Type | Code | Couleur | Icône |
|------|------|---------|-------|
| Compétition | `competition` | 🔵 Bleu | 🏆 |
| Entraînement | `training` | 🟢 Vert | 🏇 |
| Cours | `lesson` | 🟣 Violet | 📚 |
| Vétérinaire | `vet` | 🔴 Rouge | 🩺 |
| Maréchal | `farrier` | 🟠 Orange | 🔨 |
| Rappel santé | `health_reminder` | 🟡 Jaune | 💉 |
| Transport | `transport` | 🟤 Marron | 🚛 |
| Personnel | `personal` | ⚪ Gris | 📌 |

---

## 🔄 Flux Utilisateur

### Créer un événement
```
1. Click "+ Nouvel événement"
2. Sélection type
3. Formulaire:
   - Titre
   - Date/Heure début
   - Date/Heure fin (ou durée)
   - Lieu (optionnel)
   - Cheval(aux) concerné(s)
   - Description
4. Options avancées:
   - Récurrence
   - Rappels
   - Invitations
5. Créer → événement ajouté
```

### Configurer rappels santé
```
1. Calendrier → Rappels Santé
2. Ou: Fiche cheval → Santé → Rappels
3. Types de rappels:
   - Vaccin grippe: tous les 6 mois
   - Vaccin tétanos: annuel
   - Vermifuge: tous les 2 mois
   - Dentiste: annuel
   - Maréchal: toutes les 6-8 semaines
4. Configuration par cheval
5. Rappels auto-créés au calendrier
```

### Créer événement récurrent
```
1. Nouvel événement → Type: Entraînement
2. Titre: "Travail sur le plat"
3. Date/Heure: Mardi 18h-19h
4. Cheval: Tornado
5. Récurrence:
   - Type: Hebdomadaire
   - Jours: Mar, Jeu
   - Jusqu'au: 31/12/2026
6. Créer → série d'événements générée
```

### Inviter à un événement
```
1. Créer/Modifier événement
2. Onglet Participants
3. Rechercher utilisateur ou email
4. Envoyer invitation
5. Destinataire reçoit notification
6. Accepte/Refuse
7. Visible dans son calendrier si accepté
```

---

## 💾 Modèle de Données

```typescript
interface CalendarEvent {
  id: string;                    // UUID v4
  organizationId: string;        // FK Organization
  createdById: string;           // FK User

  // Type
  type: EventType;
  category?: string;             // Sous-catégorie libre

  // Titre et description
  title: string;                 // Max 255
  description?: string;          // Max 5000

  // Timing
  startTime: Date;
  endTime: Date;
  isAllDay: boolean;
  timezone: string;

  // Récurrence
  recurrence?: RecurrenceRule;
  recurrenceId?: string;         // ID événement parent si récurrent
  recurrenceException: boolean;  // Exception à la série

  // Lieu
  location?: {
    name?: string;
    address?: string;
    coordinates?: { lat: number; lng: number };
    url?: string;                // Lien visio si online
  };

  // Associations
  horseIds: string[];            // FK Horse[]
  riderIds: string[];            // FK Rider[]

  // Liens vers autres modules
  linkedAppointment?: string;    // FK Appointment (services)
  linkedAnalysis?: string;       // FK Analysis
  linkedGestation?: string;      // FK Gestation (milestone)
  linkedCompetition?: string;    // FK externe

  // Participants
  participants: EventParticipant[];

  // Rappels
  reminders: EventReminder[];

  // Pièces jointes
  attachments: {
    name: string;
    url: string;
    type: string;
  }[];

  // Compétition (si type=competition)
  competitionDetails?: {
    discipline: string;
    level: string;
    organizer?: string;
    engagementDeadline?: Date;
    fees?: number;
    status: 'planned' | 'engaged' | 'scratched' | 'completed';
    result?: {
      ranking?: number;
      score?: number;
      penalties?: number;
      notes?: string;
    };
  };

  // Statut
  status: 'scheduled' | 'completed' | 'cancelled';
  cancelReason?: string;

  // Couleur personnalisée
  color?: string;                // Hex

  // Visibilité
  visibility: 'private' | 'organization' | 'public';

  createdAt: Date;
  updatedAt: Date;
}

interface RecurrenceRule {
  frequency: 'daily' | 'weekly' | 'monthly' | 'yearly';
  interval: number;              // Tous les X (jours, semaines...)
  daysOfWeek?: number[];         // 0-6 pour weekly
  dayOfMonth?: number;           // 1-31 pour monthly
  monthOfYear?: number;          // 1-12 pour yearly
  count?: number;                // Nombre d'occurrences
  until?: Date;                  // Date de fin
  exceptions?: Date[];           // Dates exclues
}

interface EventParticipant {
  userId?: string;               // FK User (si membre)
  email?: string;                // Si externe
  name?: string;
  role: 'organizer' | 'required' | 'optional';
  status: 'pending' | 'accepted' | 'declined' | 'tentative';
  respondedAt?: Date;
  notes?: string;
}

interface EventReminder {
  id: string;
  type: 'notification' | 'email' | 'sms';
  timing: number;                // Minutes avant (ex: 60 = 1h avant)
  sent: boolean;
  sentAt?: Date;
}

interface HealthReminder {
  id: string;
  organizationId: string;
  horseId: string;               // FK Horse

  // Type
  type: HealthReminderType;
  customType?: string;

  // Fréquence
  frequency: {
    type: 'days' | 'weeks' | 'months' | 'years';
    interval: number;
  };

  // Dates
  lastDoneAt?: Date;
  nextDueAt: Date;

  // Rappel
  reminderDaysBefore: number;

  // Notes
  notes?: string;
  vetName?: string;

  // État
  isActive: boolean;

  createdAt: Date;
  updatedAt: Date;
}

type EventType =
  | 'competition'
  | 'training'
  | 'lesson'
  | 'vet'
  | 'farrier'
  | 'health_reminder'
  | 'transport'
  | 'personal'
  | 'other';

type HealthReminderType =
  | 'vaccination'
  | 'deworming'
  | 'dental'
  | 'farrier'
  | 'osteopath'
  | 'checkup'
  | 'other';
```

---

## 🔌 API Endpoints

### Calendrier
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/calendar/events` | Liste événements (range) |
| POST | `/calendar/events` | Créer événement |
| GET | `/calendar/events/:id` | Détail |
| PATCH | `/calendar/events/:id` | Modifier |
| DELETE | `/calendar/events/:id` | Supprimer |
| DELETE | `/calendar/events/:id/series` | Supprimer série |
| POST | `/calendar/events/:id/respond` | Répondre invitation |

### Rappels santé
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/calendar/health-reminders` | Liste rappels |
| POST | `/calendar/health-reminders` | Créer rappel |
| PATCH | `/calendar/health-reminders/:id` | Modifier |
| DELETE | `/calendar/health-reminders/:id` | Supprimer |
| POST | `/calendar/health-reminders/:id/done` | Marquer effectué |

### Vues
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/calendar/day/:date` | Vue jour |
| GET | `/calendar/week/:date` | Vue semaine |
| GET | `/calendar/month/:year/:month` | Vue mois |
| GET | `/calendar/agenda` | Vue agenda |

### Export/Sync
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/calendar/export/ical` | Export iCal |
| GET | `/calendar/feed/:token` | Feed iCal privé |
| POST | `/calendar/import` | Import iCal |

---

## 🔔 Système de Rappels

### Types de rappels
- **Push notification**: App mobile/web
- **Email**: Message détaillé
- **SMS**: Pour événements critiques (premium)

### Timings par défaut
| Type événement | Rappels |
|----------------|---------|
| Compétition | 1 semaine, 1 jour, 2h avant |
| Vétérinaire | 1 jour, 2h avant |
| Entraînement | 1h avant |
| Rappel santé | 1 semaine, 1 jour avant |

### Personnalisation
L'utilisateur peut configurer:
- Canaux de notification par type
- Timings personnalisés
- Heures calmes (pas de notif 22h-7h)

---

## 📱 Intégrations Calendrier

### Export iCal
- Génération URL privée unique
- Compatible: Google Calendar, Apple Calendar, Outlook
- Sync automatique (poll toutes les heures)

### Import
- Fichiers .ics
- Mapping automatique des types si possible
- Prévisualisation avant import

---

## 🎨 États de l'Interface

### Vue calendrier
- **Today**: Indicateur jour actuel
- **Selected**: Jour/semaine sélectionné
- **Events**: Points colorés par type
- **Busy**: Indication créneaux occupés

### Événement
- **Scheduled**: Badge normal
- **In Progress**: Badge vert pulsant
- **Completed**: Badge grisé avec ✓
- **Cancelled**: Badge barré

### Rappel santé
- **Upcoming**: Jaune (< 7 jours)
- **Due**: Orange (aujourd'hui)
- **Overdue**: Rouge (dépassé)
- **Done**: Vert avec date

---

## 🔒 Permissions

| Action | Owner | Admin | Analyst | Member | Viewer |
|--------|-------|-------|---------|--------|--------|
| Voir calendrier | ✓ | ✓ | ✓ | ✓ | ✓ |
| Créer événement | ✓ | ✓ | ✓ | ✓ | ✗ |
| Modifier (own) | ✓ | ✓ | ✓ | ✓ | ✗ |
| Modifier (all) | ✓ | ✓ | ✗ | ✗ | ✗ |
| Supprimer | ✓ | ✓ | ✓ | ✓* | ✗ |
| Gérer rappels | ✓ | ✓ | ✓ | ✗ | ✗ |

*Uniquement ses propres événements

---

## 🔗 Relations

| Module | Relation |
|--------|----------|
| **Horses** | Événements liés aux chevaux |
| **Services** | RDV prestataires |
| **Gestation** | Milestones gestation |
| **Health** | Rappels santé |
| **Notifications** | Rappels événements |
| **Clubs** | Cours et événements club |

---

## 📊 Métriques

- Événements créés par mois
- Types d'événements les plus fréquents
- Taux de rappels santé respectés
- Utilisation de la récurrence
- Taux de réponse aux invitations
- Export iCal actifs

