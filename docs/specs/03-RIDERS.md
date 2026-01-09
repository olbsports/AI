# 🏇 MODULE RIDERS - Gestion des Cavaliers

## Description
Gestion des profils cavaliers: identité, niveau, certifications, statistiques de performance et association avec les chevaux.

## Objectif Business
Permettre le suivi des cavaliers pour les analyses de couple cavalier/cheval et les classements de performance.

---

## 📱 Écrans/Pages

### 1. Liste des Cavaliers (`/riders`)
- Grille/Liste de cartes cavaliers
- Barre de recherche par nom
- Filtres: niveau, discipline, statut
- Tri: nom, performances, activité récente
- Pagination
- Bouton "+ Nouveau cavalier"

### 2. Détail Cavalier (`/riders/:id`)
**Onglets:**
- **Overview**: Photo, infos générales, niveau
- **Chevaux**: Liste des chevaux montés
- **Performances**: Statistiques et scores
- **Analyses**: Analyses vidéo liées
- **Certifications**: Galops, diplômes

### 3. Création/Édition (`/riders/new` ou modal)
- Formulaire complet
- Upload photo de profil
- Association avec chevaux existants

---

## 🎛️ Actions/Boutons

| Bouton | Position | Action | Condition |
|--------|----------|--------|-----------|
| + Nouveau cavalier | Header liste | Ouvre formulaire création | Toujours |
| Modifier | Header détail | Ouvre formulaire édition | Owner/Admin |
| Supprimer | Menu ⋮ | Confirmation + soft delete | Owner/Admin |
| Archiver | Menu ⋮ | Change statut → archived | Owner/Admin |
| + Photo | Profil | Upload image | Owner/Admin |
| Assigner cheval | Onglet Chevaux | Modal sélection | Owner/Admin |
| + Certification | Onglet Certifications | Formulaire | Owner/Admin |

---

## 🔄 Flux Utilisateur

### Création d'un cavalier
```
1. Click "+ Nouveau cavalier"
2. Formulaire: prénom, nom (obligatoires)
3. Optionnel: niveau, discipline, date naissance
4. Upload photo profil (optionnel)
5. Submit → POST /riders
6. Redirection vers fiche détail
7. Toast "Cavalier créé avec succès"
```

### Association cheval-cavalier
```
1. Onglet "Chevaux" → Click "Assigner"
2. Modal avec liste chevaux disponibles
3. Sélection du cheval
4. Définir rôle (principal, secondaire)
5. Submit → POST /riders/:id/horses
6. Refresh liste chevaux associés
```

### Ajout certification
```
1. Onglet "Certifications" → Click "+ Ajouter"
2. Type: Galop, BPJEPS, DEJEPS, autre
3. Niveau (ex: Galop 7)
4. Date obtention
5. Organisme délivrant
6. Upload document (optionnel)
7. Submit → POST /riders/:id/certifications
```

---

## 💾 Modèle de Données

```typescript
interface Rider {
  id: string;                    // UUID v4
  organizationId: string;        // FK Organization
  userId?: string;               // FK User (si compte associé)

  // Identité
  firstName: string;             // 1-100 caractères
  lastName: string;              // 1-100 caractères
  dateOfBirth?: Date;
  gender?: 'male' | 'female' | 'other';
  profileImageUrl?: string;      // URL S3

  // Équitation
  level: RiderLevel;
  discipline: RiderDiscipline;
  yearsExperience?: number;
  licenseNumber?: string;        // Numéro licence FFE
  club?: string;                 // Club d'appartenance

  // Contact
  email?: string;
  phone?: string;
  address?: {
    street?: string;
    city?: string;
    postalCode?: string;
    country?: string;
  };

  // Stats
  totalAnalyses: number;         // Compteur
  averageScore?: number;         // Score moyen sur analyses

  // Méta
  status: 'active' | 'inactive' | 'archived';
  notes?: string;                // Max 2000 caractères

  createdAt: Date;
  updatedAt: Date;
}

interface RiderHorseAssignment {
  id: string;
  riderId: string;               // FK Rider
  horseId: string;               // FK Horse
  role: 'primary' | 'secondary' | 'occasional';
  startDate: Date;
  endDate?: Date;
  isActive: boolean;
  createdAt: Date;
}

interface RiderCertification {
  id: string;
  riderId: string;               // FK Rider
  type: CertificationType;
  name: string;                  // Ex: "Galop 7"
  level?: number;
  obtainedAt: Date;
  expiresAt?: Date;
  issuingOrganization: string;
  documentUrl?: string;          // URL S3
  verified: boolean;
  createdAt: Date;
}

enum RiderLevel {
  BEGINNER = 'beginner',         // Galop 1-3
  INTERMEDIATE = 'intermediate', // Galop 4-5
  ADVANCED = 'advanced',         // Galop 6-7
  COMPETITION = 'competition',   // Amateur
  PROFESSIONAL = 'professional'  // Pro
}

enum RiderDiscipline {
  CSO = 'cso',                   // Saut d'obstacles
  DRESSAGE = 'dressage',
  CCE = 'cce',                   // Complet
  ENDURANCE = 'endurance',
  WESTERN = 'western',
  LOISIR = 'leisure',
  POLYVALENT = 'versatile'
}

enum CertificationType {
  GALOP = 'galop',               // FFE Galops
  BPJEPS = 'bpjeps',            // Diplôme moniteur
  DEJEPS = 'dejeps',            // Diplôme perfectionnement
  DESJEPS = 'desjeps',          // Diplôme supérieur
  LICENSE = 'license',           // Licence FFE
  OTHER = 'other'
}
```

---

## 🔌 API Endpoints

### CRUD Cavaliers
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/riders` | Liste paginée avec filtres |
| POST | `/riders` | Créer un cavalier |
| GET | `/riders/:id` | Détail d'un cavalier |
| PATCH | `/riders/:id` | Modifier un cavalier |
| DELETE | `/riders/:id` | Supprimer (soft delete) |
| POST | `/riders/:id/archive` | Archiver |
| POST | `/riders/:id/photo` | Upload photo profil |

### Relations Chevaux
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/riders/:id/horses` | Chevaux assignés |
| POST | `/riders/:id/horses` | Assigner un cheval |
| DELETE | `/riders/:id/horses/:horseId` | Retirer assignation |

### Certifications
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/riders/:id/certifications` | Liste certifications |
| POST | `/riders/:id/certifications` | Ajouter certification |
| PUT | `/riders/:id/certifications/:certId` | Modifier |
| DELETE | `/riders/:id/certifications/:certId` | Supprimer |

### Statistiques
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/riders/:id/stats` | Statistiques complètes |
| GET | `/riders/:id/analyses` | Analyses liées |
| GET | `/riders/:id/progression` | Courbe progression |

---

## ✅ Validations

| Champ | Règles |
|-------|--------|
| `firstName` | 1-100 caractères, obligatoire |
| `lastName` | 1-100 caractères, obligatoire |
| `email` | Format email valide |
| `phone` | Format téléphone international |
| `yearsExperience` | 0-100 |
| `licenseNumber` | Format FFE si fourni |
| `notes` | Maximum 2000 caractères |

---

## 🎨 États de l'Interface

### Liste
- **Loading**: Skeleton cards
- **Empty**: "Aucun cavalier. Ajoutez votre premier cavalier!"
- **Error**: Message d'erreur + bouton réessayer
- **Filtered Empty**: "Aucun résultat pour ces filtres"

### Détail
- **Loading**: Skeleton layout
- **Not Found**: "Ce cavalier n'existe pas"
- **Error**: Message d'erreur

### Formulaire
- **Submitting**: Bouton désactivé + spinner
- **Validation Error**: Bordures rouges + messages
- **Success**: Toast + redirection

---

## 🔒 Permissions

| Action | Owner | Admin | Analyst | Vet | Member | Viewer |
|--------|-------|-------|---------|-----|--------|--------|
| Voir liste | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Voir détail | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Créer | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| Modifier | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| Supprimer | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| Voir stats | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ |

---

## 🔗 Relations avec autres modules

| Module | Relation |
|--------|----------|
| **Horses** | N-N (via RiderHorseAssignment) |
| **Analyses** | 1-N (analyses liées) |
| **Calendar** | 1-N (événements) |
| **Leaderboard** | 1-N (classements) |
| **Users** | 1-1 optionnel (compte utilisateur) |

---

## 📊 Métriques

- Nombre de cavaliers par organisation
- Cavaliers actifs vs inactifs
- Distribution par niveau
- Distribution par discipline
- Score moyen par cavalier
- Progression dans le temps

