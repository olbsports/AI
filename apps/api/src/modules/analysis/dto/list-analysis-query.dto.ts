import { IsOptional, IsString, IsEnum, IsInt, Min, Max, IsUUID } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';

export class ListAnalysisQueryDto {
  @ApiProperty({ required: false, default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @ApiProperty({ required: false, default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  pageSize?: number;

  @ApiProperty({ required: false, enum: ['video_performance', 'video_course', 'radiological', 'locomotion'] })
  @IsOptional()
  @IsEnum(['video_performance', 'video_course', 'radiological', 'locomotion'])
  type?: string;

  @ApiProperty({ required: false, enum: ['pending', 'processing', 'completed', 'failed', 'cancelled'] })
  @IsOptional()
  @IsEnum(['pending', 'processing', 'completed', 'failed', 'cancelled'])
  status?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsUUID()
  horseId?: string;
}
