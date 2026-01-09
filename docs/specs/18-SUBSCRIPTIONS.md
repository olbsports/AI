# 💳 MODULE SUBSCRIPTIONS - Abonnements & Facturation

## Description
Gestion complète des abonnements, facturation et paiements. Plans tarifaires, upgrades/downgrades, essais gratuits et facturation récurrente via Stripe.

## Objectif Business
Monétiser l'application via des abonnements récurrents offrant des fonctionnalités premium et générer des revenus prévisibles.

---

## 📱 Écrans/Pages

### 1. Page Tarifs (`/pricing`)
- Comparatif des plans
- Features par plan
- CTA inscription/upgrade
- FAQ tarifs

### 2. Mon Abonnement (`/settings/subscription`)
- Plan actuel
- Date renouvellement
- Historique factures
- Actions: upgrade, downgrade, annuler

### 3. Checkout (`/checkout/:planId`)
- Récapitulatif plan
- Formulaire paiement (Stripe)
- Application code promo
- Confirmation

### 4. Gestion Moyens de Paiement (`/settings/billing`)
- Cartes enregistrées
- Ajouter/Supprimer carte
- Carte par défaut

### 5. Factures (`/settings/invoices`)
- Liste factures
- Téléchargement PDF
- Statut paiement

---

## 📦 Plans d'Abonnement

### Plans B2C (Particuliers)

| Plan | Prix/mois | Prix/an | Tokens/mois | Features |
|------|-----------|---------|-------------|----------|
| **FREE** | 0€ | 0€ | 50 | Base |
| **STARTER** | 9,99€ | 99€ | 200 | + Rapports |
| **PRO** | 24,99€ | 249€ | 500 | + EquiCote, Breeding |
| **UNLIMITED** | 49,99€ | 499€ | 2000 | Tout illimité |

### Plans B2B (Clubs/Structures)

| Plan | Prix/mois | Members | Features |
|------|-----------|---------|----------|
| **CLUB_STARTER** | 49€ | 20 | Base club |
| **CLUB_PRO** | 149€ | 100 | + Analytics |
| **CLUB_ENTERPRISE** | 399€ | Illimité | + API, Support |

---

## 🎁 Features par Plan

### FREE
- ✓ 3 chevaux max
- ✓ 50 tokens/mois
- ✓ Analyses basiques
- ✓ Carnet de santé
- ✓ Social (lecture)
- ✗ Rapports PDF
- ✗ EquiCote
- ✗ Breeding AI
- ✗ Support prioritaire

### STARTER
- ✓ 10 chevaux
- ✓ 200 tokens/mois
- ✓ Analyses complètes
- ✓ Rapports PDF
- ✓ Export données
- ✓ Social complet
- ✗ EquiCote
- ✗ Breeding AI
- ✗ Support prioritaire

### PRO
- ✓ 50 chevaux
- ✓ 500 tokens/mois
- ✓ Analyses avancées
- ✓ EquiCote
- ✓ Breeding AI
- ✓ Marketplace prioritaire
- ✓ Analytics avancées
- ✓ Support prioritaire

### UNLIMITED
- ✓ Chevaux illimités
- ✓ 2000 tokens/mois
- ✓ Toutes fonctionnalités
- ✓ API accès (beta)
- ✓ Support dédié
- ✓ Fonctionnalités beta

---

## 🔄 Flux Utilisateur

### Souscrire un abonnement
```
1. Page tarifs ou CTA upgrade
2. Sélection du plan
3. Choix période: mensuel/annuel
4. Page checkout:
   - Récapitulatif
   - Code promo (optionnel)
   - Montant final
5. Informations paiement (Stripe Elements)
6. Validation paiement
7. Webhook Stripe → activation
8. Email confirmation
9. Redirection dashboard
```

### Upgrade de plan
```
1. Mon abonnement → "Changer de plan"
2. Sélection nouveau plan (supérieur)
3. Calcul prorata:
   - Crédit jours restants ancien plan
   - Prix nouveau plan
   - Montant à payer immédiat
4. Confirmation paiement
5. Upgrade immédiat
6. Nouvelles features disponibles
```

### Downgrade de plan
```
1. Mon abonnement → "Changer de plan"
2. Sélection plan inférieur
3. Avertissement:
   - Features perdues
   - Effectif à la fin de période
4. Confirmation
5. Statut: "Downgrade prévu le XX/XX"
6. À la date: nouveau plan actif
```

### Annuler abonnement
```
1. Mon abonnement → "Annuler"
2. Enquête de sortie (optionnel)
3. Proposition:
   - Pause 1 mois
   - Downgrade
   - Offre rétention (-20%)
4. Si confirmation:
   - Accès jusqu'à fin période payée
   - Puis passage à FREE
5. Email confirmation
```

### Gérer moyens de paiement
```
1. Paramètres → Facturation
2. Liste cartes:
   - **** **** **** 4242 (par défaut)
   - **** **** **** 1234
3. Actions:
   - Définir par défaut
   - Supprimer
4. Ajouter carte:
   - Formulaire Stripe Elements
   - Validation 3D Secure si requis
```

---

## 💾 Modèle de Données

```typescript
interface Subscription {
  id: string;                    // UUID v4
  organizationId: string;        // FK Organization

  // Plan
  planId: string;                // FK Plan
  planName: string;              // Dénormalisé
  planType: 'b2c' | 'b2b';

  // Période
  billingPeriod: 'monthly' | 'yearly';
  currentPeriodStart: Date;
  currentPeriodEnd: Date;

  // Statut
  status: SubscriptionStatus;
  cancelAtPeriodEnd: boolean;
  canceledAt?: Date;
  cancelReason?: string;

  // Paiement
  stripeSubscriptionId: string;
  stripeCustomerId: string;

  // Prix
  amount: number;                // En centimes
  currency: string;              // EUR

  // Réductions
  discountId?: string;
  discountPercent?: number;
  discountEndsAt?: Date;

  // Trial
  trialStart?: Date;
  trialEnd?: Date;

  // Changements prévus
  scheduledChange?: {
    newPlanId: string;
    effectiveDate: Date;
    type: 'upgrade' | 'downgrade';
  };

  // Timestamps
  createdAt: Date;
  updatedAt: Date;
}

interface Plan {
  id: string;
  name: string;                  // "PRO"
  displayName: string;           // "Plan Pro"
  description: string;
  type: 'b2c' | 'b2b';

  // Prix
  priceMonthly: number;          // En centimes
  priceYearly: number;
  currency: string;

  // Stripe
  stripePriceIdMonthly: string;
  stripePriceIdYearly: string;

  // Limites
  limits: {
    maxHorses: number | null;    // null = illimité
    tokensPerMonth: number;
    maxMembers?: number;         // Pour B2B
    maxStorage?: number;         // MB
  };

  // Features
  features: string[];            // IDs des features

  // Disponibilité
  isPublic: boolean;
  isAvailable: boolean;
  sortOrder: number;

  // Métadonnées
  metadata: Record<string, any>;

  createdAt: Date;
  updatedAt: Date;
}

interface Feature {
  id: string;
  name: string;                  // "equicote"
  displayName: string;           // "Valorisation EquiCote"
  description: string;
  category: string;              // "ai", "export", etc.
  isBoolean: boolean;            // Oui/Non ou quantité
}

interface Invoice {
  id: string;
  organizationId: string;        // FK Organization
  subscriptionId: string;        // FK Subscription

  // Stripe
  stripeInvoiceId: string;
  stripeInvoiceUrl?: string;
  stripePdfUrl?: string;

  // Montants
  subtotal: number;              // HT en centimes
  tax: number;                   // TVA
  total: number;                 // TTC
  amountPaid: number;
  amountDue: number;
  currency: string;

  // Période
  periodStart: Date;
  periodEnd: Date;

  // Statut
  status: InvoiceStatus;
  paidAt?: Date;

  // Lignes
  lines: InvoiceLine[];

  // Numéro
  number: string;                // "HT-2026-00001"

  createdAt: Date;
}

interface InvoiceLine {
  description: string;
  quantity: number;
  unitAmount: number;
  amount: number;
  periodStart?: Date;
  periodEnd?: Date;
}

interface PaymentMethod {
  id: string;
  organizationId: string;
  stripePaymentMethodId: string;

  type: 'card' | 'sepa_debit';

  // Si carte
  card?: {
    brand: string;               // "visa", "mastercard"
    last4: string;
    expMonth: number;
    expYear: number;
  };

  // Si SEPA
  sepaDebit?: {
    last4: string;
    bankCode?: string;
  };

  isDefault: boolean;

  createdAt: Date;
}

interface Coupon {
  id: string;
  code: string;                  // "WELCOME20"

  // Réduction
  discountType: 'percent' | 'fixed';
  discountValue: number;         // % ou centimes

  // Validité
  validFrom: Date;
  validUntil?: Date;
  maxRedemptions?: number;
  currentRedemptions: number;

  // Restrictions
  applicablePlans?: string[];    // Si vide = tous
  minPurchase?: number;
  firstTimeOnly: boolean;

  // Durée
  duration: 'once' | 'repeating' | 'forever';
  durationMonths?: number;       // Si repeating

  isActive: boolean;

  createdAt: Date;
}

type SubscriptionStatus =
  | 'trialing'
  | 'active'
  | 'past_due'
  | 'canceled'
  | 'unpaid'
  | 'paused';

type InvoiceStatus =
  | 'draft'
  | 'open'
  | 'paid'
  | 'void'
  | 'uncollectible';
```

---

## 🔌 API Endpoints

### Plans
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/plans` | Liste des plans |
| GET | `/plans/:id` | Détail plan |
| GET | `/plans/compare` | Comparatif |

### Abonnement
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/subscription` | Mon abonnement |
| POST | `/subscription` | Créer abonnement |
| POST | `/subscription/upgrade` | Upgrade |
| POST | `/subscription/downgrade` | Downgrade |
| POST | `/subscription/cancel` | Annuler |
| POST | `/subscription/resume` | Reprendre |
| POST | `/subscription/pause` | Mettre en pause |

### Paiement
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/billing/checkout` | Créer session checkout |
| GET | `/billing/portal` | URL portail Stripe |
| GET | `/billing/payment-methods` | Mes moyens paiement |
| POST | `/billing/payment-methods` | Ajouter carte |
| DELETE | `/billing/payment-methods/:id` | Supprimer |
| POST | `/billing/payment-methods/:id/default` | Définir par défaut |

### Factures
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/invoices` | Liste factures |
| GET | `/invoices/:id` | Détail facture |
| GET | `/invoices/:id/pdf` | Télécharger PDF |
| GET | `/invoices/upcoming` | Prochaine facture |

### Coupons
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/coupons/validate` | Valider un code |
| POST | `/coupons/apply` | Appliquer coupon |

---

## 💰 Intégration Stripe

### Webhooks écoutés
```typescript
// Abonnement
'customer.subscription.created'
'customer.subscription.updated'
'customer.subscription.deleted'
'customer.subscription.trial_will_end'

// Factures
'invoice.paid'
'invoice.payment_failed'
'invoice.finalized'

// Paiement
'payment_intent.succeeded'
'payment_intent.payment_failed'
'payment_method.attached'
'payment_method.detached'

// Client
'customer.created'
'customer.updated'
'customer.deleted'
```

### Checkout Session
- Mode: `subscription`
- Payment method types: `card`, `sepa_debit`
- Allow promotion codes: `true`
- Success URL: `/checkout/success`
- Cancel URL: `/checkout/cancel`

---

## 🎁 Essai Gratuit

### Configuration
- Durée: 14 jours
- Plan: PRO
- Carte requise: Oui (mais pas débitée)
- Annulation facile

### Flux
```
1. Inscription
2. Sélection "Essayer gratuitement"
3. Ajout carte (non débitée)
4. Accès PRO pendant 14j
5. J-3: Email rappel
6. J-1: Email dernier rappel
7. J0: Conversion automatique en payant
   (sauf si annulé)
```

---

## 🎨 États de l'Interface

### Abonnement
- **Active**: Badge vert "Actif"
- **Trialing**: Badge bleu "Essai - X jours restants"
- **Past Due**: Badge orange "Paiement en attente"
- **Canceled**: Badge gris "Annulé le XX/XX"
- **Paused**: Badge jaune "En pause"

### Checkout
- **Loading**: Skeleton formulaire
- **Ready**: Formulaire Stripe Elements
- **Processing**: Spinner + "Traitement..."
- **Success**: Checkmark + redirection
- **Error**: Message + bouton réessayer

### Facture
- **Paid**: Badge vert + date
- **Open**: Badge orange "En attente"
- **Void**: Badge gris "Annulée"

---

## 🔒 Permissions

| Action | FREE | STARTER+ | Admin |
|--------|------|----------|-------|
| Voir son abonnement | ✓ | ✓ | ✓ |
| Upgrade | ✓ | ✓ | ✓ |
| Downgrade | ✓ | ✓ | ✓ |
| Annuler | ✓ | ✓ | ✓ |
| Gérer cartes | ✓ | ✓ | ✓ |
| Voir factures | ✓ | ✓ | ✓ |

---

## 🔗 Relations

| Module | Relation |
|--------|----------|
| **Organizations** | 1-1 |
| **Tokens** | Allocation mensuelle |
| **Features** | Accès par plan |
| **Invoices** | Historique factures |
| **Notifications** | Alertes paiement |

---

## 📊 Métriques

- MRR (Monthly Recurring Revenue)
- ARR (Annual Recurring Revenue)
- Churn rate
- LTV (Lifetime Value)
- Conversion trial → paid
- ARPU (Average Revenue Per User)
- Répartition par plan
- Taux d'échec paiement

---

## 🛡️ Sécurité & Conformité

### PCI DSS
- Aucune donnée carte stockée côté serveur
- Stripe Elements pour saisie sécurisée
- 3D Secure 2 activé

### RGPD
- Consentement explicite
- Droit à la portabilité (export factures)
- Suppression données sur demande

### SCA (Strong Customer Authentication)
- 3D Secure obligatoire pour paiements européens
- Gestion automatique par Stripe

