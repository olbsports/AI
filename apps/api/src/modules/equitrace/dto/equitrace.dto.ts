import { IsString, IsDate, IsOptional, IsEnum, IsBoolean, IsObject, IsArray } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';

export enum EquiTraceEntryType {
  OWNERSHIP = 'ownership',
  COMPETITION = 'competition',
  HEALTH = 'health',
  LOCATION = 'location',
  TRAINING = 'training',
  SALE = 'sale',
  BREEDING = 'breeding',
}

export class CreateEntryDto {
  @ApiProperty({ enum: EquiTraceEntryType })
  @IsEnum(EquiTraceEntryType)
  type: EquiTraceEntryType;

  @ApiProperty()
  @IsDate()
  @Type(() => Date)
  date: Date;

  @ApiProperty()
  @IsString()
  title: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  description?: string;

  @ApiPropertyOptional()
  @IsObject()
  @IsOptional()
  metadata?: Record<string, any>;

  @ApiPropertyOptional()
  @IsArray()
  @IsOptional()
  attachments?: string[];
}

export interface EquiTraceEntry {
  id: string;
  type: EquiTraceEntryType | string;
  date: Date;
  title: string;
  description?: string;
  source: string;
  sourceUrl?: string;
  verified: boolean;
  metadata?: Record<string, any>;
}

export interface EquiTracePedigree {
  sire?: {
    name: string;
    ueln?: string;
    sire?: { name: string; ueln?: string };
    dam?: { name: string; ueln?: string };
  };
  dam?: {
    name: string;
    ueln?: string;
    sire?: { name: string; ueln?: string };
    dam?: { name: string; ueln?: string };
  };
}

export interface EquiTraceStats {
  totalCompetitions: number;
  wins: number;
  podiums: number;
  ownershipChanges: number;
  healthEvents: number;
  firstCompetition: Date | null;
  lastCompetition: Date | null;
  disciplines: string[];
  highestLevel: string | null;
  verifiedEntries: number;
  totalEntries: number;
}

export interface EquiTraceReport {
  horseId: string;
  horseName: string;
  sireNumber?: string;
  ueln?: string;
  microchip?: string;
  birthDate?: Date;
  breed?: string;
  studbook?: string;
  color?: string;
  gender: string;
  pedigree: EquiTracePedigree;
  timeline: EquiTraceEntry[];
  stats: EquiTraceStats;
  dataSources: string[];
  generatedAt: Date;
}

export interface EquiTraceTimeline {
  horseId: string;
  entries: EquiTraceEntry[];
  lastUpdated: Date;
}
