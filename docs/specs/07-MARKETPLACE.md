# 🏪 MODULE MARKETPLACE - Marché Équestre

## Description
Plateforme de petites annonces équestres permettant la vente de chevaux, la proposition de services de reproduction (étalons/juments), et l'échange d'équipements entre utilisateurs.

## Objectif Business
Créer un écosystème complet où les utilisateurs peuvent acheter, vendre et échanger dans le monde équestre, avec des données enrichies par les analyses HorseTempo.

---

## 📱 Écrans/Pages

### 1. Marketplace (`/marketplace`)
- Grille d'annonces avec photos
- Barre de recherche
- Filtres avancés (type, prix, race, âge, discipline, localisation)
- Tri (récent, prix, popularité)
- Carte géographique optionnelle
- Onglets: Tous, Chevaux à vendre, Étalons, Juments, Favoris

### 2. Détail Annonce (`/marketplace/:id`)
- Galerie photos/vidéos
- Informations complètes
- Prix et contact vendeur
- Lien vers fiche cheval HorseTempo (si dispo)
- Boutons: Contacter, Favoris, Partager, Signaler
- Annonces similaires

### 3. Créer Annonce (`/marketplace/new`)
- Sélection type (vente cheval, étalon, jument, équipement)
- Formulaire adapté au type
- Upload médias
- Preview avant publication

### 4. Mes Annonces (`/marketplace/my-listings`)
- Liste de mes annonces
- Statistiques (vues, contacts, favoris)
- Actions: Modifier, Désactiver, Supprimer

---

## 📦 Types d'Annonces

| Type | Code | Description | Champs spécifiques |
|------|------|-------------|-------------------|
| Vente cheval | `horse_sale` | Cheval à vendre | Prix, niveau, discipline |
| Étalon | `stallion` | Service de saillie | Prix saillie, conditions |
| Jument | `mare` | Jument pour reproduction | Statut reproductif |
| Location | `lease` | Cheval en location | Durée, conditions |
| Équipement | `equipment` | Matériel équestre | État, catégorie |

---

## 🔄 Flux Utilisateur

### Créer une annonce de vente
```
1. Click "Vendre un cheval"
2. Sélection cheval existant OU création nouveau
3. Si existant → pré-remplissage données
4. Informations annonce:
   - Titre accrocheur
   - Description détaillée
   - Prix (ou "Sur demande")
   - Localisation
5. Upload photos (5-20 recommandé)
6. Upload vidéos (optionnel)
7. Choix: Public / Membres HorseTempo uniquement
8. Options payantes: Featured, Boost
9. Preview → Publier
10. Annonce active immédiatement
```

### Contacter un vendeur
```
1. Click "Contacter le vendeur"
2. Formulaire de message
3. Option: Partager mon profil/analyses
4. Envoi → notification au vendeur
5. Conversation dans messagerie intégrée
```

### Proposer un étalon
```
1. Click "Proposer un étalon"
2. Sélection cheval (étalon)
3. Informations reproduction:
   - Prix saillie
   - Conditions (IAF, IAC, monte naturelle)
   - Disponibilités
   - Station de monte
4. Pedigree détaillé
5. Résultats sportifs / indices
6. Produits (si disponible)
7. Upload médias
8. Publier
```

---

## 💾 Modèle de Données

```typescript
interface MarketplaceListing {
  id: string;
  organizationId: string;
  createdById: string;

  // Type & Statut
  type: ListingType;
  status: 'draft' | 'active' | 'sold' | 'expired' | 'disabled';

  // Contenu
  title: string;                 // Max 200
  description: string;           // Max 5000

  // Média
  mediaUrls: string[];           // Photos/vidéos S3
  thumbnailUrl?: string;
  videoUrl?: string;

  // Prix
  price?: number;
  currency: string;              // Défaut: EUR
  priceNegotiable: boolean;
  priceOnRequest: boolean;

  // Localisation
  location: {
    country: string;             // ISO code
    region?: string;
    city?: string;
    postalCode?: string;
    coordinates?: {
      lat: number;
      lng: number;
    };
  };

  // Données cheval (si applicable)
  horseId?: string;              // FK Horse
  horseData?: {
    name: string;
    breed?: string;
    gender: string;
    dateOfBirth?: Date;
    heightCm?: number;
    color?: string;
    discipline?: string[];
    level?: string;
    pedigree?: object;
  };

  // Reproduction (étalons/juments)
  breeding?: {
    studFee?: number;
    conditions: string[];        // IAF, IAC, etc.
    station?: string;
    availableFrom?: Date;
    availableTo?: Date;
    reproductiveStatus?: 'maiden' | 'proven' | 'in_foal';
  };

  // Stats
  viewCount: number;
  favoriteCount: number;
  contactCount: number;

  // Options
  isFeatured: boolean;
  featuredUntil?: Date;

  // Dates
  publishedAt?: Date;
  expiresAt?: Date;
  soldAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

type ListingType =
  | 'horse_sale'
  | 'stallion'
  | 'mare'
  | 'lease'
  | 'equipment';

interface ListingContact {
  id: string;
  listingId: string;
  senderId: string;
  message: string;
  phone?: string;
  email?: string;
  createdAt: Date;
}

interface ListingFavorite {
  userId: string;
  listingId: string;
  createdAt: Date;
}
```

---

## 🔌 API Endpoints

### Listings
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/marketplace` | Liste avec filtres |
| GET | `/marketplace/search` | Recherche avancée |
| POST | `/marketplace` | Créer annonce |
| GET | `/marketplace/:id` | Détail annonce |
| PUT | `/marketplace/:id` | Modifier |
| DELETE | `/marketplace/:id` | Supprimer |
| POST | `/marketplace/:id/publish` | Publier |
| POST | `/marketplace/:id/disable` | Désactiver |
| POST | `/marketplace/:id/sold` | Marquer vendu |

### Interactions
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/marketplace/:id/favorite` | Ajouter favoris |
| DELETE | `/marketplace/:id/favorite` | Retirer favoris |
| POST | `/marketplace/:id/contact` | Contacter vendeur |
| POST | `/marketplace/:id/report` | Signaler |
| GET | `/marketplace/:id/similar` | Annonces similaires |

### Statistiques
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/marketplace/:id/stats` | Stats annonce |
| GET | `/marketplace/my-listings` | Mes annonces |
| GET | `/marketplace/favorites` | Mes favoris |

### Breeding
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/marketplace/stallions` | Étalons disponibles |
| GET | `/marketplace/mares` | Juments disponibles |
| GET | `/marketplace/breeding-matches/:mareId` | Recommandations IA |

---

## 🎨 États de l'Interface

### Liste
- **Loading**: Skeleton cards
- **Empty**: "Aucune annonce trouvée"
- **Filtered Empty**: "Modifiez vos filtres"

### Création
- **Draft**: Sauvegarde automatique
- **Validating**: Vérification médias
- **Publishing**: "Publication en cours..."
- **Published**: Toast + redirection

### Annonce
- **Active**: Badge vert
- **Featured**: Badge doré + position prioritaire
- **Sold**: Badge "Vendu" + grayed out
- **Expired**: Badge "Expirée"

---

## 💰 Options Payantes

| Option | Prix | Durée | Effet |
|--------|------|-------|-------|
| Featured | 50 tokens | 7 jours | Top des résultats |
| Super Featured | 100 tokens | 14 jours | Top + bandeau spécial |
| Boost | 30 tokens | 3 jours | +50% visibilité |
| Refresh | 10 tokens | - | Remonte en top |

---

## 🔒 Permissions

| Action | Owner | Admin | Analyst | Member | Viewer |
|--------|-------|-------|---------|--------|--------|
| Voir annonces | ✓ | ✓ | ✓ | ✓ | ✓ |
| Créer annonce | ✓ | ✓ | ✓ | ✓ | ✗ |
| Modifier sa annonce | ✓ | ✓ | ✓ | ✓ | ✗ |
| Contacter vendeur | ✓ | ✓ | ✓ | ✓ | ✗ |
| Signaler | ✓ | ✓ | ✓ | ✓ | ✓ |
| Modérer (admin) | ✗ | ✓ | ✗ | ✗ | ✗ |

---

## 🔗 Relations

| Module | Relation |
|--------|----------|
| **Horses** | Annonce liée à un cheval |
| **Users** | Vendeur, acheteur |
| **Tokens** | Options payantes |
| **EquiCote** | Valuation suggérée |
| **Breeding** | Recommandations IA |
| **Notifications** | Alertes favoris |

---

## 📊 Métriques

- Nombre d'annonces actives
- Temps moyen avant vente
- Taux de conversion contact → vente
- Annonces les plus vues
- Prix moyens par catégorie
- Répartition géographique
