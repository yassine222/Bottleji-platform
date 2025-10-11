import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { TrainingService } from './training.service';
import { CreateTrainingContentDto } from './dto/create-training-content.dto';
import { UpdateTrainingContentDto } from './dto/update-training-content.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

@Controller('training')
export class TrainingController {
  constructor(private readonly trainingService: TrainingService) {}

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin' as any, 'admin' as any, 'moderator' as any)
  async create(@Body() createTrainingContentDto: CreateTrainingContentDto, @Request() req) {
    return this.trainingService.create(createTrainingContentDto, req.user.id);
  }

  @Get()
  async findAll(
    @Query('category') category?: string,
    @Query('type') type?: string,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ) {
    return this.trainingService.findAll({
      category,
      type,
      page,
      limit,
    });
  }

  @Get('stats')
  async getStats() {
    return this.trainingService.getStats();
  }

  @Get('categories')
  async getCategories() {
    return this.trainingService.getCategories();
  }

  @Get('featured')
  async getFeaturedContent() {
    return this.trainingService.getFeaturedContent();
  }

  @Get('category/:category')
  async getContentByCategory(@Param('category') category: string) {
    return this.trainingService.getContentByCategory(category);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.trainingService.findOne(id);
  }

  @Post(':id/view')
  async incrementView(@Param('id') id: string) {
    return this.trainingService.incrementViewCount(id);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin' as any, 'admin' as any, 'moderator' as any)
  async update(@Param('id') id: string, @Body() updateTrainingContentDto: UpdateTrainingContentDto) {
    return this.trainingService.update(id, updateTrainingContentDto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin' as any, 'admin' as any)
  async remove(@Param('id') id: string) {
    await this.trainingService.remove(id);
    return { message: 'Training content deleted successfully' };
  }
}
