import { IsString, IsNumber, IsOptional, IsArray } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateValuationDto {
  @ApiProperty()
  @IsString()
  horseId: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  studbook?: string;

  @ApiPropertyOptional()
  @IsNumber()
  @IsOptional()
  age?: number;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  level?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  discipline?: string;

  @ApiPropertyOptional()
  @IsArray()
  @IsOptional()
  competitionWins?: number;
}

export class QuickEstimateDto {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  studbook?: string;

  @ApiPropertyOptional()
  @IsNumber()
  @IsOptional()
  age?: number;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  level?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  discipline?: string;

  @ApiPropertyOptional()
  @IsNumber()
  @IsOptional()
  heightCm?: number;
}

export interface ValuationFactors {
  age: number;
  level: number;
  competition: number;
  health: number;
  lineage: number;
  demand: number;
  market: number;
  studbook: number;
  physical: number;
}

export interface ValuationResponse {
  id: string;
  horseId: string;
  horseName: string;
  minPrice: number;
  maxPrice: number;
  averagePrice: number;
  confidence: number;
  factors: ValuationFactors;
  marketTrend: string | null;
  demandIndex: number | null;
  aiAnalysis: string | null;
  aiRecommendations: string[];
  dataSources: string[];
  validUntil: Date;
  createdAt: Date;
}
