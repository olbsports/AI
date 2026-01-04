import { IsString, IsOptional, IsEnum, IsInt, Min, IsDateString, IsObject } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum LogLevel {
  DEBUG = 'debug',
  INFO = 'info',
  WARN = 'warn',
  ERROR = 'error',
}

export enum AlertSeverity {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  CRITICAL = 'critical',
}

export enum AlertStatus {
  ACTIVE = 'active',
  ACKNOWLEDGED = 'acknowledged',
  RESOLVED = 'resolved',
}

export class LogQueryDto {
  @ApiPropertyOptional({ enum: LogLevel })
  @IsOptional()
  @IsEnum(LogLevel)
  level?: LogLevel;

  @ApiPropertyOptional({ description: 'Search in log messages' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ description: 'Start date' })
  @IsOptional()
  @IsDateString()
  from?: string;

  @ApiPropertyOptional({ description: 'End date' })
  @IsOptional()
  @IsDateString()
  to?: string;

  @ApiPropertyOptional({ description: 'Page number' })
  @IsOptional()
  @IsInt()
  @Min(1)
  page?: number;

  @ApiPropertyOptional({ description: 'Items per page' })
  @IsOptional()
  @IsInt()
  @Min(1)
  limit?: number;
}

export class CreateAlertRuleDto {
  @ApiProperty({ description: 'Rule name' })
  @IsString()
  name: string;

  @ApiProperty({ description: 'Metric to monitor' })
  @IsString()
  metric: string;

  @ApiProperty({ description: 'Condition operator (gt, lt, eq)' })
  @IsString()
  operator: string;

  @ApiProperty({ description: 'Threshold value' })
  @IsInt()
  threshold: number;

  @ApiProperty({ enum: AlertSeverity })
  @IsEnum(AlertSeverity)
  severity: AlertSeverity;

  @ApiPropertyOptional({ description: 'Notification channels' })
  @IsOptional()
  @IsObject()
  notifications?: {
    email?: boolean;
    webhook?: boolean;
    slack?: boolean;
  };
}

export class AcknowledgeAlertDto {
  @ApiPropertyOptional({ description: 'Acknowledgment note' })
  @IsOptional()
  @IsString()
  note?: string;
}
