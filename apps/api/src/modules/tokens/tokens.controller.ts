import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { TokensService } from './tokens.service';
import {
  DebitTokensDto,
  TransferTokensDto,
  TokenTransactionQueryDto,
} from './dto/token.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { OrganizationGuard } from '../auth/guards/organization.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentOrganization } from '../auth/decorators/organization.decorator';

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
}
