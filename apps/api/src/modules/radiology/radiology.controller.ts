import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
  UseInterceptors,
  UploadedFiles,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiParam,
  ApiConsumes,
  ApiBody,
} from '@nestjs/swagger';
import { FilesInterceptor } from '@nestjs/platform-express';

import { RadiologyService } from './radiology.service';
import {
  CreateRadiologyDto,
  ValidateRadiologyDto,
  RadiologyQueryDto,
  AnatomicalRegion,
} from './dto/radiology.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { OrganizationGuard } from '../auth/guards/organization.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentOrganization } from '../auth/decorators/organization.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('radiology')
@Controller('radiology')
@UseGuards(JwtAuthGuard, OrganizationGuard)
@ApiBearerAuth()
export class RadiologyController {
  constructor(private readonly radiologyService: RadiologyService) {}

  @Get()
  @ApiOperation({ summary: 'List all radiology analyses' })
  async findAll(
    @CurrentOrganization() organizationId: string,
    @Query() query: RadiologyQueryDto,
  ) {
    return this.radiologyService.findAll(organizationId, query);
  }

  @Post()
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin', 'analyst', 'veterinarian')
  @ApiOperation({ summary: 'Create a new radiology analysis' })
  async create(
    @CurrentOrganization() organizationId: string,
    @CurrentUser('id') userId: string,
    @Body() dto: CreateRadiologyDto,
  ) {
    return this.radiologyService.create(organizationId, userId, dto);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a radiology analysis by ID' })
  @ApiParam({ name: 'id', description: 'Analysis ID' })
  async findOne(
    @CurrentOrganization() organizationId: string,
    @Param('id') id: string,
  ) {
    return this.radiologyService.findOne(organizationId, id);
  }

  @Get(':id/status')
  @ApiOperation({ summary: 'Get real-time analysis status' })
  @ApiParam({ name: 'id', description: 'Analysis ID' })
  async getStatus(
    @CurrentOrganization() organizationId: string,
    @Param('id') id: string,
  ) {
    return this.radiologyService.getStatus(organizationId, id);
  }

  @Post(':id/upload')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin', 'analyst', 'veterinarian')
  @ApiOperation({ summary: 'Upload radiographic images' })
  @ApiParam({ name: 'id', description: 'Analysis ID' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        files: {
          type: 'array',
          items: { type: 'string', format: 'binary' },
        },
        regions: {
          type: 'array',
          items: { type: 'string' },
          description: 'Anatomical regions for each image',
        },
        views: {
          type: 'array',
          items: { type: 'string' },
          description: 'View types for each image (optional)',
        },
      },
    },
  })
  @UseInterceptors(FilesInterceptor('files', 20))
  async uploadImages(
    @CurrentOrganization() organizationId: string,
    @Param('id') id: string,
    @UploadedFiles() files: Express.Multer.File[],
    @Body('regions') regions: string | string[],
    @Body('views') views?: string | string[],
  ) {
    // Parse regions and views
    const regionsArray = Array.isArray(regions) ? regions : [regions];
    const viewsArray = views ? (Array.isArray(views) ? views : [views]) : [];

    const imageInfos = files.map((_, index) => ({
      region: (regionsArray[index] as AnatomicalRegion) || AnatomicalRegion.AUTRE,
      view: viewsArray[index],
    }));

    return this.radiologyService.uploadImages(organizationId, id, files, imageInfos);
  }

  @Post(':id/analyze')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin', 'analyst', 'veterinarian')
  @ApiOperation({ summary: 'Start AI analysis of uploaded images' })
  @ApiParam({ name: 'id', description: 'Analysis ID' })
  async startAnalysis(
    @CurrentOrganization() organizationId: string,
    @Param('id') id: string,
  ) {
    return this.radiologyService.startAnalysis(organizationId, id);
  }

  @Post(':id/validate')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin', 'veterinarian')
  @ApiOperation({ summary: 'Validate analysis by veterinarian' })
  @ApiParam({ name: 'id', description: 'Analysis ID' })
  async validate(
    @CurrentOrganization() organizationId: string,
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
    @Body() dto: ValidateRadiologyDto,
  ) {
    return this.radiologyService.validate(organizationId, id, userId, dto);
  }

  @Get(':id/compare/:otherId')
  @ApiOperation({ summary: 'Compare two radiology analyses' })
  @ApiParam({ name: 'id', description: 'First analysis ID' })
  @ApiParam({ name: 'otherId', description: 'Second analysis ID' })
  async compare(
    @CurrentOrganization() organizationId: string,
    @Param('id') id: string,
    @Param('otherId') otherId: string,
  ) {
    return this.radiologyService.compare(organizationId, id, otherId);
  }

  @Post(':id/report')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin', 'analyst', 'veterinarian')
  @ApiOperation({ summary: 'Generate PDF report' })
  @ApiParam({ name: 'id', description: 'Analysis ID' })
  async generateReport(
    @CurrentOrganization() organizationId: string,
    @Param('id') id: string,
  ) {
    return this.radiologyService.generateReport(organizationId, id);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  @ApiOperation({ summary: 'Delete a radiology analysis' })
  @ApiParam({ name: 'id', description: 'Analysis ID' })
  async delete(
    @CurrentOrganization() organizationId: string,
    @Param('id') id: string,
  ) {
    await this.radiologyService.delete(organizationId, id);
    return { success: true };
  }
}
