import { IsEmail, IsNotEmpty, IsIn, IsOptional } from 'class-validator';

export class CreateInvitationDto {
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @IsIn(['admin', 'veterinarian', 'analyst', 'viewer'])
  @IsOptional()
  role?: string = 'viewer';
}
