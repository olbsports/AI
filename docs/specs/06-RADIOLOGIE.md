# 🩻 MODULE RADIOLOGIE - Analyse Radiographique IA

## Description
Analyse IA de clichés radiographiques équins pour aide au diagnostic. Détection automatique d'anomalies osseuses, articulaires et tissulaires avec scoring et recommandations.

## Objectif Business
Fournir une première analyse objective des radios pour aider les vétérinaires et propriétaires à détecter précocement les pathologies.

---

## ⚠️ Avertissement Médical

> **IMPORTANT**: Ce module est un outil d'aide à la décision. Il ne remplace en aucun cas l'avis d'un vétérinaire qualifié. Les résultats doivent toujours être validés par un professionnel de santé équine.

---

## 📱 Écrans/Pages

### 1. Liste des Analyses Radio (`/radiology`)
- Grille/Liste des analyses radiologiques
- Filtres: cheval, région anatomique, statut, date
- Vignettes des clichés
- Score de pathologie visible
- Bouton "+ Nouvelle analyse"

### 2. Upload & Configuration (`/radiology/new`)
- Zone d'upload multiple (drag & drop)
- Sélection cheval
- Sélection région anatomique
- Contexte clinique (texte)
- Estimation coût tokens
- Bouton "Analyser"

### 3. Résultats (`/radiology/:id`)
**Sections:**
- **Vue d'ensemble**: Score pathologie global
- **Clichés**: Viewer avec zoom, annotations IA
- **Détections**: Liste des anomalies détectées
- **Interprétation IA**: Texte explicatif
- **Recommandations**: Conseils vétérinaires
- **Comparaison**: Avec analyses précédentes

---

## 🦴 Régions Anatomiques Supportées

| Région | Code | Description |
|--------|------|-------------|
| Pied | `FOOT` | Phalange, naviculaire, sesamoïdes |
| Boulet | `FETLOCK` | Articulation métacarpo-phalangienne |
| Canon | `CANNON` | Métacarpe/Métatarse |
| Genou | `KNEE` | Carpe |
| Jarret | `HOCK` | Tarse |
| Grasset | `STIFLE` | Articulation fémoro-tibio-patellaire |
| Dos | `BACK` | Colonne vertébrale thoraco-lombaire |
| Encolure | `NECK` | Colonne cervicale |
| Tête | `HEAD` | Crâne, sinus, dents |

---

## 🔄 Flux Utilisateur

### Soumission d'une analyse
```
1. Click "+ Nouvelle analyse"
2. Upload clichés DICOM ou JPEG (1-10 images)
3. Sélection cheval concerné
4. Sélection région anatomique
5. Contexte: "Boiterie membre antérieur gauche depuis 2 semaines"
6. Affichage coût: 200 tokens
7. Vérification solde
8. Submit → POST /radiology
9. Statut "processing"
10. Notification quand terminé
```

### Consultation résultats
```
1. Accès /radiology/:id
2. Affichage score pathologie:
   - 0-3: Faible (vert)
   - 4-6: Modéré (orange)
   - 7-10: Élevé (rouge)
3. Viewer clichés avec:
   - Zones annotées (rectangles colorés)
   - Labels des anomalies
   - Zoom/Pan
4. Liste détections par sévérité
5. Interprétation textuelle IA
6. Recommandations (consultation véto, repos, etc.)
7. Bouton "Exporter PDF"
```

### Comparaison évolutive
```
1. Onglet "Comparaison"
2. Sélection analyse précédente
3. Affichage côte à côte
4. Différences mises en évidence
5. Progression/régression des pathologies
```

---

## 💾 Modèle de Données

```typescript
interface RadiologyAnalysis {
  id: string;                    // UUID v4
  organizationId: string;        // FK Organization
  horseId: string;               // FK Horse
  createdById: string;           // FK User

  // Configuration
  anatomicalRegion: AnatomicalRegion;
  clinicalContext?: string;      // Max 2000 caractères

  // Images
  images: RadioImage[];

  // Résultats IA
  status: AnalysisStatus;
  pathologyScore?: number;       // 0-10
  confidence?: number;           // 0-1

  detections: RadioDetection[];
  interpretation?: string;       // Texte IA
  recommendations: string[];

  // Métadonnées
  aiModel: string;               // Version du modèle
  processingTimeMs?: number;

  // Validation vétérinaire
  vetValidation?: {
    validatedBy: string;         // FK User (role=vet)
    validatedAt: Date;
    notes?: string;
    agrees: boolean;
  };

  // Rapport
  reportId?: string;             // FK Report si généré

  // Billing
  tokensConsumed: number;

  // Erreur
  errorMessage?: string;

  createdAt: Date;
  updatedAt: Date;
}

interface RadioImage {
  id: string;
  url: string;                   // URL S3
  thumbnailUrl: string;
  filename: string;
  mimeType: string;              // image/dicom, image/jpeg
  width: number;
  height: number;
  metadata?: {
    modality?: string;           // CR, DR, CT
    bodyPart?: string;
    laterality?: 'left' | 'right';
    view?: string;               // LAT, AP, OBL
    studyDate?: Date;
    institution?: string;
  };
  annotatedUrl?: string;         // URL avec annotations IA
}

interface RadioDetection {
  id: string;
  imageId: string;               // FK RadioImage

  // Localisation
  boundingBox: {
    x: number;                   // % de l'image
    y: number;
    width: number;
    height: number;
  };

  // Classification
  type: PathologyType;
  name: string;                  // "Ostéophyte marginal"
  description: string;

  // Sévérité
  severity: 'mild' | 'moderate' | 'severe';
  severityScore: number;         // 1-10

  // Confiance
  confidence: number;            // 0-1

  // Contexte
  anatomicalLocation: string;    // "Phalange distale, face dorsale"
  clinicalSignificance?: string;
}

type AnatomicalRegion =
  | 'foot'
  | 'fetlock'
  | 'cannon'
  | 'knee'
  | 'hock'
  | 'stifle'
  | 'back'
  | 'neck'
  | 'head';

type PathologyType =
  | 'osteophyte'                 // Ostéophyte
  | 'osteoarthritis'             // Arthrose
  | 'fracture'                   // Fracture
  | 'bone_cyst'                  // Kyste osseux
  | 'navicular_syndrome'         // Syndrome naviculaire
  | 'ocd'                        // OCD
  | 'sesamoiditis'              // Sesamoïdite
  | 'tendon_calcification'       // Calcification tendineuse
  | 'joint_effusion'             // Épanchement articulaire
  | 'bone_remodeling'            // Remodelage osseux
  | 'soft_tissue'                // Anomalie tissus mous
  | 'other';

type AnalysisStatus =
  | 'pending'
  | 'processing'
  | 'completed'
  | 'failed'
  | 'cancelled';
```

---

## 🔌 API Endpoints

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/radiology` | Liste paginée avec filtres |
| POST | `/radiology` | Créer analyse radio |
| GET | `/radiology/:id` | Détail analyse |
| DELETE | `/radiology/:id` | Supprimer |
| GET | `/radiology/:id/status` | Statut en temps réel |
| POST | `/radiology/:id/validate` | Validation vétérinaire |
| GET | `/radiology/:id/compare/:otherId` | Comparaison |
| POST | `/radiology/:id/report` | Générer rapport |

### Upload
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/radiology/upload` | Upload images |
| GET | `/radiology/upload/:uploadId` | Statut upload |

---

## 🎯 Précision & Limites

### Performances attendues
| Pathologie | Sensibilité | Spécificité |
|------------|-------------|-------------|
| Ostéophytes | 85% | 90% |
| Fractures évidentes | 95% | 95% |
| Arthrose avancée | 80% | 85% |
| OCD | 75% | 80% |
| Lésions subtiles | 60% | 70% |

### Limites connues
- Qualité dépendante de la qualité du cliché
- Angles non standards peuvent réduire la précision
- Lésions débutantes possiblement non détectées
- Ne remplace PAS l'expertise vétérinaire

---

## 🎨 États de l'Interface

### Upload
- **Idle**: Zone drag & drop avec formats acceptés
- **Uploading**: Barre progression par image
- **Processing**: "Analyse en cours..." avec estimation
- **Complete**: Redirection vers résultats
- **Error**: Message + bouton retry

### Viewer Radio
- **Loading**: Skeleton image
- **Ready**: Image + contrôles (zoom, brightness, contrast)
- **Annotated**: Zones détectées en surbrillance
- **Error**: "Impossible de charger l'image"

### Résultats
- **Pending**: "En attente d'analyse..."
- **Processing**: Barre progression + étapes
- **Complete**: Scores + détections + recommandations
- **Failed**: Message d'erreur

---

## 🔒 Permissions

| Action | Owner | Admin | Analyst | Vet | Member | Viewer |
|--------|-------|-------|---------|-----|--------|--------|
| Voir liste | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ |
| Créer analyse | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ |
| Voir résultats | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ |
| Valider (véto) | ✗ | ✗ | ✗ | ✓ | ✗ | ✗ |
| Supprimer | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| Générer rapport | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ |

---

## 🔗 Relations

| Module | Relation |
|--------|----------|
| **Horses** | N-1 (analyse liée à un cheval) |
| **Reports** | 1-1 (rapport généré) |
| **Health** | Lien avec historique santé |
| **Tokens** | Consommation tokens |
| **Notifications** | Alerte fin traitement |

---

## 📊 Métriques

- Nombre d'analyses par région anatomique
- Score pathologie moyen
- Taux de validation vétérinaire
- Temps moyen de traitement
- Corrélation IA/diagnostic final
- Types de pathologies les plus détectées

---

## 🛡️ Sécurité & Conformité

### Données médicales
- Chiffrement des images au repos (AES-256)
- Transmission HTTPS uniquement
- Accès audité (logs)
- RGPD: droit à l'effacement

### Disclaimer légal
Texte affiché avant chaque analyse:
> "Cette analyse IA est fournie à titre informatif uniquement. Elle ne constitue pas un diagnostic médical. Consultez toujours un vétérinaire qualifié pour toute décision médicale concernant votre cheval."

