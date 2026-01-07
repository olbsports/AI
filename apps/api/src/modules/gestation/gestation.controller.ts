import { Controller, Get, Post, Put, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { GestationService } from './gestation.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('gestations')
@Controller('gestations')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class GestationController {
  constructor(private readonly gestationService: GestationService) {}

  @Get()
  @ApiOperation({ summary: 'Get all gestations' })
  async getGestations(@CurrentUser() user: any) {
    return this.gestationService.getGestations(user.id, user.organizationId);
  }

  @Get('active')
  @ApiOperation({ summary: 'Get active gestations' })
  async getActiveGestations(@CurrentUser() user: any) {
    return this.gestationService.getActiveGestations(user.id, user.organizationId);
  }

  @Get('stats')
  @ApiOperation({ summary: 'Get breeding stats' })
  async getBreedingStats(@CurrentUser() user: any) {
    return this.gestationService.getBreedingStats(user.organizationId);
  }

  @Post()
  @ApiOperation({ summary: 'Create gestation' })
  async createGestation(
    @CurrentUser() user: any,
    @Body()
    body: {
      horseId: string;
      stallionName?: string;
      breedingDate: string;
      expectedDueDate?: string;
      notes?: string;
    }
  ) {
    return this.gestationService.createGestation(user.organizationId, body);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get gestation by ID' })
  async getGestation(@CurrentUser() user: any, @Param('id') id: string) {
    return this.gestationService.getGestation(id, user.organizationId);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update gestation' })
  async updateGestation(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body()
    body: {
      stallionName?: string;
      breedingDate?: string;
      expectedDueDate?: string;
      notes?: string;
      status?: string;
    }
  ) {
    return this.gestationService.updateGestation(id, user.organizationId, body);
  }

  @Put(':id/status')
  @ApiOperation({ summary: 'Update gestation status' })
  async updateStatus(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { status: string }
  ) {
    return this.gestationService.updateStatus(id, user.organizationId, body.status);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete gestation' })
  async deleteGestation(@CurrentUser() user: any, @Param('id') id: string) {
    return this.gestationService.deleteGestation(id, user.organizationId);
  }

  // ==================== CHECKUPS ====================

  @Get(':id/checkups')
  @ApiOperation({ summary: 'Get gestation checkups' })
  async getCheckups(@CurrentUser() user: any, @Param('id') id: string) {
    return this.gestationService.getCheckups(id, user.organizationId);
  }

  @Post(':id/checkups')
  @ApiOperation({ summary: 'Add checkup' })
  async addCheckup(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body()
    body: {
      date: string;
      type: string;
      notes?: string;
      vetName?: string;
      results?: any;
    }
  ) {
    return this.gestationService.addCheckup(id, user.organizationId, body);
  }

  // ==================== MILESTONES ====================

  @Get(':id/milestones')
  @ApiOperation({ summary: 'Get gestation milestones' })
  async getMilestones(@CurrentUser() user: any, @Param('id') id: string) {
    return this.gestationService.getMilestones(id, user.organizationId);
  }

  @Post(':id/milestones/:milestoneId/complete')
  @ApiOperation({ summary: 'Complete milestone' })
  async completeMilestone(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Param('milestoneId') milestoneId: string
  ) {
    return this.gestationService.completeMilestone(id, milestoneId, user.organizationId);
  }

  // ==================== NOTES ====================

  @Get(':id/notes')
  @ApiOperation({ summary: 'Get gestation notes' })
  async getNotes(@CurrentUser() user: any, @Param('id') id: string) {
    return this.gestationService.getNotes(id, user.organizationId);
  }

  @Post(':id/notes')
  @ApiOperation({ summary: 'Add note' })
  async addNote(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { content: string }
  ) {
    return this.gestationService.addNote(id, user.organizationId, body);
  }

  // ==================== BIRTH ====================

  @Post(':id/birth')
  @ApiOperation({ summary: 'Record birth' })
  async recordBirth(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body()
    body: {
      birthDate: string;
      foalName?: string;
      foalGender?: string;
      foalColor?: string;
      birthWeight?: number;
      notes?: string;
    }
  ) {
    return this.gestationService.recordBirth(id, user.organizationId, body);
  }

  @Post(':id/loss')
  @ApiOperation({ summary: 'Record pregnancy loss' })
  async recordLoss(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body()
    body: {
      date: string;
      reason?: string;
      notes?: string;
    }
  ) {
    return this.gestationService.recordLoss(id, user.organizationId, body);
  }
}

// ==================== BIRTHS CONTROLLER ====================

@ApiTags('births')
@Controller('births')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class BirthsController {
  constructor(private readonly gestationService: GestationService) {}

  @Get()
  @ApiOperation({ summary: 'Get all births' })
  async getBirths(@CurrentUser() user: any) {
    return this.gestationService.getBirths(user.organizationId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get birth by ID' })
  async getBirth(@CurrentUser() user: any, @Param('id') id: string) {
    return this.gestationService.getBirth(id, user.organizationId);
  }
}

// ==================== BREEDING STATS CONTROLLER ====================

@ApiTags('breeding')
@Controller('breeding')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class BreedingController {
  constructor(private readonly gestationService: GestationService) {}

  @Get('stats')
  @ApiOperation({ summary: 'Get breeding statistics' })
  async getStats(@CurrentUser() user: any) {
    return this.gestationService.getBreedingStats(user.organizationId);
  }
}
