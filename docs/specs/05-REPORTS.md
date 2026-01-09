# 📄 MODULE REPORTS - Génération de Rapports

## Description
Génération de rapports PDF professionnels à partir des analyses, des données chevaux et des statistiques. Exports personnalisables pour vétérinaires, acheteurs ou usage personnel.

## Objectif Business
Fournir des documents professionnels valorisant le travail d'analyse IA, utilisables pour la vente, le suivi vétérinaire ou la communication.

---

## 📱 Écrans/Pages

### 1. Liste des Rapports (`/reports`)
- Grille/Liste des rapports générés
- Filtres: type, cheval, date, statut
- Tri: date création, type
- Téléchargement direct
- Bouton "+ Nouveau rapport"

### 2. Générateur de Rapport (`/reports/new`)
- Sélection type de rapport
- Configuration des sections
- Prévisualisation
- Personnalisation branding
- Bouton "Générer"

### 3. Visualisation (`/reports/:id`)
- Viewer PDF intégré
- Boutons: Télécharger, Partager, Supprimer
- Métadonnées du rapport

---

## 📋 Types de Rapports

| Type | Code | Tokens | Contenu |
|------|------|--------|---------|
| Fiche Cheval | `HORSE_PROFILE` | 25 | Profil complet du cheval |
| Rapport Analyse | `ANALYSIS_REPORT` | 50 | Résultats analyse détaillés |
| Rapport Santé | `HEALTH_REPORT` | 30 | Historique médical |
| Rapport Progression | `PROGRESSION_REPORT` | 75 | Évolution sur période |
| Rapport Vente | `SALE_REPORT` | 100 | Dossier complet pour vente |
| Rapport Élevage | `BREEDING_REPORT` | 75 | Pedigree + recommandations |
| Rapport Vétérinaire | `VET_EXPORT` | 40 | Export pour vétérinaire |

---

## 🔄 Flux Utilisateur

### Génération depuis une analyse
```
1. Page analyse → Click "Générer rapport"
2. Type pré-sélectionné: ANALYSIS_REPORT
3. Options de personnalisation:
   - Inclure vidéo annotée: oui/non
   - Inclure recommandations: oui/non
   - Langue: FR/EN
4. Prévisualisation (aperçu)
5. Vérification solde tokens
6. Submit → POST /reports
7. Status "generating"
8. Notification quand prêt
9. Téléchargement automatique
```

### Génération rapport vente
```
1. Fiche cheval → "Générer rapport vente"
2. Sections à inclure:
   - [x] Profil complet
   - [x] Pedigree
   - [x] Historique santé
   - [x] Dernières analyses (max 5)
   - [x] EquiCote valorisation
   - [ ] Performances compétition
3. Personnalisation:
   - Logo personnel
   - Coordonnées vendeur
   - Message personnalisé
4. Submit → génération PDF
5. Partage via lien sécurisé
```

### Partage rapport
```
1. Page rapport → "Partager"
2. Options:
   - Lien public (expire dans X jours)
   - Envoi par email
   - Protection par mot de passe
3. Génération lien unique
4. Tracking des consultations
5. Révocation possible
```

---

## 💾 Modèle de Données

```typescript
interface Report {
  id: string;                    // UUID v4
  organizationId: string;        // FK Organization
  createdById: string;           // FK User

  // Type & Source
  type: ReportType;
  sourceType: 'horse' | 'analysis' | 'rider' | 'breeding';
  sourceId: string;              // ID de l'entité source

  // Métadonnées
  title: string;                 // Max 255
  description?: string;
  language: 'fr' | 'en' | 'es' | 'de';

  // Configuration
  config: ReportConfig;

  // Fichier
  fileUrl?: string;              // URL S3 du PDF
  fileSize?: number;             // En bytes
  pageCount?: number;
  thumbnailUrl?: string;         // Aperçu première page

  // Statut
  status: ReportStatus;
  generatedAt?: Date;
  expiresAt?: Date;              // Pour liens temporaires

  // Partage
  shareSettings?: {
    isPublic: boolean;
    publicUrl?: string;
    password?: string;           // Hash si protégé
    expiresAt?: Date;
    allowDownload: boolean;
    viewCount: number;
  };

  // Billing
  tokensConsumed: number;

  // Erreur
  errorMessage?: string;

  createdAt: Date;
  updatedAt: Date;
}

type ReportType =
  | 'horse_profile'
  | 'analysis_report'
  | 'health_report'
  | 'progression_report'
  | 'sale_report'
  | 'breeding_report'
  | 'vet_export';

type ReportStatus =
  | 'pending'
  | 'generating'
  | 'completed'
  | 'failed';

interface ReportConfig {
  // Sections à inclure
  sections: {
    profile?: boolean;
    pedigree?: boolean;
    health?: boolean;
    analyses?: boolean;
    photos?: boolean;
    recommendations?: boolean;
    equicote?: boolean;
    performances?: boolean;
  };

  // Branding
  branding?: {
    logoUrl?: string;
    primaryColor?: string;       // Hex color
    companyName?: string;
    contactInfo?: string;
  };

  // Limites
  maxAnalyses?: number;          // Nombre d'analyses à inclure
  dateRange?: {
    from: Date;
    to: Date;
  };

  // Message personnalisé
  customMessage?: string;
}

interface ReportTemplate {
  id: string;
  organizationId: string;
  name: string;
  type: ReportType;
  config: ReportConfig;
  isDefault: boolean;
  createdAt: Date;
}
```

---

## 🔌 API Endpoints

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/reports` | Liste paginée avec filtres |
| POST | `/reports` | Créer/Générer un rapport |
| GET | `/reports/:id` | Détail d'un rapport |
| DELETE | `/reports/:id` | Supprimer |
| GET | `/reports/:id/download` | URL signée téléchargement |
| POST | `/reports/:id/share` | Configurer partage |
| DELETE | `/reports/:id/share` | Révoquer partage |
| GET | `/reports/:id/status` | Statut génération |
| GET | `/reports/public/:token` | Accès rapport public |

### Templates
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/reports/templates` | Liste templates |
| POST | `/reports/templates` | Créer template |
| PUT | `/reports/templates/:id` | Modifier template |
| DELETE | `/reports/templates/:id` | Supprimer template |

---

## 📄 Structure PDF

### Rapport Analyse Type
```
┌─────────────────────────────────────┐
│ [Logo] HORSETEMPO ANALYSIS REPORT   │
│ Date: 15/01/2026                    │
├─────────────────────────────────────┤
│ CHEVAL: Tornado                     │
│ Race: Selle Français | Âge: 12 ans  │
│ Cavalier: Jean Dupont               │
├─────────────────────────────────────┤
│ SCORE GLOBAL                        │
│ ████████░░ 7.8/10                   │
├─────────────────────────────────────┤
│ SCORES DÉTAILLÉS                    │
│ Cheval:    ████████░░ 8.2           │
│ Cavalier:  ███████░░░ 7.5           │
│ Harmonie:  ████████░░ 7.9           │
│ Technique: ███████░░░ 7.6           │
├─────────────────────────────────────┤
│ OBSTACLES                           │
│ 1. Vertical d'entrée       8.5     │
│ 2. Oxer Longines           7.2     │
│ ...                                 │
├─────────────────────────────────────┤
│ PROBLÈMES IDENTIFIÉS                │
│ ⚠️ Abords irréguliers (obstacles 5,8)│
│ ℹ️ Perte d'impulsion (obstacle 5)   │
├─────────────────────────────────────┤
│ RECOMMANDATIONS                     │
│ • Améliorer régularité du galop    │
│ • Travailler impulsion combinaisons│
├─────────────────────────────────────┤
│ Généré par HorseTempo IA           │
│ www.horsetempo.com                  │
└─────────────────────────────────────┘
```

### Rapport Vente Type
```
Page 1: Couverture avec photo cheval
Page 2: Profil complet + caractéristiques
Page 3: Pedigree sur 3 générations
Page 4: Historique santé résumé
Page 5-6: Meilleures analyses
Page 7: Valorisation EquiCote
Page 8: Informations vendeur
```

---

## 🎨 États de l'Interface

### Génération
- **Pending**: "En attente de traitement..."
- **Generating**: Barre de progression
- **Completed**: "Rapport prêt!" + téléchargement
- **Failed**: Message d'erreur + bouton retry

### Prévisualisation
- **Loading**: Skeleton PDF
- **Ready**: Viewer interactif
- **Error**: "Impossible de charger l'aperçu"

---

## 🔒 Permissions

| Action | Owner | Admin | Analyst | Vet | Member | Viewer |
|--------|-------|-------|---------|-----|--------|--------|
| Voir liste | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ |
| Générer | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ |
| Télécharger | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ |
| Partager | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| Supprimer | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| Templates | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |

---

## 🔗 Relations

| Module | Relation |
|--------|----------|
| **Analyses** | N-1 (rapport basé sur analyse) |
| **Horses** | N-1 (rapport lié à un cheval) |
| **Tokens** | Consommation de tokens |
| **Marketplace** | Attaché aux annonces |

---

## 📊 Métriques

- Nombre de rapports générés par type
- Temps moyen de génération
- Taux de partage
- Nombre de vues rapports publics
- Tokens consommés pour rapports

