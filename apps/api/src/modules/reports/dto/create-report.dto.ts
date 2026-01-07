import { IsString, IsNotEmpty, IsOptional, IsArray, IsDateString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateReportDto {
  @ApiProperty({ description: 'Analysis session ID' })
  @IsString()
  @IsNotEmpty()
  analysisSessionId: string;

  @ApiProperty({ description: 'Report type', example: 'course_analysis' })
  @IsString()
  @IsNotEmpty()
  type: string;

  @ApiProperty({ description: 'Exam date', example: '2024-01-15' })
  @IsDateString()
  @IsNotEmpty()
  examDate: string;

  @ApiProperty({ description: 'Exam time', required: false })
  @IsString()
  @IsOptional()
  examTime?: string;

  @ApiProperty({ description: 'Horse ID', required: false })
  @IsString()
  @IsOptional()
  horseId?: string;

  @ApiProperty({ description: 'Location', required: false })
  @IsString()
  @IsOptional()
  location?: string;

  @ApiProperty({ description: 'Veterinarians', required: false })
  @IsArray()
  @IsOptional()
  veterinarians?: any[];

  @ApiProperty({ description: 'Examined regions', required: false })
  @IsArray()
  @IsOptional()
  examinedRegions?: any[];

  @ApiProperty({ description: 'Global score', required: false })
  @IsOptional()
  globalScore?: number;

  @ApiProperty({ description: 'Category', required: false })
  @IsString()
  @IsOptional()
  category?: string;
}
