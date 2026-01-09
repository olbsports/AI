# 🤰 MODULE GESTATION - Suivi de Gestation

## Description
Suivi complet des gestations équines: de la saillie au poulinage, avec alertes, milestones, monitoring santé et conseils adaptés à chaque étape.

## Objectif Business
Accompagner les éleveurs dans le suivi rigoureux des gestations pour maximiser le taux de réussite et la santé des poulains.

---

## 📱 Écrans/Pages

### 1. Liste Gestations (`/gestations`)
- Vue tableau/calendrier
- Filtres: statut, jument, terme prévu
- Indicateurs visuels (couleurs par trimestre)
- Alertes en cours
- Bouton "+ Nouvelle gestation"

### 2. Détail Gestation (`/gestations/:id`)
**Sections:**
- **Timeline**: Progression jour par jour
- **Milestones**: Étapes clés à venir
- **Santé**: Suivis vétérinaires
- **Photos**: Évolution ventre
- **Notes**: Observations quotidiennes

### 3. Création (`/gestations/new`)
- Sélection jument
- Sélection/Info étalon
- Date saillie
- Type (monte naturelle, IA)
- Notes

### 4. Dashboard Élevage (`/gestations/dashboard`)
- Gestations en cours par trimestre
- Poulinages prévus ce mois
- Alertes actives
- Statistiques reproduction

---

## 🔄 Flux Utilisateur

### Enregistrer une gestation
```
1. Click "+ Nouvelle gestation"
2. Sélection jument (doit être femelle)
3. Information étalon:
   - Étalon interne (sélection)
   - Étalon externe (nom + infos)
4. Date de saillie
5. Type de reproduction:
   - Monte naturelle
   - IAF (Insémination Artificielle Fraîche)
   - IAC (Insémination Artificielle Congelée)
   - Transfert embryon
6. Notes (optionnel)
7. Submit → POST /gestations
8. Calcul automatique terme prévu (J+340)
9. Création des milestones automatiques
10. Activation alertes
```

### Suivi quotidien
```
1. Accès fiche gestation
2. Vue timeline avec jour actuel
3. Milestones à venir en évidence
4. Ajout observation:
   - Date (défaut: aujourd'hui)
   - Type: comportement, alimentation, santé
   - Description
   - Photo optionnelle
5. Validation → historique mis à jour
```

### Enregistrer examen vétérinaire
```
1. Onglet "Santé" → "+ Examen"
2. Type: échographie, palpation, prise de sang
3. Date
4. Résultat: confirmé, douteux, négatif
5. Nombre de fœtus (si écho)
6. Notes vétérinaire
7. Documents joints
8. Submit → mise à jour statut si nécessaire
```

### Déclarer naissance
```
1. Bouton "Poulain né!"
2. Formulaire:
   - Date et heure naissance
   - Sexe poulain
   - Robe/couleur
   - Poids (optionnel)
   - Taille (optionnel)
   - Nom (optionnel, peut être ajouté plus tard)
   - Complications? oui/non
   - Notes
3. Photo poulain
4. Submit → POST /gestations/:id/birth
5. Création automatique fiche cheval (poulain)
6. Lien pedigree automatique (mère + père)
7. Gestation → statut "completed"
8. +300 XP bonus!
```

---

## 💾 Modèle de Données

```typescript
interface Gestation {
  id: string;                    // UUID v4
  organizationId: string;        // FK Organization
  mareId: string;                // FK Horse (jument)
  createdById: string;           // FK User

  // Père
  stallion: {
    type: 'internal' | 'external';
    horseId?: string;            // FK Horse si interne
    name?: string;               // Si externe
    breed?: string;
    registrationNumber?: string;
    owner?: string;
    stationName?: string;
  };

  // Reproduction
  breedingDate: Date;            // Date saillie
  breedingMethod: BreedingMethod;
  breedingNotes?: string;

  // Dates calculées
  estimatedDueDate: Date;        // J+340
  actualDueDate?: Date;          // Si modifié par véto

  // Statut
  status: GestationStatus;
  currentDay: number;            // Jour de gestation
  trimester: 1 | 2 | 3;

  // Examens
  examinations: GestationExam[];

  // Observations
  observations: GestationObservation[];

  // Photos évolution
  progressPhotos: {
    date: Date;
    url: string;
    dayOfGestation: number;
  }[];

  // Naissance
  birth?: {
    date: Date;
    time?: string;
    foalId: string;              // FK Horse (poulain créé)
    sex: 'male' | 'female';
    color?: string;
    weightKg?: number;
    heightCm?: number;
    complications: boolean;
    complicationNotes?: string;
    apgarScore?: number;         // 0-10
    notes?: string;
  };

  // Milestones
  milestones: Milestone[];

  // Échec
  lossInfo?: {
    date: Date;
    type: 'early_loss' | 'abortion' | 'stillbirth';
    reason?: string;
    vetNotes?: string;
  };

  createdAt: Date;
  updatedAt: Date;
}

interface GestationExam {
  id: string;
  date: Date;
  dayOfGestation: number;
  type: ExamType;
  result: 'confirmed' | 'doubtful' | 'negative';
  foetusCount?: number;
  foetusViable?: boolean;
  heartbeat?: boolean;
  vetName?: string;
  notes?: string;
  attachments: string[];         // URLs documents
}

interface GestationObservation {
  id: string;
  date: Date;
  dayOfGestation: number;
  category: 'behavior' | 'feeding' | 'health' | 'other';
  description: string;
  severity?: 'normal' | 'attention' | 'urgent';
  photoUrl?: string;
  createdById: string;
  createdAt: Date;
}

interface Milestone {
  id: string;
  day: number;                   // Jour de gestation
  title: string;
  description: string;
  category: MilestoneCategory;
  status: 'upcoming' | 'current' | 'completed' | 'skipped';
  dueDate: Date;
  completedAt?: Date;
  notes?: string;
}

type BreedingMethod =
  | 'natural'                    // Monte naturelle
  | 'fresh_ai'                   // IAF
  | 'frozen_ai'                  // IAC
  | 'embryo_transfer';           // Transfert embryon

type GestationStatus =
  | 'suspected'                  // En attente confirmation
  | 'confirmed'                  // Confirmée par écho
  | 'at_risk'                    // Surveillance accrue
  | 'near_term'                  // Proche du terme
  | 'overdue'                    // Dépassé terme
  | 'completed'                  // Poulain né
  | 'lost';                      // Perte

type ExamType =
  | 'ultrasound_14d'            // Écho J14
  | 'ultrasound_28d'            // Écho J28
  | 'ultrasound_45d'            // Écho J45
  | 'ultrasound_60d'            // Écho J60
  | 'ultrasound_other'          // Autre écho
  | 'rectal_palpation'          // Palpation rectale
  | 'blood_test'                // Prise de sang
  | 'other';

type MilestoneCategory =
  | 'exam'                       // Examen vétérinaire
  | 'nutrition'                  // Changement alimentation
  | 'exercise'                   // Adaptation exercice
  | 'preparation'               // Préparation poulinage
  | 'development';              // Développement fœtal
```

---

## 📅 Milestones Standard (340 jours)

| Jour | Catégorie | Milestone |
|------|-----------|-----------|
| 14-16 | exam | Première échographie (vésicule) |
| 25-30 | exam | Écho heartbeat |
| 42-45 | exam | Écho confirmation sexe possible |
| 60 | exam | Écho contrôle |
| 90 | nutrition | Ajustement ration (fin T1) |
| 120 | development | Fin organogenèse |
| 150 | exam | Contrôle mi-gestation |
| 180 | nutrition | Augmentation ration (T2) |
| 240 | nutrition | Ration gestation avancée |
| 270 | preparation | Préparation box poulinage |
| 300 | exam | Échographie pré-terme |
| 310 | preparation | Vaccination pré-poulinage |
| 320 | preparation | Test colostrum |
| 330 | preparation | Surveillance 24h |
| 340 | development | Terme prévu |

---

## 🔌 API Endpoints

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/gestations` | Liste paginée |
| POST | `/gestations` | Créer gestation |
| GET | `/gestations/:id` | Détail |
| PATCH | `/gestations/:id` | Modifier |
| DELETE | `/gestations/:id` | Supprimer |
| POST | `/gestations/:id/exam` | Ajouter examen |
| POST | `/gestations/:id/observation` | Ajouter observation |
| POST | `/gestations/:id/photo` | Ajouter photo évolution |
| POST | `/gestations/:id/birth` | Déclarer naissance |
| POST | `/gestations/:id/loss` | Déclarer perte |
| GET | `/gestations/:id/milestones` | Liste milestones |
| PATCH | `/gestations/:id/milestones/:mid` | Mettre à jour milestone |
| GET | `/gestations/dashboard` | Stats élevage |
| GET | `/gestations/calendar` | Vue calendrier |

---

## 🔔 Alertes Automatiques

| Déclencheur | Notification | Avance |
|-------------|--------------|--------|
| Milestone exam | "Échographie J14 prévue pour [jument]" | 3 jours |
| Milestone nutrition | "Ajuster la ration de [jument]" | 1 jour |
| Proche terme (J330) | "Préparer le box de poulinage" | Immédiat |
| Terme J340 | "Terme prévu aujourd'hui!" | Jour J |
| Dépassement J345 | "Terme dépassé, consulter véto" | Urgent |

---

## 🎨 États de l'Interface

### Timeline
- **Trimestre 1** (J1-110): Couleur bleue
- **Trimestre 2** (J111-220): Couleur verte
- **Trimestre 3** (J221-340): Couleur orange
- **Proche terme** (J330+): Couleur rouge

### Statut visuel
- 🟢 Confirmed: "Gestation confirmée"
- 🟡 Suspected: "En attente confirmation"
- 🟠 At Risk: "Surveillance accrue"
- 🔴 Near Term: "Proche du terme"
- ⚫ Lost: "Perte de gestation"
- ✅ Completed: "Poulain né!"

---

## 🔒 Permissions

| Action | Owner | Admin | Analyst | Vet | Member | Viewer |
|--------|-------|-------|---------|-----|--------|--------|
| Voir liste | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Créer | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ |
| Modifier | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ |
| Ajouter examen | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ |
| Déclarer naissance | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ |
| Supprimer | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |

---

## 🔗 Relations

| Module | Relation |
|--------|----------|
| **Horses** | N-1 (jument), N-1 (étalon), 1-1 (poulain) |
| **Breeding** | 1-1 (réservation si via Breeding) |
| **Calendar** | Milestones en événements |
| **Notifications** | Alertes automatiques |
| **Health** | Examens liés à la santé jument |

---

## 📊 Métriques

- Taux de confirmation (gestations confirmées / tentatives)
- Taux de réussite (naissances / gestations confirmées)
- Durée moyenne de gestation
- Taux de complications
- Répartition sexe poulains
- Performances par étalon

