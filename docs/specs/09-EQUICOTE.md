# 💎 MODULE EQUICOTE - Valorisation IA des Chevaux

## Description
Système d'estimation de valeur des chevaux basé sur l'IA analysant les performances, le pedigree, l'état de santé et les tendances du marché. Génère une "cote" officielle HorseTempo.

## Objectif Business
Fournir une référence objective de valorisation pour faciliter les transactions et renforcer la confiance sur le Marketplace.

---

## 📱 Écrans/Pages

### 1. Dashboard EquiCote (`/equicote`)
- Vue d'ensemble des chevaux valorisés
- Tendance du marché
- Dernières estimations
- Bouton "Nouvelle estimation"

### 2. Estimation (`/equicote/new`)
- Sélection du cheval
- Complétion données requises
- Options d'estimation
- Estimation coût tokens
- Bouton "Estimer"

### 3. Résultat (`/equicote/:id`)
- Valeur estimée (fourchette)
- Score de confiance
- Détail des critères
- Comparaison marché
- Historique estimations
- Bouton "Télécharger certificat"

### 4. Comparateur (`/equicote/compare`)
- Sélection plusieurs chevaux
- Tableau comparatif
- Graphiques

---

## 🔄 Flux Utilisateur

### Demander une estimation
```
1. Click "Nouvelle estimation"
2. Sélection du cheval
3. Vérification complétude profil:
   - ✓ Infos de base (race, âge, sexe)
   - ✓ Pedigree (minimum parents)
   - ⚠️ Historique santé (recommandé)
   - ⚠️ Analyses récentes (recommandé)
4. Options:
   - Type: Standard / Premium
   - Objectif: Vente / Assurance / Personnel
5. Affichage coût: 150 tokens
6. Submit → POST /equicote
7. Processing (30-60s)
8. Résultats affichés
```

### Consulter une estimation
```
1. Accès /equicote/:id
2. Affichage valeur:
   - Fourchette basse: 25,000€
   - Valeur estimée: 32,000€
   - Fourchette haute: 40,000€
3. Score confiance: 85%
4. Détail scoring par critère
5. Chevaux comparables vendus
6. Tendance prix (graphe 12 mois)
7. Bouton "Générer certificat PDF"
```

### Historique et tendance
```
1. Fiche cheval → Onglet "Valorisation"
2. Graphique évolution valeur
3. Liste estimations passées
4. Comparaison avec inflation marché
5. Alerte si valeur significativement changée
```

---

## 💾 Modèle de Données

```typescript
interface EquicoteValuation {
  id: string;                    // UUID v4
  organizationId: string;        // FK Organization
  horseId: string;               // FK Horse
  createdById: string;           // FK User

  // Type
  type: ValuationType;
  purpose: ValuationPurpose;

  // Résultat
  status: ValuationStatus;
  estimatedValue: number;        // Valeur centrale
  lowEstimate: number;           // Fourchette basse
  highEstimate: number;          // Fourchette haute
  currency: string;              // EUR, USD, etc.

  // Confiance
  confidenceScore: number;       // 0-100
  confidenceFactors: {
    dataCompleteness: number;    // 0-100
    marketData: number;          // 0-100
    comparables: number;         // 0-100
  };

  // Scoring détaillé
  scoring: {
    pedigree: { score: number; weight: number; details: string };
    performance: { score: number; weight: number; details: string };
    conformation: { score: number; weight: number; details: string };
    health: { score: number; weight: number; details: string };
    age: { score: number; weight: number; details: string };
    market: { score: number; weight: number; details: string };
  };

  // Comparables
  comparables: ComparableHorse[];

  // Marché
  marketAnalysis: {
    trend: 'rising' | 'stable' | 'declining';
    trendPercentage: number;
    averagePrice: number;
    medianPrice: number;
    priceRange: { min: number; max: number };
    sampleSize: number;
    period: string;              // "12 derniers mois"
  };

  // Certificat
  certificateUrl?: string;       // URL PDF si généré
  certificateNumber?: string;    // Numéro unique

  // Validité
  validUntil: Date;              // 90 jours

  // IA
  aiModel: string;
  aiExplanation?: string;

  // Billing
  tokensConsumed: number;

  createdAt: Date;
  updatedAt: Date;
}

interface ComparableHorse {
  name: string;
  breed: string;
  age: number;
  level: string;
  salePrice: number;
  saleDate: Date;
  source: string;                // "Marketplace HT", "FFE", etc.
  similarityScore: number;       // 0-100
}

type ValuationType =
  | 'standard'                   // Basique
  | 'premium'                    // Détaillé avec certificat
  | 'expert';                    // Avec validation humaine

type ValuationPurpose =
  | 'sale'                       // Pour vente
  | 'purchase'                   // Pour achat
  | 'insurance'                  // Pour assurance
  | 'personal'                   // Usage personnel
  | 'breeding';                  // Pour élevage

type ValuationStatus =
  | 'pending'
  | 'processing'
  | 'completed'
  | 'failed';
```

---

## 🔌 API Endpoints

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/equicote` | Liste mes estimations |
| POST | `/equicote` | Demander estimation |
| GET | `/equicote/:id` | Détail estimation |
| GET | `/equicote/:id/certificate` | Télécharger certificat |
| GET | `/equicote/horse/:horseId` | Estimations d'un cheval |
| GET | `/equicote/horse/:horseId/history` | Historique valeurs |
| GET | `/equicote/market` | Tendances marché |
| GET | `/equicote/compare` | Comparaison chevaux |

---

## 🧠 Algorithme de Valorisation

### Critères et poids

| Critère | Poids | Description |
|---------|-------|-------------|
| Pedigree | 25% | Qualité lignées, indices génétiques |
| Performance | 30% | Niveau compétition, résultats |
| Conformation | 15% | Morphologie, taille |
| Santé | 15% | Historique, absence pathologies |
| Âge | 10% | Courbe de valeur par âge |
| Marché | 5% | Tendance, demande |

### Courbe âge/valeur (CSO)
```
Valeur relative:
  3 ans: 60%    (potentiel)
  5 ans: 85%    (valorisation)
  7-9 ans: 100% (prime)
  10-12 ans: 80% (expérience)
  13-15 ans: 50% (déclin)
  16+ ans: 30%  (retraite)
```

### Sources de données marché
- Ventes Marketplace HorseTempo
- Résultats ventes aux enchères (Fences, Arqana)
- Données FFE (indices, classements)
- Prix observés sur plateformes concurrentes

---

## 📄 Certificat EquiCote

### Contenu du certificat PDF
```
┌─────────────────────────────────────────┐
│     CERTIFICAT DE VALORISATION          │
│           EQUICOTE™                     │
│                                         │
│  N° HT-EQ-2026-00456                   │
│  Date: 15/01/2026                       │
│  Validité: 15/04/2026                   │
├─────────────────────────────────────────┤
│                                         │
│  CHEVAL: Tornado du Bois                │
│  SIRE: 123456789012345                  │
│  Race: Selle Français                   │
│  Né le: 12/03/2014 (12 ans)            │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  VALEUR ESTIMÉE                         │
│                                         │
│     30,000 € - 35,000 €                │
│                                         │
│  Valeur médiane: 32,500€               │
│  Indice de confiance: 87%              │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  DÉTAIL SCORING                         │
│  Pedigree:     ████████░░ 8.2/10       │
│  Performance:  ███████░░░ 7.5/10       │
│  Conformation: ████████░░ 8.0/10       │
│  Santé:        █████████░ 9.0/10       │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  Ce certificat est généré par           │
│  HorseTempo IA et ne constitue pas     │
│  une expertise officielle.              │
│                                         │
│  Vérifiable sur: horsetempo.com/verify │
│  Code: EQ-XXXX-XXXX-XXXX               │
│                                         │
└─────────────────────────────────────────┘
```

---

## 💰 Tarification

| Type | Tokens | Inclus |
|------|--------|--------|
| Standard | 100 | Valeur + scoring basique |
| Premium | 200 | + Certificat + comparables détaillés |
| Expert | 500 | + Validation par expert humain |

---

## 🎨 États de l'Interface

### Estimation
- **Incomplete**: "Complétez le profil pour une estimation précise"
- **Ready**: Formulaire avec estimation tokens
- **Processing**: "Analyse du marché en cours..."
- **Complete**: Résultats avec confiance
- **Low Confidence**: "Données insuffisantes" (warning)

### Certificat
- **Not Generated**: Bouton "Générer certificat"
- **Generating**: "Création du certificat..."
- **Ready**: Bouton "Télécharger PDF"
- **Expired**: "Certificat expiré, générer nouveau"

---

## 🔒 Permissions

| Action | Owner | Admin | Analyst | Vet | Member | Viewer |
|--------|-------|-------|---------|-----|--------|--------|
| Voir estimations | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ |
| Demander estimation | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| Générer certificat | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| Voir tendances | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

---

## 🔗 Relations

| Module | Relation |
|--------|----------|
| **Horses** | N-1 (estimation liée à un cheval) |
| **Marketplace** | Affichage badge "Estimé X€" |
| **Reports** | Inclusion dans rapports vente |
| **Breeding** | Valorisation poulains potentiels |
| **Tokens** | Consommation |

---

## 📊 Métriques

- Nombre d'estimations par mois
- Score de confiance moyen
- Écart estimation vs prix vente réel
- Tendance du marché par segment
- Revenus générés par EquiCote

---

## 🛡️ Disclaimer

> **Avertissement**: Les estimations EquiCote sont fournies à titre indicatif et ne constituent pas une expertise officielle de la valeur marchande. Les prix réels de vente peuvent varier significativement en fonction des conditions du marché, de la négociation et de facteurs non pris en compte par notre algorithme. HorseTempo décline toute responsabilité quant aux décisions financières prises sur la base de ces estimations.

