import { Injectable, Inject, forwardRef } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { EarningsSession, EarningsSessionDocument } from './schemas/earnings-session.schema';
import { CollectionAttempt } from '../dropoffs/schemas/collection-attempt.schema';

@Injectable()
export class EarningsSessionService {
  constructor(
    @InjectModel(EarningsSession.name) private earningsSessionModel: Model<EarningsSessionDocument>,
    @InjectModel(CollectionAttempt.name) private collectionAttemptModel: Model<CollectionAttempt>,
  ) {}

  /**
   * Get or create an earnings session for a user on a specific date
   */
  async getOrCreateSession(userId: string, date: Date = new Date()): Promise<EarningsSessionDocument> {
    // Use UTC to ensure consistent date comparison regardless of server timezone
    const sessionDate = new Date(Date.UTC(
      date.getUTCFullYear(),
      date.getUTCMonth(),
      date.getUTCDate(),
      0, 0, 0, 0
    )); // Start of day in UTC

    let session = await this.earningsSessionModel.findOne({
      userId: new Types.ObjectId(userId),
      date: sessionDate,
    }).exec();

    if (!session) {
      session = new this.earningsSessionModel({
        userId: new Types.ObjectId(userId),
        date: sessionDate,
        sessionEarnings: 0,
        collectionCount: 0,
        collectionAttemptIds: [],
        startTime: new Date(),
        lastCollectionTime: new Date(),
        isActive: true,
      });
      await session.save();
    }

    return session;
  }

  /**
   * Add a collection attempt to a session and update earnings
   */
  async addCollectionToSession(
    userId: string,
    attemptId: string,
    earnings: number,
    collectionTime: Date = new Date(),
  ): Promise<EarningsSessionDocument> {
    // Use UTC to ensure consistent date comparison regardless of server timezone
    const sessionDate = new Date(Date.UTC(
      collectionTime.getUTCFullYear(),
      collectionTime.getUTCMonth(),
      collectionTime.getUTCDate(),
      0, 0, 0, 0
    ));

    const session = await this.getOrCreateSession(userId, sessionDate);

    // Check if attempt is already in session
    const attemptObjectId = new Types.ObjectId(attemptId);
    if (session.collectionAttemptIds.some(id => id.equals(attemptObjectId))) {
      console.log(`⚠️ Attempt ${attemptId} already in session ${session._id}`);
      return session;
    }

    // Update session
    session.collectionAttemptIds.push(attemptObjectId);
    session.sessionEarnings += earnings;
    session.collectionCount += 1;
    session.lastCollectionTime = collectionTime;

    // Update isActive: true if last collection was within 3 hours
    const threeHoursAgo = new Date(Date.now() - 3 * 60 * 60 * 1000);
    session.isActive = collectionTime >= threeHoursAgo;

    // Update startTime if this is the first collection
    if (session.collectionCount === 1) {
      session.startTime = collectionTime;
    }

    await session.save();
    console.log(`✅ Updated session ${session._id} for user ${userId}: +${earnings} TND`);

    return session;
  }

  /**
   * Get active session for a user (last collection within 3 hours)
   */
  async getActiveSession(userId: string): Promise<EarningsSessionDocument | null> {
    const threeHoursAgo = new Date(Date.now() - 3 * 60 * 60 * 1000);

    const session = await this.earningsSessionModel.findOne({
      userId: new Types.ObjectId(userId),
      isActive: true,
      lastCollectionTime: { $gte: threeHoursAgo },
    }).sort({ lastCollectionTime: -1 }).exec();

    return session;
  }

  /**
   * Get today's session for a user
   */
  async getTodaySession(userId: string): Promise<EarningsSessionDocument | null> {
    // Use UTC to ensure consistent date comparison regardless of server timezone
    const now = new Date();
    const today = new Date(Date.UTC(
      now.getUTCFullYear(),
      now.getUTCMonth(),
      now.getUTCDate(),
      0, 0, 0, 0
    ));

    const session = await this.earningsSessionModel.findOne({
      userId: new Types.ObjectId(userId),
      date: today,
    }).exec();

    return session;
  }

  /**
   * Get earnings history for a user
   */
  async getEarningsHistory(
    userId: string,
    page: number = 1,
    limit: number = 20,
  ): Promise<{ sessions: EarningsSessionDocument[]; total: number }> {
    const skip = (page - 1) * limit;

    const [sessions, total] = await Promise.all([
      this.earningsSessionModel
        .find({ userId: new Types.ObjectId(userId) })
        .sort({ date: -1 })
        .skip(skip)
        .limit(limit)
        .exec(),
      this.earningsSessionModel.countDocuments({ userId: new Types.ObjectId(userId) }),
    ]);

    return { sessions, total };
  }

  /**
   * Update session activity status (called by background job)
   */
  async updateSessionActivity(): Promise<void> {
    const threeHoursAgo = new Date(Date.now() - 3 * 60 * 60 * 1000);

    // Mark sessions as inactive if last collection was more than 3 hours ago
    await this.earningsSessionModel.updateMany(
      {
        isActive: true,
        lastCollectionTime: { $lt: threeHoursAgo },
      },
      {
        isActive: false,
      },
    ).exec();

    console.log(`✅ Updated session activity status`);
  }

  /**
   * Get total earnings for a user across all sessions
   */
  async getTotalEarnings(userId: string): Promise<number> {
    const result = await this.earningsSessionModel.aggregate([
      { $match: { userId: new Types.ObjectId(userId) } },
      { $group: { _id: null, total: { $sum: '$sessionEarnings' } } },
    ]).exec();

    return result.length > 0 ? result[0].total : 0;
  }
}

