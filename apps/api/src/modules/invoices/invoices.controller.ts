import {
  Controller,
  Get,
  Post,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { InvoicesService } from './invoices.service';
import { InvoiceQueryDto } from './dto/invoice.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { OrganizationGuard } from '../auth/guards/organization.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentOrganization } from '../auth/decorators/organization.decorator';

@ApiTags('invoices')
@Controller('invoices')
@UseGuards(JwtAuthGuard, OrganizationGuard)
@ApiBearerAuth()
export class InvoicesController {
  constructor(private readonly invoicesService: InvoicesService) {}

  @Get()
  @ApiOperation({ summary: 'Get invoice list' })
  async getInvoices(
    @CurrentOrganization() organizationId: string,
    @Query() query: InvoiceQueryDto,
  ) {
    return this.invoicesService.getInvoices(organizationId, query);
  }

  @Get('summary')
  @ApiOperation({ summary: 'Get invoice summary' })
  async getSummary(@CurrentOrganization() organizationId: string) {
    return this.invoicesService.getSummary(organizationId);
  }

  @Get('upcoming')
  @ApiOperation({ summary: 'Get upcoming invoice preview' })
  async getUpcoming(@CurrentOrganization() organizationId: string) {
    return this.invoicesService.getUpcomingInvoice(organizationId);
  }

  @Get('report/:year')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  @ApiOperation({ summary: 'Get yearly billing report' })
  async getYearlyReport(
    @CurrentOrganization() organizationId: string,
    @Param('year') year: string,
  ) {
    return this.invoicesService.getYearlyReport(organizationId, parseInt(year, 10));
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get invoice details' })
  async getInvoice(
    @CurrentOrganization() organizationId: string,
    @Param('id') invoiceId: string,
  ) {
    return this.invoicesService.getInvoice(organizationId, invoiceId);
  }

  @Get(':id/download')
  @ApiOperation({ summary: 'Get invoice PDF download URL' })
  async downloadInvoice(
    @CurrentOrganization() organizationId: string,
    @Param('id') invoiceId: string,
  ) {
    return this.invoicesService.downloadInvoice(organizationId, invoiceId);
  }

  @Post('sync')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  @ApiOperation({ summary: 'Sync invoices from Stripe' })
  async syncInvoices(@CurrentOrganization() organizationId: string) {
    return this.invoicesService.syncInvoicesFromStripe(organizationId);
  }
}
