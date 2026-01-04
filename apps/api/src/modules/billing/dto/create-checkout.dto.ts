import { IsString, IsEnum, IsOptional, IsInt, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum PlanType {
  STARTER = 'starter',
  PROFESSIONAL = 'professional',
  ENTERPRISE = 'enterprise',
}

export enum BillingInterval {
  MONTHLY = 'monthly',
  YEARLY = 'yearly',
}

export class CreateCheckoutDto {
  @ApiProperty({ enum: PlanType, description: 'Plan to subscribe to' })
  @IsEnum(PlanType)
  plan: PlanType;

  @ApiProperty({ enum: BillingInterval, description: 'Billing interval' })
  @IsEnum(BillingInterval)
  interval: BillingInterval;

  @ApiPropertyOptional({ description: 'Success redirect URL' })
  @IsOptional()
  @IsString()
  successUrl?: string;

  @ApiPropertyOptional({ description: 'Cancel redirect URL' })
  @IsOptional()
  @IsString()
  cancelUrl?: string;
}

export class PurchaseTokensDto {
  @ApiProperty({ description: 'Number of tokens to purchase', minimum: 100 })
  @IsInt()
  @Min(100)
  amount: number;
}

export class CreatePortalSessionDto {
  @ApiPropertyOptional({ description: 'Return URL after portal session' })
  @IsOptional()
  @IsString()
  returnUrl?: string;
}
