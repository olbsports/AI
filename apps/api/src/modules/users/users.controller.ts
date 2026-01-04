import { Controller, Get, Patch, Body, UseGuards, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UpdateUserDto } from './dto/update-user.dto';

@ApiTags('users')
@Controller('users')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  @ApiOperation({ summary: 'Get current user profile' })
  async getProfile(@CurrentUser() user: any) {
    return this.usersService.findById(user.id);
  }

  @Patch('me')
  @ApiOperation({ summary: 'Update current user profile' })
  async updateProfile(
    @CurrentUser() user: any,
    @Body() dto: UpdateUserDto,
  ) {
    return this.usersService.update(user.id, dto);
  }

  @Get('organization')
  @ApiOperation({ summary: 'List organization members' })
  async listOrganizationMembers(@CurrentUser() user: any) {
    return this.usersService.findByOrganization(user.organizationId);
  }
}
