import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  Param,
  UseGuards,
  Headers,
  RawBodyRequest,
  Req,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiParam } from '@nestjs/swagger';
import { Request } from 'express';

import { TokensService } from './tokens.service';
import {
  DebitTokensDto,
  TransferTokensDto,
  TokenTransactionQueryDto,
  PurchaseTokensDto,
  CheckTokensDto,
  PurchaseHistoryQueryDto,
} from './dto/token.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { OrganizationGuard } from '../auth/guards/organization.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentOrganization } from '../auth/decorators/organization.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Public } from '../auth/decorators/public.decorator';
import Stripe from 'stripe';

@ApiTags('tokens')
@Controller('tokens')
@UseGuards(JwtAuthGuard, OrganizationGuard)
@ApiBearerAuth()
export class TokensController {
  constructor(private readonly tokensService: TokensService) {}

  @Get('balance')
  @ApiOperation({ summary: 'Get current token balance' })
  async getBalance(@CurrentOrganization() organizationId: string) {
    return this.tokensService.getBalance(organizationId);
  }

  @Get('transactions')
  @ApiOperation({ summary: 'Get token transaction history' })
  async getTransactions(
    @CurrentOrganization() organizationId: string,
    @Query() query: TokenTransactionQueryDto,
  ) {
    return this.tokensService.getTransactions(organizationId, query);
  }

  @Get('usage')
  @ApiOperation({ summary: 'Get token usage statistics' })
  async getUsageStats(@CurrentOrganization() organizationId: string) {
    return this.tokensService.getUsageStats(organizationId);
  }

  @Get('costs')
  @ApiOperation({ summary: 'Get token costs per operation' })
  getCosts() {
    return this.tokensService.getTokenCosts();
  }

  @Post('debit')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  @ApiOperation({ summary: 'Manually debit tokens (admin only)' })
  async debitTokens(
    @CurrentOrganization() organizationId: string,
    @Body() dto: DebitTokensDto,
  ) {
    return this.tokensService.debitTokens(organizationId, dto);
  }

  @Post('transfer')
  @UseGuards(RolesGuard)
  @Roles('owner')
  @ApiOperation({ summary: 'Transfer tokens to another organization' })
  async transferTokens(
    @CurrentOrganization() organizationId: string,
    @Body() dto: TransferTokensDto,
  ) {
    return this.tokensService.transferTokens(organizationId, dto);
  }

  // ==================== TOKEN PACKS & PURCHASE ====================

  @Get('packs')
  @ApiOperation({ summary: 'Get available token packs' })
  async getTokenPacks() {
    return this.tokensService.getTokenPacks();
  }

  @Post('check')
  @ApiOperation({ summary: 'Check if tokens are available for an operation' })
  async checkTokens(
    @CurrentOrganization() organizationId: string,
    @Body() dto: CheckTokensDto,
  ) {
    return this.tokensService.checkTokenAvailability(organizationId, dto);
  }

  @Get('estimate/:serviceType')
  @ApiOperation({ summary: 'Estimate token cost for a service' })
  @ApiParam({ name: 'serviceType', description: 'Service type (e.g., radiologySimple, videoAnalysis)' })
  async estimateCost(@Param('serviceType') serviceType: string) {
    return this.tokensService.estimateCost(serviceType);
  }

  @Post('purchase')
  @ApiOperation({ summary: 'Create a checkout session to purchase tokens' })
  async purchaseTokens(
    @CurrentOrganization() organizationId: string,
    @CurrentUser('id') userId: string,
    @Body() dto: PurchaseTokensDto,
  ) {
    return this.tokensService.createPurchaseSession(organizationId, userId, dto);
  }

  @Get('purchases')
  @ApiOperation({ summary: 'Get purchase history' })
  async getPurchaseHistory(
    @CurrentOrganization() organizationId: string,
    @Query() query: PurchaseHistoryQueryDto,
  ) {
    return this.tokensService.getPurchaseHistory(organizationId, query);
  }

  @Post('webhook')
  @Public()
  @ApiOperation({ summary: 'Stripe webhook for payment events' })
  async handleStripeWebhook(
    @Req() req: RawBodyRequest<Request>,
    @Headers('stripe-signature') signature: string,
  ) {
    const stripeWebhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
    if (!stripeWebhookSecret) {
      throw new Error('STRIPE_WEBHOOK_SECRET not configured');
    }

    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
      apiVersion: '2024-06-20',
    });

    const event = stripe.webhooks.constructEvent(
      req.rawBody!,
      signature,
      stripeWebhookSecret,
    );

    await this.tokensService.handleStripeWebhook(event);
    return { received: true };
  }
}
