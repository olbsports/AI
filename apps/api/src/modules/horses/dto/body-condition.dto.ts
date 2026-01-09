import {
  IsString,
  IsOptional,
  IsNumber,
  IsDate,
  IsEnum,
  IsArray,
  Min,
  Max,
  MaxLength,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';

export class CreateBodyConditionDto {
  @ApiProperty({ description: 'Score global (1-9 echelle Henneke ou 0-5 echelle francaise)' })
  @IsNumber()
  @Min(0)
  @Max(9)
  score: number;

  @ApiProperty({ required: false, default: 'henneke', description: 'Type echelle: henneke (1-9) ou french (0-5)' })
  @IsOptional()
  @IsEnum(['henneke', 'french'])
  scaleType?: string;

  @ApiProperty({ description: 'Date de l evaluation' })
  @Type(() => Date)
  @IsDate()
  date: Date;

  // Scores par zone (optionnels)
  @ApiProperty({ required: false, description: 'Score encolure' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(9)
  neckScore?: number;

  @ApiProperty({ required: false, description: 'Score garrot' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(9)
  withersScore?: number;

  @ApiProperty({ required: false, description: 'Score dos' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(9)
  backScore?: number;

  @ApiProperty({ required: false, description: 'Score cotes' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(9)
  ribsScore?: number;

  @ApiProperty({ required: false, description: 'Score base de la queue' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(9)
  tailheadScore?: number;

  @ApiProperty({ required: false, description: 'Score epaule' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(9)
  shoulderScore?: number;

  // Mesures complementaires
  @ApiProperty({ required: false, description: 'Poids estime en kg' })
  @IsOptional()
  @IsNumber()
  @Min(100)
  @Max(1500)
  weightKg?: number;

  @ApiProperty({ required: false, description: 'Tour de sangle en cm' })
  @IsOptional()
  @IsNumber()
  @Min(100)
  @Max(300)
  bellyGirthCm?: number;

  // Evaluateur
  @ApiProperty({ required: false, description: 'Nom de l evaluateur' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  evaluatedBy?: string;

  @ApiProperty({ required: false, default: 'visual', description: 'Methode: visual, palpation, combined' })
  @IsOptional()
  @IsEnum(['visual', 'palpation', 'combined'])
  method?: string;

  // Notes
  @ApiProperty({ required: false, description: 'Notes' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;

  @ApiProperty({ required: false, description: 'Recommandations' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  recommendations?: string;

  @ApiProperty({ required: false, description: 'URLs des photos' })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  photoUrls?: string[];
}

export class UpdateBodyConditionDto {
  @ApiProperty({ required: false, description: 'Score global' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(9)
  score?: number;

  @ApiProperty({ required: false, description: 'Type echelle' })
  @IsOptional()
  @IsEnum(['henneke', 'french'])
  scaleType?: string;

  @ApiProperty({ required: false, description: 'Date' })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  date?: Date;

  @ApiProperty({ required: false, description: 'Score encolure' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(9)
  neckScore?: number;

  @ApiProperty({ required: false, description: 'Score garrot' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(9)
  withersScore?: number;

  @ApiProperty({ required: false, description: 'Score dos' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(9)
  backScore?: number;

  @ApiProperty({ required: false, description: 'Score cotes' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(9)
  ribsScore?: number;

  @ApiProperty({ required: false, description: 'Score base de la queue' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(9)
  tailheadScore?: number;

  @ApiProperty({ required: false, description: 'Score epaule' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(9)
  shoulderScore?: number;

  @ApiProperty({ required: false, description: 'Poids en kg' })
  @IsOptional()
  @IsNumber()
  @Min(100)
  @Max(1500)
  weightKg?: number;

  @ApiProperty({ required: false, description: 'Tour de sangle en cm' })
  @IsOptional()
  @IsNumber()
  @Min(100)
  @Max(300)
  bellyGirthCm?: number;

  @ApiProperty({ required: false, description: 'Evaluateur' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  evaluatedBy?: string;

  @ApiProperty({ required: false, description: 'Methode' })
  @IsOptional()
  @IsEnum(['visual', 'palpation', 'combined'])
  method?: string;

  @ApiProperty({ required: false, description: 'Notes' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;

  @ApiProperty({ required: false, description: 'Recommandations' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  recommendations?: string;

  @ApiProperty({ required: false, description: 'URLs des photos' })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  photoUrls?: string[];
}

export class BodyConditionHistoryDto {
  @ApiProperty({ description: 'Historique des scores' })
  history: {
    id: string;
    score: number;
    scaleType: string;
    date: Date;
    weightKg?: number;
    evaluatedBy?: string;
  }[];

  @ApiProperty({ description: 'Score actuel' })
  currentScore: number | null;

  @ApiProperty({ description: 'Tendance: improving, stable, declining' })
  trend: string | null;

  @ApiProperty({ description: 'Score moyen sur les 6 derniers mois' })
  averageScore: number | null;

  @ApiProperty({ description: 'Score ideal recommande' })
  recommendedScore: { min: number; max: number };
}
