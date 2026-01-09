# 🏆 MODULE LEADERBOARD - Classements & Compétitions

## Description
Système de classements et compétitions virtuelles basés sur les performances des analyses IA, les XP de gamification et les résultats compétitions officielles.

## Objectif Business
Stimuler l'engagement et la compétition saine entre utilisateurs, encourager les analyses régulières et créer une communauté active.

---

## 📱 Écrans/Pages

### 1. Dashboard Classements (`/leaderboard`)
- Vue d'ensemble des classements
- Position personnelle
- Top 10 par catégorie
- Tendances (↑↓)
- Filtres temporels

### 2. Classement Détaillé (`/leaderboard/:type`)
- Liste complète paginée
- Profil cliquable
- Statistiques détaillées
- Historique de position

### 3. Challenges (`/leaderboard/challenges`)
- Challenges en cours
- Challenges à venir
- Historique participations
- Récompenses à réclamer

### 4. Mon Profil Compétiteur (`/leaderboard/me`)
- Résumé positions
- Progression temporelle
- Badges et trophées
- Historique challenges

---

## 🏅 Types de Classements

| Type | Code | Base de calcul |
|------|------|----------------|
| Global | `global` | XP total |
| Analyses | `analyses` | Nombre + qualité analyses |
| Performance | `performance` | Score moyen analyses |
| Progression | `progression` | Amélioration scores |
| Social | `social` | Engagement communauté |
| Élevage | `breeding` | Succès reproduction |
| Mensuel | `monthly` | XP du mois |
| Régional | `regional` | Par zone géographique |

---

## 🔄 Flux Utilisateur

### Consulter les classements
```
1. Menu → Classements
2. Vue dashboard:
   - Ma position globale: #42
   - Progression: ↑5 places
   - XP ce mois: 1,250
3. Cliquer sur un classement
4. Liste complète avec:
   - Rang
   - Avatar + nom
   - Score
   - Tendance
5. Click profil → voir détails
```

### Participer à un challenge
```
1. Challenges → "Défi de la semaine"
2. Description:
   - "Réalisez 5 analyses CSO cette semaine"
   - Récompense: 500 XP + Badge "Analyste Pro"
   - Participants: 234
3. Click "Participer"
4. Suivi progression:
   - 2/5 analyses réalisées
5. Compléter → récompense attribuée
6. Classement du challenge affiché
```

### Comparer avec un autre utilisateur
```
1. Profil utilisateur → "Comparer"
2. Vue côte à côte:
   - XP total
   - Analyses
   - Score moyen
   - Badges
3. Graphique évolution comparée
4. Domaines où chacun excelle
```

---

## 💾 Modèle de Données

```typescript
interface LeaderboardEntry {
  id: string;                    // UUID v4
  leaderboardType: LeaderboardType;
  period: LeaderboardPeriod;
  periodStart?: Date;            // Pour périodiques
  periodEnd?: Date;

  // Utilisateur
  userId: string;                // FK User
  organizationId: string;        // FK Organization

  // Position
  rank: number;
  previousRank?: number;
  rankChange: number;            // Positif = montée

  // Score
  score: number;
  scoreBreakdown?: Record<string, number>;

  // Méta
  region?: string;               // Pour régional
  discipline?: string;           // Pour par discipline

  // Timestamp
  calculatedAt: Date;
  validUntil: Date;
}

interface Challenge {
  id: string;                    // UUID v4

  // Identité
  name: string;
  description: string;
  imageUrl?: string;

  // Type
  type: ChallengeType;
  difficulty: 'easy' | 'medium' | 'hard' | 'extreme';

  // Timing
  startDate: Date;
  endDate: Date;
  status: ChallengeStatus;

  // Objectifs
  objectives: ChallengeObjective[];
  completionType: 'all' | 'any';  // Tous objectifs ou un seul

  // Récompenses
  rewards: ChallengeReward[];

  // Limites
  maxParticipants?: number;
  currentParticipants: number;
  eligibility?: {
    minLevel?: number;
    maxLevel?: number;
    subscription?: string[];
    region?: string[];
  };

  // Classement
  hasLeaderboard: boolean;
  topRewards?: ChallengeReward[];  // Récompenses top 3

  createdAt: Date;
  updatedAt: Date;
}

interface ChallengeObjective {
  id: string;
  type: ObjectiveType;
  target: number;                // Cible à atteindre
  description: string;
  points: number;                // Points vers completion
}

interface ChallengeReward {
  type: 'xp' | 'badge' | 'tokens' | 'subscription_days' | 'physical';
  value: number | string;        // Quantité ou ID
  description: string;
}

interface ChallengeParticipation {
  id: string;
  challengeId: string;           // FK Challenge
  userId: string;                // FK User

  // Statut
  status: 'active' | 'completed' | 'failed' | 'withdrawn';
  joinedAt: Date;
  completedAt?: Date;

  // Progression
  progress: {
    objectiveId: string;
    current: number;
    target: number;
    completedAt?: Date;
  }[];
  totalProgress: number;         // 0-100%

  // Classement challenge
  rank?: number;
  score?: number;

  // Récompenses
  rewardsEarned: string[];       // IDs des rewards réclamées
  rewardsClaimed: boolean;

  updatedAt: Date;
}

interface UserStats {
  userId: string;                // FK User

  // XP
  totalXp: number;
  monthlyXp: number;
  weeklyXp: number;
  level: number;

  // Analyses
  totalAnalyses: number;
  averageScore: number;
  bestScore: number;
  analysesThisMonth: number;

  // Progression
  scoreImprovement: number;      // % sur 30 jours
  consistencyScore: number;      // Régularité

  // Social
  followers: number;
  following: number;
  postsCount: number;
  likesReceived: number;

  // Élevage (si applicable)
  foalsBorn: number;
  breedingSuccess: number;       // %

  // Challenges
  challengesCompleted: number;
  challengesWon: number;

  // Timestamps
  lastActivityAt: Date;
  updatedAt: Date;
}

type LeaderboardType =
  | 'global'
  | 'analyses'
  | 'performance'
  | 'progression'
  | 'social'
  | 'breeding'
  | 'monthly'
  | 'weekly'
  | 'regional';

type LeaderboardPeriod =
  | 'all_time'
  | 'yearly'
  | 'monthly'
  | 'weekly'
  | 'daily';

type ChallengeType =
  | 'analysis'                   // Réaliser des analyses
  | 'score'                      // Atteindre un score
  | 'streak'                     // Connexion consécutive
  | 'social'                     // Actions sociales
  | 'learning'                   // Compléter tutoriels
  | 'competition'                // Résultats compétitions
  | 'special';                   // Événement spécial

type ChallengeStatus =
  | 'draft'
  | 'upcoming'
  | 'active'
  | 'ended'
  | 'archived';

type ObjectiveType =
  | 'analyses_count'             // Nombre d'analyses
  | 'analyses_score'             // Score minimum
  | 'login_streak'               // Jours consécutifs
  | 'posts_created'              // Posts publiés
  | 'horses_added'               // Chevaux ajoutés
  | 'health_records'             // Suivis santé
  | 'social_follows'             // Nouveaux follows
  | 'xp_earned'                  // XP gagnés
  | 'custom';                    // Personnalisé
```

---

## 🔌 API Endpoints

### Classements
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/leaderboard` | Dashboard classements |
| GET | `/leaderboard/:type` | Classement spécifique |
| GET | `/leaderboard/:type/around-me` | Ma position ± 5 |
| GET | `/leaderboard/me` | Mes positions tous classements |
| GET | `/leaderboard/compare/:userId` | Comparer avec un user |

### Challenges
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/challenges` | Liste challenges actifs |
| GET | `/challenges/:id` | Détail challenge |
| POST | `/challenges/:id/join` | Participer |
| GET | `/challenges/:id/progress` | Ma progression |
| GET | `/challenges/:id/leaderboard` | Classement challenge |
| POST | `/challenges/:id/claim` | Réclamer récompenses |
| GET | `/challenges/history` | Mes participations |

### Stats
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/stats/me` | Mes statistiques |
| GET | `/stats/user/:id` | Stats d'un utilisateur |
| GET | `/stats/trends` | Tendances globales |

---

## 🎯 Calcul des Scores

### Score Global
```
Score = (XP_total × 0.4) +
        (analyses_count × 10 × 0.3) +
        (avg_score × 100 × 0.2) +
        (social_engagement × 0.1)
```

### Score Progression
```
Score = ((score_actuel - score_30j) / score_30j) × 100
```

Pondéré par le nombre d'analyses pour éviter les anomalies.

### Score Social
```
Score = (followers × 2) +
        (likes_received × 1) +
        (comments × 3) +
        (posts × 5)
```

---

## 🏅 Récompenses Challenges

### XP
- Challenge facile: 100-300 XP
- Challenge moyen: 300-500 XP
- Challenge difficile: 500-1000 XP
- Challenge extrême: 1000+ XP

### Badges spéciaux
- "Challenger de la semaine"
- "Top 10 mensuel"
- "Légende" (top 3 annuel)
- Badges thématiques saisonniers

### Récompenses physiques
- Goodies HorseTempo (top 3)
- Partenariats marques équestres
- Invitations événements

---

## 🎨 États de l'Interface

### Position
- **Top 10**: Affichage or/argent/bronze pour 1-2-3
- **Montée**: Flèche verte ↑
- **Descente**: Flèche rouge ↓
- **Stable**: Tiret gris -

### Challenge
- **Upcoming**: "Commence dans 3 jours"
- **Active**: "En cours - X participants"
- **Ending Soon**: "Plus que 24h!"
- **Completed**: "Terminé - Voir résultats"

### Progression
- **0-25%**: Barre rouge
- **25-50%**: Barre orange
- **50-75%**: Barre jaune
- **75-100%**: Barre verte

---

## 🔒 Permissions

| Action | Tous | Premium | Admin |
|--------|------|---------|-------|
| Voir classements | ✓ | ✓ | ✓ |
| Participer challenges | ✓ | ✓ | ✓ |
| Challenges exclusifs | ✗ | ✓ | ✓ |
| Voir stats détaillées | Limité | ✓ | ✓ |
| Créer challenges | ✗ | ✗ | ✓ |

---

## 🔗 Relations

| Module | Relation |
|--------|----------|
| **Gamification** | XP et niveaux |
| **Analyses** | Scores et compteurs |
| **Social** | Engagement social |
| **Users** | Profils et stats |
| **Notifications** | Alertes challenges |

---

## 📊 Métriques

- Participation aux challenges
- Taux de complétion challenges
- Évolution positions classements
- Engagement par type de classement
- Impact sur rétention utilisateurs
- Corrélation leaderboard/analyses

---

## 🗓️ Challenges Récurrents

### Hebdomadaires
- "7 jours d'analyses" (streak)
- "Meilleur score de la semaine"
- "Plus actif socialement"

### Mensuels
- "Champion du mois" (top analyses)
- "Progression record"
- "Éleveur du mois"

### Saisonniers
- "Challenge de printemps"
- "Défi estival"
- "Préparation indoor"

### Événements spéciaux
- Anniversaire HorseTempo
- Grandes compétitions (JO, CSI5*)
- Partenariats marques

