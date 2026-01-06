import {
  Controller,
  Get,
  Post,
  Put,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { HorsesService } from './horses.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { CreateHorseDto } from './dto/create-horse.dto';
import { UpdateHorseDto } from './dto/update-horse.dto';
import { ListHorsesQueryDto } from './dto/list-horses-query.dto';

@ApiTags('horses')
@Controller('horses')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class HorsesController {
  constructor(private readonly horsesService: HorsesService) {}

  @Get()
  @ApiOperation({ summary: 'List horses' })
  async list(@CurrentUser() user: any, @Query() query: ListHorsesQueryDto) {
    return this.horsesService.findAll(user.organizationId, query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get horse by ID' })
  async findOne(@CurrentUser() user: any, @Param('id') id: string) {
    return this.horsesService.findById(id, user.organizationId);
  }

  @Post()
  @ApiOperation({ summary: 'Create a horse' })
  async create(@CurrentUser() user: any, @Body() dto: CreateHorseDto) {
    return this.horsesService.create(user.organizationId, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a horse' })
  async update(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() dto: UpdateHorseDto,
  ) {
    return this.horsesService.update(id, user.organizationId, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a horse' })
  async delete(@CurrentUser() user: any, @Param('id') id: string) {
    return this.horsesService.delete(id, user.organizationId);
  }

  @Post(':id/archive')
  @ApiOperation({ summary: 'Archive a horse' })
  async archive(@CurrentUser() user: any, @Param('id') id: string) {
    return this.horsesService.archive(id, user.organizationId);
  }

  @Post(':id/photo')
  @ApiOperation({ summary: 'Upload horse photo' })
  @UseInterceptors(FileInterceptor('file'))
  async uploadPhoto(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @UploadedFile() file: any,
  ) {
    if (!file) {
      throw new BadRequestException('No file uploaded');
    }
    const horse = await this.horsesService.uploadPhoto(id, user.organizationId, file);
    return { url: horse.photoUrl };
  }

  @Delete(':id/photo')
  @ApiOperation({ summary: 'Delete horse photo' })
  async deletePhoto(@CurrentUser() user: any, @Param('id') id: string) {
    return this.horsesService.deletePhoto(id, user.organizationId);
  }

  // ========== HEALTH RECORDS ==========

  @Get(':id/health')
  @ApiOperation({ summary: 'Get health records for a horse' })
  async getHealthRecords(@CurrentUser() user: any, @Param('id') id: string) {
    return this.horsesService.getHealthRecords(id, user.organizationId);
  }

  @Get(':id/health/summary')
  @ApiOperation({ summary: 'Get health summary for a horse' })
  async getHealthSummary(@CurrentUser() user: any, @Param('id') id: string) {
    return this.horsesService.getHealthSummary(id, user.organizationId);
  }

  @Post(':id/health')
  @ApiOperation({ summary: 'Add health record' })
  async addHealthRecord(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() data: {
      type: string;
      date: string;
      title: string;
      description?: string;
      vetName?: string;
      cost?: number;
      nextDueDate?: string;
    },
  ) {
    return this.horsesService.addHealthRecord(id, user.organizationId, data);
  }

  @Put(':id/health/:recordId')
  @ApiOperation({ summary: 'Update health record' })
  async updateHealthRecord(
    @CurrentUser() user: any,
    @Param('id') horseId: string,
    @Param('recordId') recordId: string,
    @Body() data: any,
  ) {
    return this.horsesService.updateHealthRecord(horseId, recordId, user.organizationId, data);
  }

  @Delete(':id/health/:recordId')
  @ApiOperation({ summary: 'Delete health record' })
  async deleteHealthRecord(
    @CurrentUser() user: any,
    @Param('id') horseId: string,
    @Param('recordId') recordId: string,
  ) {
    return this.horsesService.deleteHealthRecord(horseId, recordId, user.organizationId);
  }

  // ========== WEIGHT & BODY CONDITION ==========

  @Get(':id/weight')
  @ApiOperation({ summary: 'Get weight records' })
  async getWeightRecords(@CurrentUser() user: any, @Param('id') id: string) {
    return this.horsesService.getWeightRecords(id, user.organizationId);
  }

  @Post(':id/weight')
  @ApiOperation({ summary: 'Add weight record' })
  async addWeightRecord(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() data: { weight: number; date: string; notes?: string },
  ) {
    return this.horsesService.addWeightRecord(id, user.organizationId, data);
  }

  @Get(':id/body-condition')
  @ApiOperation({ summary: 'Get body condition records' })
  async getBodyConditionRecords(@CurrentUser() user: any, @Param('id') id: string) {
    return this.horsesService.getBodyConditionRecords(id, user.organizationId);
  }

  @Post(':id/body-condition')
  @ApiOperation({ summary: 'Add body condition record' })
  async addBodyConditionRecord(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() data: { score: number; date: string; notes?: string },
  ) {
    return this.horsesService.addBodyConditionRecord(id, user.organizationId, data);
  }

  // ========== NUTRITION ==========

  @Get(':id/nutrition')
  @ApiOperation({ summary: 'Get nutrition plans' })
  async getNutritionPlans(@CurrentUser() user: any, @Param('id') id: string) {
    return this.horsesService.getNutritionPlans(id, user.organizationId);
  }

  @Get(':id/nutrition/active')
  @ApiOperation({ summary: 'Get active nutrition plan' })
  async getActiveNutritionPlan(@CurrentUser() user: any, @Param('id') id: string) {
    return this.horsesService.getActiveNutritionPlan(id, user.organizationId);
  }

  @Post(':id/nutrition')
  @ApiOperation({ summary: 'Create nutrition plan' })
  async createNutritionPlan(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() data: any,
  ) {
    return this.horsesService.createNutritionPlan(id, user.organizationId, data);
  }

  // ========== GESTATIONS ==========

  @Get(':id/gestations')
  @ApiOperation({ summary: 'Get gestation records' })
  async getGestations(@CurrentUser() user: any, @Param('id') id: string) {
    return this.horsesService.getGestations(id, user.organizationId);
  }

  // ========== EVENTS ==========

  @Get(':id/events')
  @ApiOperation({ summary: 'Get calendar events for horse' })
  async getHorseEvents(@CurrentUser() user: any, @Param('id') id: string) {
    return this.horsesService.getHorseEvents(id, user.organizationId);
  }
}
