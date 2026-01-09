# 📱 MODULE SOCIAL - Réseau Social Équestre

## Description
Fonctionnalités sociales de l'application: fil d'actualité, partage de contenu, commentaires, likes, follow et messaging entre utilisateurs.

## Objectif Business
Créer une communauté engagée autour de la passion équestre, augmenter la rétention et générer du contenu organique.

---

## 📱 Écrans/Pages

### 1. Feed Principal (`/feed`)
- Fil d'actualité chronologique/algorithmique
- Posts des utilisateurs suivis
- Suggestions de contenu
- Stories en haut
- Bouton "+ Créer post"

### 2. Profil Utilisateur (`/profile/:id`)
- Photo et bio
- Statistiques (posts, followers, following)
- Grille de posts
- Chevaux associés
- Badges et achievements

### 3. Création de Post (`/post/new`)
- Upload médias (photos, vidéos)
- Texte/description
- Tags chevaux, lieux
- Mentions utilisateurs
- Options de partage

### 4. Détail Post (`/post/:id`)
- Média plein écran
- Likes et commentaires
- Partage
- Infos analyse (si liée)

### 5. Messages (`/messages`)
- Liste conversations
- Chat individuel
- Partage rapide de contenus

### 6. Notifications Sociales (`/notifications`)
- Likes reçus
- Commentaires
- Nouveaux followers
- Mentions

---

## 🔄 Flux Utilisateur

### Créer un post
```
1. Click "+ Créer post"
2. Sélection type:
   - Photo/Vidéo
   - Texte seul
   - Analyse partagée
   - Achievement
3. Upload média (optionnel)
4. Rédaction description
5. Ajout tags:
   - @mention utilisateur
   - #hashtag
   - 🐴 tag cheval
   - 📍 localisation
6. Audience: Public / Followers / Privé
7. Submit → publication
8. +30 XP si public
```

### Interagir avec un post
```
1. Vue post dans feed
2. Actions disponibles:
   - ❤️ Like (toggle)
   - 💬 Commenter
   - ↗️ Partager
   - 🔖 Sauvegarder
3. Click commentaire:
   - Texte
   - Emoji
   - @mention
4. Submit → commentaire publié
5. Notification envoyée à l'auteur
```

### Suivre un utilisateur
```
1. Profil utilisateur → "Suivre"
2. Si profil public: suivi immédiat
3. Si profil privé: demande envoyée
4. Acceptation → suivi actif
5. Contenu visible dans feed
```

### Envoyer un message
```
1. Profil → "Message" ou Messages → "+"
2. Sélection destinataire
3. Rédaction message
4. Options:
   - Texte
   - Photo
   - Partage post/analyse/cheval
5. Envoi → notification push
```

---

## 💾 Modèle de Données

```typescript
interface Post {
  id: string;                    // UUID v4
  authorId: string;              // FK User
  organizationId: string;        // FK Organization

  // Contenu
  type: PostType;
  content: string;               // Max 2000 caractères
  mediaUrls: MediaItem[];

  // Tags
  taggedHorses: string[];        // FK Horse[]
  taggedUsers: string[];         // FK User[]
  hashtags: string[];
  location?: {
    name: string;
    coordinates?: { lat: number; lng: number };
  };

  // Lien vers autres modules
  linkedAnalysis?: string;       // FK Analysis
  linkedReport?: string;         // FK Report
  linkedListing?: string;        // FK Marketplace listing
  achievement?: string;          // ID achievement

  // Visibilité
  visibility: 'public' | 'followers' | 'private';

  // Engagement
  likesCount: number;
  commentsCount: number;
  sharesCount: number;
  savesCount: number;

  // Modération
  status: 'active' | 'hidden' | 'reported' | 'deleted';
  reportCount: number;

  // Timestamps
  createdAt: Date;
  updatedAt: Date;
  editedAt?: Date;
}

interface MediaItem {
  id: string;
  type: 'image' | 'video';
  url: string;
  thumbnailUrl?: string;
  width?: number;
  height?: number;
  duration?: number;             // secondes si vidéo
  altText?: string;
}

interface Comment {
  id: string;
  postId: string;                // FK Post
  authorId: string;              // FK User
  parentId?: string;             // FK Comment (réponse)

  content: string;               // Max 500 caractères
  mentions: string[];            // FK User[]

  likesCount: number;
  repliesCount: number;

  status: 'active' | 'hidden' | 'deleted';

  createdAt: Date;
  editedAt?: Date;
}

interface Like {
  id: string;
  userId: string;                // FK User
  targetType: 'post' | 'comment';
  targetId: string;              // FK Post ou Comment
  createdAt: Date;
}

interface Follow {
  id: string;
  followerId: string;            // FK User (qui suit)
  followingId: string;           // FK User (qui est suivi)
  status: 'active' | 'pending' | 'blocked';
  createdAt: Date;
  acceptedAt?: Date;
}

interface Conversation {
  id: string;
  participants: string[];        // FK User[] (2+)
  type: 'direct' | 'group';

  // Dernier message
  lastMessageId?: string;
  lastMessageAt?: Date;
  lastMessagePreview?: string;

  // Par participant
  participantStatus: {
    [userId: string]: {
      unreadCount: number;
      mutedUntil?: Date;
      leftAt?: Date;
    };
  };

  createdAt: Date;
  updatedAt: Date;
}

interface Message {
  id: string;
  conversationId: string;        // FK Conversation
  senderId: string;              // FK User

  // Contenu
  type: MessageType;
  content?: string;              // Si texte
  mediaUrl?: string;             // Si média

  // Partage
  sharedContent?: {
    type: 'post' | 'horse' | 'analysis' | 'listing';
    id: string;
    preview: Record<string, any>;
  };

  // Statut
  status: 'sent' | 'delivered' | 'read';
  readBy: { userId: string; readAt: Date }[];

  createdAt: Date;
  deletedAt?: Date;
}

interface Story {
  id: string;
  authorId: string;              // FK User
  mediaUrl: string;
  mediaType: 'image' | 'video';
  duration?: number;
  viewsCount: number;
  expiresAt: Date;               // 24h après création
  createdAt: Date;
}

type PostType =
  | 'standard'                   // Post classique
  | 'analysis_share'             // Partage analyse
  | 'achievement'                // Célébration achievement
  | 'milestone'                  // Milestone (100 analyses, etc.)
  | 'sale'                       // Annonce vente
  | 'event';                     // Événement

type MessageType =
  | 'text'
  | 'image'
  | 'video'
  | 'shared_content'
  | 'system';                    // Message système
```

---

## 🔌 API Endpoints

### Feed
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/feed` | Feed principal |
| GET | `/feed/following` | Feed abonnements uniquement |
| GET | `/feed/discover` | Découvrir (algorithme) |

### Posts
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/posts/:id` | Détail post |
| POST | `/posts` | Créer post |
| PATCH | `/posts/:id` | Modifier |
| DELETE | `/posts/:id` | Supprimer |
| POST | `/posts/:id/like` | Liker |
| DELETE | `/posts/:id/like` | Unliker |
| POST | `/posts/:id/save` | Sauvegarder |
| POST | `/posts/:id/share` | Partager |
| POST | `/posts/:id/report` | Signaler |

### Commentaires
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/posts/:id/comments` | Liste commentaires |
| POST | `/posts/:id/comments` | Commenter |
| PATCH | `/comments/:id` | Modifier |
| DELETE | `/comments/:id` | Supprimer |
| POST | `/comments/:id/like` | Liker commentaire |

### Profil & Follow
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/users/:id/profile` | Profil public |
| GET | `/users/:id/posts` | Posts utilisateur |
| POST | `/users/:id/follow` | Suivre |
| DELETE | `/users/:id/follow` | Ne plus suivre |
| GET | `/users/:id/followers` | Liste followers |
| GET | `/users/:id/following` | Liste following |
| POST | `/follow-requests/:id/accept` | Accepter demande |
| DELETE | `/follow-requests/:id` | Refuser demande |

### Messages
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/conversations` | Liste conversations |
| POST | `/conversations` | Nouvelle conversation |
| GET | `/conversations/:id` | Messages |
| POST | `/conversations/:id/messages` | Envoyer message |
| POST | `/conversations/:id/read` | Marquer lu |
| POST | `/conversations/:id/mute` | Mettre en sourdine |

### Stories
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/stories` | Stories des following |
| POST | `/stories` | Créer story |
| GET | `/stories/:id` | Voir story |
| DELETE | `/stories/:id` | Supprimer |
| POST | `/stories/:id/view` | Marquer vue |

---

## 🔔 Notifications Sociales

| Événement | Notification | Push |
|-----------|--------------|------|
| Like post | "@user a aimé votre post" | ✓ |
| Commentaire | "@user a commenté: ..." | ✓ |
| Follow | "@user vous suit maintenant" | ✓ |
| Mention | "@user vous a mentionné" | ✓ |
| Message | "Nouveau message de @user" | ✓ |
| Follow request | "@user souhaite vous suivre" | ✓ |

---

## 🧠 Algorithme Feed

### Facteurs de ranking
| Facteur | Poids | Description |
|---------|-------|-------------|
| Récence | 30% | Posts récents favorisés |
| Engagement | 25% | Likes/commentaires |
| Affinité | 20% | Interactions passées avec l'auteur |
| Qualité média | 15% | Photos/vidéos HD |
| Type contenu | 10% | Analyses > Posts texte |

### Signals négatifs
- Utilisateur masqué post similaire
- Auteur peu engageant
- Contenu répétitif
- Posts très anciens

---

## 🛡️ Modération

### Règles automatiques
- Spam: détection mots-clés
- Contenu adulte: filtrage images
- Harcèlement: analyse sentiment
- Faux comptes: comportement anormal

### Actions de modération
- `hide`: Masquer (visible uniquement auteur)
- `warn`: Avertissement utilisateur
- `restrict`: Restriction temporaire
- `ban`: Bannissement

### Signalements
Types de signalement:
- Spam
- Contenu inapproprié
- Harcèlement
- Fausses informations
- Maltraitance animale (priorité haute)
- Autre

---

## 🎨 États de l'Interface

### Feed
- **Loading**: Skeleton posts
- **Empty**: "Suivez des utilisateurs pour voir du contenu"
- **End**: "Vous avez tout vu!"
- **Error**: "Impossible de charger le feed"

### Post
- **Liked**: Cœur plein rouge
- **Saved**: Icône signet plein
- **Mine**: Options édition/suppression

### Message
- **Sent**: ✓ simple
- **Delivered**: ✓✓ gris
- **Read**: ✓✓ bleu

---

## 🔒 Permissions

| Action | Tout le monde | Followers | Owner |
|--------|---------------|-----------|-------|
| Voir profil public | ✓ | ✓ | ✓ |
| Voir posts publics | ✓ | ✓ | ✓ |
| Voir posts followers | ✗ | ✓ | ✓ |
| Commenter | ✓ | ✓ | ✓ |
| Envoyer message | ✗ | ✓* | ✓ |

*Selon paramètres utilisateur

---

## 🔗 Relations

| Module | Relation |
|--------|----------|
| **Users** | Auteur, mentions, follows |
| **Horses** | Tags dans posts |
| **Analyses** | Partage résultats |
| **Gamification** | XP sur actions sociales |
| **Notifications** | Alertes sociales |
| **Marketplace** | Partage annonces |

---

## 📊 Métriques

- DAU/MAU (utilisateurs actifs)
- Posts créés par jour
- Taux d'engagement moyen
- Temps passé sur feed
- Messages envoyés
- Croissance followers réseau
- Taux de signalement
- Virality score (partages)

---

## 🎮 Gamification Sociale

| Action | XP |
|--------|-----|
| Publier un post | 30 |
| Recevoir 10 likes | 20 |
| Premier commentaire | 10 |
| Gagner 10 followers | 50 |
| Partager analyse | 40 |
| Post devient viral (100+ likes) | 200 |

