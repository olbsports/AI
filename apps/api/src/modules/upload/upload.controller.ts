import {
  Controller,
  Post,
  Get,
  Delete,
  Body,
  Param,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  Query,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiConsumes, ApiBody } from '@nestjs/swagger';

import { UploadService } from './upload.service';
import {
  GetPresignedUrlDto,
  GetMultiplePresignedUrlsDto,
} from './dto/get-presigned-url.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentOrganization } from '../auth/decorators/organization.decorator';

@ApiTags('upload')
@Controller('upload')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class UploadController {
  constructor(private readonly uploadService: UploadService) {}

  @Post('presigned-url')
  @ApiOperation({ summary: 'Get presigned URL for file upload' })
  async getPresignedUrl(
    @CurrentOrganization() organizationId: string,
    @Body() dto: GetPresignedUrlDto,
  ) {
    return this.uploadService.getPresignedUploadUrl(organizationId, dto);
  }

  @Post('presigned-urls')
  @ApiOperation({ summary: 'Get multiple presigned URLs for batch upload' })
  async getMultiplePresignedUrls(
    @CurrentOrganization() organizationId: string,
    @Body() dto: GetMultiplePresignedUrlsDto,
  ) {
    return this.uploadService.getMultiplePresignedUrls(organizationId, dto.files);
  }

  @Get('download/:key(*)')
  @ApiOperation({ summary: 'Get presigned download URL' })
  async getDownloadUrl(@Param('key') key: string) {
    const url = await this.uploadService.getPresignedDownloadUrl(key);
    return { url };
  }

  @Delete(':key(*)')
  @ApiOperation({ summary: 'Delete a file' })
  async deleteFile(@Param('key') key: string) {
    await this.uploadService.deleteFile(key);
    return { message: 'File deleted successfully' };
  }
}
