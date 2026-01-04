import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { SubscriptionsService } from './subscriptions.service';
import {
  UpgradePlanDto,
  CancelSubscriptionDto,
} from './dto/subscription.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { OrganizationGuard } from '../auth/guards/organization.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentOrganization } from '../auth/decorators/organization.decorator';

@ApiTags('subscriptions')
@Controller('subscriptions')
export class SubscriptionsController {
  constructor(private readonly subscriptionsService: SubscriptionsService) {}

  @Get('plans')
  @ApiOperation({ summary: 'Get all available plans' })
  async getPlans() {
    return this.subscriptionsService.getPlans();
  }

  @Get('current')
  @UseGuards(JwtAuthGuard, OrganizationGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current subscription details' })
  async getCurrentSubscription(@CurrentOrganization() organizationId: string) {
    return this.subscriptionsService.getSubscription(organizationId);
  }

  @Post('upgrade')
  @UseGuards(JwtAuthGuard, RolesGuard, OrganizationGuard)
  @Roles('owner', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Upgrade to a higher plan' })
  async upgradePlan(
    @CurrentOrganization() organizationId: string,
    @Body() dto: UpgradePlanDto,
  ) {
    return this.subscriptionsService.upgradePlan(organizationId, dto);
  }

  @Post('cancel')
  @UseGuards(JwtAuthGuard, RolesGuard, OrganizationGuard)
  @Roles('owner')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Cancel subscription' })
  async cancelSubscription(
    @CurrentOrganization() organizationId: string,
    @Body() dto: CancelSubscriptionDto,
  ) {
    return this.subscriptionsService.cancelSubscription(organizationId, dto);
  }

  @Post('reactivate')
  @UseGuards(JwtAuthGuard, RolesGuard, OrganizationGuard)
  @Roles('owner', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Reactivate canceled subscription' })
  async reactivateSubscription(@CurrentOrganization() organizationId: string) {
    return this.subscriptionsService.reactivateSubscription(organizationId);
  }
}
