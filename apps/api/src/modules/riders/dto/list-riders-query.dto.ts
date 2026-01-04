import { IsOptional, IsString, IsNumber, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';

export class ListRidersQueryDto {
  @IsNumber()
  @Min(1)
  @IsOptional()
  @Type(() => Number)
  page?: number = 1;

  @IsNumber()
  @Min(1)
  @Max(100)
  @IsOptional()
  @Type(() => Number)
  pageSize?: number = 20;

  @IsString()
  @IsOptional()
  search?: string;

  @IsString()
  @IsOptional()
  discipline?: string;

  @IsString()
  @IsOptional()
  level?: string;
}
