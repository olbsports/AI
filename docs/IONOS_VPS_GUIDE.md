# 🐴 Guide Complet - VPS IONOS Horse Vision

> Guide exhaustif pour le déploiement, la maintenance et le dépannage de l'API
> Horse Vision sur VPS IONOS.

---

## 📋 Table des Matières

1. [Informations Serveur](#-informations-serveur)
2. [Structure du Projet](#-structure-du-projet)
3. [Accès au Serveur](#-accès-au-serveur)
4. [Variables d'Environnement](#-variables-denvironnement)
5. [PM2 - Gestion des Processus](#-pm2---gestion-des-processus)
6. [Build et Compilation](#-build-et-compilation)
7. [Script de Déploiement Automatisé](#-script-de-déploiement-automatisé)
8. [Base de Données (Prisma)](#-base-de-données-prisma)
9. [Nginx - Reverse Proxy](#-nginx---reverse-proxy)
10. [SSL/HTTPS avec Let's Encrypt](#-sslhttps-avec-lets-encrypt)
11. [Sauvegardes](#-sauvegardes)
12. [Monitoring et Alertes](#-monitoring-et-alertes)
13. [Logs et Debugging](#-logs-et-debugging)
14. [Sécurité](#-sécurité)
15. [Points d'Attention CRITIQUES](#-points-dattention-critiques)
16. [Problèmes Courants et Solutions](#-problèmes-courants-et-solutions)
17. [Cheat Sheet - Commandes Rapides](#-cheat-sheet---commandes-rapides)
18. [PowerShell - Commandes Windows](#-powershell---commandes-windows)

---

## 🖥 Informations Serveur

| Élément                       | Valeur                        |
| ----------------------------- | ----------------------------- |
| **Hébergeur**                 | IONOS VPS                     |
| **OS**                        | Ubuntu Linux 6.8.0-90-generic |
| **Node.js**                   | v20.19.6                      |
| **NPM**                       | 11.7.0                        |
| **pnpm**                      | Dernière version              |
| **TypeScript**                | 5.9.3                         |
| **Chemin projet**             | `/root/AI`                    |
| **Port API**                  | 4000                          |
| **Gestionnaire de processus** | PM2                           |
| **Base de données**           | PostgreSQL                    |

### Services en cours d'exécution

| Service        | Port   | Description                    |
| -------------- | ------ | ------------------------------ |
| horsetempo-api | 4000   | Backend principal Horse Vision |
| PostgreSQL     | 5432   | Base de données                |
| Nginx          | 80/443 | Reverse proxy                  |

---

## 📁 Structure du Projet

```
/root/AI/
├── 📂 apps/
│   ├── 📂 api/                    # 🔥 Backend NestJS (PRINCIPAL)
│   │   ├── 📂 src/                # Code source TypeScript
│   │   │   ├── 📂 modules/        # Modules NestJS (auth, horses, etc.)
│   │   │   ├── 📂 prisma/         # Service Prisma
│   │   │   ├── app.module.ts      # Module principal
│   │   │   └── main.ts            # Point d'entrée
│   │   ├── 📂 dist/               # ⚠️ Code compilé (généré)
│   │   ├── 📂 prisma/             # Schéma et migrations
│   │   │   └── schema.prisma      # Définition du schéma BDD
│   │   ├── .env                   # ⚠️ Variables d'environnement (NE PAS COMMIT)
│   │   ├── package.json
│   │   ├── tsconfig.json
│   │   └── tsconfig.build.json
│   │
│   ├── 📂 web/                    # Frontend Next.js (admin dashboard)
│   │   ├── 📂 src/
│   │   └── package.json
│   │
│   └── 📂 mobile/                 # App Flutter (développement local uniquement)
│       ├── 📂 lib/
│       └── pubspec.yaml
│
├── 📂 packages/                   # Packages partagés monorepo
│   ├── 📂 config/                 # Configuration partagée
│   ├── 📂 core/                   # Logique métier partagée
│   └── 📂 types/                  # Types TypeScript partagés
│
├── 📂 docs/                       # Documentation
│   └── IONOS_VPS_GUIDE.md         # Ce fichier !
│
├── 📂 node_modules/               # Dépendances (géré par pnpm)
├── 📂 scripts/                    # Scripts utilitaires
│   └── deploy.sh                  # Script de déploiement
│
├── .env                           # Variables globales
├── package.json                   # Config racine monorepo
├── pnpm-lock.yaml                 # Lockfile pnpm
├── pnpm-workspace.yaml            # Config workspace pnpm
└── turbo.json                     # Config Turborepo (si utilisé)
```

---

## 🔐 Accès au Serveur

### Connexion SSH

```bash
# Connexion standard
ssh root@<IP_SERVEUR>

# Avec clé SSH (recommandé)
ssh -i ~/.ssh/id_rsa root@<IP_SERVEUR>

# Si port SSH différent
ssh -p 2222 root@<IP_SERVEUR>
```

### Première connexion

```bash
# Mettre à jour le système
apt update && apt upgrade -y

# Installer les outils essentiels
apt install -y curl git htop vim ufw

# Installer Node.js (via nvm recommandé)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20

# Installer pnpm
npm install -g pnpm

# Installer PM2
npm install -g pm2
```

---

## 🔑 Variables d'Environnement

### Fichier `/root/AI/apps/api/.env`

```env
# ============================================
# 🔥 CONFIGURATION API HORSE VISION
# ============================================

# ----- Base de données -----
DATABASE_URL="postgresql://USER:PASSWORD@HOST:5432/DATABASE?schema=public"

# ----- JWT / Authentification -----
JWT_SECRET="votre-secret-jwt-ultra-secure-minimum-32-caracteres"
JWT_EXPIRATION="7d"
JWT_REFRESH_EXPIRATION="30d"

# ----- Application -----
NODE_ENV="production"
PORT=4000
API_PREFIX="api"

# ----- CORS -----
CORS_ORIGINS="https://votredomaine.com,https://app.votredomaine.com"

# ----- AWS S3 (stockage médias) -----
AWS_ACCESS_KEY_ID="AKIAXXXXXXXXXXXXXXXX"
AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
AWS_REGION="eu-west-3"
AWS_S3_BUCKET="horse-vision-media"

# ----- Email (Nodemailer) -----
SMTP_HOST="smtp.ionos.fr"
SMTP_PORT=587
SMTP_USER="noreply@votredomaine.com"
SMTP_PASS="password"
SMTP_FROM="Horse Vision <noreply@votredomaine.com>"

# ----- Stripe (paiements) -----
STRIPE_SECRET_KEY="sk_live_xxxxx"
STRIPE_WEBHOOK_SECRET="whsec_xxxxx"
STRIPE_PRICE_STARTER="price_xxxxx"
STRIPE_PRICE_PRO="price_xxxxx"
STRIPE_PRICE_ENTERPRISE="price_xxxxx"

# ----- Redis (optionnel - pour les queues) -----
REDIS_HOST="localhost"
REDIS_PORT=6379
REDIS_PASSWORD=""

# ----- Anthropic AI (analyses) -----
ANTHROPIC_API_KEY="sk-ant-xxxxx"

# ----- Sentry (monitoring erreurs - optionnel) -----
SENTRY_DSN="https://xxxxx@sentry.io/xxxxx"
```

### Vérifier les variables chargées

```bash
# Voir les variables d'environnement de l'API
cd /root/AI/apps/api
cat .env

# Tester une variable
node -e "require('dotenv').config(); console.log(process.env.DATABASE_URL)"
```

---

## ⚙️ PM2 - Gestion des Processus

### Configuration PM2

Le fichier de configuration PM2 devrait être créé à
`/root/AI/ecosystem.config.js` :

```javascript
// ecosystem.config.js
module.exports = {
  apps: [
    {
      name: 'horsetempo-api',
      cwd: '/root/AI/apps/api',
      script: 'dist/main.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: 4000,
      },
      error_file: '/root/.pm2/logs/api-error.log',
      out_file: '/root/.pm2/logs/api-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
    },
  ],
};
```

### Commandes PM2 Essentielles

```bash
# ===== STATUT =====
pm2 status                    # Voir tous les processus
pm2 show horsetempo-api                  # Détails d'un processus
pm2 monit                     # Monitoring en temps réel (interactif)

# ===== CONTRÔLE =====
pm2 start horsetempo-api                 # Démarrer
pm2 stop horsetempo-api                  # Arrêter
pm2 restart horsetempo-api               # Redémarrer
pm2 reload horsetempo-api                # Reload graceful (zero-downtime)
pm2 delete horsetempo-api                # Supprimer de PM2

# ===== LOGS =====
pm2 logs                      # Tous les logs en temps réel
pm2 logs horsetempo-api                  # Logs de l'API uniquement
pm2 logs horsetempo-api --lines 100      # Dernières 100 lignes
pm2 logs horsetempo-api --err            # Erreurs uniquement
pm2 flush                     # Vider les fichiers de logs

# ===== DÉMARRAGE AUTO =====
pm2 startup                   # Générer script de démarrage auto
pm2 save                      # Sauvegarder la config actuelle
pm2 resurrect                 # Restaurer les processus sauvegardés

# ===== MISE À JOUR =====
pm2 update                    # Mettre à jour PM2 in-memory
```

### Configurer le démarrage automatique au boot

```bash
# 1. Générer le script de démarrage
pm2 startup

# 2. Copier et exécuter la commande affichée (exemple) :
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u root --hp /root

# 3. Sauvegarder l'état actuel
pm2 save

# 4. Vérifier
systemctl status pm2-root
```

---

## 🔨 Build et Compilation

### ⚠️ MÉTHODE CORRECTE (TypeScript 5.9.3)

Le serveur utilise TypeScript 5.9.3 qui a un bug avec le build incrémental.
**TOUJOURS** utiliser cette séquence :

```bash
cd /root/AI/apps/api

# 1. Nettoyer l'ancien build
rm -rf dist

# 2. Compiler TypeScript (DÉSACTIVER incremental)
npx tsc --project tsconfig.build.json --outDir dist --noEmit false --incremental false

# 3. Transformer les alias de chemin (@/ -> chemins relatifs)
npx tsc-alias -p tsconfig.build.json

# 4. Vérifier que le build existe
ls -la dist/main.js

# 5. Redémarrer l'API
pm2 restart horsetempo-api
```

### ❌ NE PAS UTILISER

Ces commandes peuvent échouer **silencieusement** (exit code 0 mais aucun
fichier créé) :

```bash
# ❌ NE PAS UTILISER
pnpm run build
npm run build
nest build
npx nest build
```

### Pourquoi tsc-alias est nécessaire

Les imports avec `@/` ne fonctionnent pas en runtime Node.js :

```typescript
// Dans le code source
import { PrismaService } from '@/prisma/prisma.service';

// Après compilation (SANS tsc-alias) - ❌ NE FONCTIONNE PAS
const prisma_service_1 = require('@/prisma/prisma.service');

// Après tsc-alias - ✅ FONCTIONNE
const prisma_service_1 = require('./prisma/prisma.service');
```

---

## 🚀 Script de Déploiement Automatisé

### Créer le script `/root/AI/scripts/deploy.sh`

```bash
#!/bin/bash

# ============================================
# 🐴 Script de Déploiement Horse Vision API
# ============================================

set -e  # Arrêter en cas d'erreur

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/root/AI"
API_DIR="$PROJECT_DIR/apps/api"
BRANCH="${1:-main}"  # Branche par défaut: main

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🐴 Déploiement Horse Vision API${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. Aller dans le répertoire projet
echo -e "${YELLOW}📂 Navigation vers $PROJECT_DIR${NC}"
cd "$PROJECT_DIR"

# 2. Récupérer les dernières modifications
echo -e "${YELLOW}📥 Récupération des modifications (branche: $BRANCH)${NC}"
git fetch origin
git checkout "$BRANCH"
git pull origin "$BRANCH"

# 3. Installer les dépendances
echo -e "${YELLOW}📦 Installation des dépendances${NC}"
pnpm install

# 4. Aller dans le répertoire API
cd "$API_DIR"

# 5. Générer le client Prisma
echo -e "${YELLOW}🗄️  Génération du client Prisma${NC}"
npx prisma generate

# 6. Appliquer les migrations (optionnel - décommenter si nécessaire)
# echo -e "${YELLOW}🗄️  Application des migrations${NC}"
# npx prisma migrate deploy

# 7. Nettoyer l'ancien build
echo -e "${YELLOW}🧹 Nettoyage de l'ancien build${NC}"
rm -rf dist
rm -f *.tsbuildinfo

# 8. Compiler TypeScript
echo -e "${YELLOW}🔨 Compilation TypeScript${NC}"
npx tsc --project tsconfig.build.json --outDir dist --noEmit false --incremental false

# 9. Transformer les alias
echo -e "${YELLOW}🔄 Transformation des alias de chemin${NC}"
npx tsc-alias -p tsconfig.build.json

# 10. Vérifier le build
if [ ! -f "dist/main.js" ]; then
    echo -e "${RED}❌ ERREUR: dist/main.js non trouvé !${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build réussi${NC}"

# 11. Arrêter l'API et libérer le port
echo -e "${YELLOW}🛑 Arrêt de l'API${NC}"
pm2 stop horsetempo-api || true
sleep 2

# Tuer les processus sur le port 4000 si nécessaire
lsof -ti :4000 | xargs -r kill -9 2>/dev/null || true

# 12. Démarrer l'API
echo -e "${YELLOW}🚀 Démarrage de l'API${NC}"
pm2 start horsetempo-api

# 13. Attendre le démarrage
sleep 5

# 14. Vérifier le statut
echo -e "${YELLOW}🔍 Vérification du statut${NC}"
pm2 status

# 15. Health check
echo -e "${YELLOW}💓 Health check${NC}"
HEALTH=$(curl -s http://localhost:4000/api/health || echo "FAILED")

if echo "$HEALTH" | grep -q '"status":"ok"'; then
    echo -e "${GREEN}✅ API en ligne et fonctionnelle !${NC}"
    echo -e "${GREEN}$HEALTH${NC}"
else
    echo -e "${RED}⚠️  L'API ne répond pas correctement${NC}"
    echo -e "${RED}$HEALTH${NC}"
    echo -e "${YELLOW}Vérifiez les logs: pm2 logs horsetempo-api --lines 50${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🎉 Déploiement terminé avec succès !${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "API: ${BLUE}http://localhost:4000/api${NC}"
echo -e "Docs: ${BLUE}http://localhost:4000/api/docs${NC}"
echo -e "Logs: ${BLUE}pm2 logs horsetempo-api${NC}"
```

### Rendre le script exécutable

```bash
chmod +x /root/AI/scripts/deploy.sh
```

### Utilisation

```bash
# Déployer depuis la branche main
/root/AI/scripts/deploy.sh

# Déployer depuis une autre branche
/root/AI/scripts/deploy.sh develop
/root/AI/scripts/deploy.sh feature/new-feature
```

---

## 🗄️ Base de Données (Prisma)

### Commandes Prisma

```bash
cd /root/AI/apps/api

# ===== GÉNÉRATION =====
npx prisma generate           # Générer le client Prisma

# ===== SCHÉMA =====
npx prisma db pull            # Récupérer le schéma depuis la BDD
npx prisma db push            # Pousser le schéma vers la BDD (dev)
npx prisma format             # Formater le fichier schema.prisma

# ===== MIGRATIONS =====
npx prisma migrate dev        # Créer une migration (dev uniquement)
npx prisma migrate deploy     # Appliquer les migrations (production)
npx prisma migrate status     # Voir le statut des migrations
npx prisma migrate reset      # ⚠️ Réinitialiser la BDD (DESTRUCTIF)

# ===== DEBUG =====
npx prisma studio             # Interface graphique (port 5555)
npx prisma validate           # Valider le schéma
```

### Backup de la base de données

```bash
# Créer un backup
pg_dump -h HOST -U USER -d DATABASE > backup_$(date +%Y%m%d_%H%M%S).sql

# Restaurer un backup
psql -h HOST -U USER -d DATABASE < backup_20260107_143000.sql
```

### Script de backup automatique

Créer `/root/AI/scripts/backup-db.sh` :

```bash
#!/bin/bash

# Configuration
DB_HOST="your-db-host"
DB_USER="your-db-user"
DB_NAME="your-db-name"
BACKUP_DIR="/root/backups/database"
RETENTION_DAYS=30

# Créer le répertoire de backup
mkdir -p "$BACKUP_DIR"

# Nom du fichier avec timestamp
BACKUP_FILE="$BACKUP_DIR/horsevision_$(date +%Y%m%d_%H%M%S).sql.gz"

# Créer le backup compressé
PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -U "$DB_USER" "$DB_NAME" | gzip > "$BACKUP_FILE"

# Supprimer les backups de plus de X jours
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup créé: $BACKUP_FILE"
```

### Cron pour backup automatique

```bash
# Éditer la crontab
crontab -e

# Ajouter cette ligne (backup tous les jours à 3h du matin)
0 3 * * * /root/AI/scripts/backup-db.sh >> /var/log/backup-db.log 2>&1
```

---

## 🌐 Nginx - Reverse Proxy

### Installation

```bash
apt install nginx -y
systemctl enable nginx
systemctl start nginx
```

### Configuration `/etc/nginx/sites-available/horsevision`

```nginx
# Redirection HTTP -> HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name api.votredomaine.com;

    # Redirection vers HTTPS
    return 301 https://$server_name$request_uri;
}

# Configuration HTTPS
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name api.votredomaine.com;

    # Certificats SSL (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/api.votredomaine.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.votredomaine.com/privkey.pem;

    # Configuration SSL moderne
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;

    # Headers de sécurité
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Logs
    access_log /var/log/nginx/horsevision-access.log;
    error_log /var/log/nginx/horsevision-error.log;

    # Taille maximale des uploads
    client_max_body_size 100M;

    # Proxy vers l'API NestJS
    location / {
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;

        # Headers proxy
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Cache pour les assets statiques
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf)$ {
        proxy_pass http://127.0.0.1:4000;
        expires 7d;
        add_header Cache-Control "public, immutable";
    }
}
```

### Activer le site

```bash
# Créer le lien symbolique
ln -s /etc/nginx/sites-available/horsevision /etc/nginx/sites-enabled/

# Supprimer le site par défaut (optionnel)
rm /etc/nginx/sites-enabled/default

# Tester la configuration
nginx -t

# Recharger Nginx
systemctl reload nginx
```

---

## 🔒 SSL/HTTPS avec Let's Encrypt

### Installation de Certbot

```bash
apt install certbot python3-certbot-nginx -y
```

### Obtenir un certificat

```bash
# Obtenir et installer le certificat automatiquement
certbot --nginx -d api.votredomaine.com

# Ou manuellement
certbot certonly --nginx -d api.votredomaine.com
```

### Renouvellement automatique

```bash
# Tester le renouvellement
certbot renew --dry-run

# Le cron est automatiquement configuré
# Vérifier avec :
systemctl status certbot.timer
```

### Renouvellement manuel si nécessaire

```bash
certbot renew
systemctl reload nginx
```

---

## 💾 Sauvegardes

### Structure des sauvegardes

```
/root/backups/
├── database/           # Backups PostgreSQL
│   ├── horsevision_20260107_030000.sql.gz
│   └── horsevision_20260106_030000.sql.gz
├── uploads/            # Backups des fichiers uploadés
└── config/             # Backups des configurations
    ├── .env
    └── nginx/
```

### Script de backup complet `/root/AI/scripts/backup-full.sh`

```bash
#!/bin/bash

# ============================================
# Backup Complet Horse Vision
# ============================================

BACKUP_ROOT="/root/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Créer les répertoires
mkdir -p "$BACKUP_ROOT"/{database,config,uploads}

echo "🔄 Démarrage du backup complet..."

# 1. Backup base de données
echo "📦 Backup base de données..."
source /root/AI/apps/api/.env
PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -U "$DB_USER" "$DB_NAME" | gzip > "$BACKUP_ROOT/database/db_$DATE.sql.gz"

# 2. Backup configuration
echo "📦 Backup configuration..."
cp /root/AI/apps/api/.env "$BACKUP_ROOT/config/.env_$DATE"
cp -r /etc/nginx/sites-available "$BACKUP_ROOT/config/nginx_$DATE"

# 3. Backup uploads (si stockés localement)
# echo "📦 Backup uploads..."
# tar -czf "$BACKUP_ROOT/uploads/uploads_$DATE.tar.gz" /root/AI/apps/api/uploads/

# 4. Nettoyage des anciens backups
echo "🧹 Nettoyage des anciens backups..."
find "$BACKUP_ROOT" -type f -mtime +$RETENTION_DAYS -delete

# 5. Résumé
echo ""
echo "✅ Backup terminé !"
echo "📁 Emplacement: $BACKUP_ROOT"
du -sh "$BACKUP_ROOT"/*
```

### Planifier les backups

```bash
crontab -e

# Ajouter :
# Backup complet tous les jours à 3h
0 3 * * * /root/AI/scripts/backup-full.sh >> /var/log/backup.log 2>&1

# Backup BDD toutes les 6h
0 */6 * * * /root/AI/scripts/backup-db.sh >> /var/log/backup-db.log 2>&1
```

---

## 📊 Monitoring et Alertes

### Monitoring avec PM2

```bash
# Dashboard temps réel
pm2 monit

# Métriques
pm2 show horsetempo-api

# Historique CPU/Mémoire
pm2 logs horsetempo-api --lines 1000 | grep -i "memory\|cpu"
```

### Script de Health Check `/root/AI/scripts/healthcheck.sh`

```bash
#!/bin/bash

API_URL="http://localhost:4000/api/health"
SLACK_WEBHOOK="https://hooks.slack.com/services/XXX/YYY/ZZZ"  # Optionnel

# Vérifier l'API
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL" --max-time 10)

if [ "$RESPONSE" != "200" ]; then
    echo "❌ API DOWN - Status: $RESPONSE"

    # Notification Slack (optionnel)
    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data '{"text":"🚨 ALERTE: API Horse Vision DOWN! Status: '"$RESPONSE"'"}' \
            "$SLACK_WEBHOOK"
    fi

    # Tenter un restart automatique
    pm2 restart horsetempo-api

    exit 1
else
    echo "✅ API OK - $(date)"
fi
```

### Planifier le health check

```bash
crontab -e

# Vérification toutes les 5 minutes
*/5 * * * * /root/AI/scripts/healthcheck.sh >> /var/log/healthcheck.log 2>&1
```

### Monitoring système

```bash
# Espace disque
df -h

# Mémoire
free -h

# CPU et processus
htop

# Connexions réseau
netstat -tuln | grep LISTEN
ss -tuln

# Logs système
journalctl -f
```

---

## 📋 Logs et Debugging

### Emplacements des logs

| Log              | Emplacement                     |
| ---------------- | ------------------------------- |
| PM2 - API output | `/root/.pm2/logs/api-out.log`   |
| PM2 - API errors | `/root/.pm2/logs/api-error.log` |
| Nginx access     | `/var/log/nginx/access.log`     |
| Nginx error      | `/var/log/nginx/error.log`      |
| Système          | `/var/log/syslog`               |
| Authentification | `/var/log/auth.log`             |

### Commandes de debug

```bash
# ===== PM2 =====
pm2 logs horsetempo-api                          # Logs en temps réel
pm2 logs horsetempo-api --lines 200              # Dernières 200 lignes
pm2 logs horsetempo-api --err                    # Erreurs uniquement
pm2 logs horsetempo-api --out                    # Output uniquement

# ===== Filtrer les logs =====
pm2 logs horsetempo-api | grep -i error          # Filtrer les erreurs
pm2 logs horsetempo-api | grep "$(date +%Y-%m-%d)"  # Logs d'aujourd'hui

# ===== Nginx =====
tail -f /var/log/nginx/error.log      # Erreurs Nginx en temps réel
tail -f /var/log/nginx/access.log     # Accès en temps réel

# ===== Système =====
journalctl -u nginx -f                # Logs Nginx via systemd
dmesg | tail -50                      # Messages kernel
```

### Rotation des logs

PM2 gère automatiquement la rotation, mais vous pouvez configurer :

```bash
# Installer pm2-logrotate
pm2 install pm2-logrotate

# Configurer
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7
pm2 set pm2-logrotate:compress true
```

---

## 🛡️ Sécurité

### Firewall (UFW)

```bash
# Activer UFW
ufw enable

# Règles de base
ufw default deny incoming
ufw default allow outgoing

# Autoriser SSH (IMPORTANT - faire en premier !)
ufw allow 22/tcp

# Autoriser HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Autoriser le port API (si accès direct nécessaire)
ufw allow 4000/tcp

# Voir le statut
ufw status verbose
```

### Sécuriser SSH

Éditer `/etc/ssh/sshd_config` :

```bash
# Désactiver l'authentification par mot de passe (après avoir configuré les clés SSH)
PasswordAuthentication no

# Désactiver le login root direct (créer un autre user d'abord)
PermitRootLogin prohibit-password

# Changer le port SSH (optionnel)
Port 2222

# Redémarrer SSH
systemctl restart sshd
```

### Fail2Ban (protection brute force)

```bash
# Installer
apt install fail2ban -y

# Configurer
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Éditer /etc/fail2ban/jail.local
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

# Démarrer
systemctl enable fail2ban
systemctl start fail2ban

# Voir les bans
fail2ban-client status sshd
```

### Fichiers sensibles

**NE JAMAIS COMMIT :**

- `.env` - Variables d'environnement
- `*.pem`, `*.key` - Clés privées
- `credentials.json` - Identifiants
- `secrets/` - Dossier secrets

Ajouter au `.gitignore` :

```gitignore
.env
.env.*
*.pem
*.key
credentials.json
secrets/
```

---

## ⚠️ Points d'Attention CRITIQUES

### 1. 🔴 TypeScript 5.9.3 - Bug Incremental Build

**Problème** : `nest build` et `pnpm run build` échouent silencieusement (exit
code 0, aucun fichier créé).

**Solution** : TOUJOURS utiliser :

```bash
npx tsc --project tsconfig.build.json --outDir dist --noEmit false --incremental false
npx tsc-alias -p tsconfig.build.json
```

### 2. 🔴 Alias de Chemin (@/)

**Problème** : Les imports `@/` ne fonctionnent pas en runtime Node.js.

**Solution** : TOUJOURS exécuter `tsc-alias` après la compilation.

### 3. 🔴 Port 4000 Déjà Utilisé

**Problème** : `EADDRINUSE: address already in use :::4000`

**Solution** :

```bash
lsof -ti :4000 | xargs -r kill -9
pm2 restart horsetempo-api
```

### 4. 🟡 Conflits pnpm-lock.yaml

**Problème** : `git pull` échoue à cause de conflits.

**Solution** :

```bash
rm pnpm-lock.yaml
pnpm install
```

### 5. 🟡 Mémoire insuffisante

**Problème** : Le build ou l'API crash par manque de mémoire.

**Solution** :

```bash
# Vérifier la mémoire
free -h

# Créer un swap (si nécessaire)
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

### 6. 🟡 Prisma Client non généré

**Problème** : `Cannot find module '@prisma/client'`

**Solution** :

```bash
npx prisma generate
```

---

## 🔧 Problèmes Courants et Solutions

### API ne démarre pas

```bash
# 1. Vérifier les logs
pm2 logs horsetempo-api --lines 50

# 2. Vérifier que dist existe
ls -la /root/AI/apps/api/dist/

# 3. Rebuild complet
cd /root/AI/apps/api
rm -rf dist
npx tsc --project tsconfig.build.json --outDir dist --noEmit false --incremental false
npx tsc-alias -p tsconfig.build.json
pm2 restart horsetempo-api
```

### Module not found

```bash
# Si '@/...'
npx tsc-alias -p tsconfig.build.json

# Si autre module
pnpm install
# puis rebuild
```

### Erreur décorateurs NestJS

**Erreur** : `Cannot read properties of undefined (reading 'value')`

**Cause** : TypeScript compile avec les nouveaux décorateurs ES2022 au lieu des
legacy.

**Solution** : Rebuild avec la méthode correcte ci-dessus.

### Base de données inaccessible

```bash
# Tester la connexion
cd /root/AI/apps/api
npx prisma db pull

# Vérifier l'URL
grep DATABASE_URL .env

# Tester avec psql
psql "postgresql://user:pass@host:5432/db"
```

### Espace disque plein

```bash
# Voir l'utilisation
df -h

# Trouver les gros fichiers
du -sh /* | sort -h | tail -20

# Nettoyer les logs PM2
pm2 flush

# Nettoyer npm/pnpm cache
pnpm store prune
npm cache clean --force

# Nettoyer les anciens kernels (Ubuntu)
apt autoremove
```

### Nginx 502 Bad Gateway

```bash
# Vérifier que l'API tourne
curl http://localhost:4000/api/health

# Vérifier PM2
pm2 status

# Vérifier les logs Nginx
tail -50 /var/log/nginx/error.log

# Redémarrer tout
pm2 restart horsetempo-api
systemctl restart nginx
```

---

## 📝 Cheat Sheet - Commandes Rapides

### Déploiement

```bash
# Déploiement rapide
cd /root/AI && git pull && pnpm install && cd apps/api && \
npx tsc --project tsconfig.build.json --outDir dist --noEmit false --incremental false && \
npx tsc-alias -p tsconfig.build.json && pm2 restart horsetempo-api

# Ou utiliser le script
/root/AI/scripts/deploy.sh
```

### PM2

```bash
pm2 status              # Statut
pm2 logs horsetempo-api -f         # Logs live
pm2 restart horsetempo-api         # Restart
pm2 monit               # Dashboard
```

### Debug

```bash
# Health check
curl http://localhost:4000/api/health

# Voir les erreurs
pm2 logs horsetempo-api --err --lines 100

# Processus sur port 4000
lsof -i :4000
```

### Système

```bash
df -h                   # Espace disque
free -h                 # Mémoire
htop                    # Processus
```

### Base de données

```bash
cd /root/AI/apps/api
npx prisma studio       # GUI
npx prisma db push      # Push schema
npx prisma generate     # Générer client
```

---

## 📞 Contacts et Ressources

| Ressource              | Lien/Info                         |
| ---------------------- | --------------------------------- |
| **Repo GitHub**        | github.com/olbsports/AI           |
| **Branche principale** | main                              |
| **Documentation API**  | http://IP:4000/api/docs (Swagger) |
| **PM2 App Name**       | horsetempo-api                    |
| **Port API**           | 4000                              |

---

## 💻 PowerShell - Commandes Windows

Cette section est destinée aux utilisateurs Windows qui gèrent le serveur depuis
PowerShell.

### Connexion SSH depuis PowerShell

```powershell
# Connexion basique
ssh root@<IP_SERVEUR>

# Avec clé SSH
ssh -i $env:USERPROFILE\.ssh\id_rsa root@<IP_SERVEUR>

# Avec port personnalisé
ssh -p 2222 root@<IP_SERVEUR>
```

### Variables d'environnement PowerShell

```powershell
# Définir les variables du serveur
$SERVER_IP = "123.456.789.0"
$SERVER_USER = "root"
$PROJECT_PATH = "/root/AI"

# Fonction de connexion rapide
function Connect-VPS {
    ssh $SERVER_USER@$SERVER_IP
}

# Ajouter au profil PowerShell pour usage permanent
# notepad $PROFILE
```

### Script de Déploiement PowerShell

Créer `deploy.ps1` sur votre machine Windows :

```powershell
# ============================================
# 🐴 Script de Déploiement Horse Vision
# Pour Windows PowerShell
# ============================================

param(
    [string]$ServerIP = "VOTRE_IP_SERVEUR",
    [string]$User = "root",
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Blue
Write-Host "🐴 Déploiement Horse Vision API" -ForegroundColor Blue
Write-Host "========================================" -ForegroundColor Blue
Write-Host ""

# Commandes à exécuter sur le serveur
$DeployCommands = @"
cd /root/AI
echo '📥 Git pull...'
git fetch origin
git checkout $Branch
git pull origin $Branch

echo '📦 Installation dépendances...'
pnpm install

cd apps/api
echo '🗄️ Prisma generate...'
npx prisma generate

echo '🧹 Nettoyage...'
rm -rf dist
rm -f *.tsbuildinfo

echo '🔨 Compilation TypeScript...'
npx tsc --project tsconfig.build.json --outDir dist --noEmit false --incremental false

echo '🔄 Transformation alias...'
npx tsc-alias -p tsconfig.build.json

echo '🛑 Arrêt API...'
pm2 stop horsetempo-api || true
sleep 2
lsof -ti :4000 | xargs -r kill -9 2>/dev/null || true

echo '🚀 Démarrage API...'
pm2 start horsetempo-api
sleep 5

echo '💓 Health check...'
curl -s http://localhost:4000/api/health

echo ''
echo '✅ Déploiement terminé !'
pm2 status
"@

Write-Host "🔗 Connexion au serveur $User@$ServerIP..." -ForegroundColor Yellow
Write-Host ""

# Exécuter via SSH
ssh "$User@$ServerIP" $DeployCommands

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "🎉 Déploiement réussi !" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "❌ Erreur lors du déploiement" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    exit 1
}
```

### Utilisation du script

```powershell
# Déploiement par défaut (branche main)
.\deploy.ps1

# Déploiement avec paramètres
.\deploy.ps1 -ServerIP "123.456.789.0" -Branch "develop"

# Déploiement sur une feature branch
.\deploy.ps1 -Branch "feature/new-feature"
```

### Commandes SSH Rapides depuis PowerShell

```powershell
# ===== DÉFINIR L'IP DU SERVEUR =====
$VPS = "root@VOTRE_IP"

# ===== STATUS =====
ssh $VPS "pm2 status"

# ===== LOGS =====
ssh $VPS "pm2 logs horsetempo-api --lines 50"

# ===== RESTART =====
ssh $VPS "pm2 restart horsetempo-api"

# ===== HEALTH CHECK =====
ssh $VPS "curl -s http://localhost:4000/api/health"

# ===== ESPACE DISQUE =====
ssh $VPS "df -h"

# ===== MÉMOIRE =====
ssh $VPS "free -h"
```

### Fonctions PowerShell Utiles

Ajouter à votre profil PowerShell (`notepad $PROFILE`) :

```powershell
# ============================================
# 🐴 Horse Vision VPS Functions
# ============================================

$Global:VPS_IP = "VOTRE_IP_SERVEUR"
$Global:VPS_USER = "root"
$Global:VPS = "$VPS_USER@$VPS_IP"

# Connexion rapide
function vps { ssh $Global:VPS }

# Status PM2
function vps-status { ssh $Global:VPS "pm2 status" }

# Logs API
function vps-logs {
    param([int]$Lines = 50)
    ssh $Global:VPS "pm2 logs horsetempo-api --lines $Lines"
}

# Logs en temps réel
function vps-logs-live { ssh $Global:VPS "pm2 logs horsetempo-api" }

# Restart API
function vps-restart { ssh $Global:VPS "pm2 restart horsetempo-api" }

# Health check
function vps-health {
    ssh $Global:VPS "curl -s http://localhost:4000/api/health" | ConvertFrom-Json | Format-List
}

# Déploiement
function vps-deploy {
    param([string]$Branch = "main")
    & "$PSScriptRoot\deploy.ps1" -Branch $Branch
}

# Espace disque
function vps-disk { ssh $Global:VPS "df -h" }

# Mémoire
function vps-memory { ssh $Global:VPS "free -h" }

# Backup manuel
function vps-backup {
    ssh $Global:VPS "/root/AI/scripts/backup-full.sh"
}

# Ouvrir Prisma Studio (avec tunnel SSH)
function vps-prisma {
    Write-Host "🔗 Ouverture tunnel SSH pour Prisma Studio..." -ForegroundColor Yellow
    Write-Host "📂 Prisma Studio sera accessible sur http://localhost:5555" -ForegroundColor Cyan
    ssh -L 5555:localhost:5555 $Global:VPS "cd /root/AI/apps/api && npx prisma studio"
}

# Ouvrir les docs Swagger (avec tunnel SSH)
function vps-swagger {
    Write-Host "🔗 Ouverture tunnel SSH pour Swagger..." -ForegroundColor Yellow
    Write-Host "📚 Swagger sera accessible sur http://localhost:4000/api/docs" -ForegroundColor Cyan
    Start-Process "http://localhost:4000/api/docs"
    ssh -L 4000:localhost:4000 $Global:VPS "echo 'Tunnel actif. Ctrl+C pour fermer.' && sleep infinity"
}

Write-Host "🐴 Horse Vision VPS functions loaded!" -ForegroundColor Green
Write-Host "   Commandes: vps, vps-status, vps-logs, vps-restart, vps-health, vps-deploy" -ForegroundColor Gray
```

### Tunnels SSH pour accès local

```powershell
# Tunnel pour accéder à l'API localement
ssh -L 4000:localhost:4000 root@$VPS_IP
# Puis ouvrir http://localhost:4000/api/docs

# Tunnel pour Prisma Studio
ssh -L 5555:localhost:5555 root@$VPS_IP "cd /root/AI/apps/api && npx prisma studio"
# Puis ouvrir http://localhost:5555

# Tunnel pour la base de données PostgreSQL
ssh -L 5432:DB_HOST:5432 root@$VPS_IP
# Puis connecter avec pgAdmin sur localhost:5432
```

### Copier des fichiers (SCP)

```powershell
# Copier un fichier vers le serveur
scp .\fichier-local.txt root@${VPS_IP}:/root/AI/

# Copier un dossier vers le serveur
scp -r .\dossier-local\ root@${VPS_IP}:/root/AI/

# Télécharger un fichier depuis le serveur
scp root@${VPS_IP}:/root/AI/apps/api/.env .\backup\.env

# Télécharger les logs
scp root@${VPS_IP}:/root/.pm2/logs/api-error.log .\logs\
```

### Surveillance Continue

```powershell
# Script de monitoring (à exécuter en boucle)
while ($true) {
    Clear-Host
    Write-Host "🐴 Horse Vision Monitor - $(Get-Date)" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan

    $health = ssh $VPS "curl -s http://localhost:4000/api/health 2>/dev/null"
    if ($health -match '"status":"ok"') {
        Write-Host "✅ API: OK" -ForegroundColor Green
    } else {
        Write-Host "❌ API: DOWN" -ForegroundColor Red
    }

    ssh $VPS "pm2 jlist" | ConvertFrom-Json | ForEach-Object {
        Write-Host "📊 $($_.name): $($_.pm2_env.status) | CPU: $($_.monit.cpu)% | MEM: $([math]::Round($_.monit.memory/1MB))MB"
    }

    Start-Sleep -Seconds 30
}
```

### Alias PowerShell Rapides

```powershell
# Ajouter au profil PowerShell
Set-Alias -Name vps -Value Connect-VPS
Set-Alias -Name deploy -Value vps-deploy
Set-Alias -Name logs -Value vps-logs
```

---

## 📅 Historique des Mises à Jour

| Date       | Version | Changements                                |
| ---------- | ------- | ------------------------------------------ |
| 07/01/2026 | 1.1     | Ajout section PowerShell pour Windows      |
|            |         | Script deploy.ps1 + fonctions utilitaires  |
|            |         | Tunnels SSH, SCP, monitoring PowerShell    |
| 07/01/2026 | 1.0     | Création du guide complet                  |
|            |         | Fix TypeScript 5.9.3 incremental build     |
|            |         | Ajout ts-loader et webpack aux dépendances |

---

_Guide créé le 07/01/2026 - Maintenu par l'équipe Horse Vision_ _Version: 1.1 |
TypeScript 5.9.3 | NestJS 10.4 | Node.js 20.x | PowerShell 7.x_
