# 🎮 MODULE GAMIFICATION - Points, Badges & Récompenses

## Description
Système complet de gamification incluant points d'expérience (XP), niveaux, badges à débloquer, défis quotidiens/hebdomadaires, streaks, parrainage et récompenses pour encourager l'engagement utilisateur.

## Objectif Business
Augmenter la rétention et l'engagement des utilisateurs en rendant l'utilisation de l'application ludique et récompensante.

---

## 📱 Écrans/Pages

### 1. Dashboard Gamification (`/gamification`)
- Niveau actuel avec barre de progression
- XP total et vers prochain niveau
- Streak actuel (jours consécutifs)
- Badges débloqués récemment
- Défis actifs
- Leaderboard position

### 2. Badges (`/gamification/badges`)
- Grille de tous les badges
- Badges débloqués vs verrouillés
- Progression vers chaque badge
- Détail au click

### 3. Défis (`/gamification/challenges`)
- Défis quotidiens (3)
- Défis hebdomadaires (5)
- Défis mensuels (3)
- Progression de chaque
- Récompenses

### 4. Leaderboard (`/leaderboard`)
- Classement global
- Classement régional
- Classement par discipline
- Ma position
- Filtres période

### 5. Parrainage (`/referrals`)
- Code/lien de parrainage
- Filleuls invités
- Récompenses gagnées
- Bonus progression

---

## 🎯 Système de Points (XP)

### Sources d'XP

| Action | XP | Fréquence |
|--------|-----|-----------|
| Connexion quotidienne | 50 | 1x/jour |
| Analyse vidéo complète | 100 | Illimité |
| Rapport généré | 75 | Illimité |
| Vente marketplace | 200 | Par vente |
| Post social publié | 30 | Max 5/jour |
| Commentaire | 10 | Max 20/jour |
| Like donné | 5 | Max 50/jour |
| Nouveau follower | 20 | Illimité |
| Participation club | 40 | Par participation |
| Défi complété | Var | Par défi |
| Badge débloqué | 100-500 | Par badge |
| Streak 7 jours | 200 | Hebdo |
| Streak 30 jours | 1000 | Mensuel |

### Niveaux

| Niveau | XP requis | XP cumulé | Titre |
|--------|-----------|-----------|-------|
| 1 | 0 | 0 | Débutant |
| 5 | 500 | 2,000 | Apprenti |
| 10 | 1,000 | 7,000 | Cavalier |
| 15 | 1,500 | 14,500 | Confirmé |
| 20 | 2,000 | 24,500 | Expert |
| 25 | 2,500 | 37,000 | Maître |
| 30 | 3,000 | 52,000 | Champion |
| 40 | 4,000 | 88,000 | Légende |
| 50 | 5,000 | 138,000 | Élite |

---

## 🏆 Badges

### Catégories

#### 📊 Analyses
| Badge | Condition | XP |
|-------|-----------|-----|
| Première Analyse | 1 analyse | 100 |
| Analyste | 10 analyses | 200 |
| Data Master | 50 analyses | 300 |
| Scientifique | 100 analyses | 500 |

#### 🎬 Médias
| Badge | Condition | XP |
|-------|-----------|-----|
| Première Vidéo | 1 upload | 50 |
| Cinéaste | 50 vidéos | 200 |
| Photographe | 100 photos | 200 |

#### 🐴 Chevaux
| Badge | Condition | XP |
|-------|-----------|-----|
| Premier Cheval | 1 cheval ajouté | 100 |
| Écurie | 5 chevaux | 200 |
| Haras | 20 chevaux | 400 |

#### 🏪 Marketplace
| Badge | Condition | XP |
|-------|-----------|-----|
| Trader | 1ère annonce | 100 |
| Marchand | 5 ventes | 300 |
| Négociant | 20 ventes | 500 |

#### 👥 Social
| Badge | Condition | XP |
|-------|-----------|-----|
| Sociable | 10 followers | 100 |
| Influenceur | 100 followers | 300 |
| Célébrité | 1000 followers | 500 |

#### 🔥 Streaks
| Badge | Condition | XP |
|-------|-----------|-----|
| Régulier | 7 jours consécutifs | 150 |
| Dévoué | 30 jours | 400 |
| On Fire | 100 jours | 1000 |
| Légende | 365 jours | 2000 |

#### 🤰 Élevage
| Badge | Condition | XP |
|-------|-----------|-----|
| Éleveur | 1ère naissance | 300 |
| Naisseur | 5 naissances | 500 |

#### ⛑️ Santé
| Badge | Condition | XP |
|-------|-----------|-----|
| Soigneur | 10 suivis santé | 100 |
| Docteur | 50 suivis | 200 |
| Vétérinaire | 100 suivis | 400 |

---

## 📅 Défis

### Défis Quotidiens (reset minuit)
- **Connexion**: Se connecter → 50 XP
- **Partage**: Publier 1 post → 30 XP
- **Analyse**: Compléter 1 analyse → 100 XP

### Défis Hebdomadaires (reset lundi)
- **Analyste de la semaine**: 5 analyses → 300 XP
- **Social butterfly**: 20 interactions → 150 XP
- **Soigneur**: 3 suivis santé → 100 XP
- **Explorateur**: Visiter 5 sections → 50 XP
- **Community**: Rejoindre 1 club → 100 XP

### Défis Mensuels
- **Master Analyst**: 20 analyses → 1000 XP
- **Top Seller**: 3 ventes marketplace → 500 XP
- **Health Champion**: 10 suivis santé → 400 XP

---

## 👥 Parrainage

### Mécanique
```
1. Utilisateur obtient code unique (ex: HORSE-ABC123)
2. Partage le code
3. Filleul s'inscrit avec le code
4. Filleul vérifie son email
5. Parrain reçoit 500 XP + 50 tokens
6. Filleul reçoit 200 XP + 20 tokens
7. Si filleul passe premium → Parrain reçoit 1000 XP
```

### Récompenses Parrainage

| Filleuls | Récompense Parrain |
|----------|-------------------|
| 1 | 500 XP + 50 tokens |
| 5 | Badge "Ambassadeur" + 200 tokens |
| 10 | Badge "Recruteur" + 500 tokens |
| 25 | Badge "Champion Parrain" + 1 mois PRO |
| 50 | Badge "Légende" + 3 mois PRO |

---

## 💾 Modèle de Données

```typescript
interface UserGamification {
  userId: string;
  level: number;
  currentXp: number;
  totalXp: number;
  streakDays: number;
  longestStreak: number;
  lastActivityAt: Date;
  badges: UserBadge[];
  referralCode: string;
  referredBy?: string;
  referralCount: number;
}

interface UserBadge {
  badgeId: string;
  unlockedAt: Date;
  progress?: number;
}

interface Badge {
  id: string;
  name: string;
  description: string;
  category: string;
  icon: string;
  xpReward: number;
  condition: {
    type: string;
    target: number;
  };
  rarity: 'common' | 'rare' | 'epic' | 'legendary';
}

interface Challenge {
  id: string;
  title: string;
  description: string;
  type: 'daily' | 'weekly' | 'monthly';
  xpReward: number;
  tokenReward?: number;
  condition: {
    action: string;
    count: number;
  };
  expiresAt: Date;
}

interface UserChallenge {
  challengeId: string;
  userId: string;
  progress: number;
  completedAt?: Date;
}

interface XpTransaction {
  id: string;
  userId: string;
  amount: number;
  source: string;
  description: string;
  createdAt: Date;
}
```

---

## 🔌 API Endpoints

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/gamification/profile` | Profil gamification |
| GET | `/gamification/badges` | Tous les badges |
| GET | `/gamification/badges/mine` | Mes badges |
| GET | `/gamification/challenges` | Défis actifs |
| GET | `/gamification/challenges/progress` | Ma progression |
| POST | `/gamification/challenges/:id/claim` | Réclamer récompense |
| GET | `/gamification/leaderboard` | Classement |
| GET | `/gamification/referrals` | Mes parrainages |
| POST | `/gamification/referrals/invite` | Inviter par email |
| GET | `/gamification/history` | Historique XP |
| GET | `/gamification/stats` | Statistiques |

---

## 🎨 États de l'Interface

### Progression Niveau
- Barre de progression animée
- Confettis au level up
- Modal de célébration

### Badge Débloqué
- Animation unlock
- Notification push
- Son optionnel
- Modal détail badge

### Défi Complété
- Checkmark animé
- XP ajouté visuellement
- Bouton "Réclamer"

### Streak
- Compteur flamme 🔥
- Alerte si streak en danger (pas connecté depuis 20h)

---

## 🔗 Relations

| Module | Relation |
|--------|----------|
| **Users** | Profil gamification lié |
| **Analyses** | Source d'XP |
| **Social** | Source d'XP |
| **Marketplace** | Source d'XP |
| **Notifications** | Alertes badges/défis |
| **Leaderboard** | Classement |

---

## 📊 Métriques

- Distribution des niveaux
- Badges les plus/moins obtenus
- Taux de complétion des défis
- Longueur moyenne des streaks
- Taux de parrainage
- Corrélation XP vs rétention
