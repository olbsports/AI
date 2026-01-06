import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

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
      sellerName: listing.seller ? `${listing.seller.firstName} ${listing.seller.lastName}` : 'Vendeur',
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

    return listings.map(l => this.formatListing(l));
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

    return listings.map(l => this.formatListing(l));
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

    return listings.map(l => this.formatListing(l));
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

    return listings.map(l => this.formatListing(l));
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

    return listings.map(l => this.formatListing(l));
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

    return favorites.map(f => ({
      ...this.formatListing(f.listing),
      isFavorited: true,
    }));
  }

  async create(userId: string, organizationId: string, data: {
    type: string;
    title: string;
    description: string;
    price?: number;
    priceType?: string;
    horseId?: string;
    location?: string;
    photos?: string[];
    videos?: string[];
  }) {
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

    return listings.map(l => ({
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
}
