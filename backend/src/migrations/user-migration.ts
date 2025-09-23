import { connect, disconnect, model, Schema } from 'mongoose';

// Use the same MongoDB URI as your backend
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/bottleji';

// Define the User schema for migration
const UserSchema = new Schema({
  name: String,
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['household', 'collector', 'admin'] },
  roles: { type: [String], enum: ['household', 'collector', 'admin'], default: ['household'] },
  collectorSubscriptionType: { type: String, enum: ['free', 'pro'], default: 'free' },
  collectorApplication: {
    status: { type: String, enum: ['not_applied', 'pending', 'approved', 'rejected'], default: 'not_applied' },
    idCardPhoto: String,
    selfieWithIdPhoto: String,
    rejectionReason: String,
    appliedAt: Date,
    reviewedAt: Date
  },
  isVerified: { type: Boolean, default: false },
  verificationOTP: String,
  otpExpiresAt: Date,
  otpAttempts: { type: Number, default: 0 },
  isProfileComplete: { type: Boolean, default: false },
  phoneNumber: String,
  address: String,
  location: {
    type: { type: String },
    coordinates: [Number]
  },
  profilePhoto: String,
  otp: String,
  otpExpiry: Date,
  resetPasswordOtp: String,
  resetPasswordOtpExpiry: Date,
  warningCount: { type: Number, default: 0 },
  isAccountLocked: { type: Boolean, default: false },
  accountLockedUntil: Date,
  warnings: [{
    type: String,
    reason: String,
    timestamp: Date,
    dropId: String
  }]
}, { timestamps: true });

// Migration to update user collection
async function migrateUsers() {
  try {
    console.log('🔗 Connecting to MongoDB...');
    const connection = await connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Get the User model from the connection
    const UserModel = model('User', UserSchema);

    // Get all users
    const users = await UserModel.find({});
    console.log(`📊 Found ${users.length} users to migrate`);

    let updatedCount = 0;
    let skippedCount = 0;

    for (const user of users) {
      try {
        const updates: any = {};

        // Only add collector application if not exists
        if (!user.collectorApplication) {
          updates.collectorApplication = {
            status: 'not_applied',
            idCardPhoto: null,
            selfieWithIdPhoto: null,
            rejectionReason: null,
            appliedAt: null,
            reviewedAt: null
          };
          console.log(`📝 Adding collector application for user: ${user.email}`);
        }

        // Ensure collector subscription type exists
        if (!user.collectorSubscriptionType) {
          updates.collectorSubscriptionType = 'free';
          console.log(`💳 Setting default subscription type 'free' for user: ${user.email}`);
        }

        // Apply updates if any
        if (Object.keys(updates).length > 0) {
          await UserModel.updateOne(
            { _id: user._id },
            { $set: updates }
          );
          updatedCount++;
          console.log(`✅ Updated user: ${user.email}`);
        } else {
          skippedCount++;
          console.log(`⏭️ Skipped user (no changes needed): ${user.email}`);
        }

      } catch (error) {
        console.error(`❌ Error updating user ${user.email}:`, error);
      }
    }

    console.log('\n📈 Migration Summary:');
    console.log(`✅ Updated: ${updatedCount} users`);
    console.log(`⏭️ Skipped: ${skippedCount} users`);
    console.log(`📊 Total processed: ${users.length} users`);

  } catch (error) {
    console.error('❌ Migration failed:', error);
  } finally {
    await disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

// Run migration if this file is executed directly
if (require.main === module) {
  migrateUsers()
    .then(() => {
      console.log('🎉 Migration completed successfully!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Migration failed:', error);
      process.exit(1);
    });
}

export { migrateUsers }; 