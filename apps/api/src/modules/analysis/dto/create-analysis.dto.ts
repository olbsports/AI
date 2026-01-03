import {
  IsString,
  IsEnum,
  IsOptional,
  IsUUID,
  IsArray,
  IsUrl,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';

class CompetitionDto {
  @ApiProperty()
  @IsString()
  name: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  location?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  level?: string;
}

export class CreateAnalysisDto {
  @ApiProperty({ enum: ['video_performance', 'video_course', 'radiological', 'locomotion'] })
  @IsEnum(['video_performance', 'video_course', 'radiological', 'locomotion'])
  type: string;

  @ApiProperty({ example: 'Analysis of Grand Prix performance' })
  @IsString()
  @MaxLength(255)
  title: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsUUID()
  horseId?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsUUID()
  riderId?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @ValidateNested()
  @Type(() => CompetitionDto)
  competition?: CompetitionDto;

  @ApiProperty({ type: [String] })
  @IsArray()
  @IsUrl({}, { each: true })
  inputMediaUrls: string[];
}
