import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

interface RecommendationFactors {
  favoriteTypes: string[];
  favoriteBreeds: string[];
  favoritePriceRange: { min?: number; max?: number };
  recentFilters: any[];
  organizationHorseTypes: string[];
}

@Injectable()
export class MarketplaceRecommendationsService {
  constructor(private prisma: PrismaService) {}

  /**
   * Get personalized recommendations for a user
   * Based on: favorites history, recent filters, organization horse types
   */
  async getPersonalizedRecommendations(
    userId: string,
    organizationId: string,
    limit: number = 20
  ) {
    // Get user's recommendation factors
    const factors = await this.getUserRecommendationFactors(userId, organizationId);

    // Build recommendation query based on factors
    const whereConditions: any = {
      status: 'active',
      sellerId: { not: userId }, // Don't recommend own listings
    };

    // Prioritize based on favorite types
    if (factors.favoriteTypes.length > 0) {
      whereConditions.OR = [
        { type: { in: factors.favoriteTypes } },
        ...(factors.favoriteBreeds.length > 0
          ? [{ horse: { breed: { in: factors.favoriteBreeds } } }]
          : []),
      ];
    }

    // Price range preference
    if (factors.favoritePriceRange.min || factors.favoritePriceRange.max) {
      whereConditions.price = {};
      if (factors.favoritePriceRange.min) {
        whereConditions.price.gte = factors.favoritePriceRange.min * 0.7; // 30% below min
      }
      if (factors.favoritePriceRange.max) {
        whereConditions.price.lte = factors.favoritePriceRange.max * 1.3; // 30% above max
      }
    }

    const listings = await this.prisma.marketplaceListing.findMany({
      where: whereConditions,
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
            gender: true,
            birthDate: true,
          },
        },
        promotions: {
          where: {
            expiresAt: { gt: new Date() },
          },
        },
      },
      orderBy: [
        { isFeatured: 'desc' },
        { boostLevel: 'desc' },
        { createdAt: 'desc' },
      ],
      take: limit,
    });

    // Score and sort recommendations
    const scoredListings = listings.map((listing) => ({
      ...this.formatListing(listing),
      recommendationScore: this.calculateRecommendationScore(listing, factors),
      recommendationReasons: this.getRecommendationReasons(listing, factors),
    }));

    // Sort by recommendation score
    scoredListings.sort((a, b) => b.recommendationScore - a.recommendationScore);

    return {
      recommendations: scoredListings,
      factors: {
        basedOnFavorites: factors.favoriteTypes.length > 0,
        basedOnFilters: factors.recentFilters.length > 0,
        basedOnOrganization: factors.organizationHorseTypes.length > 0,
      },
    };
  }

  /**
   * Get similar listings to a specific listing
   */
  async getSimilarListings(listingId: string, limit: number = 10) {
    // Get the reference listing
    const referenceListing = await this.prisma.marketplaceListing.findUnique({
      where: { id: listingId },
      include: {
        horse: true,
      },
    });

    if (!referenceListing) {
      return { similar: [], referenceId: listingId };
    }

    // Build similarity query
    const whereConditions: any = {
      status: 'active',
      id: { not: listingId },
      OR: [],
    };

    // Same type
    whereConditions.OR.push({ type: referenceListing.type });

    // Similar price range (+-30%)
    if (referenceListing.price) {
      whereConditions.OR.push({
        price: {
          gte: Math.floor(referenceListing.price * 0.7),
          lte: Math.ceil(referenceListing.price * 1.3),
        },
      });
    }

    // Same breed if horse listing
    if (referenceListing.horse?.breed) {
      whereConditions.OR.push({
        horse: { breed: referenceListing.horse.breed },
      });
    }

    // Same location/country
    if (referenceListing.country) {
      whereConditions.OR.push({ country: referenceListing.country });
    }

    const similarListings = await this.prisma.marketplaceListing.findMany({
      where: whereConditions,
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
      orderBy: [{ isFeatured: 'desc' }, { boostLevel: 'desc' }, { viewCount: 'desc' }],
      take: limit * 2, // Fetch more to score and filter
    });

    // Score similarity
    const scoredListings = similarListings.map((listing) => ({
      ...this.formatListing(listing),
      similarityScore: this.calculateSimilarityScore(listing, referenceListing),
      similarityReasons: this.getSimilarityReasons(listing, referenceListing),
    }));

    // Sort by similarity score and take top results
    scoredListings.sort((a, b) => b.similarityScore - a.similarityScore);

    return {
      referenceId: listingId,
      referenceTitle: referenceListing.title,
      similar: scoredListings.slice(0, limit),
    };
  }

  /**
   * Get trending listings (most viewed/favorited recently)
   */
  async getTrendingListings(limit: number = 10) {
    const oneWeekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

    const listings = await this.prisma.marketplaceListing.findMany({
      where: {
        status: 'active',
        createdAt: { gte: oneWeekAgo },
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
            breed: true,
          },
        },
      },
      orderBy: [
        { favoriteCount: 'desc' },
        { viewCount: 'desc' },
        { contactCount: 'desc' },
      ],
      take: limit,
    });

    return listings.map((l) => ({
      ...this.formatListing(l),
      trendingScore: l.viewCount * 1 + l.favoriteCount * 3 + l.contactCount * 5,
    }));
  }

  // ============ PRIVATE METHODS ============

  private async getUserRecommendationFactors(
    userId: string,
    organizationId: string
  ): Promise<RecommendationFactors> {
    // Get user's favorites
    const favorites = await this.prisma.favorite.findMany({
      where: { userId },
      include: {
        listing: {
          include: {
            horse: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });

    // Extract patterns from favorites
    const favoriteTypes: string[] = [];
    const favoriteBreeds: string[] = [];
    const favoritePrices: number[] = [];

    favorites.forEach((fav) => {
      if (fav.listing.type) favoriteTypes.push(fav.listing.type);
      if (fav.listing.horse?.breed) favoriteBreeds.push(fav.listing.horse.breed);
      if (fav.listing.price) favoritePrices.push(fav.listing.price);
    });

    // Get organization's horses to understand preferences
    const orgHorses = await this.prisma.horse.findMany({
      where: { organizationId },
      select: { breed: true, gender: true, disciplines: true },
      take: 20,
    });

    const organizationHorseTypes = [
      ...new Set(orgHorses.map((h) => h.breed).filter(Boolean) as string[]),
    ];

    // Calculate price range preference
    const favoritePriceRange: { min?: number; max?: number } = {};
    if (favoritePrices.length > 0) {
      favoritePriceRange.min = Math.min(...favoritePrices);
      favoritePriceRange.max = Math.max(...favoritePrices);
    }

    return {
      favoriteTypes: [...new Set(favoriteTypes)].slice(0, 5),
      favoriteBreeds: [...new Set(favoriteBreeds)].slice(0, 5),
      favoritePriceRange,
      recentFilters: [], // Could be enhanced with search history
      organizationHorseTypes,
    };
  }

  private calculateRecommendationScore(listing: any, factors: RecommendationFactors): number {
    let score = 50; // Base score

    // Type match
    if (factors.favoriteTypes.includes(listing.type)) {
      score += 20;
    }

    // Breed match
    if (listing.horse?.breed && factors.favoriteBreeds.includes(listing.horse.breed)) {
      score += 15;
    }

    // Price range match
    if (listing.price && factors.favoritePriceRange.min && factors.favoritePriceRange.max) {
      if (
        listing.price >= factors.favoritePriceRange.min &&
        listing.price <= factors.favoritePriceRange.max
      ) {
        score += 15;
      }
    }

    // Featured/boosted bonus
    if (listing.isFeatured) score += 10;
    if (listing.boostLevel > 0) score += listing.boostLevel * 3;

    // Popularity bonus
    if (listing.viewCount > 100) score += 5;
    if (listing.favoriteCount > 10) score += 5;

    return Math.min(score, 100);
  }

  private getRecommendationReasons(listing: any, factors: RecommendationFactors): string[] {
    const reasons: string[] = [];

    if (factors.favoriteTypes.includes(listing.type)) {
      reasons.push('Type d\'annonce que vous consultez souvent');
    }

    if (listing.horse?.breed && factors.favoriteBreeds.includes(listing.horse.breed)) {
      reasons.push(`Race ${listing.horse.breed} que vous appréciez`);
    }

    if (listing.price && factors.favoritePriceRange.min && factors.favoritePriceRange.max) {
      if (
        listing.price >= factors.favoritePriceRange.min &&
        listing.price <= factors.favoritePriceRange.max
      ) {
        reasons.push('Dans votre gamme de prix habituelle');
      }
    }

    if (listing.isFeatured) {
      reasons.push('Annonce mise en avant');
    }

    if (reasons.length === 0) {
      reasons.push('Annonce populaire');
    }

    return reasons;
  }

  private calculateSimilarityScore(listing: any, reference: any): number {
    let score = 0;

    // Same type (highest weight)
    if (listing.type === reference.type) score += 30;

    // Same breed
    if (listing.horse?.breed && listing.horse.breed === reference.horse?.breed) {
      score += 25;
    }

    // Similar price (within 30%)
    if (listing.price && reference.price) {
      const priceDiff = Math.abs(listing.price - reference.price) / reference.price;
      if (priceDiff <= 0.1) score += 20;
      else if (priceDiff <= 0.2) score += 15;
      else if (priceDiff <= 0.3) score += 10;
    }

    // Same country
    if (listing.country === reference.country) score += 10;

    // Same seller (could be other listings from same seller)
    if (listing.sellerId === reference.sellerId) score += 5;

    // Popularity bonus
    if (listing.viewCount > 50) score += 5;
    if (listing.favoriteCount > 5) score += 5;

    return score;
  }

  private getSimilarityReasons(listing: any, reference: any): string[] {
    const reasons: string[] = [];

    if (listing.type === reference.type) {
      reasons.push('Même type d\'annonce');
    }

    if (listing.horse?.breed && listing.horse.breed === reference.horse?.breed) {
      reasons.push(`Même race (${listing.horse.breed})`);
    }

    if (listing.price && reference.price) {
      const priceDiff = Math.abs(listing.price - reference.price) / reference.price;
      if (priceDiff <= 0.3) {
        reasons.push('Prix similaire');
      }
    }

    if (listing.country === reference.country) {
      reasons.push('Même pays');
    }

    return reasons;
  }

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
      priceDisplay: listing.price ? `${listing.price.toLocaleString()} EUR` : 'Prix sur demande',
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
      horseBreed: listing.horse?.breed,
      viewCount: listing.viewCount,
      favoriteCount: listing.favoriteCount,
      contactCount: listing.contactCount,
      isFeatured: listing.isFeatured,
      isPremium: listing.boostLevel > 0,
      isVerified: listing.hasVetCheck,
      createdAt: listing.createdAt,
    };
  }
}
