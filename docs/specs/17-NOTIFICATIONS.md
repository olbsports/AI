# 🔔 MODULE NOTIFICATIONS - Notifications & Alertes

## Description
Système centralisé de notifications push, email et in-app pour informer les utilisateurs des événements importants: analyses terminées, rappels santé, activité sociale, etc.

## Objectif Business
Maintenir l'engagement utilisateur et assurer qu'aucune information critique ne soit manquée.

---

## 📱 Écrans/Pages

### 1. Centre de Notifications (`/notifications`)
- Liste chronologique
- Filtres par type/lu/non-lu
- Actions en masse
- Badge compteur non-lus

### 2. Paramètres Notifications (`/settings/notifications`)
- Configuration par canal
- Configuration par type
- Heures calmes
- Fréquence digests

---

## 📨 Canaux de Notification

| Canal | Description | Disponibilité |
|-------|-------------|---------------|
| **Push** | Notification push mobile/web | Tous |
| **In-app** | Dans l'application | Tous |
| **Email** | Email individuel | Tous |
| **Email Digest** | Résumé périodique | Tous |
| **SMS** | Message texte | Premium |

---

## 🎯 Types de Notifications

### Analyses & Rapports
| Événement | Push | Email | In-app |
|-----------|------|-------|--------|
| Analyse terminée | ✓ | ✓ | ✓ |
| Analyse échouée | ✓ | ✓ | ✓ |
| Rapport généré | ✗ | ✓ | ✓ |
| Score record atteint | ✓ | ✗ | ✓ |

### Santé & Rappels
| Événement | Push | Email | In-app |
|-----------|------|-------|--------|
| Rappel santé (7j) | ✓ | ✓ | ✓ |
| Rappel santé (1j) | ✓ | ✗ | ✓ |
| Rappel dépassé | ✓ | ✓ | ✓ |
| RDV véto demain | ✓ | ✓ | ✓ |

### Calendrier
| Événement | Push | Email | In-app |
|-----------|------|-------|--------|
| Événement dans 24h | ✓ | ✗ | ✓ |
| Événement dans 1h | ✓ | ✗ | ✓ |
| Invitation événement | ✓ | ✓ | ✓ |
| Événement annulé | ✓ | ✓ | ✓ |

### Social
| Événement | Push | Email | In-app |
|-----------|------|-------|--------|
| Nouveau follower | ✓ | ✗ | ✓ |
| Like sur post | Config | ✗ | ✓ |
| Commentaire | ✓ | ✗ | ✓ |
| Mention | ✓ | ✓ | ✓ |
| Message privé | ✓ | Config | ✓ |

### Gamification
| Événement | Push | Email | In-app |
|-----------|------|-------|--------|
| Level up | ✓ | ✗ | ✓ |
| Badge débloqué | ✓ | ✗ | ✓ |
| Challenge terminé | ✓ | ✓ | ✓ |
| Récompense disponible | ✓ | ✓ | ✓ |

### Marketplace
| Événement | Push | Email | In-app |
|-----------|------|-------|--------|
| Nouvelle offre reçue | ✓ | ✓ | ✓ |
| Message acheteur | ✓ | ✓ | ✓ |
| Annonce vue (milestone) | ✗ | ✓ | ✓ |
| Prix baissé (alerte) | ✓ | ✓ | ✓ |

### Système
| Événement | Push | Email | In-app |
|-----------|------|-------|--------|
| Tokens faibles | ✓ | ✓ | ✓ |
| Abonnement expire | ✓ | ✓ | ✓ |
| Maintenance prévue | ✗ | ✓ | ✓ |
| Nouvelle fonctionnalité | ✗ | ✓ | ✓ |

---

## 🔄 Flux Utilisateur

### Recevoir une notification push
```
1. Événement déclencheur (ex: analyse terminée)
2. Système crée notification
3. Vérification préférences utilisateur
4. Si push activé + pas en heures calmes:
   - Envoi push via FCM/APNs
5. Utilisateur reçoit sur device
6. Click → deep link vers contenu
7. Notification marquée lue
```

### Configurer les notifications
```
1. Paramètres → Notifications
2. Vue par catégorie:
   - Analyses: [Push ✓] [Email ✓] [In-app ✓]
   - Social: [Push ✓] [Email ✗] [In-app ✓]
   - ...
3. Configuration globale:
   - Heures calmes: 22h-7h
   - Fréquence digest: Quotidien
4. Sauvegarder
```

### Gérer les notifications
```
1. Accès centre notifications
2. Liste avec indicateur non-lu
3. Actions:
   - Click → voir détail
   - Swipe → archiver
   - Menu → marquer lu/non-lu
4. Actions en masse:
   - Tout marquer comme lu
   - Supprimer les anciennes
```

---

## 💾 Modèle de Données

```typescript
interface Notification {
  id: string;                    // UUID v4
  userId: string;                // FK User destinataire
  organizationId: string;        // FK Organization

  // Type
  type: NotificationType;
  category: NotificationCategory;
  priority: 'low' | 'normal' | 'high' | 'urgent';

  // Contenu
  title: string;                 // Max 100
  body: string;                  // Max 500
  imageUrl?: string;

  // Action
  actionUrl?: string;            // Deep link
  actionType?: string;           // Type d'action
  actionData?: Record<string, any>;

  // Source
  sourceType?: string;           // 'analysis', 'horse', etc.
  sourceId?: string;             // ID de la source

  // Statut
  status: 'pending' | 'sent' | 'delivered' | 'read' | 'archived';
  readAt?: Date;
  archivedAt?: Date;

  // Canaux
  channels: {
    push?: {
      sent: boolean;
      sentAt?: Date;
      delivered?: boolean;
    };
    email?: {
      sent: boolean;
      sentAt?: Date;
      opened?: boolean;
    };
    sms?: {
      sent: boolean;
      sentAt?: Date;
    };
  };

  // Timestamps
  createdAt: Date;
  scheduledFor?: Date;           // Si programmée
  expiresAt?: Date;              // Expiration
}

interface NotificationPreferences {
  userId: string;                // FK User

  // Par catégorie
  categories: {
    [key in NotificationCategory]: {
      push: boolean;
      email: boolean;
      inApp: boolean;
      sms?: boolean;
    };
  };

  // Globales
  global: {
    enabled: boolean;
    quietHoursEnabled: boolean;
    quietHoursStart: string;     // "22:00"
    quietHoursEnd: string;       // "07:00"
    timezone: string;
  };

  // Digest
  digest: {
    enabled: boolean;
    frequency: 'daily' | 'weekly' | 'never';
    time: string;                // "09:00"
    includeCategories: NotificationCategory[];
  };

  // Spécifiques
  social: {
    likesFromFollowersOnly: boolean;
    mentionsFromFollowersOnly: boolean;
    messageFromFollowersOnly: boolean;
  };

  updatedAt: Date;
}

interface PushSubscription {
  id: string;
  userId: string;                // FK User
  platform: 'ios' | 'android' | 'web';
  token: string;                 // FCM/APNs token
  deviceId: string;
  deviceName?: string;
  appVersion?: string;
  isActive: boolean;
  lastUsedAt: Date;
  createdAt: Date;
}

interface EmailTemplate {
  id: string;
  type: NotificationType;
  locale: string;                // 'fr', 'en'
  subject: string;
  bodyHtml: string;
  bodyText: string;
  variables: string[];           // Variables disponibles
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

type NotificationType =
  // Analyses
  | 'analysis_completed'
  | 'analysis_failed'
  | 'report_ready'
  | 'score_record'
  // Santé
  | 'health_reminder_week'
  | 'health_reminder_day'
  | 'health_overdue'
  | 'appointment_reminder'
  // Calendrier
  | 'event_reminder'
  | 'event_invitation'
  | 'event_cancelled'
  // Social
  | 'new_follower'
  | 'post_liked'
  | 'post_commented'
  | 'user_mentioned'
  | 'new_message'
  // Gamification
  | 'level_up'
  | 'badge_unlocked'
  | 'challenge_completed'
  | 'reward_available'
  // Marketplace
  | 'new_offer'
  | 'listing_message'
  | 'listing_milestone'
  | 'price_alert'
  // Système
  | 'tokens_low'
  | 'subscription_expiring'
  | 'maintenance_scheduled'
  | 'new_feature';

type NotificationCategory =
  | 'analyses'
  | 'health'
  | 'calendar'
  | 'social'
  | 'gamification'
  | 'marketplace'
  | 'system';
```

---

## 🔌 API Endpoints

### Notifications
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/notifications` | Liste notifications |
| GET | `/notifications/unread-count` | Compteur non-lus |
| POST | `/notifications/:id/read` | Marquer lu |
| POST | `/notifications/:id/archive` | Archiver |
| POST | `/notifications/read-all` | Tout marquer lu |
| DELETE | `/notifications/:id` | Supprimer |

### Préférences
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/notifications/preferences` | Mes préférences |
| PATCH | `/notifications/preferences` | Modifier |
| POST | `/notifications/test` | Envoyer test |

### Push
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/push/subscribe` | Enregistrer device |
| DELETE | `/push/unsubscribe` | Désenregistrer |
| GET | `/push/devices` | Mes devices |

---

## 📧 Templates Email

### Analyse terminée
```
Sujet: 🎬 Votre analyse "{title}" est prête!

Bonjour {firstName},

L'analyse de votre vidéo "{title}" est maintenant disponible.

Score global: {score}/10

🐴 Cheval: {score_horse}/10
🏇 Cavalier: {score_rider}/10
💫 Harmonie: {score_harmony}/10

[Voir les résultats détaillés]

À bientôt sur HorseTempo!
```

### Rappel santé
```
Sujet: 💉 Rappel: {type} pour {horseName} dans {days} jours

Bonjour {firstName},

Un rappel santé arrive à échéance pour {horseName}:

📋 {type}
📅 Date prévue: {dueDate}
🩺 Dernier: {lastDate}

N'oubliez pas de prendre rendez-vous!

[Voir le carnet de santé]
```

### Digest quotidien
```
Sujet: 📊 Votre résumé HorseTempo du {date}

Bonjour {firstName},

Voici ce qui s'est passé aujourd'hui:

📈 Analyses
- 2 analyses terminées
- Score moyen: 7.5/10

❤️ Social
- 12 nouveaux likes
- 3 commentaires

🏆 Gamification
- +150 XP gagnés
- Badge "Assidu" débloqué!

[Voir tout dans l'app]
```

---

## ⏰ Heures Calmes

### Comportement
- Notifications push supprimées
- Notifications in-app stockées
- Emails différés ou digest
- Urgences passent quand même

### Exceptions (toujours envoyées)
- Urgence vétérinaire
- Problème sécurité compte
- Analyse échouée (pour retry)

---

## 🎨 États de l'Interface

### Badge compteur
- 0: Pas de badge
- 1-9: Chiffre exact
- 10+: "9+"
- 99+: "99+"

### Notification
- **Non lue**: Fond légèrement coloré
- **Lue**: Fond normal
- **Urgente**: Bordure rouge
- **Archivée**: Grisée

### Push
- **Haute priorité**: Son + vibration
- **Normale**: Son seul
- **Basse**: Silencieux

---

## 🔒 Permissions

| Action | Tous |
|--------|------|
| Recevoir notifications | ✓ |
| Configurer préférences | ✓ |
| Désactiver tout | ✓ |
| SMS notifications | Premium |

---

## 🔗 Relations

| Module | Relation |
|--------|----------|
| **Tous modules** | Source des notifications |
| **Users** | Destinataire + préférences |
| **Calendar** | Rappels événements |
| **Health** | Rappels santé |
| **Social** | Activité sociale |

---

## 📊 Métriques

- Taux de délivrabilité push
- Taux d'ouverture emails
- Taux de click-through
- Temps moyen avant lecture
- Notifications par utilisateur/jour
- Taux de désabonnement
- Types les plus engageants

---

## 🛠️ Infrastructure

### Services utilisés
- **FCM**: Firebase Cloud Messaging (Android/Web)
- **APNs**: Apple Push Notification service (iOS)
- **SendGrid/SES**: Emails transactionnels
- **Twilio**: SMS (premium)

### Queue
- Bull/Redis pour traitement asynchrone
- Retry automatique sur échec
- Rate limiting par canal

### Monitoring
- Alertes sur taux d'échec
- Dashboard temps réel
- Logs détaillés

