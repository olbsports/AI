import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ServicesService {
  constructor(private prisma: PrismaService) {}

  // Mock data for service providers
  private mockProviders = [
    {
      id: 'vet-1',
      name: 'Dr. Martin Dupont',
      type: 'veterinarian',
      specialty: 'Équine',
      phone: '+33 6 12 34 56 78',
      email: 'martin.dupont@vet.fr',
      address: '15 Rue des Chevaux, 75001 Paris',
      rating: 4.8,
      reviewCount: 45,
      available: true,
      distance: 5.2,
      photoUrl: null,
      services: ['Consultation', 'Urgences', 'Chirurgie', 'Dentisterie'],
      workingHours: {
        mon: '8:00-18:00',
        tue: '8:00-18:00',
        wed: '8:00-18:00',
        thu: '8:00-18:00',
        fri: '8:00-18:00',
      },
    },
    {
      id: 'farrier-1',
      name: 'Jean-Pierre Leblanc',
      type: 'farrier',
      specialty: 'Maréchal-ferrant',
      phone: '+33 6 98 76 54 32',
      email: 'jp.leblanc@marechal.fr',
      address: '8 Chemin du Fer, 77000 Melun',
      rating: 4.9,
      reviewCount: 78,
      available: true,
      distance: 12.5,
      photoUrl: null,
      services: ['Ferrure', 'Parage', 'Orthopédie'],
      workingHours: {
        mon: '7:00-17:00',
        tue: '7:00-17:00',
        wed: '7:00-17:00',
        thu: '7:00-17:00',
        fri: '7:00-17:00',
      },
    },
    {
      id: 'osteo-1',
      name: 'Marie Durand',
      type: 'osteopath',
      specialty: 'Ostéopathe équin',
      phone: '+33 6 45 67 89 01',
      email: 'marie.durand@osteo.fr',
      address: '22 Avenue du Sport, 78000 Versailles',
      rating: 4.7,
      reviewCount: 32,
      available: true,
      distance: 8.3,
      photoUrl: null,
      services: ['Ostéopathie', 'Massage', 'Rééducation'],
      workingHours: {
        mon: '9:00-19:00',
        tue: '9:00-19:00',
        wed: '9:00-19:00',
        thu: '9:00-19:00',
        fri: '9:00-19:00',
      },
    },
    {
      id: 'dentist-1',
      name: 'Dr. Sophie Bernard',
      type: 'dentist',
      specialty: 'Dentiste équin',
      phone: '+33 6 23 45 67 89',
      email: 'sophie.bernard@dentiste.fr',
      address: '5 Place du Marché, 91000 Évry',
      rating: 4.6,
      reviewCount: 28,
      available: false,
      distance: 15.0,
      photoUrl: null,
      services: ['Examen dentaire', 'Râpage', 'Extractions'],
      workingHours: { mon: '8:00-17:00', tue: '8:00-17:00', thu: '8:00-17:00', fri: '8:00-17:00' },
    },
  ];

  async searchProviders(filters: { query?: string; type?: string; location?: string }) {
    let providers = [...this.mockProviders];

    if (filters.type) {
      providers = providers.filter((p) => p.type === filters.type);
    }

    if (filters.query) {
      const q = filters.query.toLowerCase();
      providers = providers.filter(
        (p) => p.name.toLowerCase().includes(q) || p.specialty.toLowerCase().includes(q)
      );
    }

    return providers;
  }

  async getProviders(type?: string) {
    if (type) {
      return this.mockProviders.filter((p) => p.type === type);
    }
    return this.mockProviders;
  }

  async getNearbyProviders(lat?: number, lng?: number, emergency = false) {
    let providers = [...this.mockProviders].sort((a, b) => a.distance - b.distance);

    if (emergency) {
      providers = providers.filter((p) => p.available);
    }

    return providers.slice(0, 5);
  }

  async getSavedProviders(userId: string) {
    // Return first 2 as "saved"
    return this.mockProviders.slice(0, 2);
  }

  async getFeaturedProviders() {
    return this.mockProviders.filter((p) => p.rating >= 4.7);
  }

  async getStats(organizationId: string) {
    return {
      totalProviders: this.mockProviders.length,
      totalAppointments: 12,
      upcomingAppointments: 3,
      averageRating: 4.7,
    };
  }

  async getEmergencyContacts(organizationId: string) {
    return [
      {
        id: 'ec-1',
        name: 'Urgences Vétérinaires',
        phone: '01 44 44 44 44',
        type: 'emergency',
        notes: 'Disponible 24h/24',
      },
      {
        id: 'ec-2',
        name: 'Dr. Martin (vétérinaire)',
        phone: '+33 6 12 34 56 78',
        type: 'veterinarian',
        notes: 'Vétérinaire principal',
      },
      {
        id: 'ec-3',
        name: 'Clinique équine de Paris',
        phone: '01 55 55 55 55',
        type: 'clinic',
        notes: 'Clinique de référence',
      },
    ];
  }

  async getProvider(id: string) {
    return this.mockProviders.find((p) => p.id === id) || null;
  }

  async getProviderReviews(providerId: string) {
    return [
      {
        id: 'r1',
        userId: 'u1',
        userName: 'Jean D.',
        rating: 5,
        comment: 'Excellent vétérinaire, très professionnel',
        date: new Date(),
      },
      {
        id: 'r2',
        userId: 'u2',
        userName: 'Marie L.',
        rating: 4,
        comment: 'Bon service, un peu cher',
        date: new Date(Date.now() - 86400000),
      },
    ];
  }

  async saveProvider(userId: string, providerId: string) {
    return { success: true, message: 'Provider saved' };
  }

  async removeSavedProvider(userId: string, providerId: string) {
    return { success: true, message: 'Provider removed from saved' };
  }

  async addReview(userId: string, providerId: string, data: { rating: number; comment: string }) {
    return {
      id: `review-${Date.now()}`,
      userId,
      providerId,
      ...data,
      date: new Date(),
    };
  }

  async addEmergencyContact(
    organizationId: string,
    data: { name: string; phone: string; type: string; notes?: string }
  ) {
    return {
      id: `ec-${Date.now()}`,
      ...data,
      organizationId,
    };
  }

  async updateEmergencyContact(id: string, data: any) {
    return { id, ...data };
  }

  async deleteEmergencyContact(id: string) {
    return { success: true, message: 'Emergency contact deleted' };
  }

  // ========== APPOINTMENTS ==========

  async getAppointments(organizationId: string) {
    return [
      {
        id: 'apt-1',
        providerId: 'vet-1',
        providerName: 'Dr. Martin Dupont',
        providerType: 'veterinarian',
        horseName: 'Spirit',
        date: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
        time: '10:00',
        type: 'consultation',
        status: 'confirmed',
        notes: 'Contrôle annuel',
      },
      {
        id: 'apt-2',
        providerId: 'farrier-1',
        providerName: 'Jean-Pierre Leblanc',
        providerType: 'farrier',
        horseName: 'Thunder',
        date: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
        time: '14:00',
        type: 'ferrure',
        status: 'pending',
        notes: 'Ferrure complète',
      },
    ];
  }

  async createAppointment(organizationId: string, userId: string, data: any) {
    return {
      id: `apt-${Date.now()}`,
      ...data,
      status: 'pending',
      createdAt: new Date(),
    };
  }

  async updateAppointment(id: string, data: any) {
    return { id, ...data, updatedAt: new Date() };
  }

  async cancelAppointment(id: string) {
    return { id, status: 'cancelled', cancelledAt: new Date() };
  }

  async rateAppointment(id: string, data: { rating: number; comment?: string }) {
    return { id, ...data, ratedAt: new Date() };
  }

  async updateReview(userId: string, providerId: string, reviewId: string, data: any) {
    return { success: true, reviewId, ...data };
  }

  async deleteReview(userId: string, providerId: string, reviewId: string) {
    return { success: true, reviewId, message: 'Review deleted' };
  }

  async markReviewHelpful(userId: string, reviewId: string) {
    return { success: true, reviewId, helpful: true };
  }

  async reportProvider(userId: string, providerId: string, data: any) {
    return { success: true, providerId, message: 'Report submitted' };
  }
}
