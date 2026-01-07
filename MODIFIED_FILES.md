# Fichiers Modifiés - Cohérence Mobile/Backend

## Fichiers Controllers Modifiés

### 1. `/apps/api/src/modules/gestation/gestation.controller.ts`

**Endpoints ajoutés**:

- `PUT /gestations/:id/checkups/:checkupId` (ligne 113-129)
- `PUT /births/:id` (ligne 224-239)

**Test**:

```bash
# Tester updateCheckup
curl -X PUT http://localhost:3000/gestations/{gestationId}/checkups/{checkupId} \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"date": "2024-01-15", "notes": "Updated notes"}'

# Tester updateBirth
curl -X PUT http://localhost:3000/births/{birthId} \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"foalName": "Updated Name", "birthWeight": 55}'
```

### 2. `/apps/api/src/modules/clubs/clubs.controller.ts`

**Endpoints ajoutés**:

- `POST /clubs/challenges/:id/accept` (ligne 207-211)
- `POST /clubs/events/:id/join` (ligne 231-235)
- `POST /clubs/:id/posts/:postId/like` (ligne 247-255)

**Test**:

```bash
# Tester acceptChallenge
curl -X POST http://localhost:3000/clubs/challenges/{challengeId}/accept \
  -H "Authorization: Bearer {token}"

# Tester joinEvent
curl -X POST http://localhost:3000/clubs/events/{eventId}/join \
  -H "Authorization: Bearer {token}"

# Tester likePost
curl -X POST http://localhost:3000/clubs/{clubId}/posts/{postId}/like \
  -H "Authorization: Bearer {token}"
```

### 3. `/apps/api/src/modules/gamification/gamification.controller.ts`

**Endpoints ajoutés**:

- `POST /gamification/referrals/invite` (ligne 75-82)

**Test**:

```bash
# Tester sendReferralInvite
curl -X POST http://localhost:3000/gamification/referrals/invite \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"email": "friend@example.com", "message": "Join me!"}'
```

### 4. `/apps/api/src/modules/marketplace/marketplace.controller.ts`

**Endpoints ajoutés**:

- `GET /marketplace/breeding-matches/:mareId` (ligne 73-77)
- `POST /marketplace/:id/report` (ligne 179-187)

**Test**:

```bash
# Tester getBreedingMatches
curl -X GET http://localhost:3000/marketplace/breeding-matches/{mareId} \
  -H "Authorization: Bearer {token}"

# Tester reportListing
curl -X POST http://localhost:3000/marketplace/{listingId}/report \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"reason": "inappropriate", "details": "Offensive content"}'
```

### 5. `/apps/api/src/modules/equicote/equicote.controller.ts`

**Endpoints ajoutés**:

- `GET /equicote/comparables/:horseId` (ligne 53-57)

**Test**:

```bash
# Tester getComparables
curl -X GET http://localhost:3000/equicote/comparables/{horseId} \
  -H "Authorization: Bearer {token}"
```

### 6. `/apps/api/src/modules/services/services.controller.ts`

**Endpoints ajoutés**:

- `PUT /services/:id/reviews/:reviewId` (ligne 120-129)
- `DELETE /services/:id/reviews/:reviewId` (ligne 131-139)
- `POST /services/:id/reviews/:reviewId/helpful` (ligne 141-149)
- `POST /services/:id/report` (ligne 151-159)

**Test**:

```bash
# Tester updateReview
curl -X PUT http://localhost:3000/services/{providerId}/reviews/{reviewId} \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"rating": 5, "comment": "Updated review"}'

# Tester deleteReview
curl -X DELETE http://localhost:3000/services/{providerId}/reviews/{reviewId} \
  -H "Authorization: Bearer {token}"

# Tester markReviewHelpful
curl -X POST http://localhost:3000/services/{providerId}/reviews/{reviewId}/helpful \
  -H "Authorization: Bearer {token}"

# Tester reportProvider
curl -X POST http://localhost:3000/services/{providerId}/report \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"reason": "fraud", "details": "Fake provider"}'
```

### 7. `/apps/api/src/modules/social/social.controller.ts`

**Endpoints ajoutés**:

- `GET /feed` (ligne 17-39)

**Test**:

```bash
# Tester getFeed avec différents types
curl -X GET http://localhost:3000/feed?type=forYou&page=1 \
  -H "Authorization: Bearer {token}"

curl -X GET http://localhost:3000/feed?type=following&page=1 \
  -H "Authorization: Bearer {token}"

curl -X GET http://localhost:3000/feed?type=trending&page=1 \
  -H "Authorization: Bearer {token}"
```

## Fichiers à Modifier (Services)

Ces fichiers nécessitent l'ajout des implémentations de service:

1. `/apps/api/src/modules/gestation/gestation.service.ts`
2. `/apps/api/src/modules/clubs/clubs.service.ts`
3. `/apps/api/src/modules/gamification/gamification.service.ts`
4. `/apps/api/src/modules/marketplace/marketplace.service.ts`
5. `/apps/api/src/modules/equicote/equicote.service.ts`
6. `/apps/api/src/modules/services/services.service.ts`

Voir `SERVICE_IMPLEMENTATIONS_TODO.md` pour les détails d'implémentation.

## Plan de Test Complet

### Phase 1: Tests Unitaires des Services

```bash
# Pour chaque service modifié
npm test -- gestation.service.spec.ts
npm test -- clubs.service.spec.ts
npm test -- gamification.service.spec.ts
npm test -- marketplace.service.spec.ts
npm test -- equicote.service.spec.ts
npm test -- services.service.spec.ts
```

### Phase 2: Tests d'Intégration des Controllers

```bash
# Tests E2E
npm run test:e2e -- gestation.e2e-spec.ts
npm run test:e2e -- clubs.e2e-spec.ts
npm run test:e2e -- gamification.e2e-spec.ts
npm run test:e2e -- marketplace.e2e-spec.ts
npm run test:e2e -- equicote.e2e-spec.ts
npm run test:e2e -- services.e2e-spec.ts
npm run test:e2e -- social.e2e-spec.ts
```

### Phase 3: Tests Mobile

```bash
cd apps/mobile

# Tester chaque provider affecté
flutter test test/providers/gestation_provider_test.dart
flutter test test/providers/clubs_provider_test.dart
flutter test test/providers/gamification_provider_test.dart
flutter test test/providers/marketplace_provider_test.dart
flutter test test/providers/services_provider_test.dart
flutter test test/providers/social_provider_test.dart
```

### Phase 4: Tests E2E Mobile → Backend

```bash
# Lancer le backend en mode test
cd apps/api
npm run start:dev

# Lancer les tests d'intégration mobile
cd apps/mobile
flutter test integration_test/
```

## Commandes Git

```bash
# Voir les modifications
git status
git diff

# Voir les fichiers modifiés
git diff --name-only

# Commit les changements des controllers
git add apps/api/src/modules/*/
git commit -m "feat: add missing API endpoints for mobile app coherence

- Add gestation checkup and birth update endpoints
- Add club challenge accept, event join, and post like endpoints
- Add gamification referral invite endpoint
- Add marketplace breeding matches and report endpoints
- Add equicote comparables endpoint
- Add services review CRUD and report endpoints
- Add social feed endpoint with type parameter

Resolves mobile-backend API coherence issues
See COHERENCE_REPORT.md for details"
```

## Checklist de Vérification

Avant de merger ces changements:

- [ ] Tous les endpoints ajoutés sont documentés dans Swagger
- [ ] Les implémentations de service sont complétées
- [ ] Les tests unitaires passent (100%)
- [ ] Les tests E2E passent (100%)
- [ ] Les migrations Prisma sont créées si nécessaire
- [ ] La documentation API est mise à jour
- [ ] Les DTOs de validation sont ajoutés
- [ ] Les tests mobile passent
- [ ] L'équipe mobile a été notifiée des nouveaux endpoints
- [ ] Les logs de monitoring sont ajoutés
- [ ] Les permissions/guards sont correctement configurés
- [ ] Le CHANGELOG est mis à jour

## Scripts Utiles

### Vérifier la compilation TypeScript

```bash
cd apps/api
npm run build
```

### Générer la documentation Swagger

```bash
cd apps/api
npm run start:dev
# Ouvrir http://localhost:3000/api
```

### Lancer tous les tests

```bash
cd apps/api
npm run test:all
npm run test:e2e:all
```

### Vérifier le linting

```bash
cd apps/api
npm run lint
npm run lint:fix
```

## Déploiement

### Ordre de déploiement recommandé:

1. **Database**: Appliquer les migrations Prisma si nécessaire

   ```bash
   npx prisma migrate deploy
   ```

2. **Backend**: Déployer le backend avec les nouveaux endpoints

   ```bash
   npm run build
   npm run start:prod
   ```

3. **Mobile**: Mettre à jour l'app mobile (optionnel car rétrocompatible)
   ```bash
   flutter build apk --release
   flutter build ios --release
   ```

### Rollback en cas de problème:

Si un problème survient, les anciens endpoints continuent de fonctionner. Les
nouveaux endpoints peuvent être désactivés individuellement via des feature
flags si nécessaire.

## Support et Questions

Pour toute question sur ces modifications:

- Voir `COHERENCE_REPORT.md` pour le rapport complet
- Voir `SERVICE_IMPLEMENTATIONS_TODO.md` pour les détails d'implémentation
- Contact: [Équipe Backend/Mobile]

---

**Date**: 2026-01-07 **Branche**: claude/fix-errors-setup-admin-IltCZ
**Status**: ✅ Controllers mis à jour, ⚠️ Services à implémenter
