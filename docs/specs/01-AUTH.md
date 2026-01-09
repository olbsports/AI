# 🔐 MODULE AUTH - Authentification

## Description
Module complet de gestion d'authentification incluant inscription, connexion, récupération de mot de passe, vérification email, 2FA et gestion de profil.

## Objectif Business
Sécuriser l'accès à l'application et gérer les identités des utilisateurs avec support multi-organisation.

---

## 📱 Écrans/Pages

### 1. Login (`/auth/login`)
- Champ email
- Champ mot de passe
- Bouton "Se connecter"
- Lien "Mot de passe oublié"
- Lien "Créer un compte"
- Option "Se souvenir de moi"

### 2. Register (`/auth/register`)
- Champ prénom
- Champ nom
- Champ email
- Champ mot de passe
- Champ confirmation mot de passe
- Champ nom d'organisation
- Checkbox CGU
- Bouton "S'inscrire"

### 3. Forgot Password (`/auth/forgot-password`)
- Champ email
- Bouton "Envoyer le lien"
- Lien retour connexion

### 4. Reset Password (`/auth/reset-password?token=XXX`)
- Champ nouveau mot de passe
- Champ confirmation
- Bouton "Réinitialiser"

### 5. Verify Email (`/auth/verify-email?token=XXX`)
- Page de confirmation
- Bouton "Continuer vers le dashboard"

---

## 👤 Rôles Utilisateur

| Rôle | Description | Permissions principales |
|------|-------------|-------------------------|
| **OWNER** | Propriétaire de l'organisation | Accès complet, facturation |
| **ADMIN** | Administrateur | Gestion équipe, paramètres |
| **ANALYST** | Analyste | Création analyses, gestion chevaux |
| **VETERINARIAN** | Vétérinaire | Avis experts, radiologies |
| **MEMBER** | Membre | Lecture, partage limité |
| **VIEWER** | Observateur | Lecture seule |

---

## 🔄 Flux Utilisateur

### Inscription
```
1. Visite /auth/register
2. Remplit le formulaire (email, mot de passe, nom, organisation)
3. Validation côté client (format email, force mot de passe)
4. POST /auth/register
5. Création User + Organization en base
6. Email de vérification envoyé
7. Redirection page "Vérifiez votre email"
8. Click lien dans email → GET /auth/verify-email?token=XXX
9. emailVerified = true
10. Redirection dashboard
```

### Connexion
```
1. Visite /auth/login
2. Saisit email + mot de passe
3. POST /auth/login
4. Vérification credentials (bcrypt)
5. Si 2FA activé → demande code TOTP
6. Génération JWT tokens:
   - accessToken (expire: 15 min)
   - refreshToken (expire: 7 jours)
7. Stockage localStorage
8. Redirection dashboard
9. Mise à jour lastLoginAt
```

### Reset Password
```
1. Visite /auth/forgot-password
2. Saisit email
3. POST /auth/forgot-password
4. Email avec lien reset (token valide 1h)
5. Click lien → /auth/reset-password?token=XXX
6. Nouveau mot de passe
7. POST /auth/reset-password
8. Token invalidé
9. Redirection login
```

---

## 💾 Modèle de Données

```typescript
interface User {
  id: string;                    // UUID v4
  email: string;                 // Unique, indexed, lowercase
  emailVerified: boolean;        // Défaut: false
  firstName: string;             // 1-100 caractères
  lastName: string;              // 1-100 caractères
  avatarUrl?: string;            // URL S3
  passwordHash: string;          // bcrypt hash
  role: UserRole;                // Enum
  organizationId: string;        // FK vers Organization
  mfaEnabled: boolean;           // Défaut: false
  mfaSecret?: string;            // Secret TOTP
  lastLoginAt?: Date;
  locale: string;                // Défaut: 'fr-FR'
  timezone: string;              // Défaut: 'Europe/Paris'
  theme: 'light' | 'dark' | 'system';
  createdAt: Date;
  updatedAt: Date;
}

interface Organization {
  id: string;
  name: string;
  slug: string;                  // URL-friendly, unique
  ownerId: string;               // FK vers User
  logoUrl?: string;
  createdAt: Date;
  updatedAt: Date;
}

interface RefreshToken {
  id: string;
  userId: string;
  token: string;                 // Hash du token
  expiresAt: Date;
  createdAt: Date;
}
```

---

## 🔌 API Endpoints

| Méthode | Endpoint | Description | Auth |
|---------|----------|-------------|------|
| POST | `/auth/register` | Inscription | Non |
| POST | `/auth/login` | Connexion | Non |
| POST | `/auth/logout` | Déconnexion | Oui |
| POST | `/auth/refresh` | Rafraîchir token | Non |
| GET | `/auth/me` | Profil courant | Oui |
| PATCH | `/auth/profile` | Modifier profil | Oui |
| POST | `/auth/profile/photo` | Upload avatar | Oui |
| POST | `/auth/forgot-password` | Demander reset | Non |
| POST | `/auth/reset-password` | Reset mot de passe | Non |
| POST | `/auth/change-password` | Changer mot de passe | Oui |
| GET | `/auth/verify-email` | Vérifier email | Non |
| POST | `/auth/resend-verification` | Renvoyer verif | Non |
| POST | `/auth/2fa/enable` | Activer 2FA | Oui |
| POST | `/auth/2fa/disable` | Désactiver 2FA | Oui |
| POST | `/auth/2fa/verify` | Vérifier code 2FA | Oui |

---

## ✅ Validations

### Email
- Format valide (regex)
- Unicité en base
- Conversion lowercase automatique
- Max 255 caractères

### Mot de passe
- Minimum 8 caractères
- Au moins 1 majuscule
- Au moins 1 chiffre
- Au moins 1 caractère spécial (!@#$%^&*)
- Ne peut pas contenir l'email
- Ne peut pas être un mot de passe commun (liste noire)

### Prénom / Nom
- Minimum 1 caractère
- Maximum 100 caractères
- Alphanumériques + espaces + accents

### Organisation
- Minimum 2 caractères
- Maximum 255 caractères

---

## 🎨 États de l'Interface

### Loading
- Bouton désactivé avec spinner
- Champs en readonly
- Message "Connexion en cours..."

### Success
- Toast notification vert
- Redirection automatique
- Animation de transition

### Error
- Message d'erreur sous le champ concerné
- Bordure rouge sur le champ
- Toast notification rouge (erreur serveur)

### Messages d'erreur courants
| Code | Message |
|------|---------|
| `invalid_credentials` | "Email ou mot de passe incorrect" |
| `email_not_verified` | "Veuillez vérifier votre email" |
| `account_disabled` | "Ce compte a été désactivé" |
| `too_many_attempts` | "Trop de tentatives, réessayez dans 15 min" |
| `weak_password` | "Le mot de passe ne respecte pas les critères" |
| `email_taken` | "Cet email est déjà utilisé" |

---

## 🔒 Sécurité

### Tokens JWT
- **Access Token**: 15 minutes, stocké en mémoire
- **Refresh Token**: 7 jours, stocké localStorage
- Algorithme: RS256
- Claims: userId, organizationId, role, exp, iat

### Rate Limiting
- Login: 5 tentatives / 15 min par IP
- Register: 3 comptes / heure par IP
- Password reset: 3 demandes / heure par email

### 2FA (TOTP)
- Algorithme: SHA1
- Période: 30 secondes
- Digits: 6
- Compatible Google Authenticator, Authy

### Sessions
- Maximum 5 sessions actives par utilisateur
- Expiration automatique après 30 jours d'inactivité
- Possibilité de révoquer toutes les sessions

---

## 🔗 Relations avec autres modules

| Module | Type de relation |
|--------|------------------|
| **Organizations** | 1-N (User appartient à une org) |
| **Horses** | Créateur/Modificateur |
| **Analyses** | Créateur |
| **Notifications** | Destinataire |
| **Subscriptions** | Via Organization |
| **Tokens** | Via Organization |

---

## 📊 Métriques à tracker

- Taux d'inscription
- Taux de vérification email
- Taux de connexion réussie
- Temps moyen de session
- Taux d'adoption 2FA
- Nombre de reset password
