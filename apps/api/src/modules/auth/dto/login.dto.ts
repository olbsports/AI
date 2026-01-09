import { IsEmail, IsString, MinLength, IsOptional, IsBoolean } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class LoginDto {
  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'password123' })
  @IsString()
  @MinLength(8)
  password: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsBoolean()
  rememberMe?: boolean;

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
