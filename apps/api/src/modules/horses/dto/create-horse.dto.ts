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
}
