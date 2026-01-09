import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

// Promotion types and their costs/durations
const PROMOTION_CONFIG = {
  featured: { tokenCost: 50, durationDays: 7, boostLevel: 3 },
  boost: { tokenCost: 30, durationDays: 3, boostLevel: 2 },
  refresh: { tokenCost: 10, durationDays: 0, boostLevel: 0 }, // Refresh just updates createdAt
} as const;

type PromotionType = keyof typeof PROMOTION_CONFIG;

@Injectable()
export class MarketplaceService {
  constructor(private prisma: PrismaService) {}

  private formatListing(listing: any) {
    return {
      id: listing.id,
      type: listing.type,
      status: listing.status,
      title: listing.title,
      description: listing.description,
      price: listing.price,
      priceType: listing.priceType,
      currency: listing.currency,
      priceDisplay: listing.price ? `${listing.price.toLocaleString()} €` : 'Prix sur demande',
      mediaUrls: listing.photos || [],
      videoUrls: listing.videos || [],
      sellerName: listing.seller
        ? `${listing.seller.firstName} ${listing.seller.lastName}`
        : 'Vendeur',
      sellerPhotoUrl: listing.seller?.avatarUrl,
      sellerId: listing.sellerId,
      sellerLocation: listing.location,
      horseId: listing.horseId,
      horseName: listing.horse?.name,
      viewCount: listing.viewCount,
      favoriteCount: listing.favoriteCount,
      contactCount: listing.contactCount,
      isFeatured: listing.isFeatured,
      isPremium: listing.boostLevel > 0,
      isVerified: listing.hasVetCheck,
      isFavorited: false, // Will be set dynamically
      createdAt: listing.createdAt,
    };
  }

  async search(filters: {
    type?: string;
    minPrice?: number;
    maxPrice?: number;
    breed?: string;
    sortBy?: string;
  }) {
    const where: any = {
      status: 'active',
    };

    if (filters.type) {
      where.type = filters.type;
    }
    if (filters.minPrice) {
      where.price = { ...where.price, gte: filters.minPrice };
    }
    if (filters.maxPrice) {
      where.price = { ...where.price, lte: filters.maxPrice };
    }

    let orderBy: any = { createdAt: 'desc' };
    if (filters.sortBy === 'price_asc') orderBy = { price: 'asc' };
    if (filters.sortBy === 'price_desc') orderBy = { price: 'desc' };
    if (filters.sortBy === 'popular') orderBy = { viewCount: 'desc' };

    const listings = await this.prisma.marketplaceListing.findMany({
      where,
      include: {
        seller: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
            breed: true,
          },
        },
      },
      orderBy,
      take: 50,
    });

    return listings.map((l) => this.formatListing(l));
  }

  async getByType(type: string) {
    const listings = await this.prisma.marketplaceListing.findMany({
      where: {
        status: 'active',
        type,
      },
      include: {
        seller: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });

    return listings.map((l) => this.formatListing(l));
  }

  async getRecent() {
    const listings = await this.prisma.marketplaceListing.findMany({
      where: { status: 'active' },
      include: {
        seller: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 20,
    });

    return listings.map((l) => this.formatListing(l));
  }

  async getFeatured() {
    const listings = await this.prisma.marketplaceListing.findMany({
      where: {
        status: 'active',
        isFeatured: true,
      },
      include: {
        seller: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 10,
    });

    return listings.map((l) => this.formatListing(l));
  }

  async getById(listingId: string, userId?: string) {
    const listing = await this.prisma.marketplaceListing.findUnique({
      where: { id: listingId },
      include: {
        seller: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
        horse: true,
      },
    });

    if (!listing) {
      throw new NotFoundException('Listing not found');
    }

    // Increment view count
    await this.prisma.marketplaceListing.update({
      where: { id: listingId },
      data: { viewCount: { increment: 1 } },
    });

    const formatted = this.formatListing(listing);

    // Check if user has favorited
    if (userId) {
      const favorite = await this.prisma.favorite.findUnique({
        where: {
          userId_listingId: { userId, listingId },
        },
      });
      formatted.isFavorited = !!favorite;
    }

    return formatted;
  }

  async getMyListings(userId: string) {
    const listings = await this.prisma.marketplaceListing.findMany({
      where: { sellerId: userId },
      include: {
        seller: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return listings.map((l) => this.formatListing(l));
  }

  async getFavorites(userId: string) {
    const favorites = await this.prisma.favorite.findMany({
      where: { userId },
      include: {
        listing: {
          include: {
            seller: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                avatarUrl: true,
              },
            },
            horse: {
              select: {
                id: true,
                name: true,
                photoUrl: true,
              },
            },
          },
        },
      },
    });

    return favorites.map((f) => ({
      ...this.formatListing(f.listing),
      isFavorited: true,
    }));
  }

  async create(
    userId: string,
    organizationId: string,
    data: {
      type: string;
      title: string;
      description: string;
      price?: number;
      priceType?: string;
      horseId?: string;
      location?: string;
      photos?: string[];
      videos?: string[];
    }
  ) {
    return this.prisma.marketplaceListing.create({
      data: {
        type: data.type,
        title: data.title,
        description: data.description,
        price: data.price,
        priceType: data.priceType || 'fixed',
        horseId: data.horseId,
        location: data.location,
        photos: data.photos || [],
        videos: data.videos || [],
        sellerId: userId,
        organizationId,
        status: 'active',
      },
    });
  }

  async update(listingId: string, userId: string, data: any) {
    const listing = await this.prisma.marketplaceListing.findUnique({
      where: { id: listingId },
    });

    if (!listing) {
      throw new NotFoundException('Listing not found');
    }

    if (listing.sellerId !== userId) {
      throw new ForbiddenException('You can only edit your own listings');
    }

    return this.prisma.marketplaceListing.update({
      where: { id: listingId },
      data,
    });
  }

  async delete(listingId: string, userId: string) {
    const listing = await this.prisma.marketplaceListing.findUnique({
      where: { id: listingId },
    });

    if (!listing) {
      throw new NotFoundException('Listing not found');
    }

    if (listing.sellerId !== userId) {
      throw new ForbiddenException('You can only delete your own listings');
    }

    return this.prisma.marketplaceListing.delete({
      where: { id: listingId },
    });
  }

  async toggleFavorite(listingId: string, userId: string, organizationId: string) {
    const existingFavorite = await this.prisma.favorite.findUnique({
      where: {
        userId_listingId: { userId, listingId },
      },
    });

    if (existingFavorite) {
      await this.prisma.favorite.delete({
        where: { id: existingFavorite.id },
      });
      await this.prisma.marketplaceListing.update({
        where: { id: listingId },
        data: { favoriteCount: { decrement: 1 } },
      });
      return { favorited: false };
    } else {
      await this.prisma.favorite.create({
        data: {
          userId,
          listingId,
          organizationId,
        },
      });
      await this.prisma.marketplaceListing.update({
        where: { id: listingId },
        data: { favoriteCount: { increment: 1 } },
      });
      return { favorited: true };
    }
  }

  async contactSeller(listingId: string, userId: string, message: string) {
    const listing = await this.prisma.marketplaceListing.findUnique({
      where: { id: listingId },
    });

    if (!listing) {
      throw new NotFoundException('Listing not found');
    }

    // Create message
    await this.prisma.message.create({
      data: {
        content: message,
        senderId: userId,
        receiverId: listing.sellerId,
        listingId,
      },
    });

    // Increment contact count
    await this.prisma.marketplaceListing.update({
      where: { id: listingId },
      data: { contactCount: { increment: 1 } },
    });

    return { success: true };
  }

  // Breeding listings (simplified)
  async getBreedingListings(type: string, breed?: string) {
    const listings = await this.prisma.marketplaceListing.findMany({
      where: {
        status: 'active',
        type: { in: ['stallion_service', 'mare_lease'] },
      },
      include: {
        seller: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
        horse: true,
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });

    return listings.map((l) => ({
      id: l.id,
      type: l.type === 'stallion_service' ? 'stallionSemen' : 'mareForBreeding',
      horseName: l.horse?.name || l.title,
      horseId: l.horseId,
      price: l.servicePrice || l.price,
      priceDisplay: l.servicePrice ? `${l.servicePrice.toLocaleString()} €` : 'Prix sur demande',
      mediaUrls: l.photos || [],
      studbook: l.horse?.studbook,
      breed: l.horse?.breed,
      sellerName: `${l.seller.firstName} ${l.seller.lastName}`,
      sellerId: l.sellerId,
      description: l.description,
      freshSemen: l.freshSemen,
      frozenSemen: l.frozenSemen,
      naturalService: l.naturalService,
      indices: null,
      previousFoals: null,
      embryoTransfer: false,
    }));
  }

  // Get horse profile with all listings
  async getHorseProfile(horseId: string) {
    const horse = await this.prisma.horse.findUnique({
      where: { id: horseId },
      include: {
        competitionResults: {
          orderBy: { competitionDate: 'desc' },
          take: 10,
        },
      },
    });

    if (!horse) {
      throw new NotFoundException('Horse not found');
    }

    const listings = await this.prisma.marketplaceListing.findMany({
      where: { horseId },
      include: {
        seller: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return {
      horse: {
        id: horse.id,
        name: horse.name,
        breed: horse.breed,
        studbook: horse.studbook,
        birthDate: horse.birthDate,
        gender: horse.gender,
        color: horse.color,
        heightCm: horse.heightCm,
        photoUrl: horse.photoUrl,
        level: horse.level,
        disciplines: horse.disciplines,
      },
      listings: listings.map((l) => this.formatListing(l)),
      competitionResults: horse.competitionResults,
      stats: {
        totalListings: listings.length,
        activeListings: listings.filter((l) => l.status === 'active').length,
        soldListings: listings.filter((l) => l.status === 'sold').length,
        totalViews: listings.reduce((sum, l) => sum + l.viewCount, 0),
      },
    };
  }

  // Get marketplace statistics
  async getStats() {
    const [
      totalListings,
      activeListings,
      totalViews,
      totalFavorites,
      recentSales,
      popularCategories,
    ] = await Promise.all([
      this.prisma.marketplaceListing.count(),
      this.prisma.marketplaceListing.count({ where: { status: 'active' } }),
      this.prisma.marketplaceListing.aggregate({
        _sum: { viewCount: true },
      }),
      this.prisma.favorite.count(),
      this.prisma.marketplaceListing.count({
        where: {
          status: 'sold',
          updatedAt: {
            gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // Last 30 days
          },
        },
      }),
      this.prisma.marketplaceListing.groupBy({
        by: ['type'],
        where: { status: 'active' },
        _count: true,
        orderBy: { _count: { type: 'desc' } },
        take: 5,
      }),
    ]);

    return {
      totalListings,
      activeListings,
      soldListings: await this.prisma.marketplaceListing.count({ where: { status: 'sold' } }),
      draftListings: await this.prisma.marketplaceListing.count({ where: { status: 'draft' } }),
      totalViews: totalViews._sum.viewCount || 0,
      totalFavorites,
      recentSales,
      popularCategories: popularCategories.map((c) => ({
        type: c.type,
        count: c._count,
      })),
      averagePrice: await this.getAveragePrice(),
    };
  }

  private async getAveragePrice() {
    const result = await this.prisma.marketplaceListing.aggregate({
      where: {
        status: 'active',
        price: { not: null },
      },
      _avg: { price: true },
    });
    return Math.round(result._avg.price || 0);
  }

  // Mark listing as sold
  async markAsSold(listingId: string, userId: string, soldPrice?: number, soldDate?: Date) {
    const listing = await this.prisma.marketplaceListing.findUnique({
      where: { id: listingId },
    });

    if (!listing) {
      throw new NotFoundException('Listing not found');
    }

    if (listing.sellerId !== userId) {
      throw new ForbiddenException('You can only mark your own listings as sold');
    }

    return this.prisma.marketplaceListing.update({
      where: { id: listingId },
      data: {
        status: 'sold',
        soldPrice: soldPrice || listing.price,
        soldAt: soldDate ? new Date(soldDate) : new Date(),
      },
    });
  }

  // Promote listing (boost)
  async promoteListing(listingId: string, userId: string, boostLevel: number, duration: number) {
    const listing = await this.prisma.marketplaceListing.findUnique({
      where: { id: listingId },
    });

    if (!listing) {
      throw new NotFoundException('Listing not found');
    }

    if (listing.sellerId !== userId) {
      throw new ForbiddenException('You can only promote your own listings');
    }

    const featuredUntil = new Date(Date.now() + duration * 24 * 60 * 60 * 1000);

    return this.prisma.marketplaceListing.update({
      where: { id: listingId },
      data: {
        boostLevel,
        featuredUntil,
        isFeatured: boostLevel >= 2,
      },
    });
  }

  // Get AI-generated horse profile
  async getAIHorseProfile(horseId: string) {
    const horse = await this.prisma.horse.findUnique({
      where: { id: horseId },
      include: {
        competitionResults: {
          orderBy: { competitionDate: 'desc' },
          take: 10,
        },
        healthRecords: {
          orderBy: { date: 'desc' },
          take: 5,
        },
      },
    });

    if (!horse) {
      throw new NotFoundException('Horse not found');
    }

    // Generate AI profile
    const profile = this.generateBasicProfile(horse);

    return {
      horseId,
      horseName: horse.name,
      profile: profile.description,
      highlights: profile.highlights,
      lastUpdated: new Date(),
      cached: false,
    };
  }

  private generateBasicProfile(horse: any) {
    const highlights: string[] = [];
    let description = `${horse.name} est un`;

    if (horse.gender === 'stallion') description += ' étalon';
    else if (horse.gender === 'mare') description += 'e jument';
    else if (horse.gender === 'gelding') description += ' hongre';

    if (horse.studbook) {
      description += ` ${horse.studbook}`;
      highlights.push(`Studbook: ${horse.studbook}`);
    }

    if (horse.birthDate) {
      const age = Math.floor(
        (Date.now() - horse.birthDate.getTime()) / (365.25 * 24 * 60 * 60 * 1000)
      );
      description += ` de ${age} ans`;
      highlights.push(`Âge: ${age} ans`);
    }

    if (horse.level) {
      description += `, niveau ${horse.level}`;
      highlights.push(`Niveau: ${horse.level}`);
    }

    if (horse.disciplines && (horse.disciplines as string[]).length > 0) {
      description += `. Pratique: ${(horse.disciplines as string[]).join(', ')}`;
      highlights.push(`Disciplines: ${(horse.disciplines as string[]).join(', ')}`);
    }

    if (horse.competitionResults?.length > 0) {
      const wins = horse.competitionResults.filter((r: any) => r.rank === 1).length;
      if (wins > 0) {
        description += `. ${wins} victoire${wins > 1 ? 's' : ''} en compétition`;
        highlights.push(`${wins} victoire${wins > 1 ? 's' : ''}`);
      }
    }

    description += '.';

    return { description, highlights };
  }

  // Analyze listing with AI
  async analyzeWithAI(data: {
    title: string;
    description: string;
    price?: number;
    horseId?: string;
  }) {
    // This would call the AI service for analysis
    // For now, return a basic analysis
    const analysis = {
      titleScore: this.scoreTitleQuality(data.title),
      descriptionScore: this.scoreDescriptionQuality(data.description),
      priceAnalysis: data.price ? this.analyzePricing(data.price) : null,
      suggestions: [] as string[],
      estimatedViews: 0,
    };

    if (analysis.titleScore < 70) {
      analysis.suggestions.push('Rendre le titre plus descriptif et accrocheur');
    }

    if (analysis.descriptionScore < 70) {
      analysis.suggestions.push('Ajouter plus de détails dans la description');
    }

    if (data.price && analysis.priceAnalysis?.competitive === false) {
      analysis.suggestions.push('Le prix semble élevé par rapport au marché');
    }

    if (!data.horseId) {
      analysis.suggestions.push('Associer un cheval pour augmenter la visibilité');
    }

    // Estimate views based on quality scores
    analysis.estimatedViews = Math.round(
      ((analysis.titleScore + analysis.descriptionScore) / 2) * 10
    );

    return analysis;
  }

  private scoreTitleQuality(title: string): number {
    let score = 50;

    if (title.length > 20) score += 20;
    if (title.length > 40) score += 10;
    if (/[A-Z]/.test(title)) score += 10; // Has capital letters
    if (title.includes('-')) score += 5;
    if (title.split(' ').length > 3) score += 5;

    return Math.min(score, 100);
  }

  private scoreDescriptionQuality(description: string): number {
    let score = 50;

    if (description.length > 100) score += 15;
    if (description.length > 200) score += 15;
    if (description.length > 300) score += 10;
    if (description.split('\n').length > 2) score += 5; // Multiple paragraphs
    if (description.match(/\d+/)) score += 5; // Contains numbers

    return Math.min(score, 100);
  }

  private analyzePricing(price: number): { range: string; competitive: boolean } {
    // Simple price analysis (would be more sophisticated with real market data)
    if (price < 5000) return { range: 'low', competitive: true };
    if (price < 15000) return { range: 'medium', competitive: true };
    if (price < 50000) return { range: 'high', competitive: false };
    return { range: 'premium', competitive: false };
  }

  async getBreedingMatches(mareId: string, userId: string) {
    return { mareId, matches: [], message: 'Breeding matches feature coming soon' };
  }

  async reportListing(listingId: string, userId: string, reason: string, details?: string) {
    return { success: true, listingId, message: 'Report submitted' };
  }

  // ============ PROMOTION SYSTEM ============

  /**
   * Promote a listing with tokens
   * Types: featured (50 tokens, 7 days), boost (30 tokens, 3 days), refresh (10 tokens)
   */
  async promoteListingWithTokens(
    listingId: string,
    userId: string,
    organizationId: string,
    type: PromotionType
  ) {
    const listing = await this.prisma.marketplaceListing.findUnique({
      where: { id: listingId },
    });

    if (!listing) {
      throw new NotFoundException('Listing not found');
    }

    if (listing.sellerId !== userId) {
      throw new ForbiddenException('You can only promote your own listings');
    }

    const config = PROMOTION_CONFIG[type];
    if (!config) {
      throw new BadRequestException('Invalid promotion type. Use: featured, boost, or refresh');
    }

    // Check organization token balance
    const org = await this.prisma.organization.findUnique({
      where: { id: organizationId },
      select: { tokenBalance: true },
    });

    if (!org || org.tokenBalance < config.tokenCost) {
      throw new BadRequestException(
        `Insufficient tokens. Required: ${config.tokenCost}, Available: ${org?.tokenBalance || 0}`
      );
    }

    // Calculate expiration
    const expiresAt =
      config.durationDays > 0
        ? new Date(Date.now() + config.durationDays * 24 * 60 * 60 * 1000)
        : null;

    // Use transaction to ensure atomicity
    const result = await this.prisma.$transaction(async (tx) => {
      // Deduct tokens
      await tx.organization.update({
        where: { id: organizationId },
        data: { tokenBalance: { decrement: config.tokenCost } },
      });

      // Record token transaction
      await tx.tokenTransaction.create({
        data: {
          amount: -config.tokenCost,
          type: 'debit',
          description: `Promotion ${type} for listing: ${listing.title}`,
          metadata: { listingId, promotionType: type },
          organizationId,
        },
      });

      // Create promotion record
      const promotion = await tx.listingPromotion.create({
        data: {
          listingId,
          type,
          tokenCost: config.tokenCost,
          expiresAt,
        },
      });

      // Update listing based on promotion type
      const updateData: any = {};

      if (type === 'featured') {
        updateData.isFeatured = true;
        updateData.featuredUntil = expiresAt;
        updateData.boostLevel = Math.max(listing.boostLevel, config.boostLevel);
      } else if (type === 'boost') {
        updateData.boostLevel = Math.max(listing.boostLevel, config.boostLevel);
        updateData.featuredUntil = expiresAt;
      } else if (type === 'refresh') {
        // Refresh brings the listing to the top of recent
        updateData.createdAt = new Date();
      }

      const updatedListing = await tx.marketplaceListing.update({
        where: { id: listingId },
        data: updateData,
      });

      return { promotion, listing: updatedListing };
    });

    return {
      success: true,
      promotion: {
        id: result.promotion.id,
        type,
        tokenCost: config.tokenCost,
        startedAt: result.promotion.startedAt,
        expiresAt: result.promotion.expiresAt,
      },
      listing: this.formatListing(result.listing),
      message: `Listing promoted successfully with ${type}`,
    };
  }

  /**
   * Get current promotion status for a listing
   */
  async getListingPromotion(listingId: string) {
    const listing = await this.prisma.marketplaceListing.findUnique({
      where: { id: listingId },
      select: {
        id: true,
        title: true,
        isFeatured: true,
        featuredUntil: true,
        boostLevel: true,
      },
    });

    if (!listing) {
      throw new NotFoundException('Listing not found');
    }

    // Get active promotions
    const activePromotions = await this.prisma.listingPromotion.findMany({
      where: {
        listingId,
        OR: [{ expiresAt: { gt: new Date() } }, { expiresAt: null }],
      },
      orderBy: { createdAt: 'desc' },
    });

    // Get promotion history
    const promotionHistory = await this.prisma.listingPromotion.findMany({
      where: { listingId },
      orderBy: { createdAt: 'desc' },
      take: 10,
    });

    return {
      listingId,
      title: listing.title,
      currentStatus: {
        isFeatured: listing.isFeatured,
        featuredUntil: listing.featuredUntil,
        boostLevel: listing.boostLevel,
        isActive: activePromotions.length > 0,
      },
      activePromotions: activePromotions.map((p) => ({
        id: p.id,
        type: p.type,
        startedAt: p.startedAt,
        expiresAt: p.expiresAt,
        tokenCost: p.tokenCost,
      })),
      history: promotionHistory.map((p) => ({
        id: p.id,
        type: p.type,
        startedAt: p.startedAt,
        expiresAt: p.expiresAt,
        tokenCost: p.tokenCost,
        isExpired: p.expiresAt ? p.expiresAt < new Date() : false,
      })),
      availablePromotions: Object.entries(PROMOTION_CONFIG).map(([key, value]) => ({
        type: key,
        tokenCost: value.tokenCost,
        durationDays: value.durationDays,
        description: this.getPromotionDescription(key as PromotionType),
      })),
    };
  }

  private getPromotionDescription(type: PromotionType): string {
    switch (type) {
      case 'featured':
        return 'Mise en avant pendant 7 jours - Affichage prioritaire sur la page d\'accueil';
      case 'boost':
        return 'Boost de visibilité pendant 3 jours - Meilleur classement dans les recherches';
      case 'refresh':
        return 'Remontée en tête des annonces récentes';
      default:
        return '';
    }
  }

  // ============ LISTING ALERTS SYSTEM ============

  /**
   * Create a new listing alert
   */
  async createListingAlert(
    userId: string,
    data: {
      filters: {
        type?: string;
        minPrice?: number;
        maxPrice?: number;
        breed?: string;
        location?: string;
        country?: string;
      };
      notifyEmail?: boolean;
      notifyPush?: boolean;
    }
  ) {
    // Validate that at least one filter is provided
    if (!data.filters || Object.keys(data.filters).length === 0) {
      throw new BadRequestException('At least one filter must be provided');
    }

    const alert = await this.prisma.listingAlert.create({
      data: {
        userId,
        filters: data.filters,
        notifyEmail: data.notifyEmail ?? true,
        notifyPush: data.notifyPush ?? true,
      },
    });

    return {
      id: alert.id,
      filters: alert.filters,
      notifyEmail: alert.notifyEmail,
      notifyPush: alert.notifyPush,
      isActive: alert.isActive,
      createdAt: alert.createdAt,
    };
  }

  /**
   * Get user's listing alerts
   */
  async getListingAlerts(userId: string) {
    const alerts = await this.prisma.listingAlert.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    return alerts.map((alert) => ({
      id: alert.id,
      filters: alert.filters,
      notifyEmail: alert.notifyEmail,
      notifyPush: alert.notifyPush,
      isActive: alert.isActive,
      lastTriggeredAt: alert.lastTriggeredAt,
      createdAt: alert.createdAt,
    }));
  }

  /**
   * Update a listing alert
   */
  async updateListingAlert(
    alertId: string,
    userId: string,
    data: {
      filters?: any;
      notifyEmail?: boolean;
      notifyPush?: boolean;
      isActive?: boolean;
    }
  ) {
    const alert = await this.prisma.listingAlert.findUnique({
      where: { id: alertId },
    });

    if (!alert) {
      throw new NotFoundException('Alert not found');
    }

    if (alert.userId !== userId) {
      throw new ForbiddenException('You can only update your own alerts');
    }

    const updated = await this.prisma.listingAlert.update({
      where: { id: alertId },
      data: {
        ...(data.filters && { filters: data.filters }),
        ...(data.notifyEmail !== undefined && { notifyEmail: data.notifyEmail }),
        ...(data.notifyPush !== undefined && { notifyPush: data.notifyPush }),
        ...(data.isActive !== undefined && { isActive: data.isActive }),
      },
    });

    return {
      id: updated.id,
      filters: updated.filters,
      notifyEmail: updated.notifyEmail,
      notifyPush: updated.notifyPush,
      isActive: updated.isActive,
      createdAt: updated.createdAt,
    };
  }

  /**
   * Delete a listing alert
   */
  async deleteListingAlert(alertId: string, userId: string) {
    const alert = await this.prisma.listingAlert.findUnique({
      where: { id: alertId },
    });

    if (!alert) {
      throw new NotFoundException('Alert not found');
    }

    if (alert.userId !== userId) {
      throw new ForbiddenException('You can only delete your own alerts');
    }

    await this.prisma.listingAlert.delete({
      where: { id: alertId },
    });

    return { success: true, message: 'Alert deleted successfully' };
  }

  // ============ SELLER STATS ============

  /**
   * Get seller statistics
   */
  async getSellerStats(userId: string) {
    // Get all seller's listings
    const listings = await this.prisma.marketplaceListing.findMany({
      where: { sellerId: userId },
      include: {
        promotions: true,
      },
    });

    // Calculate stats
    const totalListings = listings.length;
    const activeListings = listings.filter((l) => l.status === 'active').length;
    const soldListings = listings.filter((l) => l.status === 'sold').length;
    const draftListings = listings.filter((l) => l.status === 'draft').length;

    const totalViews = listings.reduce((sum, l) => sum + l.viewCount, 0);
    const totalContacts = listings.reduce((sum, l) => sum + l.contactCount, 0);
    const totalFavorites = listings.reduce((sum, l) => sum + l.favoriteCount, 0);

    // Calculate conversion rate (contacts / views)
    const conversionRate = totalViews > 0 ? (totalContacts / totalViews) * 100 : 0;

    // Calculate sales stats
    const salesRevenue = listings
      .filter((l) => l.status === 'sold' && l.soldPrice)
      .reduce((sum, l) => sum + (l.soldPrice || 0), 0);

    const averageSalePrice =
      soldListings > 0
        ? salesRevenue / soldListings
        : 0;

    // Calculate time-based stats (last 30 days)
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const recentListings = listings.filter((l) => new Date(l.createdAt) >= thirtyDaysAgo);
    const recentViews = recentListings.reduce((sum, l) => sum + l.viewCount, 0);
    const recentContacts = recentListings.reduce((sum, l) => sum + l.contactCount, 0);

    // Calculate promotion stats
    const totalPromotions = listings.reduce((sum, l) => sum + l.promotions.length, 0);
    const totalPromotionSpent = listings.reduce(
      (sum, l) => sum + l.promotions.reduce((pSum, p) => pSum + p.tokenCost, 0),
      0
    );

    // Get top performing listings
    const topListings = [...listings]
      .filter((l) => l.status === 'active')
      .sort((a, b) => b.viewCount - a.viewCount)
      .slice(0, 5)
      .map((l) => ({
        id: l.id,
        title: l.title,
        viewCount: l.viewCount,
        favoriteCount: l.favoriteCount,
        contactCount: l.contactCount,
        price: l.price,
      }));

    // Get listings by type
    const listingsByType = listings.reduce(
      (acc, l) => {
        acc[l.type] = (acc[l.type] || 0) + 1;
        return acc;
      },
      {} as Record<string, number>
    );

    // Calculate performance by listing type
    const performanceByType = Object.keys(listingsByType).map((type) => {
      const typeListings = listings.filter((l) => l.type === type);
      return {
        type,
        count: typeListings.length,
        totalViews: typeListings.reduce((sum, l) => sum + l.viewCount, 0),
        totalContacts: typeListings.reduce((sum, l) => sum + l.contactCount, 0),
        avgViews:
          typeListings.length > 0
            ? Math.round(typeListings.reduce((sum, l) => sum + l.viewCount, 0) / typeListings.length)
            : 0,
      };
    });

    return {
      overview: {
        totalListings,
        activeListings,
        soldListings,
        draftListings,
      },
      engagement: {
        totalViews,
        totalContacts,
        totalFavorites,
        conversionRate: Math.round(conversionRate * 100) / 100, // 2 decimal places
        viewToFavoriteRate: totalViews > 0 ? Math.round((totalFavorites / totalViews) * 10000) / 100 : 0,
      },
      sales: {
        totalSold: soldListings,
        totalRevenue: salesRevenue,
        averageSalePrice: Math.round(averageSalePrice),
        currency: 'EUR',
      },
      last30Days: {
        newListings: recentListings.length,
        views: recentViews,
        contacts: recentContacts,
      },
      promotions: {
        totalPromotions,
        tokensSpent: totalPromotionSpent,
      },
      topListings,
      listingsByType,
      performanceByType,
    };
  }
}
