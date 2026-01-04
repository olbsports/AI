import { IsString, IsOptional, IsEnum, IsArray, IsDateString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum ExportFormat {
  CSV = 'csv',
  EXCEL = 'xlsx',
  PDF = 'pdf',
  JSON = 'json',
}

export enum ExportEntity {
  HORSES = 'horses',
  RIDERS = 'riders',
  ANALYSES = 'analyses',
  REPORTS = 'reports',
  INVOICES = 'invoices',
  USERS = 'users',
  TOKENS = 'tokens',
}

export class ExportRequestDto {
  @ApiProperty({ enum: ExportEntity })
  @IsEnum(ExportEntity)
  entity: ExportEntity;

  @ApiProperty({ enum: ExportFormat })
  @IsEnum(ExportFormat)
  format: ExportFormat;

  @ApiPropertyOptional({ description: 'Specific fields to include' })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  fields?: string[];

  @ApiPropertyOptional({ description: 'Start date filter' })
  @IsOptional()
  @IsDateString()
  from?: string;

  @ApiPropertyOptional({ description: 'End date filter' })
  @IsOptional()
  @IsDateString()
  to?: string;

  @ApiPropertyOptional({ description: 'Additional filters as JSON' })
  @IsOptional()
  @IsString()
  filters?: string;
}

export class ExportReportDto {
  @ApiProperty({ description: 'Report ID to export' })
  @IsString()
  reportId: string;

  @ApiProperty({ enum: ['pdf', 'html'], description: 'Export format' })
  @IsEnum(['pdf', 'html'])
  format: 'pdf' | 'html';

  @ApiPropertyOptional({ description: 'Include images in export' })
  @IsOptional()
  includeImages?: boolean;
}
