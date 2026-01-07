import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ClubsService {
  constructor(private prisma: PrismaService) {}

  async getMyClubs(userId: string) {
    const memberships = await this.prisma.clubMembership.findMany({
      where: { userId, status: 'active' },
      include: {
        club: true,
      },
    });
    return memberships.map((m) => ({
      ...m.club,
      role: m.role,
      joinedAt: m.joinedAt,
    }));
  }

  async getClub(clubId: string) {
    const club = await this.prisma.club.findUnique({
      where: { id: clubId },
      include: {
        _count: {
          select: {
            memberships: true,
          },
        },
      },
    });

    if (!club) {
      throw new NotFoundException('Club not found');
    }

    return club;
  }

  async createClub(
    userId: string,
    organizationId: string,
    data: {
      name: string;
      description?: string;
      type?: string;
      location?: string;
      isPublic?: boolean;
    }
  ) {
    // Create club
    const club = await this.prisma.club.create({
      data: {
        name: data.name,
        description: data.description,
        type: data.type || 'stable',
        location: data.location,
        isPublic: data.isPublic ?? true,
        memberCount: 1,
      },
    });

    // Add creator as owner
    await this.prisma.clubMembership.create({
      data: {
        clubId: club.id,
        userId,
        organizationId,
        role: 'owner',
        status: 'active',
      },
    });

    return club;
  }

  async updateClub(
    clubId: string,
    userId: string,
    data: {
      name?: string;
      description?: string;
      logoUrl?: string;
      coverUrl?: string;
      location?: string;
      isPublic?: boolean;
    }
  ) {
    // Check if user is admin/owner
    const membership = await this.prisma.clubMembership.findUnique({
      where: {
        clubId_userId: { clubId, userId },
      },
    });

    if (!membership || !['owner', 'admin'].includes(membership.role)) {
      throw new ForbiddenException('You do not have permission to update this club');
    }

    return this.prisma.club.update({
      where: { id: clubId },
      data,
    });
  }

  async deleteClub(clubId: string, userId: string) {
    const membership = await this.prisma.clubMembership.findUnique({
      where: {
        clubId_userId: { clubId, userId },
      },
    });

    if (!membership || membership.role !== 'owner') {
      throw new ForbiddenException('Only the owner can delete this club');
    }

    return this.prisma.club.delete({
      where: { id: clubId },
    });
  }

  async getMembers(clubId: string) {
    const memberships = await this.prisma.clubMembership.findMany({
      where: { clubId, status: 'active' },
      include: {
        user: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
      },
    });

    return memberships.map((m) => ({
      id: m.id,
      memberId: m.userId,
      memberName: `${m.user.firstName} ${m.user.lastName}`,
      memberPhotoUrl: m.user.avatarUrl,
      role: m.role,
      joinedAt: m.joinedAt,
    }));
  }

  async joinClub(clubId: string, userId: string, organizationId: string) {
    const club = await this.prisma.club.findUnique({
      where: { id: clubId },
    });

    if (!club) {
      throw new NotFoundException('Club not found');
    }

    const existingMembership = await this.prisma.clubMembership.findUnique({
      where: {
        clubId_userId: { clubId, userId },
      },
    });

    if (existingMembership) {
      throw new ForbiddenException('You are already a member of this club');
    }

    // Create membership
    await this.prisma.clubMembership.create({
      data: {
        clubId,
        userId,
        organizationId,
        role: 'member',
        status: club.requiresApproval ? 'pending' : 'active',
      },
    });

    // Update member count
    if (!club.requiresApproval) {
      await this.prisma.club.update({
        where: { id: clubId },
        data: { memberCount: { increment: 1 } },
      });
    }

    return { success: true };
  }

  async leaveClub(clubId: string, userId: string) {
    const membership = await this.prisma.clubMembership.findUnique({
      where: {
        clubId_userId: { clubId, userId },
      },
    });

    if (!membership) {
      throw new NotFoundException('You are not a member of this club');
    }

    if (membership.role === 'owner') {
      throw new ForbiddenException('The owner cannot leave the club. Transfer ownership first.');
    }

    await this.prisma.clubMembership.delete({
      where: { id: membership.id },
    });

    await this.prisma.club.update({
      where: { id: clubId },
      data: { memberCount: { decrement: 1 } },
    });

    return { success: true };
  }

  async updateMemberRole(clubId: string, memberId: string, userId: string, role: string) {
    const adminMembership = await this.prisma.clubMembership.findUnique({
      where: {
        clubId_userId: { clubId, userId },
      },
    });

    if (!adminMembership || !['owner', 'admin'].includes(adminMembership.role)) {
      throw new ForbiddenException('You do not have permission to update member roles');
    }

    return this.prisma.clubMembership.update({
      where: {
        clubId_userId: { clubId, userId: memberId },
      },
      data: { role },
    });
  }

  async removeMember(clubId: string, memberId: string, userId: string) {
    const adminMembership = await this.prisma.clubMembership.findUnique({
      where: {
        clubId_userId: { clubId, userId },
      },
    });

    if (!adminMembership || !['owner', 'admin'].includes(adminMembership.role)) {
      throw new ForbiddenException('You do not have permission to remove members');
    }

    await this.prisma.clubMembership.delete({
      where: {
        clubId_userId: { clubId, userId: memberId },
      },
    });

    await this.prisma.club.update({
      where: { id: clubId },
      data: { memberCount: { decrement: 1 } },
    });

    return { success: true };
  }

  async getLeaderboard(type?: string) {
    const clubs = await this.prisma.club.findMany({
      where: type ? { type } : {},
      orderBy: { memberCount: 'desc' },
      take: 50,
    });

    return clubs.map((club, index) => ({
      id: club.id,
      clubId: club.id,
      clubName: club.name,
      clubLogoUrl: club.logoUrl,
      rank: index + 1,
      previousRank: index + 1,
      totalScore: club.memberCount * 100,
      memberCount: club.memberCount,
      activeMembers: club.memberCount,
      analysisCount: 0,
      averageScore: 0,
    }));
  }

  async getStats(clubId: string) {
    const club = await this.prisma.club.findUnique({
      where: { id: clubId },
    });

    if (!club) {
      throw new NotFoundException('Club not found');
    }

    return {
      memberCount: club.memberCount,
      activeMembers: club.memberCount,
      totalAnalyses: 0,
      averageScore: 0,
      topMembers: [],
      recentActivity: [],
    };
  }

  async searchClubs(query: string) {
    return this.prisma.club.findMany({
      where: {
        OR: [{ name: { contains: query } }, { description: { contains: query } }],
        isPublic: true,
      },
      take: 20,
    });
  }

  async getNearbyClubs(lat: number, lng: number, radius: number) {
    // Simplified - in production you'd use proper geospatial queries
    return this.prisma.club.findMany({
      where: { isPublic: true },
      take: 20,
    });
  }

  // Placeholder methods for challenges, events, posts, invitations
  async getChallenges(clubId: string) {
    return [];
  }

  async getActiveChallenges() {
    return [];
  }

  async getEvents(clubId: string) {
    return [];
  }

  async getUpcomingEvents() {
    return [];
  }

  async getPosts(clubId: string) {
    return [];
  }

  async getInvitations(userId: string) {
    return [];
  }

  // ==================== INVITATIONS ====================

  async inviteToClub(clubId: string, userId: string, email: string, message?: string) {
    // Check if user is admin/owner
    const membership = await this.prisma.clubMembership.findUnique({
      where: { clubId_userId: { clubId, userId } },
    });

    if (!membership || !['owner', 'admin'].includes(membership.role)) {
      throw new ForbiddenException('You do not have permission to invite members');
    }

    // For now, return success - in production, send email invitation
    return {
      success: true,
      invitationId: `inv_${Date.now()}`,
      email,
      clubId,
      status: 'pending',
    };
  }

  async acceptInvitation(invitationId: string, userId: string, organizationId: string) {
    // For now, return success - in production, validate invitation token
    return { success: true, message: 'Invitation accepted' };
  }

  async declineInvitation(invitationId: string, userId: string) {
    return { success: true, message: 'Invitation declined' };
  }

  // ==================== CLUB CONTENT ====================

  async createChallenge(
    clubId: string,
    userId: string,
    data: {
      title: string;
      description?: string;
      type?: string;
      startDate?: string;
      endDate?: string;
      targetValue?: number;
      reward?: string;
    }
  ) {
    // Check if user is admin/owner
    const membership = await this.prisma.clubMembership.findUnique({
      where: { clubId_userId: { clubId, userId } },
    });

    if (!membership || !['owner', 'admin'].includes(membership.role)) {
      throw new ForbiddenException('You do not have permission to create challenges');
    }

    // Return mock challenge - in production, save to DB
    return {
      id: `challenge_${Date.now()}`,
      clubId,
      ...data,
      createdAt: new Date().toISOString(),
      status: 'active',
      participantCount: 0,
    };
  }

  async createEvent(
    clubId: string,
    userId: string,
    data: {
      title: string;
      description?: string;
      date: string;
      location?: string;
      type?: string;
      maxParticipants?: number;
    }
  ) {
    // Check if user is admin/owner
    const membership = await this.prisma.clubMembership.findUnique({
      where: { clubId_userId: { clubId, userId } },
    });

    if (!membership || !['owner', 'admin'].includes(membership.role)) {
      throw new ForbiddenException('You do not have permission to create events');
    }

    // Return mock event - in production, save to DB
    return {
      id: `event_${Date.now()}`,
      clubId,
      ...data,
      createdAt: new Date().toISOString(),
      participantCount: 0,
    };
  }

  async createPost(
    clubId: string,
    userId: string,
    data: { content: string; mediaUrls?: string[] }
  ) {
    // Check membership
    const membership = await this.prisma.clubMembership.findUnique({
      where: { clubId_userId: { clubId, userId } },
    });

    if (!membership || membership.status !== 'active') {
      throw new ForbiddenException('You must be a member to post in this club');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { firstName: true, lastName: true, avatarUrl: true },
    });

    // Return mock post - in production, save to DB
    return {
      id: `clubpost_${Date.now()}`,
      clubId,
      authorId: userId,
      authorName: user ? `${user.firstName} ${user.lastName}` : 'Unknown',
      authorPhotoUrl: user?.avatarUrl,
      content: data.content,
      mediaUrls: data.mediaUrls || [],
      createdAt: new Date().toISOString(),
      likeCount: 0,
      commentCount: 0,
    };
  }
}
