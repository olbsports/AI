import {
  IsString,
  IsOptional,
  IsEnum,
  IsNumber,
  IsDate,
  IsUUID,
  MaxLength,
  Min,
  Max,
  IsArray,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';

export class CreateHorseDto {
  @ApiProperty({ example: 'Thunder' })
  @IsString()
  @MaxLength(255)
  name: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  sireId?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  ueln?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  microchip?: string;

  @ApiProperty({ enum: ['male', 'female', 'gelding'] })
  @IsEnum(['male', 'female', 'gelding'])
  gender: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  birthDate?: Date;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  breed?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  color?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsNumber()
  @Min(100)
  @Max(200)
  heightCm?: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  ownerName?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsUUID()
  riderId?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tags?: string[];

  @ApiProperty({ required: false, description: 'Discipline principale' })
  @IsOptional()
  @IsString()
  discipline?: string;

  @ApiProperty({ required: false, description: 'Niveau (0-7)' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(7)
  level?: number;

  @ApiProperty({ required: false, description: 'Notes' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;

  @ApiProperty({ required: false, description: 'Numéro de passeport' })
  @IsOptional()
  @IsString()
  passportNumber?: string;

  @ApiProperty({ required: false, description: 'Statut du cheval' })
  @IsOptional()
  @IsEnum(['active', 'retired', 'sold', 'deceased'])
  status?: string;

  // Pedigree / Origines
  @ApiProperty({ required: false, description: 'Père' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  sireName?: string;

  @ApiProperty({ required: false, description: 'Mère' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  damName?: string;

  @ApiProperty({ required: false, description: 'Grand-père paternel' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  siresSireName?: string;

  @ApiProperty({ required: false, description: 'Grand-mère paternelle' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  siresDamName?: string;

  @ApiProperty({ required: false, description: 'Grand-père maternel' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  damsSireName?: string;

  @ApiProperty({ required: false, description: 'Grand-mère maternelle' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  damsDamName?: string;
}
