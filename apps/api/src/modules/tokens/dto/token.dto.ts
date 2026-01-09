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

// ==================== TOKEN PACKS (PURCHASE) ====================

export class PurchaseTokensDto {
  @ApiProperty({ description: 'Token pack ID to purchase' })
  @IsString()
  packId: string;

  @ApiPropertyOptional({ description: 'Quantity of packs', default: 1 })
  @IsOptional()
  @IsInt()
  @Min(1)
  quantity?: number;

  @ApiPropertyOptional({ description: 'Success redirect URL' })
  @IsOptional()
  @IsString()
  successUrl?: string;

  @ApiPropertyOptional({ description: 'Cancel redirect URL' })
  @IsOptional()
  @IsString()
  cancelUrl?: string;
}

export class CheckTokensDto {
  @ApiProperty({ description: 'Number of tokens required' })
  @IsInt()
  @Min(1)
  amount: number;

  @ApiPropertyOptional({ description: 'Service type for cost estimation' })
  @IsOptional()
  @IsString()
  serviceType?: string;
}

export class TokenPackResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  name: string;

  @ApiProperty()
  description: string | null;

  @ApiProperty()
  baseTokens: number;

  @ApiProperty()
  bonusPercent: number;

  @ApiProperty()
  totalTokens: number;

  @ApiProperty({ description: 'Price in cents' })
  price: number;

  @ApiProperty()
  currency: string;

  @ApiProperty({ description: 'Price per token in currency' })
  pricePerToken: number;

  @ApiProperty()
  isPopular: boolean;

  @ApiProperty({ description: 'Savings percentage compared to smallest pack' })
  savingsPercent: number;
}

export class PurchaseHistoryQueryDto {
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
