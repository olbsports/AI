import { IsOptional, IsEnum, IsInt, Min, Max, IsUUID } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';

export class ListReportsQueryDto {
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

  @ApiProperty({ required: false, enum: ['course_analysis', 'radiological', 'locomotion', 'purchase_exam'] })
  @IsOptional()
  @IsEnum(['course_analysis', 'radiological', 'locomotion', 'purchase_exam'])
  type?: string;

  @ApiProperty({ required: false, enum: ['draft', 'pending_review', 'completed', 'archived'] })
  @IsOptional()
  @IsEnum(['draft', 'pending_review', 'completed', 'archived'])
  status?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsUUID()
  horseId?: string;

  @ApiProperty({ required: false, enum: ['A', 'A-', 'B+', 'B', 'B-', 'C', 'D'] })
  @IsOptional()
  @IsEnum(['A', 'A-', 'B+', 'B', 'B-', 'C', 'D'])
  category?: string;
}
