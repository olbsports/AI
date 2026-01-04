import { IsString, IsOptional, IsEnum, IsDateString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export enum TimeGranularity {
  HOUR = 'hour',
  DAY = 'day',
  WEEK = 'week',
  MONTH = 'month',
}

export enum MetricType {
  ANALYSES = 'analyses',
  REPORTS = 'reports',
  USERS = 'users',
  TOKENS = 'tokens',
  REVENUE = 'revenue',
}

export class AnalyticsQueryDto {
  @ApiPropertyOptional({ description: 'Start date' })
  @IsOptional()
  @IsDateString()
  from?: string;

  @ApiPropertyOptional({ description: 'End date' })
  @IsOptional()
  @IsDateString()
  to?: string;

  @ApiPropertyOptional({ enum: TimeGranularity, default: 'day' })
  @IsOptional()
  @IsEnum(TimeGranularity)
  granularity?: TimeGranularity;
}

export class MetricQueryDto extends AnalyticsQueryDto {
  @ApiPropertyOptional({ enum: MetricType })
  @IsOptional()
  @IsEnum(MetricType)
  metric?: MetricType;
}

export class ComparisonQueryDto {
  @ApiPropertyOptional({ description: 'Period to compare (7d, 30d, 90d)' })
  @IsOptional()
  @IsString()
  period?: string;
}
