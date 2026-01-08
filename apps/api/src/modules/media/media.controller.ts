import {
  Controller,
  Post,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  Query,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiConsumes, ApiBody } from '@nestjs/swagger';

import { UploadService } from '../upload/upload.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentOrganization } from '../auth/decorators/organization.decorator';

@ApiTags('media')
@Controller('media')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class MediaController {
  constructor(private readonly uploadService: UploadService) {}

  @Post('upload')
  @UseInterceptors(FileInterceptor('file'))
  @ApiOperation({ summary: 'Upload a media file directly' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          format: 'binary',
        },
        type: {
          type: 'string',
          enum: ['image', 'video'],
          default: 'image',
        },
      },
    },
  })
  async uploadMedia(
    @CurrentOrganization() organizationId: string,
    @UploadedFile() file: Express.Multer.File,
    @Query('type') type: string = 'image',
  ) {
    if (!file) {
      throw new BadRequestException('No file provided');
    }

    // Map type to category
    const category = type === 'video' ? 'media' : 'media';

    const result = await this.uploadService.uploadFile(
      organizationId,
      category,
      file,
    );

    return {
      url: result.url,
      key: result.key,
    };
  }
}
