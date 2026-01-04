import { IsString, IsInt, IsOptional, IsEnum, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum TransactionType {
  CREDIT = 'credit',
  DEBIT = 'debit',
}

export class DebitTokensDto {
  @ApiProperty({ description: 'Number of tokens to debit', minimum: 1 })
  @IsInt()
  @Min(1)
  amount: number;

  @ApiProperty({ description: 'Reason for debit' })
  @IsString()
  reason: string;

  @ApiPropertyOptional({ description: 'Related analysis ID' })
  @IsOptional()
  @IsString()
  analysisId?: string;
}

export class TransferTokensDto {
  @ApiProperty({ description: 'Target organization ID' })
  @IsString()
  targetOrganizationId: string;

  @ApiProperty({ description: 'Number of tokens to transfer', minimum: 1 })
  @IsInt()
  @Min(1)
  amount: number;

  @ApiPropertyOptional({ description: 'Transfer note' })
  @IsOptional()
  @IsString()
  note?: string;
}

export class TokenTransactionQueryDto {
  @ApiPropertyOptional({ enum: TransactionType })
  @IsOptional()
  @IsEnum(TransactionType)
  type?: TransactionType;

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
