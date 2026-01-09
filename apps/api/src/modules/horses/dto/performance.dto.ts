import {
  IsString,
  IsOptional,
  IsNumber,
  IsDate,
  IsEnum,
  IsInt,
  Min,
  Max,
  MaxLength,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';

export class CreatePerformanceDto {
  @ApiProperty({ description: 'Date de la competition' })
  @Type(() => Date)
  @IsDate()
  date: Date;

  @ApiProperty({ description: 'Nom de la competition' })
  @IsString()
  @MaxLength(255)
  competition: string;

  @ApiProperty({ description: 'Discipline: CSO, Dressage, CCE, Hunter, Endurance' })
  @IsString()
  discipline: string;

  @ApiProperty({ required: false, description: 'Niveau: Club4, Club3, Club2, Club1, Amateur, Pro' })
  @IsOptional()
  @IsString()
  level?: string;

  @ApiProperty({ required: false, description: 'Classement' })
  @IsOptional()
  @IsInt()
  @Min(1)
  rank?: number;

  @ApiProperty({ required: false, description: 'Nombre total de participants' })
  @IsOptional()
  @IsInt()
  @Min(1)
  totalParticipants?: number;

  @ApiProperty({ required: false, description: 'Points de penalite (fautes, refus)' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  penaltyPoints?: number;

  @ApiProperty({ required: false, description: 'Temps en secondes' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  timeSeconds?: number;

  @ApiProperty({ required: false, description: 'Score (pour dressage)' })
  @IsOptional()
  @IsNumber()
  score?: number;

  @ApiProperty({ required: false, description: 'Pourcentage (dressage)' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  percentage?: number;

  @ApiProperty({ required: false, description: 'Nom du cavalier' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  riderName?: string;

  @ApiProperty({ required: false, description: 'Lieu de la competition' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  location?: string;

  @ApiProperty({ required: false, description: 'Type de sol: sable, herbe, etc.' })
  @IsOptional()
  @IsString()
  surfaceType?: string;

  @ApiProperty({ required: false, description: 'Conditions meteo' })
  @IsOptional()
  @IsString()
  weather?: string;

  @ApiProperty({ required: false, description: 'Notes' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;
}

export class UpdatePerformanceDto {
  @ApiProperty({ required: false, description: 'Date de la competition' })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  date?: Date;

  @ApiProperty({ required: false, description: 'Nom de la competition' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  competition?: string;

  @ApiProperty({ required: false, description: 'Discipline' })
  @IsOptional()
  @IsString()
  discipline?: string;

  @ApiProperty({ required: false, description: 'Niveau' })
  @IsOptional()
  @IsString()
  level?: string;

  @ApiProperty({ required: false, description: 'Classement' })
  @IsOptional()
  @IsInt()
  @Min(1)
  rank?: number;

  @ApiProperty({ required: false, description: 'Nombre total de participants' })
  @IsOptional()
  @IsInt()
  @Min(1)
  totalParticipants?: number;

  @ApiProperty({ required: false, description: 'Points de penalite' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  penaltyPoints?: number;

  @ApiProperty({ required: false, description: 'Temps en secondes' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  timeSeconds?: number;

  @ApiProperty({ required: false, description: 'Score' })
  @IsOptional()
  @IsNumber()
  score?: number;

  @ApiProperty({ required: false, description: 'Pourcentage' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  percentage?: number;

  @ApiProperty({ required: false, description: 'Nom du cavalier' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  riderName?: string;

  @ApiProperty({ required: false, description: 'Lieu' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  location?: string;

  @ApiProperty({ required: false, description: 'Type de sol' })
  @IsOptional()
  @IsString()
  surfaceType?: string;

  @ApiProperty({ required: false, description: 'Meteo' })
  @IsOptional()
  @IsString()
  weather?: string;

  @ApiProperty({ required: false, description: 'Notes' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;
}

export class PerformanceStatsDto {
  @ApiProperty({ description: 'Nombre total de performances' })
  totalPerformances: number;

  @ApiProperty({ description: 'Meilleur classement' })
  bestRank: number | null;

  @ApiProperty({ description: 'Classement moyen' })
  averageRank: number | null;

  @ApiProperty({ description: 'Nombre de victoires (1ere place)' })
  wins: number;

  @ApiProperty({ description: 'Nombre de podiums (top 3)' })
  podiums: number;

  @ApiProperty({ description: 'Taux de sans faute (CSO)' })
  clearRoundRate: number | null;

  @ApiProperty({ description: 'Moyenne des penalites' })
  averagePenalties: number | null;

  @ApiProperty({ description: 'Meilleur temps' })
  bestTime: number | null;

  @ApiProperty({ description: 'Meilleur pourcentage (dressage)' })
  bestPercentage: number | null;

  @ApiProperty({ description: 'Performances par discipline' })
  byDiscipline: Record<string, number>;

  @ApiProperty({ description: 'Performances par niveau' })
  byLevel: Record<string, number>;
}
