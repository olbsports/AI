# 🐴 MODULE HORSES - Gestion des Chevaux

## Description
Gestion complète des profils chevaux: identité, caractéristiques physiques, santé, poids, nutrition, galerie photos, historique d'événements et analyses.

## Objectif Business
Centraliser toutes les informations d'un cheval pour un suivi complet et permettre des analyses IA basées sur des données riches.

---

## 📱 Écrans/Pages

### 1. Liste des Chevaux (`/horses`)
- Grille/Liste de cartes chevaux
- Barre de recherche
- Filtres: statut, race, sexe
- Tri: nom, date création, dernière activité
- Pagination
- Bouton "+ Nouveau cheval"

### 2. Détail Cheval (`/horses/:id`)
**Onglets:**
- **Overview**: Infos générales, photo, caractéristiques
- **Santé**: Historique médical, vaccinations, traitements
- **Poids**: Courbe de poids, historique pesées
- **Nutrition**: Plans alimentaires actifs
- **Événements**: Compétitions, entraînements planifiés
- **Analyses**: Analyses IA liées au cheval
- **Galerie**: Photos et vidéos

### 3. Création/Édition (`/horses/new` ou modal)
- Formulaire complet en étapes ou single page
- Upload photo de profil
- Validation en temps réel

---

## 🎛️ Actions/Boutons

| Bouton | Position | Action | Condition |
|--------|----------|--------|-----------|
| + Nouveau cheval | Header liste | Ouvre formulaire création | Toujours |
| Modifier | Header détail | Ouvre formulaire édition | Owner/Admin/Analyst |
| Supprimer | Menu ⋮ | Confirmation + soft delete | Owner/Admin |
| Archiver | Menu ⋮ | Change statut → archived | Owner/Admin |
| + Photo | Galerie | Upload image | Owner/Admin/Analyst |
| + Suivi santé | Onglet Santé | Ouvre formulaire | Owner/Admin/Analyst |
| + Pesée | Onglet Poids | Ouvre formulaire | Owner/Admin/Analyst |
| + Plan nutrition | Onglet Nutrition | Ouvre formulaire | Owner/Admin/Analyst |
| Nouvelle analyse | Onglet Analyses | Redirige vers /analyses/new | Analyst+ |

---

## 🔄 Flux Utilisateur

### Création d'un cheval
```
1. Click "+ Nouveau cheval"
2. Formulaire: nom (obligatoire)
3. Optionnel: race, couleur, sexe, date naissance
4. Upload photo profil (optionnel)
5. Submit → POST /horses
6. Redirection vers fiche détail
7. Toast "Cheval créé avec succès"
```

### Ajout d'un suivi santé
```
1. Onglet "Santé" → Click "+ Ajouter"
2. Sélection type: vaccination, checkup, blessure, traitement, autre
3. Date du soin
4. Titre/Description
5. Nom vétérinaire (optionnel)
6. Coût (optionnel)
7. Date prochain RDV (optionnel)
8. Pièces jointes (optionnel)
9. Submit → POST /horses/:id/health
10. Refresh liste santé
```

### Ajout d'une pesée
```
1. Onglet "Poids" → Click "+ Ajouter"
2. Date de pesée
3. Poids en kg
4. Notes (optionnel)
5. Submit → POST /horses/:id/weight
6. Mise à jour graphique
```

---

## 💾 Modèle de Données

```typescript
interface Horse {
  id: string;                    // UUID v4
  organizationId: string;        // FK Organization
  name: string;                  // 2-255 caractères
  registrationNumber?: string;   // Numéro SIRE/FFE
  microchipNumber?: string;      // 15 chiffres exactement
  ueln?: string;                 // Universal Equine Life Number
  passportNumber?: string;
  dateOfBirth?: Date;
  gender: 'male' | 'female' | 'gelding';
  breed?: HorseBreed;            // Enum des races
  color: HorseColor;             // Enum des couleurs
  heightCm?: number;             // 100-200 cm
  weightKg?: number;             // 200-1000 kg
  pedigree?: {
    sire?: string;               // Père
    dam?: string;                // Mère
    sireSire?: string;           // Grand-père paternel
    sireDam?: string;            // Grand-mère paternelle
    damSire?: string;            // Grand-père maternel
    damDam?: string;             // Grand-mère maternelle
  };
  ownerName?: string;
  ownerContact?: {
    email?: string;
    phone?: string;
  };
  currentRiderId?: string;       // FK Rider
  profileImageUrl?: string;      // URL S3
  galleryUrls: string[];         // URLs S3
  status: 'active' | 'retired' | 'sold' | 'deceased';
  tags: string[];                // Max 10 tags
  notes?: string;                // Max 5000 caractères
  createdAt: Date;
  updatedAt: Date;
}

interface HorseHealthRecord {
  id: string;
  horseId: string;               // FK Horse
  organizationId: string;
  type: 'vaccination' | 'checkup' | 'injury' | 'treatment' | 'deworming' | 'dental' | 'other';
  date: Date;
  title: string;
  description?: string;
  vetName?: string;
  vetContact?: string;
  cost?: number;
  currency?: string;             // Défaut: EUR
  nextDueDate?: Date;
  attachments: string[];         // URLs S3
  createdAt: Date;
  updatedAt: Date;
}

interface WeightRecord {
  id: string;
  horseId: string;
  date: Date;
  weight: number;                // En kg
  notes?: string;
  createdAt: Date;
}

interface BodyConditionScore {
  id: string;
  horseId: string;
  date: Date;
  score: number;                 // 1-9 (échelle Henneke)
  notes?: string;
  photoUrl?: string;
  createdAt: Date;
}

interface NutritionPlan {
  id: string;
  horseId: string;
  name: string;
  startDate: Date;
  endDate?: Date;
  isActive: boolean;
  dailyRation: {
    hay?: { amount: number; unit: string };
    grain?: { amount: number; unit: string; type: string };
    supplements?: { name: string; amount: number; unit: string }[];
  };
  feedingSchedule?: string[];
  notes?: string;
  createdAt: Date;
}
```

### Enums

```typescript
enum HorseBreed {
  SELLE_FRANCAIS = 'Selle Français',
  KWPN = 'KWPN',
  BWP = 'BWP',
  HANOVRIEN = 'Hanovrien',
  HOLSTEINER = 'Holsteiner',
  OLDENBURG = 'Oldenburg',
  ANGLO_ARABE = 'Anglo-Arabe',
  PUR_SANG = 'Pur-Sang',
  TROTTEUR = 'Trotteur Français',
  ARABE = 'Arabe',
  LUSITANIEN = 'Lusitanien',
  PRE = 'PRE',
  IRISH_SPORT = 'Irish Sport Horse',
  WESTPHALIEN = 'Westphalien',
  AUTRE = 'Autre'
}

enum HorseColor {
  BAI = 'Bai',
  BAI_BRUN = 'Bai Brun',
  ALEZAN = 'Alezan',
  GRIS = 'Gris',
  NOIR = 'Noir',
  ISABELLE = 'Isabelle',
  PALOMINO = 'Palomino',
  PIE = 'Pie',
  ROUAN = 'Rouan',
  APPALOOSA = 'Appaloosa',
  CREMELLO = 'Cremello',
  AUTRE = 'Autre'
}
```

---

## 🔌 API Endpoints

### CRUD Chevaux
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/horses` | Liste paginée avec filtres |
| POST | `/horses` | Créer un cheval |
| GET | `/horses/:id` | Détail d'un cheval |
| PATCH | `/horses/:id` | Modifier un cheval |
| DELETE | `/horses/:id` | Supprimer (soft delete) |
| POST | `/horses/:id/archive` | Archiver |
| POST | `/horses/:id/photo` | Upload photo profil |
| DELETE | `/horses/:id/photo` | Supprimer photo |

### Santé
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/horses/:id/health` | Historique santé |
| GET | `/horses/:id/health/summary` | Résumé (prochains RDV) |
| POST | `/horses/:id/health` | Ajouter suivi |
| PUT | `/horses/:id/health/:recordId` | Modifier suivi |
| DELETE | `/horses/:id/health/:recordId` | Supprimer suivi |

### Poids & Condition
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/horses/:id/weight` | Historique poids |
| POST | `/horses/:id/weight` | Ajouter pesée |
| GET | `/horses/:id/body-condition` | Historique BCS |
| POST | `/horses/:id/body-condition` | Ajouter BCS |

### Nutrition
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/horses/:id/nutrition` | Plans nutrition |
| GET | `/horses/:id/nutrition/active` | Plan actif |
| POST | `/horses/:id/nutrition` | Créer plan |
| PUT | `/horses/:id/nutrition/:planId` | Modifier plan |
| DELETE | `/horses/:id/nutrition/:planId` | Supprimer plan |

### Relations
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/horses/:id/gestations` | Gestations liées |
| GET | `/horses/:id/events` | Événements calendrier |
| GET | `/horses/:id/analyses` | Analyses IA |

---

## ✅ Validations

| Champ | Règles |
|-------|--------|
| `name` | 2-255 caractères, obligatoire |
| `microchipNumber` | Exactement 15 chiffres |
| `heightCm` | 100-200 cm |
| `weightKg` | 200-1000 kg |
| `dateOfBirth` | Pas dans le futur |
| `tags` | Maximum 10 tags |
| `notes` | Maximum 5000 caractères |
| `galleryUrls` | Maximum 50 photos |

---

## 🎨 États de l'Interface

### Liste
- **Loading**: Skeleton cards
- **Empty**: "Aucun cheval. Ajoutez votre premier cheval!"
- **Error**: Message d'erreur + bouton réessayer
- **Filtered Empty**: "Aucun résultat pour ces filtres"

### Détail
- **Loading**: Skeleton layout
- **Not Found**: "Ce cheval n'existe pas"
- **Error**: Message d'erreur

### Formulaire
- **Submitting**: Bouton désactivé + spinner
- **Validation Error**: Bordures rouges + messages
- **Success**: Toast + redirection

---

## 🔗 Relations avec autres modules

| Module | Relation |
|--------|----------|
| **Riders** | N-1 (cheval assigné à un cavalier) |
| **Analyses** | 1-N (analyses liées au cheval) |
| **Reports** | 1-N (rapports générés) |
| **Calendar** | 1-N (événements planifiés) |
| **Gestation** | 1-N (gestations pour juments) |
| **Marketplace** | 1-1 (annonce de vente) |
| **EquiCote** | 1-N (valuations) |
| **Breeding** | N-N (réservations) |

---

## 🔒 Permissions

| Action | Owner | Admin | Analyst | Vet | Member | Viewer |
|--------|-------|-------|---------|-----|--------|--------|
| Voir liste | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Voir détail | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Créer | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| Modifier | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| Supprimer | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| Ajouter santé | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ |
| Modifier santé | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ |

---

## 📊 Métriques

- Nombre de chevaux par organisation
- Chevaux actifs vs archivés
- Taux de complétion des profils
- Fréquence des suivis santé
- Évolution moyenne du poids
