# 🏛️ MODULE CLUBS - Gestion des Clubs & Écuries

## Description
Gestion des clubs équestres, écuries et centres de formation. Permet de gérer les membres, les chevaux de club, les cours et les abonnements collectifs.

## Objectif Business
Offrir une solution complète aux structures professionnelles pour gérer leur activité et fidéliser via des fonctionnalités exclusives B2B.

---

## 📱 Écrans/Pages

### 1. Dashboard Club (`/club`)
- Vue d'ensemble de la structure
- Statistiques membres
- Chevaux de club
- Événements à venir
- Alertes et rappels

### 2. Liste des Membres (`/club/members`)
- Grille/Liste des membres
- Filtres: niveau, statut, abonnement
- Recherche par nom
- Actions en masse
- Bouton "+ Inviter membre"

### 3. Détail Membre (`/club/members/:id`)
- Profil utilisateur
- Cavalier associé
- Historique cours/leçons
- Abonnement club
- Performances

### 4. Gestion Chevaux Club (`/club/horses`)
- Liste chevaux appartenant au club
- Attribution aux membres
- Planning d'utilisation
- Suivi santé groupé

### 5. Planning & Cours (`/club/schedule`)
- Vue calendrier
- Cours collectifs
- Leçons individuelles
- Stages et événements

### 6. Administration (`/club/settings`)
- Informations du club
- Tarifs et abonnements
- Permissions membres
- Intégrations

---

## 🏢 Types de Structures

| Type | Description | Fonctionnalités |
|------|-------------|-----------------|
| **Centre équestre** | Structure avec cavalerie | Cours, pension, location |
| **Écurie de propriétaires** | Pension pure | Pension, services |
| **Haras** | Élevage | Breeding, vente |
| **Club de compétition** | Équipe sportive | Analyses, coaching |
| **École de formation** | Formation pro | Certifications, stages |

---

## 🔄 Flux Utilisateur

### Inviter un membre
```
1. Click "+ Inviter membre"
2. Saisir email du futur membre
3. Sélectionner rôle club:
   - Cavalier
   - Propriétaire
   - Moniteur
   - Personnel
4. Sélectionner niveau d'accès
5. Envoyer invitation
6. Email envoyé avec lien
7. Destinataire crée compte ou lie existant
8. Membre ajouté au club
```

### Créer un cours collectif
```
1. Planning → "+ Nouveau cours"
2. Type: Cours collectif
3. Informations:
   - Titre: "Cours CSO Intermédiaire"
   - Moniteur: sélection
   - Date et heure
   - Durée: 1h
   - Places max: 8
   - Niveau requis: Galop 4+
   - Tarif: 35€ ou inclus abonnement
4. Chevaux de club disponibles
5. Créer → cours visible au planning
6. Membres peuvent s'inscrire
```

### Gérer un cheval de club
```
1. Chevaux club → Sélection cheval
2. Informations spécifiques:
   - Niveau d'utilisation: débutant/intermédiaire/avancé
   - Spécialités: CSO, dressage, mise en selle
   - Restrictions: poids max cavalier
3. Planning d'utilisation:
   - Heures max/jour: 4h
   - Jours de repos: dimanche
4. Attribution temporaire à membres
5. Suivi utilisation automatique
```

---

## 💾 Modèle de Données

```typescript
interface Club {
  id: string;                    // UUID v4
  organizationId: string;        // FK Organization (1-1)

  // Identité
  name: string;
  type: ClubType;
  description?: string;
  logoUrl?: string;
  coverImageUrl?: string;

  // Coordonnées
  address: {
    street: string;
    city: string;
    postalCode: string;
    country: string;
    coordinates?: { lat: number; lng: number };
  };
  phone?: string;
  email?: string;
  website?: string;

  // Informations légales
  siret?: string;
  licenseFFE?: string;
  insuranceNumber?: string;

  // Capacités
  capacity: {
    maxMembers?: number;
    maxHorses?: number;
    arenas: number;
    stables: number;
  };

  // Paramètres
  settings: {
    allowPublicBooking: boolean;
    requireApproval: boolean;
    minBookingAdvance: number;   // heures
    maxBookingAdvance: number;   // jours
    cancellationPolicy: string;
  };

  // Stats
  stats: {
    totalMembers: number;
    activeMembers: number;
    totalHorses: number;
    clubHorses: number;
    privateHorses: number;
  };

  // Subscription
  subscriptionPlan: string;      // Plan B2B
  subscriptionStatus: 'active' | 'trial' | 'expired';

  createdAt: Date;
  updatedAt: Date;
}

interface ClubMembership {
  id: string;
  clubId: string;                // FK Club
  userId: string;                // FK User
  riderId?: string;              // FK Rider (si cavalier)

  // Rôle
  role: ClubRole;
  permissions: ClubPermission[];

  // Abonnement
  subscription?: {
    planId: string;
    startDate: Date;
    endDate?: Date;
    status: 'active' | 'expired' | 'cancelled';
    autoRenew: boolean;
  };

  // Dates
  joinedAt: Date;
  leftAt?: Date;
  status: 'active' | 'inactive' | 'pending' | 'suspended';

  // Notes
  notes?: string;
  emergencyContact?: {
    name: string;
    phone: string;
    relation: string;
  };

  createdAt: Date;
  updatedAt: Date;
}

interface ClubHorse {
  id: string;
  clubId: string;                // FK Club
  horseId: string;               // FK Horse

  // Type
  ownershipType: 'club_owned' | 'private_boarded';

  // Si cheval de club
  clubSettings?: {
    usageLevel: 'beginner' | 'intermediate' | 'advanced' | 'competition';
    specialties: string[];       // CSO, dressage, etc.
    maxDailyHours: number;
    restDays: number[];          // 0=dimanche
    maxRiderWeight?: number;     // kg
    restrictions?: string;
  };

  // Si pension
  boardingSettings?: {
    ownerId: string;             // FK User (propriétaire)
    boxNumber?: string;
    monthlyRate: number;
    services: string[];          // nourri, sorti, etc.
    startDate: Date;
    endDate?: Date;
  };

  // Planning
  schedule: {
    weeklyMaxHours: number;
    currentWeekHours: number;
    lastUsed?: Date;
  };

  status: 'available' | 'in_use' | 'resting' | 'unavailable';

  createdAt: Date;
  updatedAt: Date;
}

interface ClubLesson {
  id: string;
  clubId: string;                // FK Club

  // Type
  type: 'group' | 'private' | 'stage' | 'competition_prep';

  // Informations
  title: string;
  description?: string;
  discipline: string;
  level: string;                 // "Galop 4-5"

  // Encadrant
  instructorId: string;          // FK User (moniteur)

  // Timing
  startTime: Date;
  endTime: Date;
  duration: number;              // minutes
  recurrence?: {
    type: 'weekly' | 'biweekly' | 'monthly';
    days?: number[];             // 0-6
    until?: Date;
  };

  // Participants
  maxParticipants: number;
  currentParticipants: number;
  participants: LessonParticipant[];
  waitlist: string[];            // User IDs

  // Tarification
  pricing: {
    regularPrice: number;
    memberPrice?: number;
    includedInPlans?: string[];
  };

  // Lieu
  arena?: string;                // Nom de la carrière/manège

  // Statut
  status: 'scheduled' | 'in_progress' | 'completed' | 'cancelled';
  cancellationReason?: string;

  createdAt: Date;
  updatedAt: Date;
}

interface LessonParticipant {
  userId: string;
  riderId?: string;
  horseId?: string;              // Cheval monté
  horseSource: 'club' | 'private';
  registeredAt: Date;
  attendance?: 'present' | 'absent' | 'excused';
  paymentStatus: 'pending' | 'paid' | 'included';
}

type ClubType =
  | 'riding_school'             // Centre équestre
  | 'boarding_stable'           // Écurie pension
  | 'breeding_farm'             // Haras
  | 'competition_team'          // Équipe compétition
  | 'training_center';          // Centre formation

type ClubRole =
  | 'owner'                     // Gérant
  | 'manager'                   // Responsable
  | 'instructor'                // Moniteur
  | 'stable_hand'               // Palefrenier
  | 'rider'                     // Cavalier
  | 'horse_owner'               // Propriétaire
  | 'visitor';                  // Visiteur

type ClubPermission =
  | 'manage_members'
  | 'manage_horses'
  | 'manage_schedule'
  | 'manage_billing'
  | 'view_analytics'
  | 'create_lessons'
  | 'book_lessons'
  | 'use_club_horses';
```

---

## 🔌 API Endpoints

### Club
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/club` | Infos du club |
| PATCH | `/club` | Modifier club |
| GET | `/club/stats` | Statistiques |
| GET | `/club/analytics` | Analytics détaillées |

### Membres
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/club/members` | Liste membres |
| POST | `/club/members/invite` | Inviter membre |
| GET | `/club/members/:id` | Détail membre |
| PATCH | `/club/members/:id` | Modifier |
| DELETE | `/club/members/:id` | Retirer membre |
| POST | `/club/members/:id/suspend` | Suspendre |

### Chevaux
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/club/horses` | Chevaux du club |
| POST | `/club/horses` | Ajouter cheval |
| GET | `/club/horses/:id` | Détail |
| PATCH | `/club/horses/:id` | Modifier |
| GET | `/club/horses/:id/schedule` | Planning cheval |

### Planning
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/club/lessons` | Liste cours |
| POST | `/club/lessons` | Créer cours |
| GET | `/club/lessons/:id` | Détail cours |
| PATCH | `/club/lessons/:id` | Modifier |
| DELETE | `/club/lessons/:id` | Annuler |
| POST | `/club/lessons/:id/register` | S'inscrire |
| DELETE | `/club/lessons/:id/register` | Se désinscrire |
| POST | `/club/lessons/:id/attendance` | Noter présences |

---

## 💰 Abonnements Club (B2B)

| Plan | Prix/mois | Membres | Chevaux | Features |
|------|-----------|---------|---------|----------|
| **Starter** | 49€ | 20 | 10 | Base |
| **Pro** | 149€ | 100 | 50 | + Analytics |
| **Enterprise** | 399€ | Illimité | Illimité | + API + Support |

### Features par plan
- **Starter**: Gestion membres, planning, chevaux club
- **Pro**: + Analytics avancées, multi-sites, exports
- **Enterprise**: + API intégration, support dédié, SLA

---

## 🎨 États de l'Interface

### Dashboard
- **Empty**: "Configurez votre club pour commencer"
- **Active**: Statistiques temps réel
- **Alerts**: Bannière alertes importantes

### Cours
- **Open**: Places disponibles
- **Full**: Complet (liste attente possible)
- **In Progress**: Cours en cours
- **Cancelled**: Annulé (raison affichée)

### Membre
- **Pending**: Invitation envoyée
- **Active**: Membre actif
- **Suspended**: Compte suspendu
- **Inactive**: Plus membre

---

## 🔒 Permissions

| Action | Owner | Manager | Instructor | Rider |
|--------|-------|---------|------------|-------|
| Gérer club | ✓ | ✗ | ✗ | ✗ |
| Gérer membres | ✓ | ✓ | ✗ | ✗ |
| Créer cours | ✓ | ✓ | ✓ | ✗ |
| Inscrire cours | ✓ | ✓ | ✓ | ✓ |
| Gérer chevaux | ✓ | ✓ | ✗ | ✗ |
| Voir analytics | ✓ | ✓ | ✗ | ✗ |
| Facturation | ✓ | ✓ | ✗ | ✗ |

---

## 🔗 Relations

| Module | Relation |
|--------|----------|
| **Organizations** | 1-1 |
| **Users** | N-N (membres) |
| **Horses** | N-N (chevaux club) |
| **Calendar** | Cours en événements |
| **Subscriptions** | Abonnements B2B |
| **Gamification** | Challenges inter-clubs |

---

## 📊 Métriques

- Taux d'occupation des cours
- Utilisation chevaux de club
- Taux de rétention membres
- Revenus par membre
- Fréquentation moyenne
- NPS (satisfaction)

