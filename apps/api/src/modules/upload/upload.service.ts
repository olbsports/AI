import { Injectable, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand,
  HeadObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { v4 as uuidv4 } from 'uuid';
import * as path from 'path';
import * as fs from 'fs';

import { GetPresignedUrlDto } from './dto/get-presigned-url.dto';

export interface PresignedUrlResponse {
  uploadUrl: string;
  fileUrl: string;
  key: string;
  expiresAt: Date;
}

@Injectable()
export class UploadService {
  private readonly s3Client: S3Client | null;
  private readonly bucket: string;
  private readonly cdnUrl: string;
  private readonly region: string;
  private readonly useLocalStorage: boolean;
  private readonly localStoragePath: string;
  private readonly publicUrl: string;

  // Allowed file types by category
  private readonly allowedTypes: Record<string, string[]> = {
    media: [
      'video/mp4',
      'video/quicktime',
      'video/x-msvideo',
      'image/jpeg',
      'image/png',
      'image/webp',
      'image/heic',
      'application/dicom',
    ],
    reports: ['application/pdf', 'text/html'],
    avatars: ['image/jpeg', 'image/png', 'image/webp'],
    documents: [
      'application/pdf',
      'image/jpeg',
      'image/png',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    ],
  };

  // Max file sizes by category (in bytes)
  private readonly maxSizes: Record<string, number> = {
    media: 5 * 1024 * 1024 * 1024, // 5GB for videos
    reports: 50 * 1024 * 1024, // 50MB
    avatars: 5 * 1024 * 1024, // 5MB
    documents: 100 * 1024 * 1024, // 100MB
  };

  constructor(private readonly configService: ConfigService) {
    this.region = this.configService.get('AWS_REGION', 'eu-west-3');
    this.bucket = this.configService.get('S3_BUCKET', '');
    this.cdnUrl = this.configService.get('CDN_URL', '');

    // Local storage configuration
    this.localStoragePath = this.configService.get('LOCAL_STORAGE_PATH', './uploads');
    this.publicUrl = this.configService.get('PUBLIC_URL', 'https://api.horsetempo.app');

    // Use local storage if S3 bucket is not configured
    const awsAccessKey = this.configService.get('AWS_ACCESS_KEY_ID', '');
    this.useLocalStorage = !this.bucket || !awsAccessKey;

    if (this.useLocalStorage) {
      // Ensure local storage directory exists
      this.ensureLocalStorageDir();
      console.log('📁 Using LOCAL file storage at:', this.localStoragePath);
      this.s3Client = null;
    } else {
      console.log('☁️  Using S3 cloud storage, bucket:', this.bucket);
      this.s3Client = new S3Client({
        region: this.region,
        credentials: {
          accessKeyId: this.configService.get('AWS_ACCESS_KEY_ID', ''),
          secretAccessKey: this.configService.get('AWS_SECRET_ACCESS_KEY', ''),
        },
        // For local development with MinIO
        ...(this.configService.get('S3_ENDPOINT') && {
          endpoint: this.configService.get('S3_ENDPOINT'),
          forcePathStyle: true,
        }),
      });
    }
  }

  private ensureLocalStorageDir() {
    const dirs = ['', 'avatars', 'media', 'reports', 'documents'];
    for (const dir of dirs) {
      const fullPath = path.join(this.localStoragePath, dir);
      if (!fs.existsSync(fullPath)) {
        fs.mkdirSync(fullPath, { recursive: true });
      }
    }
  }

  async getPresignedUploadUrl(
    organizationId: string,
    dto: GetPresignedUrlDto,
  ): Promise<PresignedUrlResponse> {
    // Validate content type
    const allowedTypes = this.allowedTypes[dto.category];
    if (!allowedTypes?.includes(dto.contentType)) {
      throw new BadRequestException(
        `Invalid content type for category ${dto.category}`,
      );
    }

    // Validate file size
    const maxSize = this.maxSizes[dto.category];
    if (dto.fileSize && dto.fileSize > maxSize) {
      throw new BadRequestException(
        `File size exceeds maximum of ${maxSize / (1024 * 1024)}MB for ${dto.category}`,
      );
    }

    // Generate unique key
    const ext = path.extname(dto.filename);
    const fileId = uuidv4();
    const key = `${organizationId}/${dto.category}/${fileId}${ext}`;

    if (this.useLocalStorage) {
      // For local storage, return a direct upload URL
      const fileUrl = `${this.publicUrl}/uploads/${key}`;
      return {
        uploadUrl: `${this.publicUrl}/api/upload/direct`, // Direct upload endpoint
        fileUrl,
        key,
        expiresAt: new Date(Date.now() + 3600 * 1000),
      };
    }

    // Create presigned URL for S3 upload
    const command = new PutObjectCommand({
      Bucket: this.bucket,
      Key: key,
      ContentType: dto.contentType,
      Metadata: {
        'original-filename': dto.filename,
        'organization-id': organizationId,
        category: dto.category,
      },
    });

    const expiresIn = 3600; // 1 hour
    const uploadUrl = await getSignedUrl(this.s3Client!, command, { expiresIn });

    // Generate file URL (CDN or S3)
    const fileUrl = this.cdnUrl
      ? `${this.cdnUrl}/${key}`
      : `https://${this.bucket}.s3.${this.region}.amazonaws.com/${key}`;

    return {
      uploadUrl,
      fileUrl,
      key,
      expiresAt: new Date(Date.now() + expiresIn * 1000),
    };
  }

  async getPresignedDownloadUrl(key: string): Promise<string> {
    if (this.useLocalStorage) {
      return `${this.publicUrl}/uploads/${key}`;
    }

    const command = new GetObjectCommand({
      Bucket: this.bucket,
      Key: key,
    });

    const expiresIn = 3600; // 1 hour
    return getSignedUrl(this.s3Client!, command, { expiresIn });
  }

  async deleteFile(key: string): Promise<void> {
    if (this.useLocalStorage) {
      const filePath = path.join(this.localStoragePath, key);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
      return;
    }

    const command = new DeleteObjectCommand({
      Bucket: this.bucket,
      Key: key,
    });

    await this.s3Client!.send(command);
  }

  async fileExists(key: string): Promise<boolean> {
    if (this.useLocalStorage) {
      const filePath = path.join(this.localStoragePath, key);
      return fs.existsSync(filePath);
    }

    try {
      const command = new HeadObjectCommand({
        Bucket: this.bucket,
        Key: key,
      });
      await this.s3Client!.send(command);
      return true;
    } catch {
      return false;
    }
  }

  async getMultiplePresignedUrls(
    organizationId: string,
    files: GetPresignedUrlDto[],
  ): Promise<PresignedUrlResponse[]> {
    return Promise.all(
      files.map((file) => this.getPresignedUploadUrl(organizationId, file)),
    );
  }

  /**
   * Generate a presigned URL for report PDF/HTML
   */
  async getReportUrl(key: string, expiresIn = 86400): Promise<string> {
    if (this.useLocalStorage) {
      return `${this.publicUrl}/uploads/${key}`;
    }

    // For CDN URLs, return directly
    if (this.cdnUrl && !key.includes('private')) {
      return `${this.cdnUrl}/${key}`;
    }

    const command = new GetObjectCommand({
      Bucket: this.bucket,
      Key: key,
    });

    return getSignedUrl(this.s3Client!, command, { expiresIn });
  }

  /**
   * Upload a file directly (from multipart form data)
   */
  async uploadFile(
    organizationId: string,
    category: string,
    file: any,
  ): Promise<{ url: string; key: string }> {
    // Validate content type
    const allowedTypes = this.allowedTypes[category];
    if (allowedTypes && !allowedTypes.includes(file.mimetype)) {
      throw new BadRequestException(
        `Invalid content type ${file.mimetype} for category ${category}`,
      );
    }

    // Validate file size
    const maxSize = this.maxSizes[category];
    if (maxSize && file.size > maxSize) {
      throw new BadRequestException(
        `File size exceeds maximum of ${maxSize / (1024 * 1024)}MB for ${category}`,
      );
    }

    // Generate unique key
    const ext = path.extname(file.originalname);
    const fileId = uuidv4();
    const key = `${organizationId}/${category}/${fileId}${ext}`;

    if (this.useLocalStorage) {
      // Save file to local storage
      const filePath = path.join(this.localStoragePath, key);
      const dirPath = path.dirname(filePath);

      // Ensure directory exists
      if (!fs.existsSync(dirPath)) {
        fs.mkdirSync(dirPath, { recursive: true });
      }

      // Write file
      fs.writeFileSync(filePath, file.buffer);

      const url = `${this.publicUrl}/uploads/${key}`;
      return { url, key };
    }

    // Upload to S3
    const command = new PutObjectCommand({
      Bucket: this.bucket,
      Key: key,
      Body: file.buffer,
      ContentType: file.mimetype,
      Metadata: {
        'original-filename': file.originalname,
        'organization-id': organizationId,
        category: category,
      },
    });

    await this.s3Client!.send(command);

    // Generate file URL
    const url = this.cdnUrl
      ? `${this.cdnUrl}/${key}`
      : `https://${this.bucket}.s3.${this.region}.amazonaws.com/${key}`;

    return { url, key };
  }
}
