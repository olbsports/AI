import { IsString, IsNotEmpty, Length, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class Enable2FAResponseDto {
  @ApiProperty({ description: 'Base32 encoded secret for authenticator apps' })
  secret: string;

  @ApiProperty({ description: 'QR code URL for scanning' })
  qrCodeUrl: string;

  @ApiProperty({ description: 'Backup codes for recovery' })
  backupCodes: string[];
}

export class Verify2FADto {
  @ApiProperty({ description: '6-digit TOTP code from authenticator app' })
  @IsString()
  @IsNotEmpty()
  @Length(6, 6)
  code: string;
}

export class Disable2FADto {
  @ApiProperty({ description: '6-digit TOTP code to confirm disable' })
  @IsString()
  @IsNotEmpty()
  @Length(6, 6)
  code: string;
}

export class Login2FADto {
  @ApiProperty({ description: 'Email address' })
  @IsString()
  @IsNotEmpty()
  email: string;

  @ApiProperty({ description: 'Password' })
  @IsString()
  @IsNotEmpty()
  password: string;

  @ApiProperty({ description: '6-digit TOTP code or backup code' })
  @IsString()
  @IsNotEmpty()
  twoFactorCode: string;

  @ApiPropertyOptional({ description: 'Device ID for session tracking' })
  @IsOptional()
  @IsString()
  deviceId?: string;

  @ApiPropertyOptional({ description: 'Device name for session tracking' })
  @IsOptional()
  @IsString()
  deviceName?: string;

  @ApiPropertyOptional({ description: 'Platform (ios, android, web, desktop)' })
  @IsOptional()
  @IsString()
  platform?: string;
}

// ========== SESSION DTOs ==========

export class SessionResponseDto {
  @ApiProperty({ description: 'Session ID' })
  id: string;

  @ApiProperty({ description: 'Device ID' })
  deviceId: string;

  @ApiProperty({ description: 'Device name', nullable: true })
  deviceName: string | null;

  @ApiProperty({ description: 'Platform (ios, android, web, desktop)', nullable: true })
  platform: string | null;

  @ApiProperty({ description: 'IP address', nullable: true })
  ipAddress: string | null;

  @ApiProperty({ description: 'Last activity timestamp' })
  lastActiveAt: Date;

  @ApiProperty({ description: 'Session creation timestamp' })
  createdAt: Date;

  @ApiProperty({ description: 'Whether this is the current session', required: false })
  isCurrent?: boolean;
}

export class RevokeSessionResponseDto {
  @ApiProperty({ description: 'Whether the revocation was successful' })
  success: boolean;
}

export class RevokeAllSessionsResponseDto {
  @ApiProperty({ description: 'Number of sessions revoked' })
  revokedCount: number;
}

// ========== BACKUP CODE DTOs ==========

export class VerifyBackupCodeDto {
  @ApiProperty({ description: 'Backup code (format: XXXX-XXXX)' })
  @IsString()
  @IsNotEmpty()
  backupCode: string;
}

export class RegenerateBackupCodesResponseDto {
  @ApiProperty({ description: 'Newly generated backup codes' })
  backupCodes: string[];

  @ApiProperty({ description: 'Number of codes generated' })
  count: number;
}
