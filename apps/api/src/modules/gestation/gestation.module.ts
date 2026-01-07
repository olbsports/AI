import { Module } from '@nestjs/common';
import { GestationController, BirthsController, BreedingController } from './gestation.controller';
import { GestationService } from './gestation.service';

@Module({
  controllers: [GestationController, BirthsController, BreedingController],
  providers: [GestationService],
  exports: [GestationService],
})
export class GestationModule {}
