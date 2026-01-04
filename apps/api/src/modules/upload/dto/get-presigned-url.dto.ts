import {
  IsNotEmpty,
  IsString,
  IsIn,
  IsOptional,
  IsNumber,
  Max,
  Min,
} from 'class-validator';

export class GetPresignedUrlDto {
  @IsString()
  @IsNotEmpty()
  filename: string;

  @IsString()
  @IsNotEmpty()
  contentType: string;

  @IsIn(['media', 'reports', 'avatars', 'documents'])
  category: 'media' | 'reports' | 'avatars' | 'documents';

  @IsNumber()
  @Min(1)
  @Max(5 * 1024 * 1024 * 1024) // 5GB max
  @IsOptional()
  fileSize?: number;
}

export class GetMultiplePresignedUrlsDto {
  files: GetPresignedUrlDto[];
}
