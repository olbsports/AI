import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class GestationService {
  constructor(private prisma: PrismaService) {}

  async getGestations(userId: string, organizationId: string) {
    return this.prisma.gestation.findMany({
      where: {
        horse: { organizationId },
      },
      include: {
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
  }

  async getActiveGestations(userId: string, organizationId: string) {
    return this.prisma.gestation.findMany({
      where: {
        horse: { organizationId },
        status: 'active',
      },
      include: {
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
      },
      orderBy: { estimatedDueDate: 'asc' },
    });
  }

  async getGestation(id: string, organizationId: string) {
    const gestation = await this.prisma.gestation.findFirst({
      where: {
        id,
        horse: { organizationId },
      },
      include: {
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
            breed: true,
          },
        },
      },
    });

    if (!gestation) {
      throw new NotFoundException('Gestation not found');
    }

    return gestation;
  }

  async createGestation(
    organizationId: string,
    data: {
      horseId: string;
      stallionName?: string;
      breedingDate: string;
      expectedDueDate?: string;
      notes?: string;
    }
  ) {
    // Verify horse belongs to organization
    const horse = await this.prisma.horse.findFirst({
      where: { id: data.horseId, organizationId },
    });

    if (!horse) {
      throw new NotFoundException('Horse not found');
    }

    // Calculate expected due date if not provided (340 days average for horses)
    const breedingDate = new Date(data.breedingDate);
    const estimatedDueDate = data.expectedDueDate
      ? new Date(data.expectedDueDate)
      : new Date(breedingDate.getTime() + 340 * 24 * 60 * 60 * 1000);

    return this.prisma.gestation.create({
      data: {
        horseId: data.horseId,
        stallionName: data.stallionName || 'Unknown',
        breedingDate,
        estimatedDueDate,
        notes: data.notes,
        status: 'pending',
        method: 'natural',
      },
      include: {
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
      },
    });
  }

  async updateGestation(
    id: string,
    organizationId: string,
    data: {
      stallionName?: string;
      breedingDate?: string;
      expectedDueDate?: string;
      notes?: string;
      status?: string;
    }
  ) {
    await this.getGestation(id, organizationId);

    return this.prisma.gestation.update({
      where: { id },
      data: {
        ...(data.stallionName && { stallionName: data.stallionName }),
        ...(data.breedingDate && { breedingDate: new Date(data.breedingDate) }),
        ...(data.expectedDueDate && { estimatedDueDate: new Date(data.expectedDueDate) }),
        ...(data.notes !== undefined && { notes: data.notes }),
        ...(data.status && { status: data.status }),
      },
      include: {
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
      },
    });
  }

  async updateStatus(id: string, organizationId: string, status: string) {
    await this.getGestation(id, organizationId);

    return this.prisma.gestation.update({
      where: { id },
      data: { status },
    });
  }

  async deleteGestation(id: string, organizationId: string) {
    await this.getGestation(id, organizationId);

    return this.prisma.gestation.delete({
      where: { id },
    });
  }

  // Checkups - return mock data for now
  async getCheckups(gestationId: string, organizationId: string) {
    await this.getGestation(gestationId, organizationId);
    return [];
  }

  async addCheckup(
    gestationId: string,
    organizationId: string,
    data: {
      date: string;
      type: string;
      notes?: string;
      vetName?: string;
      results?: any;
    }
  ) {
    await this.getGestation(gestationId, organizationId);

    return {
      id: `checkup_${Date.now()}`,
      gestationId,
      ...data,
      createdAt: new Date().toISOString(),
    };
  }

  // Milestones - return mock data for now
  async getMilestones(gestationId: string, organizationId: string) {
    await this.getGestation(gestationId, organizationId);

    // Return standard gestation milestones
    return [
      { id: '1', name: 'Confirmation', day: 14, completed: false },
      { id: '2', name: 'Heartbeat detection', day: 25, completed: false },
      { id: '3', name: 'First trimester', day: 90, completed: false },
      { id: '4', name: 'Second trimester', day: 180, completed: false },
      { id: '5', name: 'Third trimester', day: 270, completed: false },
      { id: '6', name: 'Pre-foaling', day: 320, completed: false },
    ];
  }

  async completeMilestone(gestationId: string, milestoneId: string, organizationId: string) {
    await this.getGestation(gestationId, organizationId);
    return { success: true, milestoneId, completed: true };
  }

  // Notes
  async getNotes(gestationId: string, organizationId: string) {
    await this.getGestation(gestationId, organizationId);
    return [];
  }

  async addNote(gestationId: string, organizationId: string, data: { content: string }) {
    await this.getGestation(gestationId, organizationId);

    return {
      id: `note_${Date.now()}`,
      gestationId,
      content: data.content,
      createdAt: new Date().toISOString(),
    };
  }

  // Birth
  async recordBirth(
    gestationId: string,
    organizationId: string,
    data: {
      birthDate: string;
      foalName?: string;
      foalGender?: string;
      foalColor?: string;
      birthWeight?: number;
      notes?: string;
    }
  ) {
    const gestation = await this.getGestation(gestationId, organizationId);

    // Update gestation status
    await this.prisma.gestation.update({
      where: { id: gestationId },
      data: {
        status: 'born',
        actualBirthDate: new Date(data.birthDate),
        foalName: data.foalName,
        foalGender: data.foalGender,
        foalColor: data.foalColor,
        notes: data.notes
          ? `${gestation.notes || ''}\nBirth notes: ${data.notes}`
          : gestation.notes,
      },
    });

    return {
      success: true,
      gestationId,
      birthDate: data.birthDate,
      foalName: data.foalName,
    };
  }

  async recordLoss(
    gestationId: string,
    organizationId: string,
    data: {
      date: string;
      reason?: string;
      notes?: string;
    }
  ) {
    const gestation = await this.getGestation(gestationId, organizationId);

    await this.prisma.gestation.update({
      where: { id: gestationId },
      data: {
        status: 'lost',
        complications: data.reason,
        notes: data.notes
          ? `${gestation.notes || ''}\nLoss: ${data.date} - ${data.notes}`
          : gestation.notes,
      },
    });

    return { success: true, gestationId, status: 'lost' };
  }

  // Births list
  async getBirths(organizationId: string) {
    return this.prisma.gestation.findMany({
      where: {
        horse: { organizationId },
        status: 'completed',
        foalName: { not: null },
      },
      include: {
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
      },
      orderBy: { actualBirthDate: 'desc' },
    });
  }

  async getBirth(id: string, organizationId: string) {
    return this.getGestation(id, organizationId);
  }

  // Breeding stats
  async getBreedingStats(organizationId: string) {
    const [total, active, completed, lost] = await Promise.all([
      this.prisma.gestation.count({ where: { horse: { organizationId } } }),
      this.prisma.gestation.count({ where: { horse: { organizationId }, status: 'active' } }),
      this.prisma.gestation.count({ where: { horse: { organizationId }, status: 'completed' } }),
      this.prisma.gestation.count({ where: { horse: { organizationId }, status: 'lost' } }),
    ]);

    return {
      totalGestations: total,
      activeGestations: active,
      successfulBirths: completed,
      losses: lost,
      successRate: total > 0 ? ((completed / total) * 100).toFixed(1) : 0,
    };
  }

  async updateCheckup(gestationId: string, checkupId: string, organizationId: string, data: any) {
    return { success: true, checkupId, gestationId, ...data };
  }

  async updateBirth(birthId: string, organizationId: string, data: any) {
    return { success: true, birthId, ...data };
  }
}
