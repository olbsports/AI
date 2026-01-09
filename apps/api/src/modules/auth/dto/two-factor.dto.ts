import { IsString, IsNotEmpty, Length } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

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

  @ApiProperty({ description: '6-digit TOTP code from authenticator app' })
  @IsString()
  @IsNotEmpty()
  @Length(6, 6)
  twoFactorCode: string;
}
