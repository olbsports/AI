import { IsOptional, IsString, IsEnum, IsInt, Min, Max } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';

export class ListHorsesQueryDto {
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

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiProperty({ required: false, enum: ['active', 'retired', 'sold', 'deceased'] })
  @IsOptional()
  @IsEnum(['active', 'retired', 'sold', 'deceased'])
  status?: string;

  @ApiProperty({ required: false, enum: ['male', 'female', 'gelding'] })
  @IsOptional()
  @IsEnum(['male', 'female', 'gelding'])
  gender?: string;
}
