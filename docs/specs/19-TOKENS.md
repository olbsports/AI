# 🪙 MODULE TOKENS - Système de Crédits

## Description
Système de crédits (tokens) pour consommer les services IA payants: analyses vidéo, analyses radio, rapports, recommandations breeding et valorisations EquiCote.

## Objectif Business
Monétiser les fonctionnalités IA à l'usage au-delà des quotas d'abonnement, permettant une flexibilité pour les utilisateurs occasionnels ou intensifs.

---

## 📱 Écrans/Pages

### 1. Mon Solde (`/tokens` ou widget dashboard)
- Solde actuel
- Tokens inclus restants (abonnement)
- Tokens achetés restants
- Bouton "Acheter des tokens"

### 2. Boutique Tokens (`/tokens/buy`)
- Packs disponibles
- Prix et bonus
- Méthodes de paiement
- Historique achats

### 3. Historique (`/tokens/history`)
- Transactions détaillées
- Filtres: type, date
- Export CSV

### 4. Utilisation (`/tokens/usage`)
- Graphique consommation
- Par type de service
- Tendances mensuelles

---

## 🪙 Système de Tokens

### Allocation par abonnement (mensuel)

| Plan | Tokens/mois |
|------|-------------|
| FREE | 50 |
| STARTER | 200 |
| PRO | 500 |
| UNLIMITED | 2000 |

### Renouvellement
- Tokens d'abonnement: remis à zéro chaque mois
- Tokens achetés: jamais d'expiration
- Consommation: d'abord inclus, puis achetés

---

## 💰 Packs d'Achat

| Pack | Tokens | Prix | Bonus | €/token |
|------|--------|------|-------|---------|
| **Starter** | 100 | 9,99€ | - | 0,10€ |
| **Standard** | 300 | 24,99€ | +10% | 0,076€ |
| **Pro** | 600 | 44,99€ | +20% | 0,063€ |
| **Business** | 1500 | 99,99€ | +30% | 0,051€ |
| **Enterprise** | 5000 | 299,99€ | +40% | 0,043€ |

---

## 📊 Coûts par Service

### Analyses Vidéo

| Type | Tokens | Description |
|------|--------|-------------|
| VIDEO_BASIC | 50 | Analyse simple (30s max) |
| VIDEO_STANDARD | 100 | Analyse complète (1-2min) |
| VIDEO_PARCOURS | 150 | Analyse parcours CSO |
| VIDEO_ADVANCED | 250 | Analyse ultra-détaillée |
| LOCOMOTION | 100 | Focus biomécanique |

### Analyses Radiologiques

| Type | Tokens | Description |
|------|--------|-------------|
| RADIO_SIMPLE | 150 | 1-3 clichés |
| RADIO_COMPLETE | 300 | 4-10 clichés |
| RADIO_EXPERT | 500 | + Validation expert |

### Rapports

| Type | Tokens | Description |
|------|--------|-------------|
| HORSE_PROFILE | 25 | Fiche cheval PDF |
| ANALYSIS_REPORT | 50 | Rapport analyse |
| HEALTH_REPORT | 30 | Historique santé |
| PROGRESSION_REPORT | 75 | Évolution temps |
| SALE_REPORT | 100 | Dossier vente complet |
| BREEDING_REPORT | 75 | Pedigree + recommandations |

### Autres Services

| Service | Tokens | Description |
|---------|--------|-------------|
| EQUICOTE_STANDARD | 100 | Valorisation basique |
| EQUICOTE_PREMIUM | 200 | + Certificat |
| BREEDING_RECOMMEND | 200 | Recommandations étalons |
| BREEDING_MATCH | 50 | Détail match |

---

## 🔄 Flux Utilisateur

### Consommer des tokens
```
1. Utilisateur lance une analyse (ex: VIDEO_STANDARD)
2. Vérification solde:
   - Tokens inclus disponibles? → utiliser
   - Sinon tokens achetés disponibles? → utiliser
   - Sinon → erreur "Solde insuffisant"
3. Réservation tokens (pending)
4. Traitement service
5. Si succès: tokens débités (consumed)
6. Si échec: tokens remboursés
```

### Acheter des tokens
```
1. Boutique → Sélection pack
2. Récapitulatif:
   - Pack Standard: 300 tokens
   - Bonus: +30 tokens
   - Prix: 24,99€
3. Paiement (Stripe)
4. Succès → tokens crédités immédiatement
5. Email confirmation
6. Historique mis à jour
```

### Vérifier le solde avant action
```
1. Modal pré-analyse affiche:
   - "Cette analyse coûte 150 tokens"
   - "Votre solde: 45 inclus + 200 achetés"
2. Si suffisant → bouton "Lancer l'analyse"
3. Si insuffisant:
   - Montant manquant
   - Bouton "Acheter des tokens"
   - Lien vers boutique
```

---

## 💾 Modèle de Données

```typescript
interface TokenBalance {
  id: string;                    // UUID v4
  organizationId: string;        // FK Organization (unique)

  // Soldes
  includedBalance: number;       // Tokens d'abonnement restants
  purchasedBalance: number;      // Tokens achetés restants
  totalBalance: number;          // Computed

  // Période abonnement
  includedPeriodStart: Date;
  includedPeriodEnd: Date;
  includedMonthlyQuota: number;  // Quota du plan

  // Stats
  totalConsumed: number;         // Historique total consommé
  totalPurchased: number;        // Historique total acheté

  updatedAt: Date;
}

interface TokenTransaction {
  id: string;                    // UUID v4
  organizationId: string;        // FK Organization
  userId?: string;               // FK User (qui a déclenché)

  // Type
  type: TransactionType;
  direction: 'credit' | 'debit';

  // Montant
  amount: number;                // Positif
  balanceType: 'included' | 'purchased';
  balanceAfter: number;

  // Source
  source?: {
    type: string;                // 'analysis', 'report', 'purchase'
    id: string;                  // ID de l'entité
    name?: string;               // Description
  };

  // Achat (si applicable)
  purchase?: {
    packId: string;
    packName: string;
    baseTokens: number;
    bonusTokens: number;
    amount: number;              // Prix en centimes
    currency: string;
    stripePaymentIntentId?: string;
  };

  // Statut
  status: TransactionStatus;
  failureReason?: string;

  // Notes
  description?: string;
  metadata?: Record<string, any>;

  createdAt: Date;
}

interface TokenPack {
  id: string;
  name: string;                  // "Standard"
  description: string;

  // Tokens
  baseTokens: number;            // Tokens de base
  bonusPercent: number;          // % bonus
  totalTokens: number;           // Computed

  // Prix
  price: number;                 // En centimes
  currency: string;

  // Stripe
  stripePriceId: string;

  // Disponibilité
  isActive: boolean;
  isPopular: boolean;            // Badge "Populaire"
  sortOrder: number;

  // Restrictions
  minPurchase?: number;          // Quantité min
  maxPurchase?: number;          // Par transaction
  limitPerMonth?: number;        // Par organisation

  createdAt: Date;
  updatedAt: Date;
}

interface TokenReservation {
  id: string;                    // UUID v4
  organizationId: string;        // FK Organization
  transactionId?: string;        // FK TokenTransaction quand confirmé

  // Réservation
  amount: number;
  serviceType: string;           // 'VIDEO_STANDARD', etc.
  serviceId: string;             // ID de l'analyse/rapport

  // Statut
  status: 'pending' | 'confirmed' | 'released' | 'expired';
  expiresAt: Date;               // Auto-release après X minutes

  createdAt: Date;
  confirmedAt?: Date;
  releasedAt?: Date;
}

type TransactionType =
  | 'subscription_credit'        // Crédit mensuel abonnement
  | 'purchase'                   // Achat de pack
  | 'consumption'                // Utilisation service
  | 'refund'                     // Remboursement
  | 'bonus'                      // Bonus promotionnel
  | 'transfer'                   // Transfert (admin)
  | 'adjustment'                 // Ajustement manuel
  | 'expiration';                // Expiration (si applicable)

type TransactionStatus =
  | 'pending'                    // En cours
  | 'completed'                  // Terminé
  | 'failed'                     // Échoué
  | 'refunded';                  // Remboursé
```

---

## 🔌 API Endpoints

### Solde
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/tokens/balance` | Mon solde |
| GET | `/tokens/estimate/:service` | Estimation coût |
| POST | `/tokens/check` | Vérifier disponibilité |

### Transactions
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/tokens/transactions` | Historique |
| GET | `/tokens/transactions/:id` | Détail transaction |
| GET | `/tokens/usage` | Statistiques usage |
| GET | `/tokens/usage/export` | Export CSV |

### Achats
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/tokens/packs` | Liste des packs |
| POST | `/tokens/purchase` | Acheter un pack |
| GET | `/tokens/purchases` | Mes achats |

### Admin
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/admin/tokens/credit` | Créditer tokens |
| POST | `/admin/tokens/debit` | Débiter tokens |
| GET | `/admin/tokens/stats` | Statistiques globales |

---

## 🔔 Alertes & Notifications

### Seuils d'alerte
| Seuil | Notification |
|-------|--------------|
| < 50 tokens | "Solde faible - pensez à recharger" |
| < 20 tokens | "Solde très faible" |
| 0 tokens | "Solde épuisé - rechargez pour continuer" |

### Rappels
- Renouvellement tokens inclus: notification J+1
- Non-utilisation 30j: "Vos tokens vous attendent!"

---

## 🧮 Logique de Consommation

### Ordre de consommation
```typescript
function consumeTokens(amount: number): boolean {
  // 1. D'abord les tokens inclus (perdus en fin de mois)
  if (balance.includedBalance >= amount) {
    balance.includedBalance -= amount;
    return true;
  }

  // 2. Puis les tokens achetés (jamais d'expiration)
  const remaining = amount - balance.includedBalance;
  if (balance.purchasedBalance >= remaining) {
    balance.includedBalance = 0;
    balance.purchasedBalance -= remaining;
    return true;
  }

  // 3. Insuffisant
  return false;
}
```

### Réservation (anti-concurrence)
```typescript
async function reserveTokens(amount: number, serviceId: string) {
  // Créer réservation avec TTL (10 min)
  const reservation = await createReservation({
    amount,
    serviceId,
    expiresAt: Date.now() + 10 * 60 * 1000
  });

  // Déduire temporairement du solde visible
  await updateVisibleBalance();

  return reservation.id;
}

async function confirmReservation(reservationId: string) {
  // Convertir en transaction définitive
  await createTransaction(...);
  await deleteReservation(reservationId);
}

async function releaseReservation(reservationId: string) {
  // Annuler et restaurer solde
  await deleteReservation(reservationId);
  await updateVisibleBalance();
}
```

---

## 🎨 États de l'Interface

### Widget solde
- **Vert**: > 100 tokens
- **Orange**: 20-100 tokens
- **Rouge**: < 20 tokens
- **Gris**: 0 tokens

### Transaction
- **Crédit**: Vert avec +
- **Débit**: Rouge avec -
- **Pending**: Gris italique
- **Failed**: Rouge barré

### Achat
- **Processing**: Spinner
- **Success**: Checkmark + nouveau solde
- **Failed**: Message erreur

---

## 🔒 Permissions

| Action | Tous | Admin | Super Admin |
|--------|------|-------|-------------|
| Voir son solde | ✓ | ✓ | ✓ |
| Acheter tokens | ✓ | ✓ | ✓ |
| Voir historique | ✓ | ✓ | ✓ |
| Créditer tokens | ✗ | ✗ | ✓ |
| Voir stats globales | ✗ | ✓ | ✓ |

---

## 🔗 Relations

| Module | Relation |
|--------|----------|
| **Subscriptions** | Quota mensuel |
| **Analyses** | Consommation |
| **Reports** | Consommation |
| **Radiology** | Consommation |
| **EquiCote** | Consommation |
| **Breeding** | Consommation |
| **Notifications** | Alertes solde |

---

## 📊 Métriques

- Tokens vendus par mois
- Revenu tokens
- Tokens consommés vs non utilisés (inclus)
- Répartition par type de service
- Taux de conversion insuffisance → achat
- LTV tokens par utilisateur
- Packs les plus populaires

---

## 💡 Stratégies de Monétisation

### Prix psychologique
- Pack "Standard" comme ancre
- Pack "Pro" comme meilleur rapport qualité/prix
- Affichage économie en %

### Incitations
- Premier achat: -20% avec code WELCOME
- Bonus fidélité après 3 achats
- Packs saisonniers (Noël, etc.)

### Anti-friction
- Paiement en 1 clic (carte sauvegardée)
- Suggestion contextuelle ("Il vous manque 50 tokens")
- Achat rapide depuis modal analyse

