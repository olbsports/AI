import {
  Controller,
  Get,
  Put,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { AdminService } from './admin.service';
import {
  OrganizationQueryDto,
  UserQueryDto,
  DateRangeDto,
  UpdateOrganizationDto,
  UpdateUserDto,
} from './dto/admin.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

@ApiTags('admin')
@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('owner') // Super admin only
@ApiBearerAuth()
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('dashboard')
  @ApiOperation({ summary: 'Get admin dashboard statistics' })
  async getDashboard() {
    return this.adminService.getDashboardStats();
  }

  @Get('organizations')
  @ApiOperation({ summary: 'List all organizations' })
  async getOrganizations(@Query() query: OrganizationQueryDto) {
    return this.adminService.getOrganizations(query);
  }

  @Get('organizations/top')
  @ApiOperation({ summary: 'Get top organizations by activity' })
  async getTopOrganizations(@Query('limit') limit?: number) {
    return this.adminService.getTopOrganizations(limit);
  }

  @Get('organizations/:id')
  @ApiOperation({ summary: 'Get organization details' })
  async getOrganization(@Param('id') id: string) {
    return this.adminService.getOrganization(id);
  }

  @Put('organizations/:id')
  @ApiOperation({ summary: 'Update organization' })
  async updateOrganization(
    @Param('id') id: string,
    @Body() dto: UpdateOrganizationDto,
  ) {
    return this.adminService.updateOrganization(id, dto);
  }

  @Get('users')
  @ApiOperation({ summary: 'List all users' })
  async getUsers(@Query() query: UserQueryDto) {
    return this.adminService.getUsers(query);
  }

  @Get('users/:id')
  @ApiOperation({ summary: 'Get user details' })
  async getUser(@Param('id') id: string) {
    return this.adminService.getUser(id);
  }

  @Put('users/:id')
  @ApiOperation({ summary: 'Update user' })
  async updateUser(@Param('id') id: string, @Body() dto: UpdateUserDto) {
    return this.adminService.updateUser(id, dto);
  }

  @Get('activity')
  @ApiOperation({ summary: 'Get recent platform activity' })
  async getActivity(@Query() range: DateRangeDto) {
    return this.adminService.getRecentActivity(range);
  }
}
