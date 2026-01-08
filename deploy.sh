#!/bin/bash
# Horse Tempo - Script de déploiement VPS Ionos
# Usage: ./deploy.sh [all|api|web|admin]

set -e

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier qu'on est dans le bon répertoire
if [ ! -f "docker-compose.prod.yml" ]; then
    log_error "Ce script doit être exécuté depuis la racine du projet Horse Tempo"
    exit 1
fi

# Récupérer les dernières modifications
update_code() {
    log_info "Mise à jour du code depuis Git..."
    git fetch origin
    git pull origin main
}

# Déployer l'API
deploy_api() {
    log_info "Déploiement de l'API..."
    docker-compose -f docker-compose.prod.yml build api
    docker-compose -f docker-compose.prod.yml up -d api

    log_info "Exécution des migrations de base de données..."
    docker-compose -f docker-compose.prod.yml exec api npx prisma migrate deploy || true

    log_info "API déployée avec succès!"
}

# Déployer le frontend Web
deploy_web() {
    log_info "Déploiement du frontend Web..."
    docker-compose -f docker-compose.prod.yml build web
    docker-compose -f docker-compose.prod.yml up -d web
    log_info "Frontend Web déployé avec succès!"
}

# Déployer l'admin Flutter (fichiers statiques)
deploy_admin() {
    log_info "Build de l'admin Flutter Web..."

    # Vérifier que Flutter est disponible ou utiliser les fichiers pré-buildés
    if command -v flutter &> /dev/null; then
        cd apps/admin
        flutter build web --release
        cd ../..
    else
        log_warn "Flutter non installé - utiliser les fichiers pré-buildés depuis apps/admin/build/web"
    fi

    # Copier vers le répertoire nginx
    if [ -d "apps/admin/build/web" ]; then
        log_info "Copie des fichiers admin vers nginx..."
        mkdir -p nginx/admin
        cp -r apps/admin/build/web/* nginx/admin/
        log_info "Admin déployé avec succès!"
    else
        log_error "Pas de build admin trouvé. Buildez localement et uploadez apps/admin/build/web/"
    fi
}

# Redémarrer tous les services
restart_all() {
    log_info "Redémarrage de tous les services..."
    docker-compose -f docker-compose.prod.yml down
    docker-compose -f docker-compose.prod.yml up -d
    log_info "Tous les services redémarrés!"
}

# Afficher les logs
show_logs() {
    docker-compose -f docker-compose.prod.yml logs -f --tail=100
}

# Vérifier le statut
check_status() {
    log_info "Statut des services:"
    docker-compose -f docker-compose.prod.yml ps
    echo ""
    log_info "Santé de l'API:"
    curl -s http://localhost:4000/api/health || log_warn "API non accessible"
}

# Menu principal
case "${1:-all}" in
    api)
        update_code
        deploy_api
        ;;
    web)
        update_code
        deploy_web
        ;;
    admin)
        deploy_admin
        ;;
    all)
        update_code
        deploy_api
        deploy_web
        restart_all
        ;;
    restart)
        restart_all
        ;;
    status)
        check_status
        ;;
    logs)
        show_logs
        ;;
    *)
        echo "Usage: $0 [api|web|admin|all|restart|status|logs]"
        echo ""
        echo "Commands:"
        echo "  api      - Déployer uniquement l'API"
        echo "  web      - Déployer uniquement le frontend"
        echo "  admin    - Déployer l'admin (Flutter)"
        echo "  all      - Déployer tout (défaut)"
        echo "  restart  - Redémarrer tous les services"
        echo "  status   - Afficher le statut des services"
        echo "  logs     - Afficher les logs"
        exit 1
        ;;
esac

log_info "Déploiement terminé!"
