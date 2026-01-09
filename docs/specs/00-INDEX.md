# 🐴 HORSE TEMPO - Spécifications Fonctionnelles Complètes

## 📋 Index des Modules

Ce dossier contient la documentation exhaustive de toutes les fonctionnalités de l'application HorseTempo / Horse Vision AI.

### 📁 Structure des Documents

| Fichier | Module | Description |
|---------|--------|-------------|
| [01-AUTH.md](./01-AUTH.md) | Authentification | Connexion, inscription, 2FA, reset password |
| [02-HORSES.md](./02-HORSES.md) | Chevaux | Gestion complète des chevaux, profils, santé |
| [03-RIDERS.md](./03-RIDERS.md) | Cavaliers | Gestion des cavaliers, stats, assignations |
| [04-ANALYSES.md](./04-ANALYSES.md) | Analyses IA | Analyse vidéo de parcours, locomotion |
| [05-REPORTS.md](./05-REPORTS.md) | Rapports | Génération PDF, visualisation, partage |
| [06-RADIOLOGIE.md](./06-RADIOLOGIE.md) | Radiologie | Analyse radiologique IA |
| [07-MARKETPLACE.md](./07-MARKETPLACE.md) | Marketplace | Achat/vente équestre |
| [08-BREEDING.md](./08-BREEDING.md) | Reproduction | Étalons, juments, recommandations IA |
| [09-EQUICOTE.md](./09-EQUICOTE.md) | Valorisation | Estimation valeur des chevaux |
| [10-GESTATION.md](./10-GESTATION.md) | Gestation | Suivi de gestation |
| [11-CLUBS.md](./11-CLUBS.md) | Clubs | Clubs, challenges, events |
| [12-GAMIFICATION.md](./12-GAMIFICATION.md) | Gamification | Points, badges, niveaux |
| [13-SOCIAL.md](./13-SOCIAL.md) | Social | Réseau social, publications |
| [14-SERVICES.md](./14-SERVICES.md) | Prestataires | Vétérinaires, maréchaux |
| [15-CALENDAR.md](./15-CALENDAR.md) | Calendrier | Planning, événements, objectifs |
| [16-LEADERBOARD.md](./16-LEADERBOARD.md) | Classements | Rankings, compétitions |
| [17-NOTIFICATIONS.md](./17-NOTIFICATIONS.md) | Notifications | Push, in-app |
| [18-SUBSCRIPTIONS.md](./18-SUBSCRIPTIONS.md) | Abonnements | Plans, facturation |
| [19-TOKENS.md](./19-TOKENS.md) | Tokens | Système de crédits |
| [20-AMELIORATIONS.md](./20-AMELIORATIONS.md) | Améliorations | Suggestions d'amélioration |
| [21-GUIDE-PRATIQUE.md](./21-GUIDE-PRATIQUE.md) | Guide | Utilisation pratique |
| [22-MONETISATION.md](./22-MONETISATION.md) | Monétisation | Stratégie financière |

---

## 🏗️ Architecture Technique

### Applications
- **apps/mobile** - Application Flutter (iOS/Android)
- **apps/api** - Backend NestJS
- **apps/web** - Frontend Next.js
- **apps/admin** - Dashboard administrateur

### Packages partagés
- **packages/types** - Types TypeScript
- **packages/core** - Logique métier
- **packages/ui** - Design System
- **packages/api-client** - Client API
- **packages/config** - Configuration

---

## 📊 Vue d'ensemble des Plans

| Plan | Prix | Chevaux | Analyses/mois | Tokens |
|------|------|---------|---------------|--------|
| FREE | 0€ | 1 | 3 | 0 |
| STARTER | 19€ | 3 | 15 | 50 |
| RIDER | 39€ | 10 | 50 | 150 |
| CHAMPION | 79€ | 25 | 150 | 500 |
| PRO | 149€ | 50 | ∞ | 1500 |
| ELITE | 299€ | ∞ | ∞ | 5000 |
| ENTERPRISE | Custom | ∞ | ∞ | Custom |

---

## 🔗 Ressources

- Plan de développement: [PLAN-DEVELOPPEMENT-COMPLET.md](../../PLAN-DEVELOPPEMENT-COMPLET.md)
- Rapport de cohérence: [COHERENCE_REPORT.md](../../COHERENCE_REPORT.md)
- Audit de code: [COMPREHENSIVE_CODE_AUDIT_REPORT.md](../../COMPREHENSIVE_CODE_AUDIT_REPORT.md)

---

*Généré le 9 janvier 2026*
