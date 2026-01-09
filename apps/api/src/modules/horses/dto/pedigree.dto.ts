import { IsString, IsOptional, ValidateNested, IsObject } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';

export class PedigreeAncestorDto {
  @ApiProperty({ required: false, description: 'Nom du cheval' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiProperty({ required: false, description: 'UELN du cheval' })
  @IsOptional()
  @IsString()
  ueln?: string;

  @ApiProperty({ required: false, description: 'Numero SIRE' })
  @IsOptional()
  @IsString()
  sireId?: string;

  @ApiProperty({ required: false, description: 'Studbook (SF, KWPN, BWP, etc.)' })
  @IsOptional()
  @IsString()
  studbook?: string;

  @ApiProperty({ required: false, description: 'Robe' })
  @IsOptional()
  @IsString()
  color?: string;

  @ApiProperty({ required: false, description: 'Annee de naissance' })
  @IsOptional()
  @IsString()
  birthYear?: string;
}

export class PedigreeDto {
  @ApiProperty({ required: false, description: 'Pere (Sire)' })
  @IsOptional()
  @ValidateNested()
  @Type(() => PedigreeAncestorDto)
  sire?: PedigreeAncestorDto;

  @ApiProperty({ required: false, description: 'Mere (Dam)' })
  @IsOptional()
  @ValidateNested()
  @Type(() => PedigreeAncestorDto)
  dam?: PedigreeAncestorDto;

  @ApiProperty({ required: false, description: 'Grand-pere paternel (Sire of Sire)' })
  @IsOptional()
  @ValidateNested()
  @Type(() => PedigreeAncestorDto)
  sireSire?: PedigreeAncestorDto;

  @ApiProperty({ required: false, description: 'Grand-mere paternelle (Dam of Sire)' })
  @IsOptional()
  @ValidateNested()
  @Type(() => PedigreeAncestorDto)
  sireDam?: PedigreeAncestorDto;

  @ApiProperty({ required: false, description: 'Grand-pere maternel (Sire of Dam)' })
  @IsOptional()
  @ValidateNested()
  @Type(() => PedigreeAncestorDto)
  damSire?: PedigreeAncestorDto;

  @ApiProperty({ required: false, description: 'Grand-mere maternelle (Dam of Dam)' })
  @IsOptional()
  @ValidateNested()
  @Type(() => PedigreeAncestorDto)
  damDam?: PedigreeAncestorDto;

  // Generation 3 (Arriere-grands-parents)
  @ApiProperty({ required: false, description: 'Arriere-grand-pere paternel paternel' })
  @IsOptional()
  @ValidateNested()
  @Type(() => PedigreeAncestorDto)
  sireSireSire?: PedigreeAncestorDto;

  @ApiProperty({ required: false, description: 'Arriere-grand-mere paternelle paternelle' })
  @IsOptional()
  @ValidateNested()
  @Type(() => PedigreeAncestorDto)
  sireSireDam?: PedigreeAncestorDto;

  @ApiProperty({ required: false, description: 'Arriere-grand-pere paternel maternel' })
  @IsOptional()
  @ValidateNested()
  @Type(() => PedigreeAncestorDto)
  sireDamSire?: PedigreeAncestorDto;

  @ApiProperty({ required: false, description: 'Arriere-grand-mere paternelle maternelle' })
  @IsOptional()
  @ValidateNested()
  @Type(() => PedigreeAncestorDto)
  sireDamDam?: PedigreeAncestorDto;

  @ApiProperty({ required: false, description: 'Arriere-grand-pere maternel paternel' })
  @IsOptional()
  @ValidateNested()
  @Type(() => PedigreeAncestorDto)
  damSireSire?: PedigreeAncestorDto;

  @ApiProperty({ required: false, description: 'Arriere-grand-mere maternelle paternelle' })
  @IsOptional()
  @ValidateNested()
  @Type(() => PedigreeAncestorDto)
  damSireDam?: PedigreeAncestorDto;

  @ApiProperty({ required: false, description: 'Arriere-grand-pere maternel maternel' })
  @IsOptional()
  @ValidateNested()
  @Type(() => PedigreeAncestorDto)
  damDamSire?: PedigreeAncestorDto;

  @ApiProperty({ required: false, description: 'Arriere-grand-mere maternelle maternelle' })
  @IsOptional()
  @ValidateNested()
  @Type(() => PedigreeAncestorDto)
  damDamDam?: PedigreeAncestorDto;
}

export class UpdatePedigreeDto {
  @ApiProperty({ description: 'Pedigree complet du cheval' })
  @IsObject()
  @ValidateNested()
  @Type(() => PedigreeDto)
  pedigree: PedigreeDto;
}
