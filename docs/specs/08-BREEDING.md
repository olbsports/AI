# 🧬 MODULE BREEDING - Reproduction & Recommandations IA

## Description
Module de gestion de la reproduction équine avec recommandations d'accouplements par IA basées sur les pedigrees, performances et caractéristiques génétiques.

## Objectif Business
Aider les éleveurs à optimiser leurs choix de reproduction grâce à l'IA, générant des revenus via les recommandations premium et les réservations de saillies.

---

## 📱 Écrans/Pages

### 1. Dashboard Breeding (`/breeding`)
- Vue d'ensemble élevage
- Juments disponibles
- Étalons recommandés
- Gestations en cours (lien vers module Gestation)
- Statistiques de reproduction

### 2. Recommandations IA (`/breeding/recommendations`)
- Sélection jument
- Liste étalons recommandés avec scores
- Filtres: discipline, race, localisation
- Prédictions poulain
- Bouton "Réserver saillie"

### 3. Annuaire Étalons (`/breeding/stallions`)
- Catalogue étalons disponibles
- Fiches détaillées avec pedigree
- Tarifs de saillie
- Disponibilité
- Avis et statistiques

### 4. Mes Réservations (`/breeding/bookings`)
- Réservations en cours
- Historique
- Statuts et paiements

### 5. Détail Recommandation (`/breeding/match/:id`)
- Score de compatibilité global
- Détail des critères
- Pedigree croisé (visualisation arbre)
- Prédictions génétiques
- Simulations de poulain

---

## 🔄 Flux Utilisateur

### Obtenir une recommandation
```
1. Click "Recommandations IA"
2. Sélection de la jument
3. Filtres optionnels:
   - Discipline cible (CSO, Dressage, CCE)
   - Race souhaitée
   - Budget max saillie
   - Rayon géographique
4. Submit → POST /breeding/recommend
5. Analyse IA des pedigrees
6. Affichage top 10 étalons compatibles
7. Chaque étalon: score, prédictions, prix
```

### Consulter un match
```
1. Click sur un étalon recommandé
2. Page détail avec:
   - Score global: 85/100
   - Compatibilité génétique: 90%
   - Prédiction discipline: CSO 1.40m+
   - Consanguinité: 2.3% (OK)
   - Points forts: "Force, Équilibre"
   - Points attention: "Tempérament"
3. Pedigree croisé visuel
4. Bouton "Réserver saillie"
```

### Réserver une saillie
```
1. Click "Réserver saillie"
2. Choix type:
   - Monte naturelle
   - Insémination artificielle fraîche (IAF)
   - Insémination artificielle congelée (IAC)
   - Transfert d'embryon
3. Dates souhaitées
4. Contact étalonnage
5. Paiement acompte (si en ligne)
6. Confirmation réservation
7. Suivi via notifications
```

---

## 💾 Modèle de Données

```typescript
interface BreedingRecommendation {
  id: string;                    // UUID v4
  organizationId: string;        // FK Organization
  mareId: string;                // FK Horse (jument)
  createdById: string;           // FK User

  // Filtres appliqués
  filters: {
    targetDiscipline?: Discipline;
    preferredBreeds?: string[];
    maxStallionFee?: number;
    maxDistance?: number;        // km
    minHeight?: number;          // cm
    maxConsanguinity?: number;   // %
  };

  // Résultats
  recommendations: StallionMatch[];

  // Méta IA
  aiModel: string;
  processingTimeMs: number;
  tokensConsumed: number;

  createdAt: Date;
  expiresAt: Date;               // Validité 30 jours
}

interface StallionMatch {
  stallionId: string;            // FK Horse ou externe
  stallion: StallionProfile;

  // Scores
  overallScore: number;          // 0-100
  geneticCompatibility: number;  // 0-100
  disciplineScore: number;       // 0-100
  conformationScore: number;     // 0-100

  // Prédictions
  predictions: {
    expectedHeight: { min: number; max: number };
    disciplines: { name: string; score: number }[];
    traits: { name: string; probability: number }[];
    colors: { name: string; probability: number }[];
  };

  // Analyse
  consanguinityRate: number;     // %
  commonAncestors: string[];     // Noms des ancêtres communs
  strengths: string[];
  risks: string[];

  // Détail génétique
  geneticAnalysis: {
    linebreeding: string[];      // Lignées renforcées
    outcrossLines: string[];     // Lignées nouvelles
    heritabilityFactors: Record<string, number>;
  };
}

interface StallionProfile {
  id: string;
  externalId?: string;           // ID si étalon externe (SIRE, etc.)

  // Identité
  name: string;
  registrationNumber?: string;
  breed: string;
  color: string;
  yearOfBirth: number;

  // Physique
  heightCm: number;

  // Pedigree
  pedigree: {
    sire: PedigreeEntry;
    dam: PedigreeEntry;
  };

  // Performances
  performances: {
    discipline: string;
    level: string;              // "CSO 1.60m"
    achievements: string[];
  };

  // Reproduction
  reproductionStats: {
    totalOffspring: number;
    approvedOffspring: number;
    performingOffspring: number;
    fertilityRate?: number;
  };

  // Saillie
  stallionFee: number;
  currency: string;
  availableMethods: ('natural' | 'fresh_ai' | 'frozen_ai' | 'et')[];
  location: {
    stationName: string;
    city: string;
    country: string;
    coordinates?: { lat: number; lng: number };
  };

  // Contact
  contact: {
    name: string;
    email?: string;
    phone?: string;
  };

  // Disponibilité
  availability: 'available' | 'limited' | 'unavailable';
  bookingCalendar?: string[];    // Dates disponibles

  // Média
  photoUrls: string[];
  videoUrls: string[];

  // Rating
  averageRating?: number;
  reviewCount: number;
}

interface PedigreeEntry {
  name: string;
  registrationNumber?: string;
  breed?: string;
  sire?: PedigreeEntry;
  dam?: PedigreeEntry;
}

interface BreedingBooking {
  id: string;                    // UUID v4
  organizationId: string;
  mareId: string;                // FK Horse
  stallionId: string;            // FK ou externe
  recommendationId?: string;     // FK BreedingRecommendation

  // Type
  serviceType: 'natural' | 'fresh_ai' | 'frozen_ai' | 'et';

  // Dates
  requestedDates: Date[];
  confirmedDate?: Date;

  // Statut
  status: BookingStatus;

  // Paiement
  totalAmount: number;
  depositAmount: number;
  depositPaid: boolean;
  paymentStatus: 'pending' | 'partial' | 'paid' | 'refunded';

  // Notes
  notes?: string;
  stationNotes?: string;

  // Résultat
  result?: {
    inseminationDate?: Date;
    confirmationDate?: Date;
    isPregnant?: boolean;
    gestationId?: string;        // FK Gestation si succès
  };

  createdAt: Date;
  updatedAt: Date;
}

type BookingStatus =
  | 'pending'                    // En attente
  | 'confirmed'                  // Confirmé
  | 'in_progress'               // En cours
  | 'completed'                 // Terminé
  | 'cancelled';                // Annulé

type Discipline =
  | 'cso'
  | 'dressage'
  | 'cce'
  | 'endurance'
  | 'western'
  | 'breeding';
```

---

## 🔌 API Endpoints

### Recommandations
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/breeding/recommend` | Obtenir recommandations |
| GET | `/breeding/recommendations` | Historique recommandations |
| GET | `/breeding/recommendations/:id` | Détail recommandation |
| GET | `/breeding/match/:mareId/:stallionId` | Détail match |

### Étalons
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/breeding/stallions` | Annuaire étalons |
| GET | `/breeding/stallions/:id` | Fiche étalon |
| GET | `/breeding/stallions/:id/reviews` | Avis |
| POST | `/breeding/stallions/:id/reviews` | Ajouter avis |

### Réservations
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/breeding/bookings` | Mes réservations |
| POST | `/breeding/bookings` | Créer réservation |
| GET | `/breeding/bookings/:id` | Détail réservation |
| PATCH | `/breeding/bookings/:id` | Modifier |
| POST | `/breeding/bookings/:id/cancel` | Annuler |

---

## 🧠 Algorithme IA Recommandation

### Critères de scoring

| Critère | Poids | Description |
|---------|-------|-------------|
| Compatibilité génétique | 30% | Diversité lignées, consanguinité |
| Performances | 25% | Niveau étalon + produits |
| Conformation | 20% | Complémentarité morphologique |
| Discipline cible | 15% | Adéquation discipline souhaitée |
| Tempérament | 10% | Équilibre caractères |

### Calcul consanguinité
```
Coefficient = Σ (0.5)^(n1+n2+1) × (1 + Fa)

n1 = générations côté père
n2 = générations côté mère
Fa = coefficient consanguinité ancêtre commun
```

### Seuils d'alerte
- < 3%: Excellent (vert)
- 3-6%: Acceptable (jaune)
- 6-10%: Attention (orange)
- > 10%: Déconseillé (rouge)

---

## 💰 Tarification

| Action | Tokens |
|--------|--------|
| Recommandation simple (top 5) | 100 |
| Recommandation complète (top 10 + détail) | 200 |
| Analyse match détaillée | 50 |
| Simulation poulain | 75 |

---

## 🎨 États de l'Interface

### Recommandation
- **Selecting**: Sélection jument + filtres
- **Processing**: "Analyse génétique en cours..."
- **Results**: Liste étalons avec scores
- **Empty**: "Aucun étalon ne correspond aux critères"

### Réservation
- **Draft**: Formulaire en cours
- **Pending**: En attente confirmation station
- **Confirmed**: Date confirmée
- **In Progress**: Saillie en cours
- **Completed**: Terminé (lien gestation si succès)
- **Cancelled**: Annulé

---

## 🔒 Permissions

| Action | Owner | Admin | Analyst | Vet | Member | Viewer |
|--------|-------|-------|---------|-----|--------|--------|
| Voir annuaire | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Recommandations | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| Réserver saillie | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| Voir réservations | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ |
| Publier étalon | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |

---

## 🔗 Relations

| Module | Relation |
|--------|----------|
| **Horses** | N-1 (jument analysée) |
| **Gestation** | 1-1 (si saillie réussie) |
| **Marketplace** | Annonces étalons |
| **Tokens** | Consommation |
| **EquiCote** | Valorisation produits potentiels |

---

## 📊 Métriques

- Nombre de recommandations générées
- Taux de conversion recommandation → réservation
- Taux de réussite des saillies
- Score de satisfaction éleveurs
- Étalons les plus recommandés
- Précision des prédictions (suivi produits nés)

