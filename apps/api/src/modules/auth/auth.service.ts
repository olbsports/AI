import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
  NotFoundException,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { randomBytes, createHmac } from 'crypto';
import * as speakeasy from 'speakeasy';
import * as QRCode from 'qrcode';

import { PrismaService } from '../../prisma/prisma.service';
import { UsersService } from '../users/users.service';
import { EmailService } from '../email/email.service';
import { UploadService } from '../upload/upload.service';
import { SessionTrackingService } from './session-tracking.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { ChangePasswordDto } from './dto/change-password.dto';

// Rate limiting constants
const MAX_LOGIN_ATTEMPTS = 5;
const LOCKOUT_DURATION_MINUTES = 15;

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly emailService: EmailService,
    private readonly uploadService: UploadService,
    private readonly sessionTrackingService: SessionTrackingService
  ) {}

  async validateUser(email: string, password: string, ipAddress?: string) {
    const user = await this.usersService.findByEmail(email);

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (!user.isActive) {
      throw new UnauthorizedException('Account is deactivated');
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);

    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    return user;
  }

  async login(dto: LoginDto, ipAddress?: string, userAgent?: string) {
    // Check rate limiting
    await this.checkRateLimiting(dto.email, ipAddress);

    try {
      const user = await this.validateUser(dto.email, dto.password, ipAddress);

      // Check if 2FA is enabled
      if (user.twoFactorEnabled) {
        // Return partial response indicating 2FA is required
        return {
          requiresTwoFactor: true,
          userId: user.id,
          message: 'Two-factor authentication required',
        };
      }

      // Record successful login attempt
      await this.recordLoginAttempt(dto.email, ipAddress, userAgent, true);

      // Create session if deviceId provided
      let session = null;
      if (dto.deviceId) {
        session = await this.sessionTrackingService.createOrUpdateSession({
          userId: user.id,
          deviceId: dto.deviceId,
          deviceName: dto.deviceName,
          platform: dto.platform,
          ipAddress,
          userAgent,
        });
      }

      const tokens = await this.generateTokens(user);
      return { ...tokens, session };
    } catch (error) {
      // Record failed login attempt
      await this.recordLoginAttempt(
        dto.email,
        ipAddress,
        userAgent,
        false,
        error.message || 'invalid_credentials'
      );
      throw error;
    }
  }

  async loginWith2FA(
    email: string,
    password: string,
    twoFactorCode: string,
    deviceInfo?: { deviceId?: string; deviceName?: string; platform?: string },
    ipAddress?: string,
    userAgent?: string
  ) {
    // Check rate limiting
    await this.checkRateLimiting(email, ipAddress);

    try {
      const user = await this.validateUser(email, password, ipAddress);

      if (!user.twoFactorEnabled || !user.twoFactorSecret) {
        throw new BadRequestException('Two-factor authentication is not enabled');
      }

      // First try TOTP verification
      let isValid = speakeasy.totp.verify({
        secret: user.twoFactorSecret,
        encoding: 'base32',
        token: twoFactorCode,
        window: 1, // Allow 1 step before/after for clock drift
      });

      // If TOTP fails, try backup code
      if (!isValid) {
        const backupCodeResult = await this.verifyAndConsumeBackupCode(user.id, twoFactorCode);
        isValid = backupCodeResult.valid;
      }

      if (!isValid) {
        await this.recordLoginAttempt(email, ipAddress, userAgent, false, '2fa_failed');
        throw new UnauthorizedException('Invalid two-factor code');
      }

      // Record successful login attempt
      await this.recordLoginAttempt(email, ipAddress, userAgent, true);

      // Create session if deviceId provided
      let session = null;
      if (deviceInfo?.deviceId) {
        session = await this.sessionTrackingService.createOrUpdateSession({
          userId: user.id,
          deviceId: deviceInfo.deviceId,
          deviceName: deviceInfo.deviceName,
          platform: deviceInfo.platform,
          ipAddress,
          userAgent,
        });
      }

      const tokens = await this.generateTokens(user);
      return { ...tokens, session };
    } catch (error) {
      if (!(error instanceof UnauthorizedException)) {
        await this.recordLoginAttempt(email, ipAddress, userAgent, false, error.message);
      }
      throw error;
    }
  }

  // ========== RATE LIMITING ==========

  private async checkRateLimiting(email: string, ipAddress?: string): Promise<void> {
    const windowStart = new Date(Date.now() - LOCKOUT_DURATION_MINUTES * 60 * 1000);

    // Check failed attempts for this email
    const emailAttempts = await this.prisma.loginAttempt.count({
      where: {
        email,
        successful: false,
        createdAt: { gte: windowStart },
      },
    });

    if (emailAttempts >= MAX_LOGIN_ATTEMPTS) {
      throw new HttpException(
        `Too many login attempts. Please try again in ${LOCKOUT_DURATION_MINUTES} minutes.`,
        HttpStatus.TOO_MANY_REQUESTS
      );
    }

    // Also check by IP if provided
    if (ipAddress) {
      const ipAttempts = await this.prisma.loginAttempt.count({
        where: {
          ipAddress,
          successful: false,
          createdAt: { gte: windowStart },
        },
      });

      if (ipAttempts >= MAX_LOGIN_ATTEMPTS * 2) {
        throw new HttpException(
          `Too many login attempts from this IP. Please try again later.`,
          HttpStatus.TOO_MANY_REQUESTS
        );
      }
    }
  }

  private async recordLoginAttempt(
    email: string,
    ipAddress?: string,
    userAgent?: string,
    successful: boolean = false,
    failReason?: string
  ): Promise<void> {
    await this.prisma.loginAttempt.create({
      data: {
        email,
        ipAddress,
        userAgent,
        successful,
        failReason: successful ? null : failReason,
      },
    });
  }

  // ========== BACKUP CODE VERIFICATION ==========

  private async verifyAndConsumeBackupCode(
    userId: string,
    code: string
  ): Promise<{ valid: boolean }> {
    const user = await this.usersService.findById(userId);
    if (!user) return { valid: false };

    const preferences = (user.preferences as any) || {};
    const storedCodes: string[] = preferences.backupCodes || [];

    if (storedCodes.length === 0) return { valid: false };

    // Hash the provided code for comparison
    const hashedCode = this.hashCode(code);

    // Find matching backup code
    const codeIndex = storedCodes.findIndex((stored) => stored === hashedCode);

    if (codeIndex === -1) return { valid: false };

    // Remove the used backup code
    const updatedCodes = [...storedCodes];
    updatedCodes.splice(codeIndex, 1);

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        preferences: {
          ...preferences,
          backupCodes: updatedCodes,
        },
      },
    });

    return { valid: true };
  }

  // ========== SESSION MANAGEMENT ==========

  async getUserSessions(userId: string, currentDeviceId?: string) {
    return this.sessionTrackingService.getUserSessions(userId, currentDeviceId);
  }

  async revokeSession(userId: string, sessionId: string) {
    return this.sessionTrackingService.revokeSession(userId, sessionId);
  }

  async revokeAllSessions(userId: string, exceptDeviceId?: string) {
    return this.sessionTrackingService.revokeAllSessions(userId, exceptDeviceId);
  }

  private async generateTokens(user: any) {
    // Update last login
    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    const payload = {
      sub: user.id,
      email: user.email,
      organizationId: user.organizationId,
      role: user.role,
    };

    const accessToken = this.jwtService.sign(payload);
    const refreshToken = this.jwtService.sign(payload, {
      expiresIn: this.configService.get('JWT_REFRESH_EXPIRES_IN', '7d'),
    });

    const expiresAt = Date.now() + 15 * 60 * 1000; // 15 minutes

    return {
      user,
      organization: user.organization,
      accessToken,
      refreshToken,
      expiresAt,
    };
  }

  async register(dto: RegisterDto) {
    // Check if email already exists
    const existingUser = await this.usersService.findByEmail(dto.email);
    if (existingUser) {
      throw new BadRequestException('Email already registered');
    }

    const passwordHash = await bcrypt.hash(dto.password, 12);

    const user = await this.usersService.create({
      email: dto.email,
      passwordHash,
      firstName: dto.firstName,
      lastName: dto.lastName,
      organizationName: dto.organizationName,
    });

    // Send verification email (don't block registration if email fails)
    try {
      await this.sendVerificationEmail(user.id);
    } catch (error) {
      console.warn('Failed to send verification email, but registration succeeded:', error.message);
    }

    return this.login({ email: dto.email, password: dto.password });
  }

  async refreshToken(refreshToken: string) {
    try {
      const payload = this.jwtService.verify(refreshToken);

      const user = await this.usersService.findById(payload.sub);
      if (!user || !user.isActive) {
        throw new UnauthorizedException('User not found or deactivated');
      }

      const newPayload = {
        sub: user.id,
        email: user.email,
        organizationId: user.organizationId,
        role: user.role,
      };

      const accessToken = this.jwtService.sign(newPayload);
      const newRefreshToken = this.jwtService.sign(newPayload, {
        expiresIn: this.configService.get('JWT_REFRESH_EXPIRES_IN', '7d'),
      });
      const expiresAt = Date.now() + 15 * 60 * 1000;

      return { accessToken, refreshToken: newRefreshToken, expiresAt };
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  // ========== PASSWORD RESET ==========

  async forgotPassword(dto: ForgotPasswordDto) {
    const user = await this.usersService.findByEmail(dto.email);

    // Always return success to prevent email enumeration
    if (!user) {
      return { message: 'If the email exists, a reset link will be sent' };
    }

    // Delete any existing tokens
    await this.prisma.passwordResetToken.deleteMany({
      where: { userId: user.id },
    });

    // Generate token
    const token = randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

    await this.prisma.passwordResetToken.create({
      data: {
        token,
        userId: user.id,
        expiresAt,
      },
    });

    // Send email
    await this.emailService.sendPasswordResetEmail(user.email, token, user.firstName);

    return { message: 'If the email exists, a reset link will be sent' };
  }

  async resetPassword(dto: ResetPasswordDto) {
    const tokenRecord = await this.prisma.passwordResetToken.findUnique({
      where: { token: dto.token },
      include: { user: true },
    });

    if (!tokenRecord) {
      throw new BadRequestException('Invalid or expired reset token');
    }

    if (tokenRecord.expiresAt < new Date()) {
      await this.prisma.passwordResetToken.delete({
        where: { id: tokenRecord.id },
      });
      throw new BadRequestException('Reset token has expired');
    }

    const passwordHash = await bcrypt.hash(dto.newPassword, 12);

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: tokenRecord.userId },
        data: { passwordHash },
      }),
      this.prisma.passwordResetToken.delete({
        where: { id: tokenRecord.id },
      }),
    ]);

    return { message: 'Password reset successfully' };
  }

  async changePassword(userId: string, dto: ChangePasswordDto) {
    const user = await this.usersService.findById(userId);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const isPasswordValid = await bcrypt.compare(dto.currentPassword, user.passwordHash);

    if (!isPasswordValid) {
      throw new BadRequestException('Current password is incorrect');
    }

    const passwordHash = await bcrypt.hash(dto.newPassword, 12);

    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash },
    });

    return { message: 'Password changed successfully' };
  }

  // ========== EMAIL VERIFICATION ==========

  async sendVerificationEmail(userId: string) {
    const user = await this.usersService.findById(userId);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (user.emailVerified) {
      throw new BadRequestException('Email already verified');
    }

    // Delete any existing tokens
    await this.prisma.emailVerificationToken.deleteMany({
      where: { userId: user.id },
    });

    // Generate token
    const token = randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

    await this.prisma.emailVerificationToken.create({
      data: {
        token,
        userId: user.id,
        expiresAt,
      },
    });

    await this.emailService.sendVerificationEmail(user.email, token, user.firstName);

    return { message: 'Verification email sent' };
  }

  async verifyEmail(token: string) {
    const tokenRecord = await this.prisma.emailVerificationToken.findUnique({
      where: { token },
      include: { user: true },
    });

    if (!tokenRecord) {
      throw new BadRequestException('Invalid verification token');
    }

    if (tokenRecord.expiresAt < new Date()) {
      await this.prisma.emailVerificationToken.delete({
        where: { id: tokenRecord.id },
      });
      throw new BadRequestException('Verification token has expired');
    }

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: tokenRecord.userId },
        data: { emailVerified: true },
      }),
      this.prisma.emailVerificationToken.delete({
        where: { id: tokenRecord.id },
      }),
    ]);

    return { message: 'Email verified successfully' };
  }

  // ========== PROFILE ==========

  async updateProfile(
    userId: string,
    data: {
      firstName?: string;
      lastName?: string;
      bio?: string;
      isPublic?: boolean;
      phone?: string;
    }
  ) {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: {
        ...(data.firstName && { firstName: data.firstName }),
        ...(data.lastName && { lastName: data.lastName }),
        ...(data.bio !== undefined && { bio: data.bio }),
        ...(data.isPublic !== undefined && { isPublic: data.isPublic }),
        ...(data.phone !== undefined && { phone: data.phone }),
      },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        phone: true,
        avatarUrl: true,
        bio: true,
        isPublic: true,
        xp: true,
        level: true,
        badges: true,
        followersCount: true,
        followingCount: true,
      },
    });

    return user;
  }

  async uploadProfilePhoto(userId: string, organizationId: string, file: any) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Delete old photo if exists
    if (user.avatarUrl) {
      try {
        const urlParts = user.avatarUrl.split('/');
        const key = urlParts.slice(3).join('/');
        await this.uploadService.deleteFile(key);
      } catch {
        // Ignore delete errors
      }
    }

    // Upload new photo
    const { url } = await this.uploadService.uploadFile(organizationId, 'avatars', file);

    // Update user with new photo URL
    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: { avatarUrl: url },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        avatarUrl: true,
        bio: true,
        isPublic: true,
      },
    });

    return { url, user: updatedUser };
  }

  // ========== TWO-FACTOR AUTHENTICATION ==========

  async enable2FA(userId: string): Promise<{
    secret: string;
    qrCodeUrl: string;
    backupCodes: string[];
  }> {
    const user = await this.usersService.findById(userId);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (user.twoFactorEnabled) {
      throw new BadRequestException('Two-factor authentication is already enabled');
    }

    // Generate secret
    const secret = speakeasy.generateSecret({
      name: `HorseTempo:${user.email}`,
      length: 32,
    });

    // Generate QR code
    const qrCodeUrl = await QRCode.toDataURL(secret.otpauth_url || '');

    // Generate backup codes
    const backupCodes = this.generateBackupCodes();

    // Store secret temporarily (not enabled yet until verified)
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        twoFactorSecret: secret.base32,
        // Store backup codes hashed
        preferences: {
          ...((user.preferences as any) || {}),
          pendingBackupCodes: backupCodes.map((code) => this.hashCode(code)),
        },
      },
    });

    return {
      secret: secret.base32,
      qrCodeUrl,
      backupCodes,
    };
  }

  async verify2FASetup(
    userId: string,
    code: string
  ): Promise<{ success: boolean; backupCodes: string[] }> {
    const user = await this.usersService.findById(userId);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (user.twoFactorEnabled) {
      throw new BadRequestException('Two-factor authentication is already enabled');
    }

    if (!user.twoFactorSecret) {
      throw new BadRequestException('Please initiate 2FA setup first');
    }

    // Verify the code
    const isValid = speakeasy.totp.verify({
      secret: user.twoFactorSecret,
      encoding: 'base32',
      token: code,
      window: 1,
    });

    if (!isValid) {
      throw new BadRequestException('Invalid verification code');
    }

    // Get backup codes from preferences
    const preferences = (user.preferences as any) || {};
    const backupCodes = preferences.pendingBackupCodes || [];

    // Enable 2FA
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        twoFactorEnabled: true,
        preferences: {
          ...preferences,
          pendingBackupCodes: undefined,
          backupCodes, // Store hashed backup codes
        },
      },
    });

    return {
      success: true,
      backupCodes: [], // Don't return again - user should have saved them
    };
  }

  async disable2FA(userId: string, code: string): Promise<{ success: boolean }> {
    const user = await this.usersService.findById(userId);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (!user.twoFactorEnabled || !user.twoFactorSecret) {
      throw new BadRequestException('Two-factor authentication is not enabled');
    }

    // Verify the code
    const isValid = speakeasy.totp.verify({
      secret: user.twoFactorSecret,
      encoding: 'base32',
      token: code,
      window: 1,
    });

    if (!isValid) {
      throw new BadRequestException('Invalid verification code');
    }

    // Disable 2FA
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        twoFactorEnabled: false,
        twoFactorSecret: null,
        preferences: {
          ...((user.preferences as any) || {}),
          backupCodes: undefined,
        },
      },
    });

    return { success: true };
  }

  async get2FAStatus(userId: string): Promise<{ enabled: boolean }> {
    const user = await this.usersService.findById(userId);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return { enabled: user.twoFactorEnabled };
  }

  async regenerateBackupCodes(userId: string, code: string): Promise<{ backupCodes: string[] }> {
    const user = await this.usersService.findById(userId);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (!user.twoFactorEnabled || !user.twoFactorSecret) {
      throw new BadRequestException('Two-factor authentication is not enabled');
    }

    // Verify the code
    const isValid = speakeasy.totp.verify({
      secret: user.twoFactorSecret,
      encoding: 'base32',
      token: code,
      window: 1,
    });

    if (!isValid) {
      throw new BadRequestException('Invalid verification code');
    }

    // Generate new backup codes
    const backupCodes = this.generateBackupCodes();

    // Store new backup codes
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        preferences: {
          ...((user.preferences as any) || {}),
          backupCodes: backupCodes.map((c) => this.hashCode(c)),
        },
      },
    });

    return { backupCodes };
  }

  private generateBackupCodes(count: number = 10): string[] {
    const codes: string[] = [];
    for (let i = 0; i < count; i++) {
      // Generate 8-character alphanumeric codes
      const code = randomBytes(4).toString('hex').toUpperCase().match(/.{4}/g)?.join('-') || '';
      codes.push(code);
    }
    return codes;
  }

  private hashCode(code: string): string {
    return createHmac('sha256', this.configService.get('JWT_SECRET') || 'secret')
      .update(code.replace(/-/g, ''))
      .digest('hex');
  }
}
