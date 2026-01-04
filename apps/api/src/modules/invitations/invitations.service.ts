import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { randomBytes } from 'crypto';
import * as bcrypt from 'bcrypt';

import { PrismaService } from '../../prisma/prisma.service';
import { EmailService } from '../email/email.service';
import { CreateInvitationDto } from './dto/create-invitation.dto';
import { AcceptInvitationDto } from './dto/accept-invitation.dto';

@Injectable()
export class InvitationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly emailService: EmailService,
  ) {}

  async createInvitation(
    organizationId: string,
    invitedById: string,
    dto: CreateInvitationDto,
  ) {
    // Check if user already exists in organization
    const existingUser = await this.prisma.user.findFirst({
      where: {
        email: dto.email,
        organizationId,
      },
    });

    if (existingUser) {
      throw new BadRequestException('User already belongs to this organization');
    }

    // Check for existing pending invitation
    const existingInvitation = await this.prisma.teamInvitation.findFirst({
      where: {
        email: dto.email,
        organizationId,
        status: 'pending',
      },
    });

    if (existingInvitation) {
      throw new BadRequestException(
        'An invitation has already been sent to this email',
      );
    }

    // Get inviter and organization info
    const inviter = await this.prisma.user.findUnique({
      where: { id: invitedById },
      include: { organization: true },
    });

    if (!inviter) {
      throw new NotFoundException('Inviter not found');
    }

    // Generate invitation token
    const token = randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

    const invitation = await this.prisma.teamInvitation.create({
      data: {
        email: dto.email,
        role: dto.role || 'viewer',
        token,
        expiresAt,
        organizationId,
        invitedById,
      },
    });

    // Send invitation email
    await this.emailService.sendTeamInvitationEmail(
      dto.email,
      token,
      `${inviter.firstName} ${inviter.lastName}`,
      inviter.organization.name,
      dto.role || 'viewer',
    );

    return invitation;
  }

  async getInvitations(organizationId: string) {
    return this.prisma.teamInvitation.findMany({
      where: {
        organizationId,
        status: 'pending',
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getInvitationByToken(token: string) {
    const invitation = await this.prisma.teamInvitation.findUnique({
      where: { token },
      include: { organization: true },
    });

    if (!invitation) {
      throw new NotFoundException('Invitation not found');
    }

    if (invitation.status !== 'pending') {
      throw new BadRequestException('Invitation is no longer valid');
    }

    if (invitation.expiresAt < new Date()) {
      await this.prisma.teamInvitation.update({
        where: { id: invitation.id },
        data: { status: 'expired' },
      });
      throw new BadRequestException('Invitation has expired');
    }

    return invitation;
  }

  async acceptInvitation(dto: AcceptInvitationDto) {
    const invitation = await this.getInvitationByToken(dto.token);

    // Check if email is already registered
    const existingUser = await this.prisma.user.findUnique({
      where: { email: invitation.email },
    });

    if (existingUser) {
      // If user exists but in different org, add to this org
      if (existingUser.organizationId !== invitation.organizationId) {
        throw new BadRequestException(
          'This email is already registered with another organization',
        );
      }
      throw new BadRequestException('User already exists in this organization');
    }

    const passwordHash = await bcrypt.hash(dto.password, 12);

    // Create user and update invitation in transaction
    const [user] = await this.prisma.$transaction([
      this.prisma.user.create({
        data: {
          email: invitation.email,
          passwordHash,
          firstName: dto.firstName,
          lastName: dto.lastName,
          role: invitation.role,
          organizationId: invitation.organizationId,
          emailVerified: true, // Verified through invitation
        },
        include: { organization: true },
      }),
      this.prisma.teamInvitation.update({
        where: { id: invitation.id },
        data: { status: 'accepted' },
      }),
    ]);

    return user;
  }

  async cancelInvitation(
    organizationId: string,
    invitationId: string,
    userId: string,
  ) {
    const invitation = await this.prisma.teamInvitation.findUnique({
      where: { id: invitationId },
    });

    if (!invitation) {
      throw new NotFoundException('Invitation not found');
    }

    if (invitation.organizationId !== organizationId) {
      throw new ForbiddenException('Access denied');
    }

    await this.prisma.teamInvitation.update({
      where: { id: invitationId },
      data: { status: 'cancelled' },
    });

    return { message: 'Invitation cancelled' };
  }

  async resendInvitation(
    organizationId: string,
    invitationId: string,
    userId: string,
  ) {
    const invitation = await this.prisma.teamInvitation.findUnique({
      where: { id: invitationId },
      include: { organization: true },
    });

    if (!invitation) {
      throw new NotFoundException('Invitation not found');
    }

    if (invitation.organizationId !== organizationId) {
      throw new ForbiddenException('Access denied');
    }

    if (invitation.status !== 'pending') {
      throw new BadRequestException('Cannot resend non-pending invitation');
    }

    // Get inviter info
    const inviter = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!inviter) {
      throw new NotFoundException('User not found');
    }

    // Generate new token and extend expiration
    const token = randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    await this.prisma.teamInvitation.update({
      where: { id: invitationId },
      data: { token, expiresAt },
    });

    // Resend email
    await this.emailService.sendTeamInvitationEmail(
      invitation.email,
      token,
      `${inviter.firstName} ${inviter.lastName}`,
      invitation.organization.name,
      invitation.role,
    );

    return { message: 'Invitation resent' };
  }
}
