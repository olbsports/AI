import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEmail,
  IsIn,
} from 'class-validator';

export class CreateRiderDto {
  @IsString()
  @IsNotEmpty()
  firstName: string;

  @IsString()
  @IsNotEmpty()
  lastName: string;

  @IsEmail()
  @IsOptional()
  email?: string;

  @IsString()
  @IsOptional()
  phone?: string;

  @IsString()
  @IsOptional()
  photoUrl?: string;

  @IsString()
  @IsOptional()
  federationId?: string;

  @IsString()
  @IsOptional()
  federationName?: string;

  @IsString()
  @IsOptional()
  level?: string;

  @IsIn(['cso', 'dressage', 'complet', 'endurance', 'western', 'attelage'])
  @IsOptional()
  discipline?: string;
}
