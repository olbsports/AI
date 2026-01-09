# 🔧 MODULE SERVICES - Prestataires & Professionnels

## Description
Annuaire et gestion des prestataires équins: vétérinaires, maréchaux-ferrants, ostéopathes, dentistes, transporteurs, photographes, etc. Réservation et avis intégrés.

## Objectif Business
Créer un écosystème de services autour des utilisateurs, générant des revenus via commissions sur réservations et visibilité premium pour les prestataires.

---

## 📱 Écrans/Pages

### 1. Annuaire (`/services`)
- Carte interactive avec prestataires
- Liste filtrable
- Catégories de services
- Recherche par nom/localisation
- Filtres: disponibilité, note, distance

### 2. Fiche Prestataire (`/services/:id`)
- Photo/Logo professionnel
- Informations et spécialités
- Zone d'intervention
- Tarifs indicatifs
- Avis et notes
- Calendrier disponibilités
- Bouton "Prendre RDV"

### 3. Réservation (`/services/:id/book`)
- Sélection service
- Choix date/heure
- Informations cheval
- Adresse intervention
- Confirmation et paiement

### 4. Mes Rendez-vous (`/appointments`)
- Liste RDV à venir
- Historique
- Actions: modifier, annuler

### 5. Espace Pro (`/pro/dashboard`)
- Dashboard prestataire
- Gestion agenda
- Demandes de RDV
- Statistiques

---

## 🏷️ Catégories de Services

| Catégorie | Code | Icône |
|-----------|------|-------|
| Vétérinaire | `vet` | 🩺 |
| Maréchal-ferrant | `farrier` | 🔨 |
| Ostéopathe | `osteopath` | 🦴 |
| Dentiste équin | `dentist` | 🦷 |
| Chiropracteur | `chiropractor` | 💆 |
| Masseur | `massager` | ✋ |
| Nutritionniste | `nutritionist` | 🥕 |
| Transporteur | `transporter` | 🚛 |
| Photographe | `photographer` | 📷 |
| Coach/Moniteur | `coach` | 🏇 |
| Sellier | `saddler` | 🎠 |
| Toiletteur | `groomer` | ✂️ |

---

## 🔄 Flux Utilisateur

### Rechercher un prestataire
```
1. Menu → Services
2. Vue carte ou liste
3. Filtres:
   - Catégorie: Vétérinaire
   - Distance: < 30km
   - Note: 4+ étoiles
   - Disponibilité: Cette semaine
4. Résultats filtrés
5. Click sur fiche → détails
```

### Prendre rendez-vous
```
1. Fiche prestataire → "Prendre RDV"
2. Sélection service:
   - Consultation générale (60€)
   - Vaccination (45€)
   - Urgence (+30€)
3. Sélection cheval concerné
4. Choix créneau:
   - Calendrier avec disponibilités
   - Sélection date/heure
5. Lieu:
   - À domicile (adresse)
   - Cabinet du prestataire
6. Notes/Motif
7. Récapitulatif + prix
8. Paiement (optionnel selon prestataire)
9. Confirmation → email + notification
```

### Laisser un avis
```
1. Après RDV terminé → notification "Donnez votre avis"
2. Note: 1-5 étoiles
3. Critères:
   - Ponctualité
   - Professionnalisme
   - Rapport qualité/prix
   - Communication
4. Commentaire texte (optionnel)
5. Photos (optionnel)
6. Submit → avis publié après modération
```

### S'inscrire comme prestataire
```
1. /pro/register
2. Informations personnelles
3. Qualifications:
   - Diplômes (upload)
   - Certifications
   - Assurance professionnelle
4. Services proposés
5. Zone d'intervention
6. Tarifs
7. Validation équipe HorseTempo
8. Profil activé
```

---

## 💾 Modèle de Données

```typescript
interface ServiceProvider {
  id: string;                    // UUID v4
  userId: string;                // FK User
  organizationId?: string;       // FK Organization (si structure)

  // Identité
  type: 'individual' | 'company';
  displayName: string;
  businessName?: string;
  photoUrl?: string;
  coverImageUrl?: string;
  bio?: string;                  // Max 2000 caractères

  // Catégories
  categories: ServiceCategory[];
  specializations: string[];     // Ex: "Chirurgie", "Comportementaliste"

  // Contact
  contact: {
    email: string;
    phone: string;
    website?: string;
    socialLinks?: Record<string, string>;
  };

  // Localisation
  location: {
    address: string;
    city: string;
    postalCode: string;
    country: string;
    coordinates: { lat: number; lng: number };
  };
  serviceRadius: number;         // km
  mobileService: boolean;        // Se déplace
  hasClinic: boolean;            // Reçoit sur place

  // Qualifications
  qualifications: Qualification[];
  insuranceInfo?: {
    company: string;
    policyNumber: string;
    expiresAt: Date;
  };

  // Services
  services: ServiceOffering[];

  // Disponibilités
  schedule: WeeklySchedule;
  holidayDates: Date[];
  nextAvailableSlot?: Date;

  // Tarification
  paymentMethods: ('cash' | 'card' | 'transfer' | 'check')[];
  acceptsOnlinePayment: boolean;
  depositRequired: boolean;
  depositPercent?: number;

  // Stats & Réputation
  rating: {
    average: number;             // 0-5
    count: number;
    breakdown: { [key: number]: number }; // 1-5: count
  };
  reviewCount: number;
  responseRate: number;          // %
  responseTime: number;          // minutes moyennes

  // Visibilité
  isVerified: boolean;           // Validé par HorseTempo
  isPremium: boolean;            // Abonnement pro
  status: 'active' | 'inactive' | 'pending' | 'suspended';

  createdAt: Date;
  updatedAt: Date;
}

interface ServiceOffering {
  id: string;
  name: string;                  // "Consultation générale"
  description?: string;
  category: ServiceCategory;
  duration: number;              // minutes
  price: number;
  currency: string;
  priceType: 'fixed' | 'from' | 'quote';
  atClinic: boolean;
  atHome: boolean;
  homeExtraFee?: number;
}

interface Qualification {
  id: string;
  type: 'diploma' | 'certification' | 'license' | 'other';
  name: string;
  issuer: string;
  obtainedAt: Date;
  expiresAt?: Date;
  documentUrl?: string;
  verified: boolean;
}

interface WeeklySchedule {
  monday?: DaySchedule;
  tuesday?: DaySchedule;
  wednesday?: DaySchedule;
  thursday?: DaySchedule;
  friday?: DaySchedule;
  saturday?: DaySchedule;
  sunday?: DaySchedule;
}

interface DaySchedule {
  isAvailable: boolean;
  slots: {
    start: string;               // "09:00"
    end: string;                 // "12:00"
  }[];
}

interface Appointment {
  id: string;                    // UUID v4
  providerId: string;            // FK ServiceProvider
  clientId: string;              // FK User
  organizationId: string;        // FK Organization

  // Service
  serviceId: string;             // FK ServiceOffering
  serviceName: string;           // Dénormalisé pour historique

  // Cheval
  horseId?: string;              // FK Horse
  horseName?: string;

  // Timing
  scheduledAt: Date;
  duration: number;              // minutes
  endTime: Date;

  // Lieu
  locationType: 'clinic' | 'home';
  address?: string;
  coordinates?: { lat: number; lng: number };

  // Statut
  status: AppointmentStatus;
  statusHistory: {
    status: AppointmentStatus;
    changedAt: Date;
    changedBy: string;
    reason?: string;
  }[];

  // Détails
  clientNotes?: string;
  providerNotes?: string;
  internalNotes?: string;        // Visible uniquement par provider

  // Paiement
  price: number;
  depositAmount?: number;
  depositPaid: boolean;
  paymentStatus: 'pending' | 'partial' | 'paid' | 'refunded';
  paymentMethod?: string;

  // Post-RDV
  completed: boolean;
  completedAt?: Date;
  report?: string;               // Compte-rendu prestataire

  // Review
  reviewId?: string;             // FK Review

  createdAt: Date;
  updatedAt: Date;
}

interface Review {
  id: string;
  providerId: string;            // FK ServiceProvider
  appointmentId: string;         // FK Appointment
  authorId: string;              // FK User

  // Notes
  overallRating: number;         // 1-5
  ratings: {
    punctuality?: number;        // 1-5
    professionalism?: number;
    valueForMoney?: number;
    communication?: number;
  };

  // Contenu
  content?: string;              // Max 1000
  photoUrls: string[];

  // Réponse
  providerResponse?: {
    content: string;
    respondedAt: Date;
  };

  // Modération
  status: 'pending' | 'published' | 'hidden' | 'rejected';
  reportCount: number;

  createdAt: Date;
  updatedAt: Date;
}

type ServiceCategory =
  | 'vet'
  | 'farrier'
  | 'osteopath'
  | 'dentist'
  | 'chiropractor'
  | 'massager'
  | 'nutritionist'
  | 'transporter'
  | 'photographer'
  | 'coach'
  | 'saddler'
  | 'groomer'
  | 'other';

type AppointmentStatus =
  | 'pending'                    // En attente confirmation
  | 'confirmed'                  // Confirmé
  | 'cancelled_client'           // Annulé par client
  | 'cancelled_provider'         // Annulé par prestataire
  | 'completed'                  // Terminé
  | 'no_show';                   // Non présenté
```

---

## 🔌 API Endpoints

### Annuaire
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/services` | Recherche prestataires |
| GET | `/services/:id` | Fiche prestataire |
| GET | `/services/:id/reviews` | Avis |
| GET | `/services/:id/availability` | Disponibilités |
| GET | `/services/categories` | Liste catégories |
| GET | `/services/nearby` | Proches de moi |

### Rendez-vous (Client)
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/appointments` | Mes RDV |
| POST | `/appointments` | Prendre RDV |
| GET | `/appointments/:id` | Détail |
| POST | `/appointments/:id/cancel` | Annuler |
| POST | `/appointments/:id/review` | Laisser avis |

### Espace Pro
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/pro/profile` | Mon profil pro |
| PATCH | `/pro/profile` | Modifier profil |
| GET | `/pro/appointments` | Mes demandes |
| PATCH | `/pro/appointments/:id` | Confirmer/Refuser |
| POST | `/pro/appointments/:id/complete` | Marquer terminé |
| GET | `/pro/schedule` | Mon agenda |
| PATCH | `/pro/schedule` | Modifier dispo |
| GET | `/pro/stats` | Statistiques |
| POST | `/pro/reviews/:id/respond` | Répondre avis |

---

## 💰 Modèle Économique

### Commission sur réservations
| Type | Commission |
|------|------------|
| Réservation standard | 10% |
| Avec paiement en ligne | 12% (+frais paiement) |
| Premium provider | 5% |

### Abonnement Pro
| Plan | Prix/mois | Features |
|------|-----------|----------|
| Free | 0€ | 5 RDV/mois, profil basique |
| Pro | 29€ | Illimité, mise en avant |
| Premium | 79€ | + Paiement en ligne, analytics |

---

## 🎨 États de l'Interface

### Fiche prestataire
- **Verified**: Badge vérifié ✓
- **Premium**: Badge premium ⭐
- **Available**: "Prochain créneau: demain 10h"
- **Unavailable**: "Indisponible actuellement"

### Rendez-vous
- **Pending**: En attente de confirmation
- **Confirmed**: ✓ Confirmé
- **Completed**: ✓✓ Terminé
- **Cancelled**: ✗ Annulé

### Avis
- **Pending**: "En cours de modération"
- **Published**: Visible publiquement
- **Responded**: Avec réponse du pro

---

## 🔒 Permissions

| Action | Client | Provider | Admin |
|--------|--------|----------|-------|
| Voir annuaire | ✓ | ✓ | ✓ |
| Prendre RDV | ✓ | ✗ | ✓ |
| Gérer ses RDV | ✓ | ✗ | ✓ |
| Laisser avis | ✓ | ✗ | ✓ |
| Gérer son profil pro | ✗ | ✓ | ✓ |
| Confirmer RDV | ✗ | ✓ | ✓ |
| Répondre avis | ✗ | ✓ | ✓ |

---

## 🔗 Relations

| Module | Relation |
|--------|----------|
| **Users** | Provider est un User |
| **Horses** | RDV lié à un cheval |
| **Calendar** | RDV en événements |
| **Health** | Lien avec suivi santé |
| **Notifications** | Rappels RDV |
| **Payments** | Transactions |

---

## 📊 Métriques

- Nombre de prestataires par catégorie
- RDV pris par mois
- Taux de conversion recherche → RDV
- Note moyenne par catégorie
- Taux d'annulation
- Commission générée
- Temps de réponse moyen

