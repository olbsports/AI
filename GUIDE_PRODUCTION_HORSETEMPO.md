# 🐴 HORSE TEMPO - GUIDE DE PRODUCTION ULTRA-COMPLET

> **Version:** 1.0.0
> **Date:** 9 Janvier 2026
> **Auteur:** Équipe Technique Horse Tempo
> **Statut:** Document de référence officiel

---

## 📋 TABLE DES MATIÈRES

1. [Vue d'ensemble du projet](#1-vue-densemble-du-projet)
2. [Architecture technique](#2-architecture-technique)
3. [Prérequis et environnement](#3-prérequis-et-environnement)
4. [Configuration Base de Données](#4-configuration-base-de-données)
5. [Configuration API Backend](#5-configuration-api-backend)
6. [Configuration Application Mobile](#6-configuration-application-mobile)
7. [Configuration Application Admin](#7-configuration-application-admin)
8. [Services Externes](#8-services-externes)
9. [Sécurité](#9-sécurité)
10. [Déploiement](#10-déploiement)
11. [Monitoring et Logs](#11-monitoring-et-logs)
12. [Tests](#12-tests)
13. [UI/UX Détaillé](#13-uiux-détaillé)
14. [Fonctionnalités Détaillées](#14-fonctionnalités-détaillées)
15. [Checklist Production](#15-checklist-production)
16. [Troubleshooting](#16-troubleshooting)
17. [Maintenance](#17-maintenance)

---

# 1. VUE D'ENSEMBLE DU PROJET

## 1.1 Qu'est-ce que Horse Tempo?

Horse Tempo est une **plateforme complète de gestion équine** avec intelligence artificielle, comprenant:

- **Application Mobile** (iOS/Android) - Flutter
- **Application Admin** (Web) - Flutter Web
- **API Backend** - NestJS
- **Base de données** - PostgreSQL/MySQL + Redis

## 1.2 Fonctionnalités Principales

| Module | Description | Priorité |
|--------|-------------|----------|
| **Gestion Chevaux** | CRUD complet, pedigree, identification SIRE | Critique |
| **Analyses Vidéo IA** | Locomotion, performance, CSO, dressage | Critique |
| **Santé** | Carnet de santé, vaccins, rappels | Haute |
| **Marketplace** | Vente, location, reproduction | Haute |
| **Reproduction** | Suivi gestation, breeding match IA | Moyenne |
| **Social** | Feed, posts, likes, follows | Moyenne |
| **Gamification** | XP, badges, leaderboards, challenges | Moyenne |
| **Nutrition** | Plans alimentaires IA | Basse |
| **Planning** | Calendrier, entraînements | Basse |

## 1.3 Stack Technique Complet

```
┌─────────────────────────────────────────────────────────────┐
│                    HORSE TEMPO STACK                        │
├─────────────────────────────────────────────────────────────┤
│ FRONTEND MOBILE                                             │
│ ├─ Framework: Flutter 3.19+                                 │
│ ├─ State: Riverpod 2.6.1                                    │
│ ├─ Navigation: GoRouter 13.2.0                              │
│ ├─ HTTP: Dio 5.4.0                                          │
│ ├─ Storage: flutter_secure_storage + SharedPreferences      │
│ └─ UI: Material Design 3 + Custom Theme                     │
├─────────────────────────────────────────────────────────────┤
│ FRONTEND ADMIN                                              │
│ ├─ Framework: Flutter Web                                   │
│ ├─ Charts: Syncfusion + fl_chart                            │
│ └─ Tables: data_table_2                                     │
├─────────────────────────────────────────────────────────────┤
│ BACKEND API                                                 │
│ ├─ Framework: NestJS 10.3.0                                 │
│ ├─ ORM: Prisma 5.8.1                                        │
│ ├─ Auth: JWT + Passport + bcrypt                            │
│ ├─ Validation: class-validator                              │
│ ├─ Queue: Bull + Redis                                      │
│ ├─ Email: Nodemailer / Resend                               │
│ └─ Docs: Swagger/OpenAPI                                    │
├─────────────────────────────────────────────────────────────┤
│ INTELLIGENCE ARTIFICIELLE                                   │
│ ├─ LLM Principal: Anthropic Claude (Sonnet 4)               │
│ ├─ LLM Fallback: OpenAI GPT-4                               │
│ ├─ Vision: Claude Vision API                                │
│ └─ Cache: Redis + AIAnalysisCache table                     │
├─────────────────────────────────────────────────────────────┤
│ BASE DE DONNÉES                                             │
│ ├─ Principal: PostgreSQL 16 / MySQL 8                       │
│ ├─ Cache: Redis 7                                           │
│ └─ ORM: Prisma (64 modèles)                                 │
├─────────────────────────────────────────────────────────────┤
│ SERVICES EXTERNES                                           │
│ ├─ Paiements: Stripe                                        │
│ ├─ Stockage: AWS S3 / MinIO                                 │
│ ├─ Email: Resend.com / SMTP                                 │
│ ├─ Monitoring: Sentry                                       │
│ └─ CDN: CloudFront (optionnel)                              │
├─────────────────────────────────────────────────────────────┤
│ INFRASTRUCTURE                                              │
│ ├─ Containers: Docker + Docker Compose                      │
│ ├─ Reverse Proxy: Nginx                                     │
│ ├─ SSL: Let's Encrypt / Certbot                             │
│ ├─ CI/CD: GitHub Actions                                    │
│ └─ Hosting: VPS / AWS / GCP                                 │
└─────────────────────────────────────────────────────────────┘
```

## 1.4 Modèle de Données Simplifié

```
User (1) ──────────────────────── (N) Horse
  │                                     │
  │ organizationId                      │ horseId
  ▼                                     ▼
Organization (1) ─────────────── (N) Analysis
                                        │
                                        │ analysisId
                                        ▼
                                     Report

Marketplace:
Horse (1) ────────────────────── (N) MarketplaceListing
                                        │
                                        │ listingId
                                        ▼
                                   EquiCote + EquiTrace

Social:
User (1) ──────────────────────── (N) Post
User (N) ──────────────────────── (N) Follow
User (N) ──────────────────────── (N) Like
```

---

# 2. ARCHITECTURE TECHNIQUE

## 2.1 Diagramme d'Architecture Production

```
                         ┌─────────────────┐
                         │   INTERNET      │
                         └────────┬────────┘
                                  │
                         ┌────────▼────────┐
                         │   CLOUDFLARE    │  ← CDN + DDoS Protection
                         │   (Optionnel)   │
                         └────────┬────────┘
                                  │
                         ┌────────▼────────┐
                         │     NGINX       │  ← Reverse Proxy + SSL
                         │   Port 80/443   │
                         └────────┬────────┘
                                  │
            ┌─────────────────────┼─────────────────────┐
            │                     │                     │
   ┌────────▼────────┐   ┌───────▼───────┐   ┌────────▼────────┐
   │  FRONTEND WEB   │   │   API NESTJS  │   │   ADMIN WEB     │
   │  (Flutter Web)  │   │   Port 4000   │   │  (Flutter Web)  │
   │  /app/*         │   │   /api/*      │   │  /admin/*       │
   └─────────────────┘   └───────┬───────┘   └─────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌────────▼────────┐    ┌────────▼────────┐    ┌────────▼────────┐
│   POSTGRESQL    │    │     REDIS       │    │    AWS S3       │
│   Port 5432     │    │   Port 6379     │    │   (Fichiers)    │
│   (Données)     │    │  (Cache+Queue)  │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │
┌────────▼────────┐
│  PRISMA STUDIO  │  ← Administration DB (dev only)
│   Port 5555     │
└─────────────────┘

SERVICES EXTERNES:
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│    STRIPE       │  │   ANTHROPIC     │  │    RESEND       │
│   (Paiements)   │  │     (IA)        │  │    (Email)      │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

## 2.2 Flux de Données Utilisateur

```
1. AUTHENTIFICATION
   Mobile App → POST /auth/login → API → Prisma → PostgreSQL
                                    ↓
                              JWT Token généré
                                    ↓
                              Stocké SecureStorage
                                    ↓
                              Token envoyé dans headers

2. ANALYSE VIDÉO
   Mobile App → Upload Video → S3 Bucket
                                    ↓
                              POST /analyses → API
                                    ↓
                              Bull Queue Job créé
                                    ↓
                              Worker → Anthropic Claude
                                    ↓
                              Résultat → PostgreSQL
                                    ↓
                              Push Notification → Mobile

3. MARKETPLACE
   Mobile App → GET /marketplace → API → Prisma → PostgreSQL
                                    ↓
                              Cache Redis (5min TTL)
                                    ↓
                              Réponse JSON → App
```

## 2.3 Structure des Dossiers

```
/home/user/AI/
├── apps/
│   ├── api/                          # Backend NestJS
│   │   ├── src/
│   │   │   ├── modules/              # Modules métier
│   │   │   │   ├── auth/             # Authentification
│   │   │   │   ├── users/            # Gestion utilisateurs
│   │   │   │   ├── horses/           # Gestion chevaux
│   │   │   │   ├── analysis/         # Analyses IA
│   │   │   │   ├── billing/          # Facturation Stripe
│   │   │   │   ├── marketplace/      # Marketplace
│   │   │   │   ├── health/           # Santé chevaux
│   │   │   │   ├── breeding/         # Reproduction
│   │   │   │   ├── gamification/     # XP, badges
│   │   │   │   ├── social/           # Posts, follows
│   │   │   │   ├── ai/               # Services IA
│   │   │   │   ├── admin/            # Admin endpoints
│   │   │   │   └── ...
│   │   │   ├── prisma/               # Configuration Prisma
│   │   │   ├── common/               # Guards, filters, pipes
│   │   │   ├── config/               # Configuration app
│   │   │   └── main.ts               # Entry point
│   │   ├── prisma/
│   │   │   ├── schema.prisma         # Schéma DB
│   │   │   ├── seed.ts               # Données initiales
│   │   │   └── migrations/           # Migrations DB
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   └── tsconfig.json
│   │
│   ├── mobile/                       # App Mobile Flutter
│   │   ├── lib/
│   │   │   ├── main.dart             # Entry point
│   │   │   ├── app.dart              # Configuration app + routes
│   │   │   ├── screens/              # Écrans UI
│   │   │   │   ├── auth/             # Login, Register
│   │   │   │   ├── dashboard/        # Accueil
│   │   │   │   ├── horses/           # Gestion chevaux
│   │   │   │   ├── analyses/         # Analyses
│   │   │   │   ├── marketplace/      # Marketplace
│   │   │   │   ├── settings/         # Paramètres
│   │   │   │   └── ...
│   │   │   ├── providers/            # State Riverpod
│   │   │   ├── services/             # API, Storage
│   │   │   ├── models/               # Classes de données
│   │   │   ├── widgets/              # Composants réutilisables
│   │   │   └── theme/                # Thème app
│   │   ├── android/                  # Config Android
│   │   ├── ios/                      # Config iOS
│   │   └── pubspec.yaml
│   │
│   └── admin/                        # App Admin Flutter Web
│       ├── lib/
│       │   ├── screens/
│       │   │   ├── dashboard/
│       │   │   ├── users/
│       │   │   ├── subscriptions/
│       │   │   ├── moderation/
│       │   │   └── support/
│       │   └── ...
│       └── pubspec.yaml
│
├── docker-compose.yml                # Dev environment
├── docker-compose.prod.yml           # Prod environment
├── nginx.conf                        # Nginx config
├── package.json                      # Monorepo root
├── turbo.json                        # Turborepo config
└── .env.example                      # Variables d'environnement
```

---

# 3. PRÉREQUIS ET ENVIRONNEMENT

## 3.1 Prérequis Serveur Production

### Minimum Recommandé
```
CPU:        4 vCPU
RAM:        8 GB
Stockage:   100 GB SSD
OS:         Ubuntu 22.04 LTS
Bande:      100 Mbps
```

### Recommandé pour Scale
```
CPU:        8 vCPU
RAM:        16 GB
Stockage:   250 GB SSD NVMe
OS:         Ubuntu 22.04 LTS
Bande:      1 Gbps
```

## 3.2 Logiciels à Installer

### Sur le serveur de production:

```bash
# 1. Mise à jour système
sudo apt update && sudo apt upgrade -y

# 2. Installer les outils de base
sudo apt install -y curl wget git htop nano ufw fail2ban

# 3. Installer Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 4. Installer Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 5. Installer Node.js 20 (pour scripts)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# 6. Installer pnpm
npm install -g pnpm

# 7. Installer Nginx
sudo apt install -y nginx

# 8. Installer Certbot (SSL)
sudo apt install -y certbot python3-certbot-nginx

# 9. Vérifier installations
docker --version          # Docker version 24.x+
docker-compose --version  # Docker Compose version 2.x+
node --version            # v20.x+
pnpm --version            # 8.x+
nginx -v                  # nginx/1.18+
```

## 3.3 Configuration Firewall

```bash
# Activer UFW
sudo ufw enable

# Autoriser SSH (IMPORTANT: ne pas se bloquer!)
sudo ufw allow 22/tcp

# Autoriser HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Vérifier les règles
sudo ufw status verbose

# Résultat attendu:
# Status: active
# To                         Action      From
# --                         ------      ----
# 22/tcp                     ALLOW       Anywhere
# 80/tcp                     ALLOW       Anywhere
# 443/tcp                    ALLOW       Anywhere
```

## 3.4 Configuration Fail2Ban (Protection SSH)

```bash
# Créer configuration custom
sudo nano /etc/fail2ban/jail.local
```

Contenu:
```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 86400
```

```bash
# Redémarrer fail2ban
sudo systemctl restart fail2ban
sudo systemctl enable fail2ban

# Vérifier status
sudo fail2ban-client status sshd
```

## 3.5 Variables d'Environnement Complètes

Créer le fichier `.env` sur le serveur:

```bash
sudo mkdir -p /var/www/horsetempo
sudo nano /var/www/horsetempo/.env
```

### Fichier .env COMPLET avec explications:

```bash
# ============================================================
# HORSE TEMPO - CONFIGURATION PRODUCTION
# ============================================================
# ⚠️ ATTENTION: Ne JAMAIS commiter ce fichier!
# ⚠️ Changer TOUTES les valeurs par défaut avant production!
# ============================================================

# ------------------------------------------------------------
# 1. ENVIRONNEMENT
# ------------------------------------------------------------
NODE_ENV=production
# Options: development, staging, production
# Impact: Active/désactive debug, swagger, logs détaillés

PORT=4000
# Port d'écoute de l'API NestJS
# Note: Nginx redirigera le trafic externe vers ce port

API_PREFIX=api
# Préfixe des routes API (ex: /api/auth/login)

# ------------------------------------------------------------
# 2. BASE DE DONNÉES POSTGRESQL
# ------------------------------------------------------------
DATABASE_URL="postgresql://horsetempo:CHANGE_MOT_DE_PASSE_ICI@localhost:5432/horsetempo_prod?schema=public"
# Format: postgresql://USER:PASSWORD@HOST:PORT/DATABASE?schema=SCHEMA
#
# ⚠️ SÉCURITÉ:
# - Utiliser un mot de passe fort (32+ caractères)
# - Ne jamais utiliser 'postgres' comme user en prod
# - Créer un user dédié avec permissions limitées

# Alternatives si MySQL:
# DATABASE_URL="mysql://horsetempo:PASSWORD@localhost:3306/horsetempo_prod"

# ------------------------------------------------------------
# 3. REDIS (Cache + Queue)
# ------------------------------------------------------------
REDIS_URL="redis://localhost:6379"
# Format: redis://[:PASSWORD@]HOST:PORT

REDIS_PASSWORD=""
# Mot de passe Redis (optionnel mais recommandé en prod)
# Si défini, mettre à jour REDIS_URL: redis://:PASSWORD@localhost:6379

# ------------------------------------------------------------
# 4. JWT AUTHENTIFICATION
# ------------------------------------------------------------
JWT_SECRET="CHANGER_CETTE_VALEUR_PAR_UNE_CLE_ALEATOIRE_DE_64_CARACTERES_MINIMUM"
# ⚠️ CRITIQUE: Doit être unique et aléatoire!
# Générer avec: openssl rand -base64 64
# Impact: Signature de tous les tokens d'authentification

JWT_REFRESH_SECRET="AUTRE_CLE_DIFFERENTE_DE_64_CARACTERES_MINIMUM_POUR_REFRESH"
# ⚠️ CRITIQUE: Doit être différent de JWT_SECRET!
# Générer avec: openssl rand -base64 64

JWT_EXPIRES_IN="15m"
# Durée de validité du token d'accès
# Options: 5m, 15m, 30m, 1h
# Recommandé: 15m pour sécurité optimale

JWT_REFRESH_EXPIRES_IN="7d"
# Durée de validité du token de refresh
# Options: 1d, 7d, 30d
# Recommandé: 7d pour équilibre sécurité/UX

# ------------------------------------------------------------
# 5. CORS (Cross-Origin Resource Sharing)
# ------------------------------------------------------------
CORS_ORIGINS="https://app.horsetempo.app,https://admin.horsetempo.app"
# Liste des domaines autorisés, séparés par des virgules
# ⚠️ NE JAMAIS utiliser * en production!
#
# Exemples valides:
# - https://app.horsetempo.app
# - https://admin.horsetempo.app
# - https://staging.horsetempo.app
#
# Note: L'app mobile n'est PAS affectée par CORS

FRONTEND_URL="https://app.horsetempo.app"
# URL de l'application frontend principale
# Utilisé pour: emails, redirections, liens de partage

ADMIN_URL="https://admin.horsetempo.app"
# URL de l'interface d'administration

# ------------------------------------------------------------
# 6. STRIPE (Paiements)
# ------------------------------------------------------------
STRIPE_SECRET_KEY="sk_live_VOTRE_CLE_STRIPE_LIVE"
# Clé secrète Stripe (commence par sk_live_ en prod)
# ⚠️ NE JAMAIS exposer côté client!
# Trouver sur: https://dashboard.stripe.com/apikeys

STRIPE_PUBLISHABLE_KEY="pk_live_VOTRE_CLE_PUBLIQUE_STRIPE"
# Clé publique Stripe (peut être exposée côté client)

STRIPE_WEBHOOK_SECRET="whsec_VOTRE_SECRET_WEBHOOK"
# Secret pour valider les webhooks Stripe
# Configurer sur: https://dashboard.stripe.com/webhooks
# Endpoint: https://api.horsetempo.app/api/webhooks/stripe

# IDs des produits/prix Stripe
STRIPE_PRICE_PREMIUM_MONTHLY="price_XXXXX"
STRIPE_PRICE_PREMIUM_YEARLY="price_XXXXX"
STRIPE_PRICE_PRO_MONTHLY="price_XXXXX"
STRIPE_PRICE_PRO_YEARLY="price_XXXXX"

# ------------------------------------------------------------
# 7. AWS S3 (Stockage fichiers)
# ------------------------------------------------------------
AWS_ACCESS_KEY_ID="AKIAXXXXXXXXXXXXXXXX"
# Access Key ID de votre compte AWS IAM
# Créer sur: https://console.aws.amazon.com/iam/

AWS_SECRET_ACCESS_KEY="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
# Secret Access Key correspondant
# ⚠️ Ne s'affiche qu'une fois à la création!

AWS_REGION="eu-west-3"
# Région AWS du bucket S3
# Options FR: eu-west-3 (Paris), eu-west-1 (Irlande)

AWS_S3_BUCKET="horsetempo-production"
# Nom du bucket S3
# Convention: [projet]-[environnement]

AWS_CLOUDFRONT_DOMAIN=""
# (Optionnel) Domaine CloudFront pour CDN
# Ex: d1234567890.cloudfront.net
# Améliore les performances de chargement des médias

# Alternative MinIO (self-hosted S3):
# MINIO_ENDPOINT="http://localhost:9000"
# MINIO_ACCESS_KEY="minioadmin"
# MINIO_SECRET_KEY="minioadmin"
# MINIO_BUCKET="horsetempo"

# ------------------------------------------------------------
# 8. EMAIL (Transactionnel)
# ------------------------------------------------------------
# Option A: Resend.com (Recommandé)
RESEND_API_KEY="re_XXXXXXXXXXXXXXXXXXXXX"
# Clé API Resend
# Créer sur: https://resend.com/api-keys

EMAIL_FROM="Horse Tempo <noreply@horsetempo.app>"
# Adresse d'expéditeur des emails
# Format: "Nom <email@domain.com>"
# ⚠️ Le domaine doit être vérifié dans Resend

# Option B: SMTP classique
# SMTP_HOST="smtp.gmail.com"
# SMTP_PORT=587
# SMTP_USER="votre-email@gmail.com"
# SMTP_PASS="votre-app-password"
# SMTP_SECURE=false

# ------------------------------------------------------------
# 9. INTELLIGENCE ARTIFICIELLE
# ------------------------------------------------------------
ANTHROPIC_API_KEY="sk-ant-XXXXXXXXXXXXXXXXXXXXX"
# Clé API Anthropic (Claude)
# Créer sur: https://console.anthropic.com/
# ⚠️ Surveiller les coûts! Claude Sonnet = $3/$15 par 1M tokens

OPENAI_API_KEY="sk-XXXXXXXXXXXXXXXXXXXXX"
# (Optionnel) Clé API OpenAI pour fallback
# Utilisé si Anthropic échoue

AI_MODEL_PRIMARY="claude-sonnet-4-20250514"
# Modèle Claude à utiliser
# Options: claude-sonnet-4-20250514, claude-3-haiku-20240307

AI_MODEL_FALLBACK="gpt-4-turbo-preview"
# Modèle de fallback

AI_CACHE_TTL=604800
# Durée de cache des analyses IA en secondes (7 jours)

# ------------------------------------------------------------
# 10. MONITORING (Optionnel mais recommandé)
# ------------------------------------------------------------
SENTRY_DSN="https://xxx@xxx.ingest.sentry.io/xxx"
# DSN Sentry pour tracking des erreurs
# Créer projet sur: https://sentry.io/

LOG_LEVEL="info"
# Niveau de log: debug, info, warn, error
# Production: info ou warn

# ------------------------------------------------------------
# 11. RATE LIMITING
# ------------------------------------------------------------
THROTTLE_TTL=60
# Fenêtre de temps en secondes

THROTTLE_LIMIT=100
# Nombre max de requêtes par fenêtre

# ------------------------------------------------------------
# 12. DIVERS
# ------------------------------------------------------------
TZ="Europe/Paris"
# Fuseau horaire du serveur

BCRYPT_ROUNDS=12
# Nombre de rounds bcrypt pour hash mots de passe
# Plus élevé = plus sécurisé mais plus lent
# Recommandé: 12 (équilibre sécurité/performance)
```

---

# 4. CONFIGURATION BASE DE DONNÉES

## 4.1 Installation PostgreSQL

### Option A: Via Docker (Recommandé)

Le fichier `docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: horsetempo-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: horsetempo
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: horsetempo_prod
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups
    ports:
      - "127.0.0.1:5432:5432"  # Exposé uniquement en local!
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U horsetempo -d horsetempo_prod"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - horsetempo-network

  redis:
    image: redis:7-alpine
    container_name: horsetempo-redis
    restart: unless-stopped
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    ports:
      - "127.0.0.1:6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - horsetempo-network

volumes:
  postgres_data:
  redis_data:

networks:
  horsetempo-network:
    driver: bridge
```

### Démarrer les services:

```bash
cd /var/www/horsetempo

# Créer le fichier de mots de passe
echo "DB_PASSWORD=$(openssl rand -base64 32)" >> .env
echo "REDIS_PASSWORD=$(openssl rand -base64 32)" >> .env

# Démarrer
docker-compose -f docker-compose.prod.yml up -d postgres redis

# Vérifier
docker-compose -f docker-compose.prod.yml ps
```

## 4.2 Migrations Prisma

### ⚠️ AVERTISSEMENT CRITIQUE

```
╔════════════════════════════════════════════════════════════════╗
║  ⚠️  DANGER: ACTUELLEMENT AUCUNE MIGRATION N'EXISTE!           ║
║                                                                 ║
║  Le projet utilise `prisma db push --accept-data-loss`         ║
║  qui peut DÉTRUIRE des données en production!                   ║
║                                                                 ║
║  AVANT DE DÉPLOYER EN PRODUCTION:                              ║
║  1. Créer la migration initiale                                ║
║  2. Tester sur environnement staging                           ║
║  3. Backup complet de la base                                  ║
╚════════════════════════════════════════════════════════════════╝
```

### Créer la première migration:

```bash
cd /var/www/horsetempo/apps/api

# 1. Générer la migration initiale
npx prisma migrate dev --name initial_schema

# 2. Vérifier les fichiers générés
ls -la prisma/migrations/

# 3. Appliquer en production (⚠️ BACKUP D'ABORD!)
npx prisma migrate deploy
```

### Structure des migrations:

```
apps/api/prisma/migrations/
├── 20260109000000_initial_schema/
│   └── migration.sql
├── 20260110000000_add_marketplace_indexes/
│   └── migration.sql
└── migration_lock.toml
```

### Commandes Prisma essentielles:

```bash
# Développement: créer migration + appliquer
npx prisma migrate dev --name nom_de_la_migration

# Production: appliquer les migrations existantes
npx prisma migrate deploy

# Générer le client Prisma
npx prisma generate

# Voir l'état des migrations
npx prisma migrate status

# Reset complet (⚠️ DÉTRUIT TOUTES LES DONNÉES!)
npx prisma migrate reset

# Ouvrir Prisma Studio (interface graphique)
npx prisma studio
```

## 4.3 Backup Base de Données

### Script de backup automatique:

```bash
sudo nano /var/www/horsetempo/scripts/backup-db.sh
```

```bash
#!/bin/bash
# ============================================================
# Horse Tempo - Script de Backup PostgreSQL
# ============================================================

# Configuration
BACKUP_DIR="/var/www/horsetempo/backups"
CONTAINER_NAME="horsetempo-db"
DB_NAME="horsetempo_prod"
DB_USER="horsetempo"
RETENTION_DAYS=30

# Créer le dossier de backup si nécessaire
mkdir -p $BACKUP_DIR

# Nom du fichier avec date
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/horsetempo_$TIMESTAMP.sql.gz"

# Effectuer le backup
echo "🔄 Démarrage du backup..."
docker exec $CONTAINER_NAME pg_dump -U $DB_USER $DB_NAME | gzip > $BACKUP_FILE

# Vérifier le résultat
if [ $? -eq 0 ]; then
    echo "✅ Backup créé: $BACKUP_FILE"
    echo "📦 Taille: $(du -h $BACKUP_FILE | cut -f1)"
else
    echo "❌ Erreur lors du backup!"
    exit 1
fi

# Supprimer les anciens backups
echo "🗑️ Suppression des backups > $RETENTION_DAYS jours..."
find $BACKUP_DIR -name "horsetempo_*.sql.gz" -mtime +$RETENTION_DAYS -delete

# Lister les backups restants
echo "📋 Backups disponibles:"
ls -lh $BACKUP_DIR/*.sql.gz 2>/dev/null || echo "Aucun backup trouvé"

echo "✅ Backup terminé!"
```

```bash
# Rendre exécutable
chmod +x /var/www/horsetempo/scripts/backup-db.sh

# Tester
/var/www/horsetempo/scripts/backup-db.sh
```

### Cron pour backup automatique:

```bash
# Éditer crontab
sudo crontab -e

# Ajouter (backup tous les jours à 3h du matin)
0 3 * * * /var/www/horsetempo/scripts/backup-db.sh >> /var/log/horsetempo-backup.log 2>&1
```

### Restaurer un backup:

```bash
#!/bin/bash
# restore-db.sh

BACKUP_FILE=$1
CONTAINER_NAME="horsetempo-db"
DB_NAME="horsetempo_prod"
DB_USER="horsetempo"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: ./restore-db.sh <backup_file.sql.gz>"
    exit 1
fi

echo "⚠️ ATTENTION: Ceci va REMPLACER toutes les données actuelles!"
read -p "Continuer? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Annulé."
    exit 0
fi

echo "🔄 Restauration en cours..."
gunzip -c $BACKUP_FILE | docker exec -i $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME

echo "✅ Restauration terminée!"
```

## 4.4 Optimisation Base de Données

### Indexes recommandés (à ajouter dans schema.prisma):

```prisma
// Dans schema.prisma, vérifier que ces indexes existent:

model Horse {
  // ... champs ...

  @@index([organizationId])          // Filtrage par org
  @@index([status])                  // Filtrage par statut
  @@index([createdAt])               // Tri par date
  @@index([organizationId, status])  // Combo fréquent
}

model Analysis {
  // ... champs ...

  @@index([horseId])
  @@index([status])
  @@index([createdAt])
  @@index([horseId, status])
}

model MarketplaceListing {
  // ... champs ...

  @@index([status])
  @@index([type])
  @@index([createdAt])
  @@index([status, type])
  @@index([organizationId])
}

model User {
  // ... champs ...

  @@index([email])
  @@index([organizationId])
  @@index([role])
}
```

---

# 5. CONFIGURATION API BACKEND

## 5.1 Build et Déploiement

### Structure du Dockerfile optimisé:

```dockerfile
# apps/api/Dockerfile
# ============================================================
# Horse Tempo API - Dockerfile Production
# ============================================================

# Stage 1: Dependencies
FROM node:20-alpine AS deps
WORKDIR /app

# Installer pnpm
RUN npm install -g pnpm

# Copier les fichiers de dépendances
COPY package.json pnpm-lock.yaml ./
COPY apps/api/package.json ./apps/api/

# Installer les dépendances
RUN pnpm install --frozen-lockfile --prod=false

# Stage 2: Build
FROM node:20-alpine AS builder
WORKDIR /app

RUN npm install -g pnpm

# Copier depuis deps
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/apps/api/node_modules ./apps/api/node_modules

# Copier le code source
COPY . .

# Générer Prisma Client
RUN cd apps/api && npx prisma generate

# Build l'application
RUN cd apps/api && pnpm build

# Stage 3: Production
FROM node:20-alpine AS runner
WORKDIR /app

# Créer user non-root pour sécurité
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nestjs

# Copier uniquement ce qui est nécessaire
COPY --from=builder /app/apps/api/dist ./dist
COPY --from=builder /app/apps/api/node_modules ./node_modules
COPY --from=builder /app/apps/api/package.json ./
COPY --from=builder /app/apps/api/prisma ./prisma

# Changer le propriétaire
RUN chown -R nestjs:nodejs /app

# Utiliser l'user non-root
USER nestjs

# Exposer le port
EXPOSE 4000

# Variables d'environnement
ENV NODE_ENV=production
ENV PORT=4000

# Commande de démarrage
CMD ["node", "dist/main.js"]
```

### Build et test local:

```bash
cd /var/www/horsetempo

# Build l'image
docker build -t horsetempo-api:latest -f apps/api/Dockerfile .

# Tester localement
docker run --rm -p 4000:4000 --env-file .env horsetempo-api:latest

# Vérifier que l'API répond
curl http://localhost:4000/api/health
```

## 5.2 Configuration NestJS Détaillée

### main.ts - Point d'entrée:

```typescript
// apps/api/src/main.ts
import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import helmet from 'helmet';
import * as compression from 'compression';
import { AppModule } from './app.module';

async function bootstrap() {
  const logger = new Logger('Bootstrap');

  // Créer l'application
  const app = await NestFactory.create(AppModule, {
    logger: ['error', 'warn', 'log', 'debug'],
  });

  const configService = app.get(ConfigService);
  const port = configService.get('PORT', 4000);
  const nodeEnv = configService.get('NODE_ENV', 'development');

  // ============================================================
  // SÉCURITÉ
  // ============================================================

  // Helmet pour les headers de sécurité
  app.use(helmet({
    contentSecurityPolicy: nodeEnv === 'production',
    crossOriginEmbedderPolicy: false,
  }));

  // CORS
  const corsOrigins = configService.get('CORS_ORIGINS', '').split(',');
  app.enableCors({
    origin: corsOrigins,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
    credentials: true,
    maxAge: 86400, // 24 heures
  });

  // ============================================================
  // VALIDATION
  // ============================================================

  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,              // Supprime les props non déclarées
    forbidNonWhitelisted: true,   // Erreur si props inconnues
    transform: true,              // Transforme les types
    transformOptions: {
      enableImplicitConversion: true,
    },
    disableErrorMessages: nodeEnv === 'production',
  }));

  // ============================================================
  // COMPRESSION
  // ============================================================

  app.use(compression());

  // ============================================================
  // PREFIX API
  // ============================================================

  app.setGlobalPrefix('api');

  // ============================================================
  // SWAGGER (Désactivé en production)
  // ============================================================

  if (nodeEnv !== 'production') {
    const config = new DocumentBuilder()
      .setTitle('Horse Tempo API')
      .setDescription('API documentation for Horse Tempo')
      .setVersion('1.0')
      .addBearerAuth()
      .build();

    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api/docs', app, document);

    logger.log('📚 Swagger disponible sur /api/docs');
  }

  // ============================================================
  // DÉMARRAGE
  // ============================================================

  await app.listen(port);

  logger.log(`🚀 Horse Tempo API démarré sur le port ${port}`);
  logger.log(`📍 Environnement: ${nodeEnv}`);
  logger.log(`🔗 URL: http://localhost:${port}/api`);
}

bootstrap();
```

## 5.3 Structure des Modules

### Module Auth (Authentification):

```
apps/api/src/modules/auth/
├── auth.module.ts           # Module NestJS
├── auth.controller.ts       # Endpoints REST
├── auth.service.ts          # Logique métier
├── dto/
│   ├── login.dto.ts         # Validation login
│   ├── register.dto.ts      # Validation inscription
│   ├── change-password.dto.ts
│   ├── forgot-password.dto.ts
│   └── reset-password.dto.ts
├── guards/
│   ├── jwt-auth.guard.ts    # Protection JWT
│   ├── roles.guard.ts       # Protection par rôle
│   └── organization.guard.ts # Protection par org
├── strategies/
│   └── jwt.strategy.ts      # Stratégie Passport
└── decorators/
    ├── roles.decorator.ts
    ├── current-user.decorator.ts
    └── organization.decorator.ts
```

### Endpoints Auth disponibles:

| Méthode | Endpoint | Description | Auth |
|---------|----------|-------------|------|
| POST | /api/auth/login | Connexion | Non |
| POST | /api/auth/register | Inscription | Non |
| POST | /api/auth/refresh | Refresh token | Non |
| POST | /api/auth/forgot-password | Demande reset | Non |
| POST | /api/auth/reset-password | Reset mdp | Non |
| POST | /api/auth/change-password | Changer mdp | Oui |
| GET | /api/auth/me | Profil actuel | Oui |
| POST | /api/auth/logout | Déconnexion | Oui |

## 5.4 Gestion des Erreurs

### Global Exception Filter (À CRÉER):

```typescript
// apps/api/src/common/filters/global-exception.filter.ts
import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger('ExceptionFilter');

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message = 'Internal server error';
    let error = 'Internal Server Error';

    // Gérer les exceptions HTTP NestJS
    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const exceptionResponse = exception.getResponse();

      if (typeof exceptionResponse === 'object') {
        message = (exceptionResponse as any).message || message;
        error = (exceptionResponse as any).error || error;
      } else {
        message = exceptionResponse;
      }
    } else if (exception instanceof Error) {
      // Logger l'erreur complète côté serveur
      this.logger.error(
        `${request.method} ${request.url} - ${exception.message}`,
        exception.stack,
      );

      // En production, ne pas exposer les détails
      if (process.env.NODE_ENV === 'production') {
        message = 'An unexpected error occurred';
      } else {
        message = exception.message;
      }
    }

    // Log pour monitoring
    this.logger.warn(
      `${request.method} ${request.url} - ${status} - ${message}`,
    );

    // Réponse standardisée
    response.status(status).json({
      statusCode: status,
      error,
      message,
      timestamp: new Date().toISOString(),
      path: request.url,
    });
  }
}
```

### Enregistrer le filter dans main.ts:

```typescript
import { GlobalExceptionFilter } from './common/filters/global-exception.filter';

// Dans bootstrap():
app.useGlobalFilters(new GlobalExceptionFilter());
```

---

# 6. CONFIGURATION APPLICATION MOBILE

## 6.1 Structure Flutter Détaillée

```
apps/mobile/lib/
├── main.dart                 # Point d'entrée
├── app.dart                  # Configuration app + Router
│
├── screens/                  # ÉCRANS (Pages)
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── forgot_password_screen.dart
│   │
│   ├── dashboard/
│   │   └── dashboard_screen.dart
│   │
│   ├── horses/
│   │   ├── horses_screen.dart        # Liste des chevaux
│   │   ├── horse_detail_screen.dart  # Détail d'un cheval
│   │   └── horse_form_screen.dart    # Ajout/édition cheval
│   │
│   ├── analyses/
│   │   ├── analyses_screen.dart      # Liste analyses
│   │   ├── analysis_detail_screen.dart
│   │   └── new_analysis_screen.dart  # Créer analyse
│   │
│   ├── marketplace/
│   │   ├── marketplace_screen.dart   # Liste annonces
│   │   ├── create_listing_screen.dart
│   │   └── edit_listing_screen.dart
│   │
│   ├── settings/
│   │   ├── settings_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── billing_screen.dart
│   │   ├── organization_screen.dart
│   │   └── notifications_screen.dart
│   │
│   ├── health/
│   │   └── health_screen.dart
│   │
│   ├── breeding/
│   │   └── breeding_screen.dart
│   │
│   ├── social/
│   │   └── feed_screen.dart
│   │
│   ├── gamification/
│   │   └── gamification_screen.dart
│   │
│   ├── planning/
│   │   └── planning_screen.dart
│   │
│   └── categories/               # Écrans catégories bottom nav
│       ├── ecurie_home_screen.dart
│       ├── ia_home_screen.dart
│       ├── social_home_screen.dart
│       └── plus_home_screen.dart
│
├── providers/                # STATE MANAGEMENT (Riverpod)
│   ├── auth_provider.dart         # État authentification
│   ├── horses_provider.dart       # État chevaux
│   ├── analyses_provider.dart     # État analyses
│   ├── marketplace_provider.dart  # État marketplace
│   ├── billing_provider.dart      # État facturation
│   ├── health_provider.dart       # État santé
│   ├── breeding_provider.dart     # État reproduction
│   ├── social_provider.dart       # État social
│   ├── gamification_provider.dart # État gamification
│   ├── user_profile_provider.dart # Profil utilisateur
│   ├── theme_provider.dart        # Thème app
│   └── settings_provider.dart     # Paramètres
│
├── services/                 # SERVICES
│   ├── api_service.dart           # Client HTTP Dio
│   └── storage_service.dart       # Stockage sécurisé
│
├── models/                   # MODÈLES DE DONNÉES
│   ├── models.dart                # Export all
│   ├── user.dart
│   ├── horse.dart
│   ├── analysis.dart
│   ├── marketplace_listing.dart
│   └── ...
│
├── widgets/                  # WIDGETS RÉUTILISABLES
│   ├── main_scaffold.dart         # Layout principal
│   ├── loading_button.dart        # Bouton avec loading
│   ├── error_view.dart            # Vue d'erreur
│   ├── empty_state.dart           # État vide
│   └── ...
│
└── theme/                    # THÈME
    └── app_theme.dart             # Couleurs, styles
```

## 6.2 Configuration API Service

### api_service.dart avec gestion des erreurs:

```dart
// apps/mobile/lib/services/api_service.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';

// Provider pour le service API
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref);
});

class ApiService {
  final Ref _ref;
  late final Dio _dio;

  // Pour gérer le refresh token
  bool _isRefreshing = false;
  final List<Completer<String?>> _refreshCompleters = [];

  ApiService(this._ref) {
    _dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_URL',
        defaultValue: 'https://api.horsetempo.app/api',
      ),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Intercepteur pour ajouter le token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Gérer le 401 (token expiré)
        if (error.response?.statusCode == 401) {
          try {
            final newToken = await _refreshToken();
            if (newToken != null) {
              // Retenter la requête originale
              final options = error.requestOptions;
              options.headers['Authorization'] = 'Bearer $newToken';
              final response = await _dio.fetch(options);
              return handler.resolve(response);
            }
          } catch (e) {
            // Refresh échoué, déconnecter l'utilisateur
            await _logout();
          }
        }
        handler.next(error);
      },
    ));
  }

  /// Refresh le token d'accès
  Future<String?> _refreshToken() async {
    // Éviter les appels concurrents
    if (_isRefreshing) {
      final completer = Completer<String?>();
      _refreshCompleters.add(completer);
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null) return null;

      final response = await Dio().post(
        '${_dio.options.baseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newAccessToken = response.data['accessToken'];
      final newRefreshToken = response.data['refreshToken'];

      await StorageService.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      // Résoudre les completers en attente
      for (final completer in _refreshCompleters) {
        if (!completer.isCompleted) {
          completer.complete(newAccessToken);
        }
      }
      _refreshCompleters.clear();

      return newAccessToken;
    } catch (e) {
      debugPrint('Refresh token error: $e');
      for (final completer in _refreshCompleters) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }
      _refreshCompleters.clear();
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Déconnexion
  Future<void> _logout() async {
    await StorageService.clearAll();
    // Invalider le provider auth
    _ref.invalidate(authProvider);
  }

  // ==================== MÉTHODES HTTP ====================

  /// GET request
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<dynamic> post(String path, dynamic data) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<dynamic> put(String path, dynamic data) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<dynamic> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload de fichier
  Future<String> uploadFile(String path, dynamic file, {String? type}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        if (type != null) 'type': type,
      });

      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
        onSendProgress: (sent, total) {
          debugPrint('Upload progress: ${(sent / total * 100).toStringAsFixed(0)}%');
        },
      );

      return response.data['url'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Gestion des erreurs Dio
  Exception _handleError(DioException e) {
    String message;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connexion au serveur impossible. Vérifiez votre connexion internet.';
        break;
      case DioExceptionType.sendTimeout:
        message = 'L\'envoi des données a pris trop de temps.';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Le serveur met trop de temps à répondre.';
        break;
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        if (responseData is Map && responseData['message'] != null) {
          message = responseData['message'];
        } else {
          message = _getMessageForStatusCode(statusCode);
        }
        break;
      case DioExceptionType.cancel:
        message = 'Requête annulée.';
        break;
      case DioExceptionType.connectionError:
        message = 'Impossible de se connecter au serveur.';
        break;
      default:
        message = 'Une erreur inattendue s\'est produite.';
    }

    return Exception(message);
  }

  String _getMessageForStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Requête invalide.';
      case 401:
        return 'Session expirée. Veuillez vous reconnecter.';
      case 403:
        return 'Accès non autorisé.';
      case 404:
        return 'Ressource non trouvée.';
      case 409:
        return 'Conflit de données.';
      case 422:
        return 'Données invalides.';
      case 429:
        return 'Trop de requêtes. Veuillez patienter.';
      case 500:
        return 'Erreur serveur. Veuillez réessayer.';
      case 502:
      case 503:
        return 'Service temporairement indisponible.';
      default:
        return 'Erreur inconnue ($statusCode).';
    }
  }
}
```

## 6.3 Configuration Android

### android/app/build.gradle:

```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        applicationId "app.horsetempo.mobile"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"

        // Configuration multi-environnement
        resValue "string", "app_name", "Horse Tempo"
    }

    buildTypes {
        debug {
            buildConfigField "String", "API_URL", "\"https://staging-api.horsetempo.app/api\""
        }
        release {
            buildConfigField "String", "API_URL", "\"https://api.horsetempo.app/api\""
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

### android/app/src/main/AndroidManifest.xml:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>

    <application
        android:label="Horse Tempo"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="false"
        android:networkSecurityConfig="@xml/network_security_config">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme"/>

            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>

            <!-- Deep Links -->
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:scheme="https" android:host="app.horsetempo.app"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

## 6.4 Configuration iOS

### ios/Runner/Info.plist:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>

    <key>CFBundleDisplayName</key>
    <string>Horse Tempo</string>

    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>

    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>

    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>

    <key>CFBundleName</key>
    <string>Horse Tempo</string>

    <key>CFBundlePackageType</key>
    <string>APPL</string>

    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>

    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>

    <!-- Permissions -->
    <key>NSCameraUsageDescription</key>
    <string>Horse Tempo utilise la caméra pour enregistrer les analyses vidéo de vos chevaux.</string>

    <key>NSPhotoLibraryUsageDescription</key>
    <string>Horse Tempo accède à vos photos pour les analyses et le marketplace.</string>

    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>Horse Tempo sauvegarde les analyses dans votre galerie.</string>

    <key>NSMicrophoneUsageDescription</key>
    <string>Horse Tempo utilise le microphone pour les vidéos.</string>

    <!-- Deep Links -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>horsetempo</string>
            </array>
        </dict>
    </array>

    <key>FlutterDeepLinkingEnabled</key>
    <true/>

    <!-- App Transport Security -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
    </dict>
</dict>
</plist>
```

## 6.5 Build Mobile

### Build Android:

```bash
cd apps/mobile

# Nettoyer
flutter clean
flutter pub get

# Build APK debug
flutter build apk --debug

# Build APK release
flutter build apk --release

# Build App Bundle (pour Play Store)
flutter build appbundle --release

# Les fichiers générés:
# - build/app/outputs/flutter-apk/app-release.apk
# - build/app/outputs/bundle/release/app-release.aab
```

### Build iOS:

```bash
cd apps/mobile

# Nettoyer
flutter clean
flutter pub get

# Build iOS (nécessite macOS + Xcode)
flutter build ios --release

# Ouvrir dans Xcode pour archive
open ios/Runner.xcworkspace

# Dans Xcode: Product > Archive
```

---

# 7. CONFIGURATION APPLICATION ADMIN

## 7.1 Structure Admin Flutter Web

```
apps/admin/lib/
├── main.dart
├── app.dart
├── screens/
│   ├── dashboard/
│   │   └── admin_dashboard_screen.dart    # Vue d'ensemble
│   ├── users/
│   │   ├── users_list_screen.dart         # Liste utilisateurs
│   │   └── user_detail_screen.dart        # Détail utilisateur
│   ├── subscriptions/
│   │   └── subscriptions_screen.dart      # Gestion abonnements
│   ├── organizations/
│   │   └── organizations_screen.dart      # Gestion organisations
│   ├── moderation/
│   │   ├── moderation_screen.dart         # Modération contenu
│   │   └── reports_screen.dart            # Signalements
│   ├── analytics/
│   │   └── analytics_screen.dart          # Statistiques
│   ├── support/
│   │   └── support_tickets_screen.dart    # Tickets support
│   └── settings/
│       └── admin_settings_screen.dart     # Paramètres admin
├── providers/
├── services/
├── models/
└── widgets/
```

## 7.2 Build Admin Web

```bash
cd apps/admin

# Nettoyer et récupérer dépendances
flutter clean
flutter pub get

# Build web release
flutter build web --release --web-renderer canvaskit

# Les fichiers générés sont dans:
# build/web/

# Copier vers le serveur
scp -r build/web/* user@server:/var/www/horsetempo/admin/
```

## 7.3 Configuration Nginx pour Admin

```nginx
# Dans /etc/nginx/sites-available/horsetempo
server {
    listen 443 ssl http2;
    server_name admin.horsetempo.app;

    ssl_certificate /etc/letsencrypt/live/horsetempo.app/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/horsetempo.app/privkey.pem;

    root /var/www/horsetempo/admin;
    index index.html;

    # Gestion SPA (Single Page Application)
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Sécurité
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
}
```

---

# 8. SERVICES EXTERNES

## 8.1 Stripe (Paiements)

### Configuration Dashboard Stripe

1. **Créer un compte Stripe**: https://dashboard.stripe.com/register

2. **Récupérer les clés API**:
   - Dashboard → Developers → API keys
   - Copier `Publishable key` (pk_live_xxx)
   - Copier `Secret key` (sk_live_xxx)

3. **Configurer les produits et prix**:
```
Dashboard → Products → Add product

Produit: Horse Tempo Premium
├── Prix mensuel: 49€/mois (price_xxx1)
└── Prix annuel: 490€/an (price_xxx2)

Produit: Horse Tempo Pro
├── Prix mensuel: 149€/mois (price_xxx3)
└── Prix annuel: 1490€/an (price_xxx4)
```

4. **Configurer le webhook**:
```
Dashboard → Developers → Webhooks → Add endpoint

URL: https://api.horsetempo.app/api/webhooks/stripe
Events à écouter:
- checkout.session.completed
- customer.subscription.created
- customer.subscription.updated
- customer.subscription.deleted
- invoice.paid
- invoice.payment_failed
```

### Code Backend Stripe

```typescript
// apps/api/src/modules/billing/billing.service.ts
import Stripe from 'stripe';

@Injectable()
export class BillingService {
  private stripe: Stripe;

  constructor(private configService: ConfigService) {
    this.stripe = new Stripe(
      this.configService.get('STRIPE_SECRET_KEY'),
      { apiVersion: '2023-10-16' }
    );
  }

  async createCheckoutSession(userId: string, priceId: string) {
    const session = await this.stripe.checkout.sessions.create({
      mode: 'subscription',
      payment_method_types: ['card'],
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: `${this.configService.get('FRONTEND_URL')}/billing/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${this.configService.get('FRONTEND_URL')}/billing/cancel`,
      metadata: { userId },
    });

    return { url: session.url };
  }

  async handleWebhook(payload: Buffer, signature: string) {
    const event = this.stripe.webhooks.constructEvent(
      payload,
      signature,
      this.configService.get('STRIPE_WEBHOOK_SECRET')
    );

    switch (event.type) {
      case 'checkout.session.completed':
        await this.handleCheckoutComplete(event.data.object);
        break;
      case 'customer.subscription.deleted':
        await this.handleSubscriptionCanceled(event.data.object);
        break;
      // ... autres événements
    }
  }
}
```

## 8.2 AWS S3 (Stockage Fichiers)

### Configuration S3

1. **Créer un bucket S3**:
```bash
# Via AWS CLI
aws s3 mb s3://horsetempo-production --region eu-west-3
```

2. **Configurer les permissions (IAM)**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::horsetempo-production",
        "arn:aws:s3:::horsetempo-production/*"
      ]
    }
  ]
}
```

3. **Configuration CORS du bucket**:
```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
    "AllowedOrigins": [
      "https://app.horsetempo.app",
      "https://admin.horsetempo.app"
    ],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3600
  }
]
```

### Code Backend S3

```typescript
// apps/api/src/modules/storage/storage.service.ts
import { S3Client, PutObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

@Injectable()
export class StorageService {
  private s3: S3Client;
  private bucket: string;

  constructor(private configService: ConfigService) {
    this.s3 = new S3Client({
      region: this.configService.get('AWS_REGION'),
      credentials: {
        accessKeyId: this.configService.get('AWS_ACCESS_KEY_ID'),
        secretAccessKey: this.configService.get('AWS_SECRET_ACCESS_KEY'),
      },
    });
    this.bucket = this.configService.get('AWS_S3_BUCKET');
  }

  async uploadFile(file: Express.Multer.File, path: string): Promise<string> {
    const key = `${path}/${Date.now()}-${file.originalname}`;

    await this.s3.send(new PutObjectCommand({
      Bucket: this.bucket,
      Key: key,
      Body: file.buffer,
      ContentType: file.mimetype,
      ACL: 'public-read',
    }));

    return `https://${this.bucket}.s3.amazonaws.com/${key}`;
  }

  async deleteFile(url: string): Promise<void> {
    const key = url.split('.amazonaws.com/')[1];
    await this.s3.send(new DeleteObjectCommand({
      Bucket: this.bucket,
      Key: key,
    }));
  }

  async getSignedUploadUrl(key: string, contentType: string): Promise<string> {
    const command = new PutObjectCommand({
      Bucket: this.bucket,
      Key: key,
      ContentType: contentType,
    });
    return getSignedUrl(this.s3, command, { expiresIn: 3600 });
  }
}
```

## 8.3 Email (Resend)

### Configuration Resend

1. **Créer un compte**: https://resend.com/signup

2. **Ajouter et vérifier le domaine**:
   - Resend Dashboard → Domains → Add domain
   - Ajouter les enregistrements DNS (MX, TXT, DKIM)

3. **Créer une clé API**:
   - Dashboard → API Keys → Create API Key

### Code Backend Email

```typescript
// apps/api/src/modules/email/email.service.ts
import { Resend } from 'resend';

@Injectable()
export class EmailService {
  private resend: Resend;
  private from: string;

  constructor(private configService: ConfigService) {
    this.resend = new Resend(this.configService.get('RESEND_API_KEY'));
    this.from = this.configService.get('EMAIL_FROM');
  }

  async sendWelcomeEmail(to: string, name: string) {
    await this.resend.emails.send({
      from: this.from,
      to,
      subject: 'Bienvenue sur Horse Tempo! 🐴',
      html: `
        <h1>Bienvenue ${name}!</h1>
        <p>Merci de rejoindre Horse Tempo.</p>
        <p>Commencez dès maintenant à gérer vos chevaux et analyses.</p>
        <a href="https://app.horsetempo.app">Accéder à l'application</a>
      `,
    });
  }

  async sendPasswordResetEmail(to: string, token: string) {
    const resetUrl = `https://app.horsetempo.app/reset-password?token=${token}`;

    await this.resend.emails.send({
      from: this.from,
      to,
      subject: 'Réinitialisation de votre mot de passe',
      html: `
        <h1>Réinitialisation du mot de passe</h1>
        <p>Cliquez sur le lien ci-dessous pour réinitialiser votre mot de passe:</p>
        <a href="${resetUrl}">Réinitialiser mon mot de passe</a>
        <p>Ce lien expire dans 1 heure.</p>
        <p>Si vous n'avez pas demandé cette réinitialisation, ignorez cet email.</p>
      `,
    });
  }

  async sendAnalysisCompleteEmail(to: string, analysisId: string, horseName: string) {
    await this.resend.emails.send({
      from: this.from,
      to,
      subject: `Analyse terminée pour ${horseName}`,
      html: `
        <h1>Votre analyse est prête!</h1>
        <p>L'analyse vidéo de ${horseName} est maintenant disponible.</p>
        <a href="https://app.horsetempo.app/analyses/${analysisId}">Voir l'analyse</a>
      `,
    });
  }
}
```

## 8.4 Anthropic Claude (IA)

### Configuration

1. **Créer un compte**: https://console.anthropic.com/

2. **Créer une clé API**:
   - Settings → API Keys → Create Key

3. **Surveiller l'usage**:
   - Dashboard → Usage (attention aux coûts!)

### Code Backend IA

```typescript
// apps/api/src/modules/ai/ai.service.ts
import Anthropic from '@anthropic-ai/sdk';

@Injectable()
export class AiService {
  private anthropic: Anthropic;
  private model: string;

  constructor(
    private configService: ConfigService,
    private cacheService: CacheService,
  ) {
    this.anthropic = new Anthropic({
      apiKey: this.configService.get('ANTHROPIC_API_KEY'),
    });
    this.model = this.configService.get('AI_MODEL_PRIMARY', 'claude-sonnet-4-20250514');
  }

  async analyzeVideo(videoUrl: string, analysisType: string, horseData: any) {
    // Vérifier le cache d'abord
    const cacheKey = `analysis:${videoUrl}:${analysisType}`;
    const cached = await this.cacheService.get(cacheKey);
    if (cached) return cached;

    const systemPrompt = this.getSystemPrompt(analysisType);
    const userPrompt = this.buildAnalysisPrompt(analysisType, horseData);

    try {
      const response = await this.anthropic.messages.create({
        model: this.model,
        max_tokens: 4096,
        system: systemPrompt,
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'image',
                source: { type: 'url', url: videoUrl },
              },
              {
                type: 'text',
                text: userPrompt,
              },
            ],
          },
        ],
      });

      const result = this.parseAnalysisResponse(response);

      // Mettre en cache
      await this.cacheService.set(cacheKey, result, 604800); // 7 jours

      return result;
    } catch (error) {
      this.logger.error('AI Analysis failed', error);
      throw new InternalServerErrorException('Analysis failed');
    }
  }

  private getSystemPrompt(analysisType: string): string {
    const prompts = {
      locomotion: `Tu es un expert vétérinaire équin spécialisé dans l'analyse locomotrice.
        Analyse la vidéo et fournis:
        - Score de régularité (0-100)
        - Détection de boiteries éventuelles
        - Analyse de la symétrie
        - Recommandations`,

      jumping: `Tu es un expert en saut d'obstacles équestre.
        Analyse la vidéo et fournis:
        - Technique de saut (trajectoire, style)
        - Position du cavalier
        - Points d'amélioration
        - Score global (0-100)`,

      dressage: `Tu es un juge de dressage certifié FEI.
        Analyse la vidéo et fournis:
        - Évaluation des mouvements
        - Régularité des allures
        - Connexion cavalier-cheval
        - Notes par critère`,
    };

    return prompts[analysisType] || prompts.locomotion;
  }
}
```

---

# 9. SÉCURITÉ

## 9.1 Checklist Sécurité Critique

```
╔════════════════════════════════════════════════════════════════╗
║                    SÉCURITÉ - CHECKLIST                        ║
╠════════════════════════════════════════════════════════════════╣
║ [ ] Tous les secrets en variables d'environnement              ║
║ [ ] JWT secrets uniques et aléatoires (64+ caractères)         ║
║ [ ] HTTPS forcé partout (pas de HTTP)                          ║
║ [ ] CORS configuré strictement                                 ║
║ [ ] Rate limiting activé                                       ║
║ [ ] Validation des entrées (class-validator)                   ║
║ [ ] Sanitization des sorties (XSS)                             ║
║ [ ] Mots de passe hashés (bcrypt 12 rounds)                    ║
║ [ ] Headers de sécurité (Helmet)                               ║
║ [ ] Pas de données sensibles dans les logs                     ║
║ [ ] Pas de secrets dans le code source                         ║
║ [ ] Backup chiffré de la base de données                       ║
║ [ ] Audit des dépendances (npm audit)                          ║
║ [ ] Firewall configuré (UFW)                                   ║
║ [ ] Fail2ban actif                                             ║
╚════════════════════════════════════════════════════════════════╝
```

## 9.2 Configuration Helmet (Headers Sécurité)

```typescript
// Dans main.ts
import helmet from 'helmet';

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", "https://api.horsetempo.app"],
      fontSrc: ["'self'", "https://fonts.gstatic.com"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'", "https:"],
      frameSrc: ["'none'"],
    },
  },
  crossOriginEmbedderPolicy: false,
  crossOriginResourcePolicy: { policy: "cross-origin" },
}));
```

## 9.3 Rate Limiting

```typescript
// apps/api/src/app.module.ts
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';

@Module({
  imports: [
    ThrottlerModule.forRoot([
      {
        name: 'short',
        ttl: 1000,    // 1 seconde
        limit: 3,      // 3 requêtes max
      },
      {
        name: 'medium',
        ttl: 10000,   // 10 secondes
        limit: 20,     // 20 requêtes max
      },
      {
        name: 'long',
        ttl: 60000,   // 1 minute
        limit: 100,    // 100 requêtes max
      },
    ]),
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
```

## 9.4 Validation des Données

```typescript
// apps/api/src/modules/auth/dto/register.dto.ts
import { IsEmail, IsString, MinLength, MaxLength, Matches } from 'class-validator';

export class RegisterDto {
  @IsEmail({}, { message: 'Email invalide' })
  email: string;

  @IsString()
  @MinLength(8, { message: 'Mot de passe: minimum 8 caractères' })
  @MaxLength(100)
  @Matches(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/,
    { message: 'Le mot de passe doit contenir: majuscule, minuscule, chiffre, caractère spécial' }
  )
  password: string;

  @IsString()
  @MinLength(2)
  @MaxLength(50)
  firstName: string;

  @IsString()
  @MinLength(2)
  @MaxLength(50)
  lastName: string;
}
```

## 9.5 Protection contre les Injections SQL

Prisma protège automatiquement contre les injections SQL grâce aux requêtes paramétrées:

```typescript
// ✅ SÉCURISÉ - Prisma utilise des requêtes paramétrées
const user = await prisma.user.findUnique({
  where: { email: userInput },
});

// ❌ DANGEREUX - Ne JAMAIS faire ça
const user = await prisma.$queryRawUnsafe(
  `SELECT * FROM users WHERE email = '${userInput}'`
);

// ✅ Si raw query nécessaire, utiliser $queryRaw avec paramètres
const user = await prisma.$queryRaw`
  SELECT * FROM users WHERE email = ${userInput}
`;
```

## 9.6 Audit des Dépendances

```bash
# Vérifier les vulnérabilités
cd apps/api
npm audit

# Corriger automatiquement si possible
npm audit fix

# Rapport détaillé
npm audit --json > audit-report.json

# Avec pnpm
pnpm audit
```

---

# 10. DÉPLOIEMENT

## 10.1 Docker Compose Production

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  # Base de données PostgreSQL
  postgres:
    image: postgres:16-alpine
    container_name: horsetempo-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - horsetempo-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis
  redis:
    image: redis:7-alpine
    container_name: horsetempo-redis
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - horsetempo-network

  # API NestJS
  api:
    build:
      context: .
      dockerfile: apps/api/Dockerfile
    container_name: horsetempo-api
    restart: unless-stopped
    env_file:
      - .env
    ports:
      - "127.0.0.1:4000:4000"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - horsetempo-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:
  redis_data:

networks:
  horsetempo-network:
    driver: bridge
```

## 10.2 Configuration Nginx Complète

```nginx
# /etc/nginx/sites-available/horsetempo
# Configuration Nginx pour Horse Tempo

# Redirection HTTP vers HTTPS
server {
    listen 80;
    server_name horsetempo.app www.horsetempo.app api.horsetempo.app admin.horsetempo.app;
    return 301 https://$server_name$request_uri;
}

# API Backend
server {
    listen 443 ssl http2;
    server_name api.horsetempo.app;

    # SSL
    ssl_certificate /etc/letsencrypt/live/horsetempo.app/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/horsetempo.app/privkey.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;

    # Headers sécurité
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Logs
    access_log /var/log/nginx/horsetempo-api-access.log;
    error_log /var/log/nginx/horsetempo-api-error.log;

    # Taille max upload (pour vidéos)
    client_max_body_size 500M;

    # Timeouts
    proxy_connect_timeout 60s;
    proxy_send_timeout 120s;
    proxy_read_timeout 120s;

    # Proxy vers l'API NestJS
    location / {
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Health check (pas de log)
    location /api/health {
        proxy_pass http://127.0.0.1:4000;
        access_log off;
    }
}

# Admin Web
server {
    listen 443 ssl http2;
    server_name admin.horsetempo.app;

    ssl_certificate /etc/letsencrypt/live/horsetempo.app/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/horsetempo.app/privkey.pem;

    root /var/www/horsetempo/admin;
    index index.html;

    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

## 10.3 Script de Déploiement

```bash
#!/bin/bash
# deploy.sh - Script de déploiement Horse Tempo

set -e  # Arrêter si erreur

echo "🚀 Démarrage du déploiement Horse Tempo..."

# Variables
APP_DIR="/var/www/horsetempo"
BACKUP_DIR="/var/www/horsetempo/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 1. Sauvegarde de la base de données
echo "📦 Backup de la base de données..."
docker exec horsetempo-db pg_dump -U horsetempo horsetempo_prod | gzip > "$BACKUP_DIR/pre-deploy-$TIMESTAMP.sql.gz"

# 2. Pull du code
echo "📥 Récupération du code..."
cd $APP_DIR
git fetch origin main
git reset --hard origin/main

# 3. Installation des dépendances
echo "📦 Installation des dépendances..."
pnpm install --frozen-lockfile

# 4. Génération Prisma
echo "🔧 Génération Prisma Client..."
cd apps/api
npx prisma generate

# 5. Migrations
echo "🗄️ Application des migrations..."
npx prisma migrate deploy

# 6. Build API
echo "🏗️ Build de l'API..."
pnpm build

# 7. Redémarrage des services
echo "🔄 Redémarrage des services..."
cd $APP_DIR
docker-compose -f docker-compose.prod.yml up -d --build api

# 8. Vérification santé
echo "🏥 Vérification de santé..."
sleep 10
HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4000/api/health)

if [ "$HEALTH" == "200" ]; then
    echo "✅ Déploiement réussi!"
    echo "🌐 API disponible sur https://api.horsetempo.app"
else
    echo "❌ Erreur! Code HTTP: $HEALTH"
    echo "🔙 Rollback..."
    # Restaurer le backup si nécessaire
    exit 1
fi

# 9. Nettoyage des anciennes images Docker
echo "🧹 Nettoyage..."
docker image prune -f

echo "✅ Déploiement terminé!"
```

## 10.4 SSL avec Let's Encrypt

```bash
# Installation Certbot
sudo apt install certbot python3-certbot-nginx

# Obtenir les certificats
sudo certbot --nginx -d horsetempo.app -d www.horsetempo.app -d api.horsetempo.app -d admin.horsetempo.app

# Renouvellement automatique (déjà configuré par Certbot)
# Vérifier avec:
sudo certbot renew --dry-run

# Cron pour renouvellement (normalement auto)
# 0 0,12 * * * certbot renew --quiet
```

## 10.5 GitHub Actions CI/CD

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install pnpm
        run: npm install -g pnpm

      - name: Install dependencies
        run: pnpm install

      - name: Run tests
        run: pnpm test

      - name: Run linter
        run: pnpm lint

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - name: Deploy to server
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /var/www/horsetempo
            ./scripts/deploy.sh
```

---

# 11. MONITORING ET LOGS

## 11.1 Configuration Sentry

```typescript
// apps/api/src/main.ts
import * as Sentry from '@sentry/node';

async function bootstrap() {
  // Initialiser Sentry
  if (process.env.SENTRY_DSN) {
    Sentry.init({
      dsn: process.env.SENTRY_DSN,
      environment: process.env.NODE_ENV,
      tracesSampleRate: 0.1, // 10% des transactions
      integrations: [
        new Sentry.Integrations.Http({ tracing: true }),
        new Sentry.Integrations.Express({ app }),
      ],
    });
  }

  const app = await NestFactory.create(AppModule);

  // Middleware Sentry
  app.use(Sentry.Handlers.requestHandler());
  app.use(Sentry.Handlers.tracingHandler());

  // ... configuration

  // Error handler Sentry (après les routes)
  app.use(Sentry.Handlers.errorHandler());

  await app.listen(port);
}
```

## 11.2 Logging Structuré

```typescript
// apps/api/src/common/logger/custom-logger.ts
import { LoggerService, Injectable } from '@nestjs/common';
import * as winston from 'winston';

@Injectable()
export class CustomLogger implements LoggerService {
  private logger: winston.Logger;

  constructor() {
    this.logger = winston.createLogger({
      level: process.env.LOG_LEVEL || 'info',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
      ),
      defaultMeta: { service: 'horsetempo-api' },
      transports: [
        // Console
        new winston.transports.Console({
          format: winston.format.combine(
            winston.format.colorize(),
            winston.format.simple()
          ),
        }),
        // Fichier erreurs
        new winston.transports.File({
          filename: '/var/log/horsetempo/error.log',
          level: 'error',
        }),
        // Fichier combiné
        new winston.transports.File({
          filename: '/var/log/horsetempo/combined.log',
        }),
      ],
    });
  }

  log(message: string, context?: string) {
    this.logger.info(message, { context });
  }

  error(message: string, trace?: string, context?: string) {
    this.logger.error(message, { trace, context });
  }

  warn(message: string, context?: string) {
    this.logger.warn(message, { context });
  }

  debug(message: string, context?: string) {
    this.logger.debug(message, { context });
  }
}
```

## 11.3 Health Check Endpoint

```typescript
// apps/api/src/modules/health/health.controller.ts
import { Controller, Get } from '@nestjs/common';
import { HealthCheckService, HttpHealthIndicator, PrismaHealthIndicator } from '@nestjs/terminus';

@Controller('health')
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private http: HttpHealthIndicator,
    private prisma: PrismaHealthIndicator,
  ) {}

  @Get()
  check() {
    return this.health.check([
      // Vérifier la base de données
      () => this.prisma.pingCheck('database'),
      // Vérifier Redis
      () => this.http.pingCheck('redis', 'http://localhost:6379'),
    ]);
  }

  @Get('ready')
  ready() {
    return { status: 'ready', timestamp: new Date().toISOString() };
  }
}
```

## 11.4 Dashboard Monitoring Simple

Créer un script de monitoring:

```bash
#!/bin/bash
# /var/www/horsetempo/scripts/monitor.sh

echo "========== HORSE TEMPO MONITORING =========="
echo "Date: $(date)"
echo ""

echo "=== Services Docker ==="
docker-compose -f /var/www/horsetempo/docker-compose.prod.yml ps

echo ""
echo "=== Utilisation CPU/RAM ==="
docker stats --no-stream

echo ""
echo "=== Espace Disque ==="
df -h /var/www/horsetempo

echo ""
echo "=== Dernières erreurs API ==="
tail -20 /var/log/horsetempo/error.log 2>/dev/null || echo "Aucun fichier de log"

echo ""
echo "=== Health Check ==="
curl -s http://localhost:4000/api/health | jq .

echo ""
echo "=== Connexions actives ==="
netstat -an | grep :4000 | wc -l
```

---

# 12. TESTS

## 12.1 État Actuel des Tests

```
╔════════════════════════════════════════════════════════════════╗
║  ⚠️  AVERTISSEMENT CRITIQUE                                    ║
║                                                                 ║
║  Le projet n'a actuellement AUCUN test automatisé!             ║
║                                                                 ║
║  Avant le déploiement en production, il est FORTEMENT          ║
║  recommandé d'ajouter:                                         ║
║  - Tests unitaires pour les services                           ║
║  - Tests d'intégration pour les APIs                          ║
║  - Tests E2E pour les flux critiques                          ║
╚════════════════════════════════════════════════════════════════╝
```

## 12.2 Configuration Jest (Backend)

```typescript
// apps/api/jest.config.js
module.exports = {
  moduleFileExtensions: ['js', 'json', 'ts'],
  rootDir: 'src',
  testRegex: '.*\\.spec\\.ts$',
  transform: {
    '^.+\\.(t|j)s$': 'ts-jest',
  },
  collectCoverageFrom: ['**/*.(t|j)s'],
  coverageDirectory: '../coverage',
  testEnvironment: 'node',
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/$1',
  },
};
```

## 12.3 Exemple de Test Unitaire

```typescript
// apps/api/src/modules/auth/auth.service.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';

describe('AuthService', () => {
  let service: AuthService;
  let usersService: UsersService;

  const mockUser = {
    id: '1',
    email: 'test@example.com',
    passwordHash: '$2b$12$hashedpassword',
    firstName: 'Test',
    lastName: 'User',
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        {
          provide: UsersService,
          useValue: {
            findByEmail: jest.fn(),
            findByIdInternal: jest.fn(),
            create: jest.fn(),
          },
        },
        {
          provide: JwtService,
          useValue: {
            signAsync: jest.fn().mockResolvedValue('token'),
          },
        },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    usersService = module.get<UsersService>(UsersService);
  });

  describe('validateUser', () => {
    it('should return user if credentials are valid', async () => {
      jest.spyOn(usersService, 'findByEmail').mockResolvedValue(mockUser);
      jest.spyOn(bcrypt, 'compare').mockResolvedValue(true);

      const result = await service.validateUser('test@example.com', 'password');

      expect(result).toBeDefined();
      expect(result.email).toBe('test@example.com');
    });

    it('should return null if user not found', async () => {
      jest.spyOn(usersService, 'findByEmail').mockResolvedValue(null);

      const result = await service.validateUser('wrong@example.com', 'password');

      expect(result).toBeNull();
    });

    it('should return null if password is wrong', async () => {
      jest.spyOn(usersService, 'findByEmail').mockResolvedValue(mockUser);
      jest.spyOn(bcrypt, 'compare').mockResolvedValue(false);

      const result = await service.validateUser('test@example.com', 'wrongpassword');

      expect(result).toBeNull();
    });
  });
});
```

## 12.4 Tests Flutter (Mobile)

```dart
// apps/mobile/test/services/api_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:horsetempo/services/api_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  group('ApiService', () {
    late ApiService apiService;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      // apiService = ApiService.withDio(mockDio);
    });

    test('get should return data on success', () async {
      // Arrange
      when(mockDio.get(any)).thenAnswer(
        (_) async => Response(
          data: {'id': '1', 'name': 'Test'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        ),
      );

      // Act
      final result = await apiService.get('/test');

      // Assert
      expect(result['id'], '1');
      expect(result['name'], 'Test');
    });

    test('get should throw on timeout', () async {
      // Arrange
      when(mockDio.get(any)).thenThrow(
        DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/test'),
        ),
      );

      // Act & Assert
      expect(
        () => apiService.get('/test'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
```

## 12.5 Commandes de Test

```bash
# Backend - Exécuter les tests
cd apps/api
npm test

# Backend - Avec couverture
npm run test:cov

# Backend - Watch mode
npm run test:watch

# Mobile - Exécuter les tests
cd apps/mobile
flutter test

# Mobile - Avec couverture
flutter test --coverage

# Générer rapport HTML
genhtml coverage/lcov.info -o coverage/html
```

---

# 13. UI/UX DÉTAILLÉ

## 13.1 Palette de Couleurs

```dart
// apps/mobile/lib/theme/app_theme.dart
class AppColors {
  // Couleurs principales
  static const Color primary = Color(0xFF2E7D32);      // Vert forêt
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF4CAF50);

  // Couleurs secondaires
  static const Color secondary = Color(0xFF8D6E63);    // Brun chaud
  static const Color secondaryDark = Color(0xFF5D4037);
  static const Color secondaryLight = Color(0xFFBCAAA4);

  // Couleurs d'état
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Neutres
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFBDBDBD);
}
```

## 13.2 Typographie

```dart
class AppTypography {
  static const String fontFamily = 'Inter';

  static const TextStyle headline1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle headline2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headline3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}
```

## 13.3 Composants UI Standards

### Bouton Principal

```dart
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(text, style: AppTypography.button),
                ],
              ),
      ),
    );
  }
}
```

### Champ de Formulaire

```dart
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;

  const AppTextField({
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.body2.copyWith(
          fontWeight: FontWeight.w500,
        )),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
```

## 13.4 Navigation Bottom Bar

```dart
// Configuration de la bottom navigation
class MainScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const MainScaffold({
    required this.child,
    required this.currentIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          final routes = [
            '/dashboard',
            '/horses',
            '/analyses',
            '/social',
            '/more',
          ];
          context.go(routes[index]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Écurie',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'IA',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Social',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Plus',
          ),
        ],
      ),
    );
  }
}
```

---

# 14. FONCTIONNALITÉS DÉTAILLÉES

## 14.1 Gestion des Chevaux

### Endpoints API

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | /api/horses | Liste des chevaux |
| GET | /api/horses/:id | Détail d'un cheval |
| POST | /api/horses | Créer un cheval |
| PUT | /api/horses/:id | Modifier un cheval |
| DELETE | /api/horses/:id | Supprimer un cheval |
| GET | /api/horses/:id/analyses | Analyses d'un cheval |
| GET | /api/horses/:id/health | Carnet de santé |

### Modèle de Données

```typescript
interface Horse {
  id: string;
  name: string;
  breed: string;
  birthDate: Date;
  gender: 'male' | 'female' | 'gelding';
  color: string;
  height: number;  // cm
  weight: number;  // kg
  sireNumber: string;  // Numéro SIRE
  microchip: string;

  // Relations
  organizationId: string;
  ownerId: string;

  // Médias
  profileImage: string;
  images: string[];

  // Pedigree
  sire: string;  // Père
  dam: string;   // Mère

  // Métadonnées
  createdAt: Date;
  updatedAt: Date;
}
```

## 14.2 Analyses Vidéo IA

### Types d'Analyses

| Type | Description | Durée | Crédits |
|------|-------------|-------|---------|
| locomotion | Analyse locomotrice | ~2min | 1 |
| jumping | Analyse CSO | ~3min | 2 |
| dressage | Analyse dressage | ~3min | 2 |
| behavior | Analyse comportement | ~2min | 1 |
| conformation | Analyse morphologique | ~1min | 1 |

### Flux d'Analyse

```
1. Upload vidéo → S3
2. Création job dans queue Bull
3. Worker récupère le job
4. Extraction frames vidéo
5. Envoi à Claude Vision
6. Parsing résultat
7. Sauvegarde en base
8. Notification utilisateur
```

### Structure Résultat

```typescript
interface AnalysisResult {
  id: string;
  horseId: string;
  type: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';

  // Résultats
  globalScore: number;  // 0-100
  categories: {
    name: string;
    score: number;
    comments: string[];
  }[];

  // Détails
  strengths: string[];
  improvements: string[];
  recommendations: string[];

  // IA
  aiModel: string;
  processingTime: number;  // ms
  confidence: number;  // 0-1

  // Métadonnées
  videoUrl: string;
  thumbnailUrl: string;
  createdAt: Date;
}
```

## 14.3 Marketplace

### Types d'Annonces

| Type | Description |
|------|-------------|
| sale | Vente de cheval |
| rental | Location |
| stud | Saillie (étalon) |
| breeding | Recherche poulinière |
| service | Services équestres |

### Modèle Annonce

```typescript
interface MarketplaceListing {
  id: string;
  type: 'sale' | 'rental' | 'stud' | 'breeding' | 'service';
  status: 'draft' | 'active' | 'sold' | 'expired';

  // Contenu
  title: string;
  description: string;
  price: number;
  currency: string;
  negotiable: boolean;

  // Cheval (si applicable)
  horseId?: string;

  // Médias
  images: string[];
  videos: string[];

  // Localisation
  location: {
    city: string;
    country: string;
    coordinates?: { lat: number; lng: number };
  };

  // Contact
  contactEmail: string;
  contactPhone?: string;

  // Scoring IA
  equiCote?: {
    score: number;
    breakdown: Record<string, number>;
  };

  // Stats
  views: number;
  favorites: number;

  // Métadonnées
  organizationId: string;
  createdAt: Date;
  expiresAt: Date;
}
```

## 14.4 Système de Gamification

### XP et Niveaux

```typescript
const XP_ACTIONS = {
  // Actions quotidiennes
  dailyLogin: 10,
  completeProfile: 50,

  // Chevaux
  addHorse: 100,
  uploadHorsePhoto: 20,

  // Analyses
  createAnalysis: 50,
  shareAnalysis: 25,

  // Social
  createPost: 15,
  likePost: 5,
  commentPost: 10,
  followUser: 10,

  // Marketplace
  createListing: 30,
  completeSale: 200,
};

const LEVELS = [
  { level: 1, xpRequired: 0, title: 'Débutant' },
  { level: 2, xpRequired: 100, title: 'Cavalier' },
  { level: 3, xpRequired: 300, title: 'Passionné' },
  { level: 4, xpRequired: 600, title: 'Expert' },
  { level: 5, xpRequired: 1000, title: 'Maître' },
  { level: 6, xpRequired: 2000, title: 'Champion' },
  { level: 7, xpRequired: 5000, title: 'Légende' },
];
```

### Badges

| Badge | Condition | XP Bonus |
|-------|-----------|----------|
| 🐴 Premier Cheval | Ajouter son premier cheval | 50 |
| 📊 Analyste | 10 analyses complétées | 100 |
| 🌟 Populaire | 100 followers | 150 |
| 💰 Vendeur | Première vente marketplace | 200 |
| 🏆 Champion | Niveau 6 atteint | 500 |

---

# 15. CHECKLIST PRODUCTION

## 15.1 Avant le Déploiement

```
╔════════════════════════════════════════════════════════════════╗
║                PRÉ-DÉPLOIEMENT CHECKLIST                       ║
╠════════════════════════════════════════════════════════════════╣
║                                                                 ║
║ INFRASTRUCTURE                                                  ║
║ [ ] Serveur provisionné (min 4 vCPU, 8GB RAM)                  ║
║ [ ] Docker et Docker Compose installés                         ║
║ [ ] Nginx installé et configuré                                ║
║ [ ] Certificats SSL obtenus (Let's Encrypt)                    ║
║ [ ] Firewall configuré (UFW)                                   ║
║ [ ] Fail2ban actif                                             ║
║                                                                 ║
║ BASE DE DONNÉES                                                 ║
║ [ ] PostgreSQL démarré                                         ║
║ [ ] User dédié créé (pas root/postgres)                        ║
║ [ ] Migrations appliquées                                      ║
║ [ ] Backup automatique configuré                               ║
║ [ ] Redis démarré                                              ║
║                                                                 ║
║ CONFIGURATION                                                   ║
║ [ ] Fichier .env créé avec TOUTES les variables                ║
║ [ ] JWT secrets générés (64+ caractères)                       ║
║ [ ] Clés API services externes configurées                     ║
║ [ ] CORS configuré strictement                                 ║
║                                                                 ║
║ SERVICES EXTERNES                                               ║
║ [ ] Stripe: clés live, webhook, produits créés                 ║
║ [ ] AWS S3: bucket créé, permissions IAM                       ║
║ [ ] Resend: domaine vérifié, clé API                           ║
║ [ ] Anthropic: clé API, limites budget                         ║
║ [ ] Sentry: projet créé, DSN configuré                         ║
║                                                                 ║
║ CODE                                                            ║
║ [ ] Aucune donnée sensible dans le code                        ║
║ [ ] Swagger désactivé en production                            ║
║ [ ] Logs configurés (pas de debug en prod)                     ║
║ [ ] Error messages génériques côté client                      ║
║                                                                 ║
║ TESTS                                                           ║
║ [ ] Tests unitaires passent                                    ║
║ [ ] Tests d'intégration passent                                ║
║ [ ] Build réussit sans erreur                                  ║
║ [ ] Lint sans erreur                                           ║
║                                                                 ║
╚════════════════════════════════════════════════════════════════╝
```

## 15.2 Après le Déploiement

```
╔════════════════════════════════════════════════════════════════╗
║                POST-DÉPLOIEMENT CHECKLIST                      ║
╠════════════════════════════════════════════════════════════════╣
║                                                                 ║
║ VÉRIFICATIONS                                                   ║
║ [ ] API répond sur https://api.horsetempo.app                  ║
║ [ ] Health check retourne 200                                  ║
║ [ ] Admin accessible sur https://admin.horsetempo.app          ║
║ [ ] SSL valide (grade A sur ssllabs.com)                       ║
║                                                                 ║
║ TESTS FONCTIONNELS                                              ║
║ [ ] Inscription fonctionne                                     ║
║ [ ] Connexion fonctionne                                       ║
║ [ ] Ajout de cheval fonctionne                                 ║
║ [ ] Upload de fichier fonctionne                               ║
║ [ ] Paiement Stripe test fonctionne                            ║
║ [ ] Emails arrivent                                            ║
║                                                                 ║
║ MONITORING                                                      ║
║ [ ] Sentry reçoit les erreurs                                  ║
║ [ ] Logs sont écrits                                           ║
║ [ ] Alertes configurées                                        ║
║                                                                 ║
║ BACKUP                                                          ║
║ [ ] Premier backup manuel effectué                             ║
║ [ ] Cron backup configuré                                      ║
║ [ ] Test de restauration effectué                              ║
║                                                                 ║
╚════════════════════════════════════════════════════════════════╝
```

---

# 16. TROUBLESHOOTING

## 16.1 Problèmes Courants

### L'API ne démarre pas

```bash
# Vérifier les logs
docker logs horsetempo-api

# Causes courantes:
# 1. Variables d'environnement manquantes
docker exec horsetempo-api env | grep -E "DATABASE_URL|JWT"

# 2. Base de données inaccessible
docker exec horsetempo-api npx prisma db pull

# 3. Port déjà utilisé
sudo lsof -i :4000
```

### Erreur de connexion base de données

```bash
# Vérifier que PostgreSQL est démarré
docker ps | grep postgres

# Tester la connexion
docker exec horsetempo-db psql -U horsetempo -d horsetempo_prod -c "SELECT 1"

# Vérifier DATABASE_URL
# Format: postgresql://USER:PASSWORD@HOST:PORT/DATABASE
```

### Erreur 502 Bad Gateway

```bash
# L'API n'est pas démarrée ou pas accessible
# 1. Vérifier que le container tourne
docker ps | grep api

# 2. Vérifier les logs Nginx
sudo tail -f /var/log/nginx/horsetempo-api-error.log

# 3. Vérifier que l'API répond en local
curl http://localhost:4000/api/health
```

### Erreur CORS

```bash
# Vérifier la configuration CORS_ORIGINS dans .env
# Doit inclure le domaine exact avec https://

# Exemple correct:
CORS_ORIGINS="https://app.horsetempo.app,https://admin.horsetempo.app"

# Exemple incorrect:
CORS_ORIGINS="app.horsetempo.app"  # Manque https://
CORS_ORIGINS="*"  # Trop permissif
```

### Upload de fichier échoue

```bash
# Vérifier la limite Nginx
# Dans nginx.conf: client_max_body_size 500M;

# Vérifier les permissions S3
aws s3 ls s3://horsetempo-production/

# Vérifier les credentials AWS
aws sts get-caller-identity
```

### Emails non reçus

```bash
# Vérifier la configuration Resend
# 1. Domaine vérifié dans le dashboard Resend
# 2. Clé API correcte
# 3. Adresse FROM utilise le domaine vérifié

# Tester l'envoi
curl -X POST https://api.resend.com/emails \
  -H "Authorization: Bearer $RESEND_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"from":"test@horsetempo.app","to":"you@email.com","subject":"Test","html":"<p>Test</p>"}'
```

## 16.2 Commandes de Debug

```bash
# Voir tous les logs en temps réel
docker-compose -f docker-compose.prod.yml logs -f

# Logs d'un service spécifique
docker logs -f horsetempo-api

# Entrer dans un container
docker exec -it horsetempo-api sh

# Voir l'utilisation des ressources
docker stats

# Vérifier l'espace disque
df -h

# Voir les connexions actives
netstat -tulpn | grep LISTEN

# Tester la connectivité
curl -v https://api.horsetempo.app/api/health
```

---

# 17. MAINTENANCE

## 17.1 Mises à Jour

### Mise à jour de l'application

```bash
#!/bin/bash
# update.sh

cd /var/www/horsetempo

# 1. Backup avant mise à jour
./scripts/backup-db.sh

# 2. Pull les changements
git fetch origin
git pull origin main

# 3. Installer les nouvelles dépendances
pnpm install

# 4. Appliquer les migrations
cd apps/api
npx prisma migrate deploy
npx prisma generate

# 5. Rebuild et redémarrer
cd ../..
docker-compose -f docker-compose.prod.yml up -d --build api

# 6. Vérifier
curl https://api.horsetempo.app/api/health
```

### Mise à jour des dépendances

```bash
# Vérifier les mises à jour disponibles
pnpm outdated

# Mettre à jour une dépendance spécifique
pnpm update <package-name>

# Mettre à jour toutes les dépendances (attention!)
pnpm update

# Toujours tester après mise à jour
pnpm test
pnpm build
```

## 17.2 Nettoyage

```bash
#!/bin/bash
# cleanup.sh

echo "🧹 Nettoyage Horse Tempo..."

# Supprimer les images Docker non utilisées
docker image prune -f

# Supprimer les volumes orphelins
docker volume prune -f

# Nettoyer les logs anciens (> 30 jours)
find /var/log/horsetempo -name "*.log" -mtime +30 -delete

# Nettoyer les backups anciens (> 30 jours)
find /var/www/horsetempo/backups -name "*.sql.gz" -mtime +30 -delete

# Vérifier l'espace libéré
df -h /var/www/horsetempo

echo "✅ Nettoyage terminé!"
```

## 17.3 Surveillance Quotidienne

```bash
#!/bin/bash
# daily-check.sh

echo "========== RAPPORT QUOTIDIEN HORSE TEMPO =========="
echo "Date: $(date)"
echo ""

# Services
echo "=== État des Services ==="
docker-compose -f /var/www/horsetempo/docker-compose.prod.yml ps

# Espace disque
echo ""
echo "=== Espace Disque ==="
df -h /var/www/horsetempo

# Mémoire
echo ""
echo "=== Mémoire ==="
free -h

# Derniers backups
echo ""
echo "=== Derniers Backups ==="
ls -lht /var/www/horsetempo/backups/*.sql.gz | head -5

# Erreurs récentes
echo ""
echo "=== Erreurs (dernières 24h) ==="
grep -c "ERROR" /var/log/horsetempo/error.log 2>/dev/null || echo "0 erreurs"

# Health
echo ""
echo "=== Health Check ==="
curl -s http://localhost:4000/api/health | jq .

echo ""
echo "========== FIN DU RAPPORT =========="
```

## 17.4 Plan de Disaster Recovery

```
╔════════════════════════════════════════════════════════════════╗
║              PLAN DE RÉCUPÉRATION D'URGENCE                    ║
╠════════════════════════════════════════════════════════════════╣
║                                                                 ║
║ EN CAS DE PANNE TOTALE:                                        ║
║                                                                 ║
║ 1. ÉVALUER                                                      ║
║    - Identifier la cause (serveur, DB, réseau, code)           ║
║    - Consulter les logs: docker logs, /var/log/nginx           ║
║                                                                 ║
║ 2. COMMUNIQUER                                                  ║
║    - Informer les utilisateurs (status page, email)            ║
║    - Estimer le temps de résolution                            ║
║                                                                 ║
║ 3. RESTAURER                                                    ║
║    a) Si problème de code:                                     ║
║       git checkout <last-working-commit>                       ║
║       ./scripts/deploy.sh                                      ║
║                                                                 ║
║    b) Si problème de DB:                                       ║
║       ./scripts/restore-db.sh <backup-file>                    ║
║                                                                 ║
║    c) Si problème serveur:                                     ║
║       Provisionner nouveau serveur                             ║
║       Restaurer depuis backup                                  ║
║       Mettre à jour DNS                                        ║
║                                                                 ║
║ 4. VÉRIFIER                                                     ║
║    - Tester toutes les fonctionnalités critiques               ║
║    - Vérifier les logs pour nouvelles erreurs                  ║
║                                                                 ║
║ 5. POST-MORTEM                                                  ║
║    - Documenter l'incident                                     ║
║    - Identifier les améliorations                              ║
║    - Mettre à jour les procédures                              ║
║                                                                 ║
╚════════════════════════════════════════════════════════════════╝
```

---

# ANNEXES

## A. Commandes Utiles

```bash
# === DOCKER ===
docker ps                              # Containers actifs
docker logs -f <container>             # Logs en temps réel
docker exec -it <container> sh         # Shell dans container
docker-compose up -d                   # Démarrer en background
docker-compose down                    # Arrêter tout
docker-compose restart api             # Redémarrer un service

# === PRISMA ===
npx prisma studio                      # Interface graphique DB
npx prisma migrate dev                 # Créer migration
npx prisma migrate deploy              # Appliquer migrations
npx prisma db push                     # Push schema (dev only)
npx prisma generate                    # Générer client

# === GIT ===
git log --oneline -10                  # 10 derniers commits
git diff HEAD~1                        # Différences dernier commit
git stash && git pull && git stash pop # Pull avec changements locaux

# === MONITORING ===
htop                                   # Processus en temps réel
df -h                                  # Espace disque
free -m                                # Mémoire
netstat -tulpn                         # Ports ouverts
```

## B. Contacts d'Urgence

```
Support Stripe: https://support.stripe.com
Support AWS: https://aws.amazon.com/support
Support Anthropic: https://support.anthropic.com
Support Resend: https://resend.com/support
```

## C. Ressources

```
Documentation NestJS: https://docs.nestjs.com
Documentation Flutter: https://docs.flutter.dev
Documentation Prisma: https://www.prisma.io/docs
Documentation Stripe: https://stripe.com/docs
Documentation Claude: https://docs.anthropic.com
```

---

**FIN DU GUIDE DE PRODUCTION HORSE TEMPO**

*Document généré le 9 janvier 2026*
*Version 1.0.0*
