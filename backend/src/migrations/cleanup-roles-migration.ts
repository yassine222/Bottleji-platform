import { connect, disconnect, model, Schema } from 'mongoose';

// Use the same MongoDB URI as your backend
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/bottleji';

// Define the User schema for migration
const UserSchema = new Schema({
  name: String,
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['household', 'collector', 'admin'] },
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

// Migration to clean up roles array and ensure only role field exists
async function cleanupRoles() {
  try {
    console.log('🔗 Connecting to MongoDB...');
    const connection = await connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Get the User model from the connection
    const UserModel = model('User', UserSchema);

    // Get all users
    const users = await UserModel.find({});
    console.log(`📊 Found ${users.length} users to clean up`);

    let updatedCount = 0;
    let skippedCount = 0;

    for (const user of users) {
      try {
        const updates: any = {};
        const userDoc = user.toObject() as any; // Use any type to access all fields

        // 1. Remove roles array if it exists
        if (userDoc.roles) {
          updates.$unset = { roles: 1 };
          console.log(`🗑️ Removing roles array for user: ${user.email}`);
        }

        // 2. Ensure role field exists and is correct
        if (!userDoc.role && userDoc.roles && userDoc.roles.length > 0) {
          updates.role = userDoc.roles[0]; // Use first role from array
          console.log(`🔄 Converting roles array to role field for user: ${user.email}`);
        }

        // 3. Set default role if none exists
        if (!userDoc.role) {
          updates.role = 'household';
          console.log(`🏠 Setting default role 'household' for user: ${user.email}`);
        }

        // Apply updates if any
        if (Object.keys(updates).length > 0) {
          if (updates.$unset) {
            // Remove roles array
            await UserModel.updateOne(
              { _id: user._id },
              updates
            );
          }
          
          // Update role field
          if (updates.role) {
            await UserModel.updateOne(
              { _id: user._id },
              { $set: { role: updates.role } }
            );
          }
          
          updatedCount++;
          console.log(`✅ Cleaned up user: ${user.email}`);
        } else {
          skippedCount++;
          console.log(`⏭️ Skipped user (no cleanup needed): ${user.email}`);
        }

      } catch (error) {
        console.error(`❌ Error cleaning up user ${user.email}:`, error);
      }
    }

    console.log('\n📈 Cleanup Summary:');
    console.log(`✅ Updated: ${updatedCount} users`);
    console.log(`⏭️ Skipped: ${skippedCount} users`);
    console.log(`📊 Total processed: ${users.length} users`);

  } catch (error) {
    console.error('❌ Cleanup failed:', error);
  } finally {
    await disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

// Run cleanup if this file is executed directly
if (require.main === module) {
  cleanupRoles()
    .then(() => {
      console.log('🎉 Cleanup completed successfully!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Cleanup failed:', error);
      process.exit(1);
    });
}

export { cleanupRoles }; 