# 📊 MODULE ANALYSES - Analyses Vidéo IA

## Description
Analyse IA complète de vidéos de parcours CSO, locomotion et performance équestre. Le système analyse frame par frame, détecte les obstacles, évalue la technique et génère des scores détaillés avec recommandations.

## Objectif Business
Fournir un feedback professionnel et objectif sur la performance du couple cavalier/cheval via intelligence artificielle, identifiant les points d'amélioration et trackant la progression.

---

## 📱 Écrans/Pages

### 1. Liste des Analyses (`/analyses`)
- Grille/Liste des analyses passées
- Filtres: type, statut, cheval, cavalier, date
- Indicateurs visuels de statut
- Score global en aperçu
- Bouton "+ Nouvelle analyse"

### 2. Nouvelle Analyse (`/analyses/new`)
- Sélection du type d'analyse
- Upload vidéo (drag & drop)
- Formulaire métadonnées
- Estimation tokens nécessaires
- Bouton soumettre

### 3. Processing (`/analyses/:id` en cours)
- Barre de progression
- Étapes du traitement
- Estimation temps restant
- Possibilité d'annuler

### 4. Résultats (`/analyses/:id`)
**Sections:**
- **Score Global**: Note /10 avec jauge
- **Identification**: Infos compétition, cheval, cavalier
- **Scores Détaillés**: Horse, Rider, Harmony, Technique
- **Obstacles**: Liste avec scores individuels
- **Problèmes Identifiés**: Issues par sévérité
- **Recommandations**: Conseils d'amélioration
- **Vidéo Annotée**: Player avec timestamps

---

## 🎬 Types d'Analyses

| Type | Code | Tokens | Description |
|------|------|--------|-------------|
| Vidéo Basique | `VIDEO_BASIC` | 50 | Analyse simple (30s max) |
| Vidéo Standard | `VIDEO_STANDARD` | 100 | Analyse complète (1-2min) |
| Parcours Complet | `VIDEO_PARCOURS` | 150 | Analyse parcours CSO |
| Analyse Avancée | `VIDEO_ADVANCED` | 250 | Analyse ultra-détaillée |
| Locomotion | `LOCOMOTION` | 100 | Focus biomécanique |

---

## 🔄 Flux Utilisateur

### Création d'une analyse
```
1. Click "+ Nouvelle analyse"
2. Sélection type d'analyse
3. Upload vidéo (formats: mp4, mov, webm, max 500MB)
4. Remplir métadonnées:
   - Titre (obligatoire)
   - Cheval (optionnel, sélection existant)
   - Cavalier (optionnel, sélection existant)
   - Compétition: nom, lieu, niveau, date (optionnel)
5. Affichage coût en tokens
6. Vérification solde suffisant
7. Si insuffisant → proposition achat tokens
8. Submit → POST /analyses
9. Création session status="pending"
10. Redirection vers page processing
```

### Traitement
```
1. Backend reçoit la demande
2. Upload vidéo vers S3
3. Mise en queue Bull/Redis
4. Worker récupère le job
5. Extraction frames (1fps ou keyframes)
6. Analyse IA (Claude Vision API)
7. Détection obstacles, cavalier, cheval
8. Calcul scores par obstacle
9. Identification problèmes
10. Génération recommandations
11. Sauvegarde résultats MongoDB
12. Mise à jour status="completed"
13. Notification utilisateur
14. Frontend reçoit via polling/websocket
```

### Consultation résultats
```
1. Accès /analyses/:id
2. Affichage score global en grand
3. Scores détaillés en cartes
4. Liste obstacles cliquables
5. Click obstacle → timestamp vidéo
6. Section problèmes par sévérité
7. Section recommandations
8. Bouton "Générer rapport PDF"
```

---

## 💾 Modèle de Données

```typescript
interface AnalysisSession {
  id: string;                    // UUID v4
  organizationId: string;        // FK Organization
  horseId?: string;              // FK Horse (optionnel)
  riderId?: string;              // FK Rider (optionnel)
  createdById: string;           // FK User

  // Type & Statut
  type: AnalysisType;
  status: AnalysisStatus;

  // Métadonnées
  title: string;                 // Max 255
  competition?: {
    name: string;
    location?: string;
    level?: string;              // Ex: "CSO 1.20m"
    date?: Date;
  };

  // Fichiers
  inputMediaUrls: string[];      // URLs S3 vidéos uploadées
  inputMetadata?: {
    duration: number;            // Secondes
    resolution: string;          // Ex: "1920x1080"
    fps: number;
    codec: string;
  };

  // Résultats IA
  scores?: {
    global: number;              // 0-10
    horse?: number;              // 0-10
    rider?: number;              // 0-10
    harmony?: number;            // 0-10
    technique?: number;          // 0-10
  };
  obstacles: ObstacleAnalysis[];
  issues: Issue[];
  recommendations: string[];
  aiAnalysis?: Record<string, any>;  // Données brutes IA
  confidenceScore?: number;      // 0-1

  // Rapport
  reportId?: string;             // FK Report si généré

  // Timing
  startedAt?: Date;
  completedAt?: Date;
  processingTimeMs?: number;

  // Erreur
  errorMessage?: string;

  // Billing
  tokensConsumed: number;

  createdAt: Date;
  updatedAt: Date;
}

type AnalysisType =
  | 'video_performance'
  | 'video_course'
  | 'radiological'
  | 'locomotion';

type AnalysisStatus =
  | 'pending'
  | 'processing'
  | 'completed'
  | 'failed'
  | 'cancelled';

interface ObstacleAnalysis {
  number: string;                // "1", "5A", "5B", etc.
  name: string;                  // "Vertical Sponsor X"
  type: ObstacleType;
  sponsor?: string;
  height?: number;               // En cm
  width?: number;                // En cm
  score: number;                 // 0-10
  issues: string[];              // Liste des problèmes
  notes?: string;
  videoTimestamp?: number;       // Secondes dans la vidéo
  frameUrl?: string;             // Screenshot de l'obstacle
}

type ObstacleType =
  | 'vertical'
  | 'oxer'
  | 'triple_bar'
  | 'combination'
  | 'water'
  | 'liverpool'
  | 'wall'
  | 'other';

interface Issue {
  id: string;
  title: string;
  description: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  category: 'horse' | 'rider' | 'harmony' | 'technique';
  visibleAt: string[];           // Numéros obstacles concernés
  recommendation?: string;
  confidence?: number;           // 0-1
}
```

---

## 🔌 API Endpoints

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/analyses` | Liste paginée avec filtres |
| POST | `/analyses` | Créer une analyse |
| GET | `/analyses/:id` | Détail d'une analyse |
| DELETE | `/analyses/:id` | Supprimer |
| POST | `/analyses/:id/cancel` | Annuler traitement |
| GET | `/analyses/:id/status` | Statut en temps réel |
| POST | `/analyses/:id/retry` | Relancer analyse échouée |
| GET | `/analyses/:id/video` | URL signée vidéo |
| POST | `/analyses/:id/report` | Générer rapport PDF |

### Requête POST /analyses
```json
{
  "type": "video_course",
  "title": "CSO Fontainebleau - Pro 2",
  "horseId": "uuid-cheval",
  "riderId": "uuid-cavalier",
  "competition": {
    "name": "Grand Prix FFE",
    "location": "Fontainebleau",
    "level": "CSO 1.25m",
    "date": "2026-01-15"
  },
  "mediaUrl": "s3://bucket/videos/xxx.mp4"
}
```

### Réponse GET /analyses/:id (completed)
```json
{
  "id": "uuid",
  "status": "completed",
  "title": "CSO Fontainebleau - Pro 2",
  "scores": {
    "global": 7.8,
    "horse": 8.2,
    "rider": 7.5,
    "harmony": 7.9,
    "technique": 7.6
  },
  "obstacles": [
    {
      "number": "1",
      "name": "Vertical d'entrée",
      "type": "vertical",
      "score": 8.5,
      "issues": [],
      "videoTimestamp": 12.5
    },
    {
      "number": "5A-B",
      "name": "Double Longines",
      "type": "combination",
      "score": 6.2,
      "issues": ["Abord trop court", "Perte d'impulsion"],
      "videoTimestamp": 45.3
    }
  ],
  "issues": [
    {
      "id": "issue-1",
      "title": "Abords irréguliers",
      "description": "Les abords des obstacles 5 et 8 montrent une irrégularité dans le galop...",
      "severity": "medium",
      "category": "rider",
      "visibleAt": ["5A-B", "8"],
      "recommendation": "Travailler les transitions et le contrôle du galop sur les lignes courbes."
    }
  ],
  "recommendations": [
    "Améliorer la régularité du galop dans les virages",
    "Travailler l'impulsion sur les combinaisons",
    "Maintenir un meilleur équilibre en réception"
  ],
  "tokensConsumed": 150,
  "processingTimeMs": 45000
}
```

---

## 🎨 États de l'Interface

### Upload
- **Idle**: Zone drag & drop
- **Dragging**: Zone highlight
- **Uploading**: Barre de progression %
- **Uploaded**: Checkmark vert
- **Error**: Message + bouton réessayer

### Processing
- **Pending**: "En attente de traitement..."
- **Processing**: Barre + étapes (Upload → Extraction → Analyse → Finalisation)
- **Completed**: Redirection automatique vers résultats
- **Failed**: Message d'erreur + bouton retry
- **Cancelled**: "Analyse annulée"

### Résultats
- Score global: Jauge circulaire colorée
  - 0-4: Rouge
  - 4-6: Orange
  - 6-8: Jaune
  - 8-10: Vert
- Obstacles: Liste scrollable avec mini-badges
- Issues: Cards avec icônes de sévérité

---

## 🔒 Permissions

| Action | Owner | Admin | Analyst | Vet | Member | Viewer |
|--------|-------|-------|---------|-----|--------|--------|
| Voir liste | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Voir détail | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Créer | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| Supprimer | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| Annuler | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| Générer rapport | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ |

---

## 🔗 Relations

| Module | Relation |
|--------|----------|
| **Horses** | N-1 (analyse liée à un cheval) |
| **Riders** | N-1 (analyse liée à un cavalier) |
| **Reports** | 1-1 (rapport généré) |
| **Tokens** | Consommation de tokens |
| **Notifications** | Notification fin traitement |

---

## 📊 Métriques

- Nombre d'analyses par organisation
- Temps moyen de traitement
- Taux de succès vs échec
- Score moyen global
- Progression des scores dans le temps
- Tokens consommés par mois
