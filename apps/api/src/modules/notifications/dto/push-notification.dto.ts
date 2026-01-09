import { IsString, IsOptional, IsBoolean, IsEnum, IsObject, Matches } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum Platform {
  IOS = 'ios',
  ANDROID = 'android',
  WEB = 'web',
}

// ==================== PUSH SUBSCRIPTION ====================

export class RegisterPushTokenDto {
  @ApiProperty({ description: 'FCM/APNs token' })
  @IsString()
  token: string;

  @ApiProperty({ enum: Platform, description: 'Device platform' })
  @IsEnum(Platform)
  platform: Platform;

  @ApiProperty({ description: 'Unique device identifier' })
  @IsString()
  deviceId: string;

  @ApiPropertyOptional({ description: 'Device name' })
  @IsOptional()
  @IsString()
  deviceName?: string;

  @ApiPropertyOptional({ description: 'App version' })
  @IsOptional()
  @IsString()
  appVersion?: string;
}

export class UnregisterPushTokenDto {
  @ApiProperty({ description: 'Device ID to unregister' })
  @IsString()
  deviceId: string;
}

// ==================== NOTIFICATION PREFERENCES ====================

export class UpdatePreferencesDto {
  @ApiPropertyOptional({ description: 'Enable push notifications' })
  @IsOptional()
  @IsBoolean()
  pushEnabled?: boolean;

  @ApiPropertyOptional({ description: 'Enable email notifications' })
  @IsOptional()
  @IsBoolean()
  emailEnabled?: boolean;

  @ApiPropertyOptional({ description: 'Enable in-app notifications' })
  @IsOptional()
  @IsBoolean()
  inAppEnabled?: boolean;

  @ApiPropertyOptional({ description: 'Enable quiet hours' })
  @IsOptional()
  @IsBoolean()
  quietHoursEnabled?: boolean;

  @ApiPropertyOptional({ description: 'Quiet hours start (HH:mm)' })
  @IsOptional()
  @IsString()
  @Matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, { message: 'quietHoursStart must be in HH:mm format' })
  quietHoursStart?: string;

  @ApiPropertyOptional({ description: 'Quiet hours end (HH:mm)' })
  @IsOptional()
  @IsString()
  @Matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, { message: 'quietHoursEnd must be in HH:mm format' })
  quietHoursEnd?: string;

  @ApiPropertyOptional({ description: 'User timezone' })
  @IsOptional()
  @IsString()
  timezone?: string;

  @ApiPropertyOptional({ description: 'Category-specific settings' })
  @IsOptional()
  @IsObject()
  categorySettings?: Record<string, { push?: boolean; email?: boolean; inApp?: boolean }>;

  @ApiPropertyOptional({ description: 'Enable digest emails' })
  @IsOptional()
  @IsBoolean()
  digestEnabled?: boolean;

  @ApiPropertyOptional({ description: 'Digest frequency', enum: ['daily', 'weekly', 'never'] })
  @IsOptional()
  @IsString()
  digestFrequency?: string;

  @ApiPropertyOptional({ description: 'Digest time (HH:mm)' })
  @IsOptional()
  @IsString()
  @Matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, { message: 'digestTime must be in HH:mm format' })
  digestTime?: string;
}

// ==================== SEND PUSH ====================

export class SendPushNotificationDto {
  @ApiProperty({ description: 'Target user ID' })
  @IsString()
  userId: string;

  @ApiProperty({ description: 'Notification title' })
  @IsString()
  title: string;

  @ApiProperty({ description: 'Notification body' })
  @IsString()
  body: string;

  @ApiPropertyOptional({ description: 'Custom data payload' })
  @IsOptional()
  @IsObject()
  data?: Record<string, string>;

  @ApiPropertyOptional({ description: 'Image URL (Android only)' })
  @IsOptional()
  @IsString()
  imageUrl?: string;

  @ApiPropertyOptional({ description: 'Action URL when tapped' })
  @IsOptional()
  @IsString()
  actionUrl?: string;

  @ApiPropertyOptional({ description: 'Badge count (iOS only)' })
  @IsOptional()
  badge?: number;

  @ApiPropertyOptional({ description: 'Sound to play' })
  @IsOptional()
  @IsString()
  sound?: string;
}

// ==================== RESPONSE DTOs ====================

export class PushSubscriptionResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  platform: string;

  @ApiProperty()
  deviceId: string;

  @ApiPropertyOptional()
  deviceName?: string;

  @ApiProperty()
  isActive: boolean;

  @ApiProperty()
  lastUsedAt: Date;

  @ApiProperty()
  createdAt: Date;
}

export class NotificationPreferencesResponseDto {
  @ApiProperty()
  pushEnabled: boolean;

  @ApiProperty()
  emailEnabled: boolean;

  @ApiProperty()
  inAppEnabled: boolean;

  @ApiProperty()
  quietHoursEnabled: boolean;

  @ApiProperty()
  quietHoursStart: string;

  @ApiProperty()
  quietHoursEnd: string;

  @ApiProperty()
  timezone: string;

  @ApiProperty()
  categorySettings: Record<string, any>;

  @ApiProperty()
  digestEnabled: boolean;

  @ApiProperty()
  digestFrequency: string;

  @ApiProperty()
  digestTime: string;
}

// ==================== NOTIFICATION TYPES ====================

export enum NotificationType {
  // Analysis
  ANALYSIS_COMPLETE = 'analysis_complete',
  ANALYSIS_FAILED = 'analysis_failed',
  ANALYSIS_REPORT_READY = 'analysis_report_ready',

  // Social
  LIKE = 'like',
  COMMENT = 'comment',
  FOLLOW = 'follow',
  MENTION = 'mention',

  // System
  SYSTEM = 'system',
  REMINDER = 'reminder',
  ACHIEVEMENT = 'achievement',

  // Token
  TOKEN_LOW = 'token_low',
  TOKEN_DEPLETED = 'token_depleted',
  TOKEN_PURCHASED = 'token_purchased',

  // Health
  HEALTH_REMINDER = 'health_reminder',
  VACCINATION_DUE = 'vaccination_due',

  // Marketplace
  LISTING_INQUIRY = 'listing_inquiry',
  LISTING_SOLD = 'listing_sold',
  PRICE_DROP = 'price_drop',
}

export const NotificationCategoryMap: Record<NotificationType, string> = {
  [NotificationType.ANALYSIS_COMPLETE]: 'analyses',
  [NotificationType.ANALYSIS_FAILED]: 'analyses',
  [NotificationType.ANALYSIS_REPORT_READY]: 'analyses',
  [NotificationType.LIKE]: 'social',
  [NotificationType.COMMENT]: 'social',
  [NotificationType.FOLLOW]: 'social',
  [NotificationType.MENTION]: 'social',
  [NotificationType.SYSTEM]: 'system',
  [NotificationType.REMINDER]: 'reminders',
  [NotificationType.ACHIEVEMENT]: 'achievements',
  [NotificationType.TOKEN_LOW]: 'tokens',
  [NotificationType.TOKEN_DEPLETED]: 'tokens',
  [NotificationType.TOKEN_PURCHASED]: 'tokens',
  [NotificationType.HEALTH_REMINDER]: 'health',
  [NotificationType.VACCINATION_DUE]: 'health',
  [NotificationType.LISTING_INQUIRY]: 'marketplace',
  [NotificationType.LISTING_SOLD]: 'marketplace',
  [NotificationType.PRICE_DROP]: 'marketplace',
};
