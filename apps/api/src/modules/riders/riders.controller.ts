import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { RidersService } from './riders.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { CreateRiderDto } from './dto/create-rider.dto';
import { UpdateRiderDto } from './dto/update-rider.dto';
import { ListRidersQueryDto } from './dto/list-riders-query.dto';

@ApiTags('riders')
@Controller('riders')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class RidersController {
  constructor(private readonly ridersService: RidersService) {}

  @Get()
  @ApiOperation({ summary: 'List riders' })
  async list(@CurrentUser() user: any, @Query() query: ListRidersQueryDto) {
    return this.ridersService.findAll(user.organizationId, query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get rider by ID' })
  async findOne(@CurrentUser() user: any, @Param('id') id: string) {
    return this.ridersService.findById(id, user.organizationId);
  }

  @Get(':id/stats')
  @ApiOperation({ summary: 'Get rider statistics' })
  async getStats(@CurrentUser() user: any, @Param('id') id: string) {
    return this.ridersService.getStats(id, user.organizationId);
  }

  @Post()
  @UseGuards(RolesGuard)
  @Roles('analyst', 'admin', 'owner')
  @ApiOperation({ summary: 'Create a rider' })
  async create(@CurrentUser() user: any, @Body() dto: CreateRiderDto) {
    return this.ridersService.create(user.organizationId, dto);
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles('analyst', 'admin', 'owner')
  @ApiOperation({ summary: 'Update a rider' })
  async update(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() dto: UpdateRiderDto,
  ) {
    return this.ridersService.update(id, user.organizationId, dto);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles('admin', 'owner')
  @ApiOperation({ summary: 'Delete a rider' })
  async delete(@CurrentUser() user: any, @Param('id') id: string) {
    return this.ridersService.delete(id, user.organizationId);
  }

  @Post(':id/horses/:horseId')
  @UseGuards(RolesGuard)
  @Roles('analyst', 'admin', 'owner')
  @ApiOperation({ summary: 'Assign a horse to rider' })
  async assignHorse(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Param('horseId') horseId: string,
  ) {
    return this.ridersService.assignHorse(id, user.organizationId, horseId);
  }

  @Delete(':id/horses/:horseId')
  @UseGuards(RolesGuard)
  @Roles('analyst', 'admin', 'owner')
  @ApiOperation({ summary: 'Unassign a horse from rider' })
  async unassignHorse(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Param('horseId') horseId: string,
  ) {
    return this.ridersService.unassignHorse(id, user.organizationId, horseId);
  }
}
