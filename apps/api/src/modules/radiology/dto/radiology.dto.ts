import {
  IsString,
  IsOptional,
  IsArray,
  IsInt,
  IsEnum,
  IsUUID,
  IsDateString,
  Min,
  ValidateNested,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';

export enum ExamType {
  SIMPLE = 'simple',       // 1-3 clichés (150 tokens)
  STANDARD = 'standard',   // 4-10 clichés (300 tokens)
  EXPERT = 'expert',       // + validation expert (500 tokens)
}

export enum RadiologyStatus {
  PENDING = 'pending',
  UPLOADING = 'uploading',
  PROCESSING = 'processing',
  COMPLETED = 'completed',
  FAILED = 'failed',
  CANCELLED = 'cancelled',
}

export enum AnatomicalRegion {
  BOULET_AD = 'boulet_ad',     // Boulet Antérieur Droit
  BOULET_AG = 'boulet_ag',     // Boulet Antérieur Gauche
  BOULET_PD = 'boulet_pd',     // Boulet Postérieur Droit
  BOULET_PG = 'boulet_pg',     // Boulet Postérieur Gauche
  JARRET_D = 'jarret_d',       // Jarret Droit
  JARRET_G = 'jarret_g',       // Jarret Gauche
  GENOU_D = 'genou_d',         // Genou Droit
  GENOU_G = 'genou_g',         // Genou Gauche
  PIED_AD = 'pied_ad',         // Pied Antérieur Droit
  PIED_AG = 'pied_ag',
  PIED_PD = 'pied_pd',
  PIED_PG = 'pied_pg',
  DOS = 'dos',                 // Dos / Colonne
  ENCOLURE = 'encolure',       // Encolure
  GRASSET_D = 'grasset_d',     // Grasset Droit
  GRASSET_G = 'grasset_g',
  CANON_AD = 'canon_ad',       // Canon
  CANON_AG = 'canon_ag',
  CANON_PD = 'canon_pd',
  CANON_PG = 'canon_pg',
  AUTRE = 'autre',
}

export class CreateRadiologyDto {
  @ApiProperty({ description: 'Horse ID' })
  @IsUUID()
  horseId: string;

  @ApiPropertyOptional({ enum: ExamType, default: ExamType.STANDARD })
  @IsOptional()
  @IsEnum(ExamType)
  examType?: ExamType;

  @ApiPropertyOptional({ description: 'Exam date' })
  @IsOptional()
  @IsDateString()
  examDate?: string;

  @ApiPropertyOptional({ description: 'Indication / Reason for exam' })
  @IsOptional()
  @IsString()
  indication?: string;

  @ApiPropertyOptional({ description: 'Clinical history' })
  @IsOptional()
  @IsString()
  clinicalHistory?: string;
}

export class ImageInfoDto {
  @ApiProperty({ enum: AnatomicalRegion })
  @IsEnum(AnatomicalRegion)
  region: AnatomicalRegion;

  @ApiPropertyOptional({ description: 'View type: face, profil, oblique' })
  @IsOptional()
  @IsString()
  view?: string;
}

export class AddImagesDto {
  @ApiProperty({ type: [ImageInfoDto], description: 'Image metadata array' })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ImageInfoDto)
  images: ImageInfoDto[];
}

export class ValidateRadiologyDto {
  @ApiPropertyOptional({ description: 'Veterinarian notes' })
  @IsOptional()
  @IsString()
  vetNotes?: string;

  @ApiPropertyOptional({ description: 'Digital signature' })
  @IsOptional()
  @IsString()
  vetSignature?: string;
}

export class RadiologyQueryDto {
  @ApiPropertyOptional({ description: 'Filter by horse ID' })
  @IsOptional()
  @IsUUID()
  horseId?: string;

  @ApiPropertyOptional({ enum: RadiologyStatus })
  @IsOptional()
  @IsEnum(RadiologyStatus)
  status?: RadiologyStatus;

  @ApiPropertyOptional({ enum: ExamType })
  @IsOptional()
  @IsEnum(ExamType)
  examType?: ExamType;

  @ApiPropertyOptional({ description: 'Page number', default: 1 })
  @IsOptional()
  @IsInt()
  @Min(1)
  page?: number;

  @ApiPropertyOptional({ description: 'Items per page', default: 20 })
  @IsOptional()
  @IsInt()
  @Min(1)
  limit?: number;
}

export class RadioDetectionDto {
  @ApiProperty()
  id: string;

  @ApiProperty({ description: 'Pathology type detected' })
  pathologyType: string;

  @ApiProperty({ description: 'Human readable label' })
  label: string;

  @ApiProperty({ description: 'Severity: low, moderate, high, critical' })
  severity: string;

  @ApiProperty({ description: 'Confidence score 0-100' })
  confidence: number;

  @ApiProperty({ description: 'Bounding box coordinates' })
  boundingBox: {
    x: number;
    y: number;
    width: number;
    height: number;
  };

  @ApiProperty({ description: 'AI generated description' })
  description: string;

  @ApiPropertyOptional({ description: 'Recommended action' })
  recommendation?: string;
}

export class RadioImageResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  filename: string;

  @ApiProperty()
  url: string;

  @ApiProperty()
  thumbnailUrl: string | null;

  @ApiProperty()
  region: string;

  @ApiProperty()
  regionLabel: string;

  @ApiProperty()
  view: string | null;

  @ApiProperty()
  aiScore: number | null;

  @ApiProperty({ type: [RadioDetectionDto] })
  detections: RadioDetectionDto[];
}

export class RadiologyResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  horseId: string;

  @ApiProperty()
  horseName: string;

  @ApiProperty()
  examDate: Date;

  @ApiProperty()
  examType: string;

  @ApiProperty()
  status: string;

  @ApiProperty()
  globalScore: number | null;

  @ApiProperty()
  category: string | null;

  @ApiProperty()
  findings: any[];

  @ApiProperty()
  recommendations: any[];

  @ApiProperty()
  conclusion: string | null;

  @ApiProperty({ type: [RadioImageResponseDto] })
  images: RadioImageResponseDto[];

  @ApiProperty()
  validatedAt: Date | null;

  @ApiProperty()
  tokensConsumed: number;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  completedAt: Date | null;
}

// Region labels mapping
export const REGION_LABELS: Record<AnatomicalRegion, string> = {
  [AnatomicalRegion.BOULET_AD]: 'Boulet Antérieur Droit',
  [AnatomicalRegion.BOULET_AG]: 'Boulet Antérieur Gauche',
  [AnatomicalRegion.BOULET_PD]: 'Boulet Postérieur Droit',
  [AnatomicalRegion.BOULET_PG]: 'Boulet Postérieur Gauche',
  [AnatomicalRegion.JARRET_D]: 'Jarret Droit',
  [AnatomicalRegion.JARRET_G]: 'Jarret Gauche',
  [AnatomicalRegion.GENOU_D]: 'Genou Droit',
  [AnatomicalRegion.GENOU_G]: 'Genou Gauche',
  [AnatomicalRegion.PIED_AD]: 'Pied Antérieur Droit',
  [AnatomicalRegion.PIED_AG]: 'Pied Antérieur Gauche',
  [AnatomicalRegion.PIED_PD]: 'Pied Postérieur Droit',
  [AnatomicalRegion.PIED_PG]: 'Pied Postérieur Gauche',
  [AnatomicalRegion.DOS]: 'Dos / Colonne vertébrale',
  [AnatomicalRegion.ENCOLURE]: 'Encolure',
  [AnatomicalRegion.GRASSET_D]: 'Grasset Droit',
  [AnatomicalRegion.GRASSET_G]: 'Grasset Gauche',
  [AnatomicalRegion.CANON_AD]: 'Canon Antérieur Droit',
  [AnatomicalRegion.CANON_AG]: 'Canon Antérieur Gauche',
  [AnatomicalRegion.CANON_PD]: 'Canon Postérieur Droit',
  [AnatomicalRegion.CANON_PG]: 'Canon Postérieur Gauche',
  [AnatomicalRegion.AUTRE]: 'Autre région',
};

// Token costs by exam type
export const RADIOLOGY_TOKEN_COSTS: Record<ExamType, number> = {
  [ExamType.SIMPLE]: 150,
  [ExamType.STANDARD]: 300,
  [ExamType.EXPERT]: 500,
};
