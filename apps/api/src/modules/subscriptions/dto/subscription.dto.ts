import { IsString, IsEnum, IsOptional, IsBoolean } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum SubscriptionPlan {
  FREE = 'free',
  STARTER = 'starter',
  PROFESSIONAL = 'professional',
  ENTERPRISE = 'enterprise',
}

export enum SubscriptionStatus {
  ACTIVE = 'active',
  PAST_DUE = 'past_due',
  CANCELED = 'canceled',
  INCOMPLETE = 'incomplete',
  TRIALING = 'trialing',
}

export class UpgradePlanDto {
  @ApiProperty({ enum: SubscriptionPlan, description: 'Target plan' })
  @IsEnum(SubscriptionPlan)
  plan: SubscriptionPlan;

  @ApiPropertyOptional({ description: 'Use yearly billing', default: false })
  @IsOptional()
  @IsBoolean()
  yearly?: boolean;
}

export class CancelSubscriptionDto {
  @ApiPropertyOptional({ description: 'Cancel immediately or at period end' })
  @IsOptional()
  @IsBoolean()
  immediate?: boolean;

  @ApiPropertyOptional({ description: 'Cancellation reason' })
  @IsOptional()
  @IsString()
  reason?: string;
}

export class ReactivateSubscriptionDto {
  @ApiPropertyOptional({ enum: SubscriptionPlan, description: 'Plan to reactivate with' })
  @IsOptional()
  @IsEnum(SubscriptionPlan)
  plan?: SubscriptionPlan;
}
