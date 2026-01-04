import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  Req,
  RawBodyRequest,
  Headers,
  HttpCode,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { Request } from 'express';

import { BillingService } from './billing.service';
import {
  CreateCheckoutDto,
  PurchaseTokensDto,
  CreatePortalSessionDto,
} from './dto/create-checkout.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { OrganizationGuard } from '../auth/guards/organization.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentOrganization } from '../auth/decorators/organization.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('billing')
@Controller('billing')
export class BillingController {
  constructor(private readonly billingService: BillingService) {}

  @Get('plans')
  @ApiOperation({ summary: 'Get available subscription plans' })
  getPlans() {
    return this.billingService.getPlans();
  }

  @Post('checkout')
  @UseGuards(JwtAuthGuard, RolesGuard, OrganizationGuard)
  @Roles('owner', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a checkout session for subscription' })
  async createCheckout(
    @CurrentOrganization() organizationId: string,
    @CurrentUser('id') userId: string,
    @Body() dto: CreateCheckoutDto,
  ) {
    return this.billingService.createCheckoutSession(organizationId, userId, dto);
  }

  @Post('tokens/purchase')
  @UseGuards(JwtAuthGuard, RolesGuard, OrganizationGuard)
  @Roles('owner', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Purchase additional tokens' })
  async purchaseTokens(
    @CurrentOrganization() organizationId: string,
    @CurrentUser('id') userId: string,
    @Body() dto: PurchaseTokensDto,
  ) {
    return this.billingService.createTokenPurchaseSession(organizationId, userId, dto);
  }

  @Post('portal')
  @UseGuards(JwtAuthGuard, RolesGuard, OrganizationGuard)
  @Roles('owner', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a billing portal session' })
  async createPortalSession(
    @CurrentOrganization() organizationId: string,
    @Body() dto: CreatePortalSessionDto,
  ) {
    return this.billingService.createPortalSession(organizationId, dto);
  }

  @Get('status')
  @UseGuards(JwtAuthGuard, OrganizationGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current subscription status' })
  async getSubscriptionStatus(@CurrentOrganization() organizationId: string) {
    return this.billingService.getSubscriptionStatus(organizationId);
  }

  @Post('webhook')
  @HttpCode(200)
  @ApiOperation({ summary: 'Handle Stripe webhooks' })
  async handleWebhook(
    @Req() req: RawBodyRequest<Request>,
    @Headers('stripe-signature') signature: string,
  ) {
    await this.billingService.handleWebhook(req.rawBody!, signature);
    return { received: true };
  }
}
