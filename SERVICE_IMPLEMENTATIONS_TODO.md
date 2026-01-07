# TODO: Implémentations de Service Manquantes

Les endpoints suivants ont été ajoutés aux controllers mais nécessitent des
implémentations dans les services.

## 1. Gestation Service

**Fichier**: `/apps/api/src/modules/gestation/gestation.service.ts`

### ✅ updateCheckup

```typescript
async updateCheckup(
  gestationId: string,
  checkupId: string,
  organizationId: string,
  data: {
    date?: string;
    type?: string;
    notes?: string;
    vetName?: string;
    results?: any;
  }
): Promise<GestationCheckup> {
  // 1. Vérifier que la gestation existe et appartient à l'organisation
  // 2. Trouver le checkup par ID
  // 3. Mettre à jour les champs fournis
  // 4. Sauvegarder et retourner

  return this.prisma.gestationCheckup.update({
    where: {
      id: checkupId,
      gestation: {
        organizationId,
        id: gestationId
      }
    },
    data: {
      date: data.date ? new Date(data.date) : undefined,
      type: data.type,
      notes: data.notes,
      vetName: data.vetName,
      results: data.results,
    },
  });
}
```

### ✅ updateBirth

```typescript
async updateBirth(
  birthId: string,
  organizationId: string,
  data: {
    foalName?: string;
    foalGender?: string;
    foalColor?: string;
    birthWeight?: number;
    notes?: string;
  }
): Promise<Birth> {
  // 1. Vérifier que la naissance existe et appartient à l'organisation
  // 2. Mettre à jour les champs fournis
  // 3. Retourner

  return this.prisma.birth.update({
    where: {
      id: birthId,
      gestation: {
        organizationId
      }
    },
    data: {
      foalName: data.foalName,
      foalGender: data.foalGender,
      foalColor: data.foalColor,
      birthWeight: data.birthWeight,
      notes: data.notes,
    },
  });
}
```

## 2. Clubs Service

**Fichier**: `/apps/api/src/modules/clubs/clubs.service.ts`

### ✅ acceptChallenge

```typescript
async acceptChallenge(challengeId: string, userId: string) {
  // 1. Vérifier que le challenge existe et est actif
  // 2. Vérifier que l'utilisateur est membre d'un club participant
  // 3. Créer une entrée ChallengeParticipant
  // 4. Retourner le challenge avec la participation

  const challenge = await this.prisma.challenge.findUnique({
    where: { id: challengeId },
    include: { club: true }
  });

  if (!challenge) {
    throw new NotFoundException('Challenge not found');
  }

  // Vérifier membership
  const membership = await this.prisma.clubMember.findFirst({
    where: {
      clubId: challenge.clubId,
      userId,
    },
  });

  if (!membership) {
    throw new ForbiddenException('Must be club member to accept challenge');
  }

  return this.prisma.challengeParticipant.create({
    data: {
      challengeId,
      userId,
      status: 'active',
    },
    include: {
      challenge: true,
    },
  });
}
```

### ✅ joinEvent

```typescript
async joinEvent(eventId: string, userId: string) {
  // 1. Vérifier que l'événement existe
  // 2. Vérifier la capacité maximale
  // 3. Vérifier que l'utilisateur n'est pas déjà inscrit
  // 4. Créer une participation

  const event = await this.prisma.clubEvent.findUnique({
    where: { id: eventId },
    include: {
      _count: {
        select: { participants: true }
      }
    }
  });

  if (!event) {
    throw new NotFoundException('Event not found');
  }

  if (event.maxParticipants && event._count.participants >= event.maxParticipants) {
    throw new BadRequestException('Event is full');
  }

  return this.prisma.eventParticipant.create({
    data: {
      eventId,
      userId,
    },
    include: {
      event: true,
    },
  });
}
```

### ✅ likePost

```typescript
async likePost(clubId: string, postId: string, userId: string) {
  // 1. Vérifier que le post existe et appartient au club
  // 2. Toggle le like (créer ou supprimer)

  const post = await this.prisma.clubPost.findUnique({
    where: { id: postId, clubId },
  });

  if (!post) {
    throw new NotFoundException('Post not found');
  }

  const existingLike = await this.prisma.postLike.findUnique({
    where: {
      userId_postId: {
        userId,
        postId,
      },
    },
  });

  if (existingLike) {
    await this.prisma.postLike.delete({
      where: { id: existingLike.id },
    });
    return { liked: false };
  } else {
    await this.prisma.postLike.create({
      data: {
        userId,
        postId,
      },
    });
    return { liked: true };
  }
}
```

## 3. Gamification Service

**Fichier**: `/apps/api/src/modules/gamification/gamification.service.ts`

### ✅ sendReferralInvite

```typescript
async sendReferralInvite(userId: string, email: string, message?: string) {
  // 1. Obtenir le code de parrainage de l'utilisateur
  // 2. Créer un enregistrement d'invitation
  // 3. Envoyer l'email d'invitation
  // 4. Retourner le statut

  const user = await this.prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      firstName: true,
      lastName: true,
      referralCode: true,
    },
  });

  if (!user) {
    throw new NotFoundException('User not found');
  }

  // Créer l'invitation
  const invitation = await this.prisma.referralInvitation.create({
    data: {
      userId,
      email,
      message,
      status: 'sent',
    },
  });

  // Envoyer l'email (via service d'email)
  // await this.emailService.sendReferralInvite({
  //   to: email,
  //   referrerName: `${user.firstName} ${user.lastName}`,
  //   referralCode: user.referralCode,
  //   message,
  // });

  return {
    success: true,
    invitation,
  };
}
```

## 4. Marketplace Service

**Fichier**: `/apps/api/src/modules/marketplace/marketplace.service.ts`

### ✅ getBreedingMatches

```typescript
async getBreedingMatches(mareId: string, userId: string) {
  // 1. Récupérer les informations de la jument
  // 2. Utiliser l'IA pour trouver des stallions compatibles
  // 3. Filtrer les stallions disponibles dans le marketplace
  // 4. Retourner les matches avec scores

  const mare = await this.prisma.breedingMare.findUnique({
    where: { id: mareId },
    include: {
      horse: true,
    },
  });

  if (!mare) {
    throw new NotFoundException('Mare not found');
  }

  // Logique AI de matching (similaire à breeding recommendations)
  const stallionListings = await this.prisma.marketplaceListing.findMany({
    where: {
      type: 'stallion_service',
      status: 'active',
    },
    include: {
      horse: true,
    },
  });

  // Calculer les scores de compatibilité
  const matches = stallionListings.map(listing => ({
    listing,
    compatibilityScore: this.calculateCompatibility(mare, listing),
    reasons: this.getMatchReasons(mare, listing),
  }));

  return matches.sort((a, b) => b.compatibilityScore - a.compatibilityScore);
}

private calculateCompatibility(mare: any, stallionListing: any): number {
  // Logique de calcul de compatibilité
  let score = 0;
  // Breed compatibility, discipline, temperament, etc.
  return score;
}
```

### ✅ reportListing

```typescript
async reportListing(
  listingId: string,
  userId: string,
  reason: string,
  details?: string
) {
  // 1. Vérifier que le listing existe
  // 2. Créer un report
  // 3. Notifier les modérateurs si nécessaire

  const listing = await this.prisma.marketplaceListing.findUnique({
    where: { id: listingId },
  });

  if (!listing) {
    throw new NotFoundException('Listing not found');
  }

  const report = await this.prisma.listingReport.create({
    data: {
      listingId,
      reportedBy: userId,
      reason,
      details,
      status: 'pending',
    },
  });

  // Notifier les modérateurs si c'est un cas grave
  if (reason === 'fraud' || reason === 'illegal') {
    // await this.notificationService.notifyModerators(report);
  }

  return {
    success: true,
    report,
  };
}
```

## 5. EquiCote Service

**Fichier**: `/apps/api/src/modules/equicote/equicote.service.ts`

### ✅ getComparables

```typescript
async getComparables(horseId: string) {
  // 1. Récupérer les informations du cheval
  // 2. Trouver des chevaux similaires (race, âge, discipline, performance)
  // 3. Récupérer leurs valorisations récentes
  // 4. Retourner la liste avec critères de similarité

  const horse = await this.prisma.horse.findUnique({
    where: { id: horseId },
    include: {
      breed: true,
      // autres relations pertinentes
    },
  });

  if (!horse) {
    throw new NotFoundException('Horse not found');
  }

  // Critères de recherche de comparables
  const ageDiff = 2; // années
  const minBirthYear = horse.birthYear - ageDiff;
  const maxBirthYear = horse.birthYear + ageDiff;

  const comparables = await this.prisma.horse.findMany({
    where: {
      id: { not: horseId },
      breedId: horse.breedId,
      birthYear: {
        gte: minBirthYear,
        lte: maxBirthYear,
      },
      discipline: horse.discipline,
    },
    include: {
      valuations: {
        orderBy: { createdAt: 'desc' },
        take: 1,
      },
    },
    take: 10,
  });

  return comparables.map(comp => ({
    horse: comp,
    latestValuation: comp.valuations[0],
    similarityScore: this.calculateSimilarity(horse, comp),
  }));
}

private calculateSimilarity(horse1: any, horse2: any): number {
  // Logique de calcul de similarité
  let score = 100;
  // Age, breed, discipline, performance, etc.
  return score;
}
```

## 6. Services Service

**Fichier**: `/apps/api/src/modules/services/services.service.ts`

### ✅ updateReview

```typescript
async updateReview(
  userId: string,
  providerId: string,
  reviewId: string,
  data: { rating?: number; comment?: string }
) {
  // 1. Vérifier que la review existe et appartient à l'utilisateur
  // 2. Mettre à jour
  // 3. Recalculer la note moyenne du provider

  const review = await this.prisma.serviceReview.findFirst({
    where: {
      id: reviewId,
      providerId,
      userId,
    },
  });

  if (!review) {
    throw new NotFoundException('Review not found or unauthorized');
  }

  const updated = await this.prisma.serviceReview.update({
    where: { id: reviewId },
    data: {
      rating: data.rating,
      comment: data.comment,
      updatedAt: new Date(),
    },
  });

  // Recalculer la moyenne
  await this.updateProviderRating(providerId);

  return updated;
}
```

### ✅ deleteReview

```typescript
async deleteReview(userId: string, providerId: string, reviewId: string) {
  const review = await this.prisma.serviceReview.findFirst({
    where: {
      id: reviewId,
      providerId,
      userId,
    },
  });

  if (!review) {
    throw new NotFoundException('Review not found or unauthorized');
  }

  await this.prisma.serviceReview.delete({
    where: { id: reviewId },
  });

  // Recalculer la moyenne
  await this.updateProviderRating(providerId);

  return { success: true };
}
```

### ✅ markReviewHelpful

```typescript
async markReviewHelpful(userId: string, reviewId: string) {
  // Toggle le vote "helpful"
  const existing = await this.prisma.reviewHelpful.findUnique({
    where: {
      userId_reviewId: {
        userId,
        reviewId,
      },
    },
  });

  if (existing) {
    await this.prisma.reviewHelpful.delete({
      where: { id: existing.id },
    });
    return { helpful: false };
  } else {
    await this.prisma.reviewHelpful.create({
      data: {
        userId,
        reviewId,
      },
    });
    return { helpful: true };
  }
}
```

### ✅ reportProvider

```typescript
async reportProvider(
  userId: string,
  providerId: string,
  data: { reason: string; details?: string }
) {
  const provider = await this.prisma.serviceProvider.findUnique({
    where: { id: providerId },
  });

  if (!provider) {
    throw new NotFoundException('Provider not found');
  }

  const report = await this.prisma.providerReport.create({
    data: {
      providerId,
      reportedBy: userId,
      reason: data.reason,
      details: data.details,
      status: 'pending',
    },
  });

  return {
    success: true,
    report,
  };
}

private async updateProviderRating(providerId: string) {
  const reviews = await this.prisma.serviceReview.findMany({
    where: { providerId },
  });

  const avgRating = reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length;

  await this.prisma.serviceProvider.update({
    where: { id: providerId },
    data: {
      averageRating: avgRating,
      reviewCount: reviews.length,
    },
  });
}
```

## Schéma Prisma Requis

Vérifier que les modèles suivants existent dans le schéma Prisma:

```prisma
model GestationCheckup {
  // Déjà existant normalement
}

model Birth {
  // Déjà existant normalement
}

model ChallengeParticipant {
  id          String   @id @default(cuid())
  challengeId String
  userId      String
  status      String
  createdAt   DateTime @default(now())

  challenge Challenge @relation(fields: [challengeId], references: [id])
  user      User      @relation(fields: [userId], references: [id])
}

model EventParticipant {
  id        String   @id @default(cuid())
  eventId   String
  userId    String
  createdAt DateTime @default(now())

  event ClubEvent @relation(fields: [eventId], references: [id])
  user  User      @relation(fields: [userId], references: [id])
}

model PostLike {
  id        String   @id @default(cuid())
  postId    String
  userId    String
  createdAt DateTime @default(now())

  post ClubPost @relation(fields: [postId], references: [id])
  user User     @relation(fields: [userId], references: [id])

  @@unique([userId, postId])
}

model ReferralInvitation {
  id        String   @id @default(cuid())
  userId    String
  email     String
  message   String?
  status    String
  createdAt DateTime @default(now())

  user User @relation(fields: [userId], references: [id])
}

model ListingReport {
  id         String   @id @default(cuid())
  listingId  String
  reportedBy String
  reason     String
  details    String?
  status     String
  createdAt  DateTime @default(now())

  listing MarketplaceListing @relation(fields: [listingId], references: [id])
  reporter User              @relation(fields: [reportedBy], references: [id])
}

model ReviewHelpful {
  id        String   @id @default(cuid())
  reviewId  String
  userId    String
  createdAt DateTime @default(now())

  review ServiceReview @relation(fields: [reviewId], references: [id])
  user   User          @relation(fields: [userId], references: [id])

  @@unique([userId, reviewId])
}

model ProviderReport {
  id         String   @id @default(cuid())
  providerId String
  reportedBy String
  reason     String
  details    String?
  status     String
  createdAt  DateTime @default(now())

  provider ServiceProvider @relation(fields: [providerId], references: [id])
  reporter User            @relation(fields: [reportedBy], references: [id])
}
```

## Tests à Écrire

Pour chaque méthode implémentée, créer des tests:

- Test unitaire du service
- Test d'intégration de l'endpoint
- Test E2E mobile → backend

---

**Priorité**: HAUTE **Estimation**: 4-6 heures de développement **Dépendances**:
Schéma Prisma mis à jour
