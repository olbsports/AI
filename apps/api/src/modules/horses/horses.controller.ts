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
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('No file uploaded');
    }
    return this.horsesService.uploadPhoto(id, user.organizationId, file);
  }

  @Delete(':id/photo')
  @ApiOperation({ summary: 'Delete horse photo' })
  async deletePhoto(@CurrentUser() user: any, @Param('id') id: string) {
    return this.horsesService.deletePhoto(id, user.organizationId);
  }
}
