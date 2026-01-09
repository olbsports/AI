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
import { UpdatePedigreeDto } from './dto/pedigree.dto';
import { CreatePerformanceDto, UpdatePerformanceDto } from './dto/performance.dto';
import { CreateBodyConditionDto, UpdateBodyConditionDto } from './dto/body-condition.dto';

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
  @ApiOperation({ summary: 'Get body condition scores with history and statistics' })
  async getBodyConditionScores(@CurrentUser() user: any, @Param('id') id: string) {
    return this.horsesService.getBodyConditionScores(id, user.organizationId);
  }

  @Post(':id/body-condition')
  @ApiOperation({ summary: 'Add body condition score' })
  async createBodyConditionScore(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() data: CreateBodyConditionDto,
  ) {
    return this.horsesService.createBodyConditionScore(id, user.organizationId, data);
  }

  @Patch(':id/body-condition/:scoreId')
  @ApiOperation({ summary: 'Update body condition score' })
  async updateBodyConditionScore(
    @CurrentUser() user: any,
    @Param('id') horseId: string,
    @Param('scoreId') scoreId: string,
    @Body() data: UpdateBodyConditionDto,
  ) {
    return this.horsesService.updateBodyConditionScore(horseId, scoreId, user.organizationId, data);
  }

  @Delete(':id/body-condition/:scoreId')
  @ApiOperation({ summary: 'Delete body condition score' })
  async deleteBodyConditionScore(
    @CurrentUser() user: any,
    @Param('id') horseId: string,
    @Param('scoreId') scoreId: string,
  ) {
    return this.horsesService.deleteBodyConditionScore(horseId, scoreId, user.organizationId);
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

  // ========== PEDIGREE / GENEALOGY ==========

  @Get(':id/pedigree')
  @ApiOperation({ summary: 'Get pedigree tree (4 generations)' })
  async getPedigree(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Query('generations') generations?: number,
  ) {
    return this.horsesService.getPedigree(id, user.organizationId, generations ?? 4);
  }

  @Patch(':id/pedigree')
  @ApiOperation({ summary: 'Update pedigree information' })
  async updatePedigree(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() data: UpdatePedigreeDto,
  ) {
    return this.horsesService.updatePedigree(id, user.organizationId, data.pedigree);
  }

  @Get(':id/offspring')
  @ApiOperation({ summary: 'Get offspring (progeny) of a horse' })
  async getOffspring(@CurrentUser() user: any, @Param('id') id: string) {
    return this.horsesService.getOffspring(id, user.organizationId);
  }

  // ========== PERFORMANCE TRACKING ==========

  @Get(':id/performances')
  @ApiOperation({ summary: 'Get performance records' })
  async getPerformances(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Query('discipline') discipline?: string,
    @Query('level') level?: string,
    @Query('year') year?: number,
    @Query('page') page?: number,
    @Query('pageSize') pageSize?: number,
  ) {
    return this.horsesService.getPerformances(id, user.organizationId, {
      discipline,
      level,
      year: year ? Number(year) : undefined,
      page: page ? Number(page) : undefined,
      pageSize: pageSize ? Number(pageSize) : undefined,
    });
  }

  @Post(':id/performances')
  @ApiOperation({ summary: 'Add performance record' })
  async createPerformance(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() data: CreatePerformanceDto,
  ) {
    return this.horsesService.createPerformance(id, user.organizationId, data);
  }

  @Patch(':id/performances/:performanceId')
  @ApiOperation({ summary: 'Update performance record' })
  async updatePerformance(
    @CurrentUser() user: any,
    @Param('id') horseId: string,
    @Param('performanceId') performanceId: string,
    @Body() data: UpdatePerformanceDto,
  ) {
    return this.horsesService.updatePerformance(horseId, performanceId, user.organizationId, data);
  }

  @Delete(':id/performances/:performanceId')
  @ApiOperation({ summary: 'Delete performance record' })
  async deletePerformance(
    @CurrentUser() user: any,
    @Param('id') horseId: string,
    @Param('performanceId') performanceId: string,
  ) {
    return this.horsesService.deletePerformance(horseId, performanceId, user.organizationId);
  }

  @Get(':id/performances/stats')
  @ApiOperation({ summary: 'Get performance statistics' })
  async getPerformanceStats(@CurrentUser() user: any, @Param('id') id: string) {
    return this.horsesService.getPerformanceStats(id, user.organizationId);
  }
}
