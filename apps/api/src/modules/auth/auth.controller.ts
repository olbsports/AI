import {
  Controller,
  Post,
  Body,
  UseGuards,
  Get,
  Query,
  Patch,
  Delete,
  Param,
  Req,
  Headers,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiResponse } from '@nestjs/swagger';
import { Request } from 'express';

import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { VerifyEmailDto } from './dto/verify-email.dto';
import {
  Verify2FADto,
  Disable2FADto,
  Login2FADto,
  SessionResponseDto,
  RevokeSessionResponseDto,
  RevokeAllSessionsResponseDto,
} from './dto/two-factor.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { CurrentUser } from './decorators/current-user.decorator';
import { Public } from './decorators/public.decorator';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  @Public()
  @ApiOperation({ summary: 'User login' })
  async login(
    @Body() dto: LoginDto,
    @Req() req: Request,
    @Headers('user-agent') userAgent?: string
  ) {
    const ipAddress = this.getClientIp(req);
    return this.authService.login(dto, ipAddress, userAgent);
  }

  @Post('register')
  @Public()
  @ApiOperation({ summary: 'User registration' })
  async register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('refresh')
  @Public()
  @ApiOperation({ summary: 'Refresh access token' })
  async refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refreshToken(dto.refreshToken);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current user' })
  async me(@CurrentUser() user: any) {
    return user;
  }

  @Post('logout')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'User logout' })
  async logout() {
    return { message: 'Logged out successfully' };
  }

  // ========== PASSWORD RESET ==========

  @Post('forgot-password')
  @Public()
  @ApiOperation({ summary: 'Request password reset email' })
  async forgotPassword(@Body() dto: ForgotPasswordDto) {
    return this.authService.forgotPassword(dto);
  }

  @Post('reset-password')
  @Public()
  @ApiOperation({ summary: 'Reset password with token' })
  async resetPassword(@Body() dto: ResetPasswordDto) {
    return this.authService.resetPassword(dto);
  }

  @Post('change-password')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Change current user password' })
  async changePassword(@CurrentUser() user: any, @Body() dto: ChangePasswordDto) {
    return this.authService.changePassword(user.id, dto);
  }

  // ========== EMAIL VERIFICATION ==========

  @Get('verify-email')
  @Public()
  @ApiOperation({ summary: 'Verify email with token' })
  async verifyEmail(@Query() dto: VerifyEmailDto) {
    return this.authService.verifyEmail(dto.token);
  }

  @Post('resend-verification')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Resend verification email' })
  async resendVerification(@CurrentUser() user: any) {
    return this.authService.sendVerificationEmail(user.id);
  }

  // ========== PROFILE ==========

  @Patch('profile')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update user profile' })
  async updateProfile(
    @CurrentUser() user: any,
    @Body()
    data: {
      firstName?: string;
      lastName?: string;
      bio?: string;
      isPublic?: boolean;
      phone?: string;
    }
  ) {
    return this.authService.updateProfile(user.id, data);
  }

  @Post('profile/photo')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Upload profile photo' })
  @UseInterceptors(FileInterceptor('file'))
  async uploadProfilePhoto(@CurrentUser() user: any, @UploadedFile() file: any) {
    if (!file) {
      throw new BadRequestException('No file uploaded');
    }
    return this.authService.uploadProfilePhoto(user.id, user.organizationId, file);
  }

  // ========== TWO-FACTOR AUTHENTICATION ==========

  @Post('login/2fa')
  @Public()
  @ApiOperation({ summary: 'Login with two-factor authentication (TOTP or backup code)' })
  async loginWith2FA(
    @Body() dto: Login2FADto,
    @Req() req: Request,
    @Headers('user-agent') userAgent?: string
  ) {
    const ipAddress = this.getClientIp(req);
    const deviceInfo = {
      deviceId: dto.deviceId,
      deviceName: dto.deviceName,
      platform: dto.platform,
    };
    return this.authService.loginWith2FA(
      dto.email,
      dto.password,
      dto.twoFactorCode,
      deviceInfo,
      ipAddress,
      userAgent
    );
  }

  @Get('2fa/status')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get 2FA status for current user' })
  async get2FAStatus(@CurrentUser() user: any) {
    return this.authService.get2FAStatus(user.id);
  }

  @Post('2fa/enable')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Enable two-factor authentication - returns secret and QR code' })
  async enable2FA(@CurrentUser() user: any) {
    return this.authService.enable2FA(user.id);
  }

  @Post('2fa/verify')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Verify and complete 2FA setup' })
  async verify2FASetup(@CurrentUser() user: any, @Body() dto: Verify2FADto) {
    return this.authService.verify2FASetup(user.id, dto.code);
  }

  @Post('2fa/disable')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Disable two-factor authentication' })
  async disable2FA(@CurrentUser() user: any, @Body() dto: Disable2FADto) {
    return this.authService.disable2FA(user.id, dto.code);
  }

  @Post('2fa/backup-codes')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Regenerate backup codes' })
  async regenerateBackupCodes(@CurrentUser() user: any, @Body() dto: Verify2FADto) {
    return this.authService.regenerateBackupCodes(user.id, dto.code);
  }

  @Post('2fa/backup-codes/regenerate')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Regenerate backup codes (alias)' })
  async regenerateBackupCodesAlias(@CurrentUser() user: any, @Body() dto: Verify2FADto) {
    return this.authService.regenerateBackupCodes(user.id, dto.code);
  }

  // ========== SESSION MANAGEMENT (Device Tracking) ==========

  @Get('sessions')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all active sessions for the current user' })
  @ApiResponse({ status: 200, description: 'List of active sessions', type: [SessionResponseDto] })
  async getSessions(
    @CurrentUser() user: any,
    @Headers('x-device-id') deviceId?: string
  ): Promise<SessionResponseDto[]> {
    return this.authService.getUserSessions(user.id, deviceId);
  }

  @Delete('sessions/:id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Revoke a specific session by ID' })
  @ApiResponse({ status: 200, description: 'Session revoked', type: RevokeSessionResponseDto })
  async revokeSession(
    @CurrentUser() user: any,
    @Param('id') sessionId: string
  ): Promise<RevokeSessionResponseDto> {
    return this.authService.revokeSession(user.id, sessionId);
  }

  @Delete('sessions')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Revoke all sessions except the current one' })
  @ApiResponse({ status: 200, description: 'All sessions revoked', type: RevokeAllSessionsResponseDto })
  async revokeAllSessions(
    @CurrentUser() user: any,
    @Headers('x-device-id') deviceId?: string
  ): Promise<RevokeAllSessionsResponseDto> {
    return this.authService.revokeAllSessions(user.id, deviceId);
  }

  // ========== HELPER METHODS ==========

  private getClientIp(req: Request): string | undefined {
    // Check various headers that might contain the real IP
    const forwardedFor = req.headers['x-forwarded-for'];
    if (forwardedFor) {
      const ips = (Array.isArray(forwardedFor) ? forwardedFor[0] : forwardedFor).split(',');
      return ips[0].trim();
    }

    const realIp = req.headers['x-real-ip'];
    if (realIp) {
      return Array.isArray(realIp) ? realIp[0] : realIp;
    }

    return req.ip || req.socket?.remoteAddress;
  }
}
