import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { TrainingContent, TrainingContentDocument } from './schemas/training-content.schema';
import { CreateTrainingContentDto } from './dto/create-training-content.dto';
import { UpdateTrainingContentDto } from './dto/update-training-content.dto';

@Injectable()
export class TrainingService {
  constructor(
    @InjectModel(TrainingContent.name) 
    private trainingContentModel: Model<TrainingContentDocument>,
  ) {}

  async create(createTrainingContentDto: CreateTrainingContentDto, createdBy: string): Promise<TrainingContent> {
    const trainingContent = new this.trainingContentModel({
      ...createTrainingContentDto,
      createdBy,
    });
    return trainingContent.save();
  }

  async findAll(params?: {
    category?: string;
    type?: string;
    isActive?: boolean;
    isFeatured?: boolean;
    page?: number;
    limit?: number;
  }): Promise<{ content: TrainingContent[]; total: number; page: number; totalPages: number }> {
    const {
      category,
      type,
      isActive,
      isFeatured,
      page = 1,
      limit = 20,
    } = params || {};

    const filter: any = {};
    if (category) filter.category = category;
    if (type) filter.type = type;
    if (isActive !== undefined) filter.isActive = isActive;
    if (isFeatured !== undefined) filter.isFeatured = isFeatured;

    const skip = (page - 1) * limit;
    const total = await this.trainingContentModel.countDocuments(filter);
    const content = await this.trainingContentModel
      .find(filter)
      .sort({ order: 1, createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .exec();

    return {
      content,
      total,
      page,
      totalPages: Math.ceil(total / limit),
    };
  }

  async findOne(id: string): Promise<TrainingContent> {
    const trainingContent = await this.trainingContentModel.findById(id).exec();
    if (!trainingContent) {
      throw new NotFoundException('Training content not found');
    }
    return trainingContent;
  }

  async update(id: string, updateTrainingContentDto: UpdateTrainingContentDto): Promise<TrainingContent> {
    const trainingContent = await this.trainingContentModel
      .findByIdAndUpdate(id, updateTrainingContentDto, { new: true })
      .exec();
    if (!trainingContent) {
      throw new NotFoundException('Training content not found');
    }
    return trainingContent;
  }

  async remove(id: string): Promise<void> {
    const result = await this.trainingContentModel.findByIdAndDelete(id).exec();
    if (!result) {
      throw new NotFoundException('Training content not found');
    }
  }

  async getStats(): Promise<{
    totalContent: number;
    videoCount: number;
    imageCount: number;
    storyCount: number;
    activeCount: number;
    featuredCount: number;
  }> {
    const [
      totalContent,
      videoCount,
      imageCount,
      storyCount,
      activeCount,
      featuredCount,
    ] = await Promise.all([
      this.trainingContentModel.countDocuments(),
      this.trainingContentModel.countDocuments({ type: 'video' }),
      this.trainingContentModel.countDocuments({ type: 'image' }),
      this.trainingContentModel.countDocuments({ type: 'story' }),
      this.trainingContentModel.countDocuments({ isActive: true }),
      this.trainingContentModel.countDocuments({ isFeatured: true }),
    ]);

    return {
      totalContent,
      videoCount,
      imageCount,
      storyCount,
      activeCount,
      featuredCount,
    };
  }

  async getCategories(): Promise<{ category: string; count: number }[]> {
    const categories = await this.trainingContentModel.aggregate([
      { $group: { _id: '$category', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
    ]);

    return categories.map(cat => ({
      category: cat._id,
      count: cat.count,
    }));
  }

  async getFeaturedContent(): Promise<TrainingContent[]> {
    return this.trainingContentModel
      .find({ isFeatured: true, isActive: true })
      .sort({ order: 1, createdAt: -1 })
      .exec();
  }

  async getContentByCategory(category: string): Promise<TrainingContent[]> {
    return this.trainingContentModel
      .find({ category, isActive: true })
      .sort({ order: 1, createdAt: -1 })
      .exec();
  }
}
