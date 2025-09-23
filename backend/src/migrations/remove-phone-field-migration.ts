import { connect, disconnect, model, Schema } from 'mongoose';

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji';

// Define the User schema for migration
const UserSchema = new Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  name: String,
  phoneNumber: String, // Keep this field
  phone: String, // This is the field we want to remove
  isPhoneVerified: { type: Boolean, default: false },
  phoneVerificationId: String,
  address: String,
  profilePhoto: String,
  roles: { type: [String], default: ['household'] },
  collectorApplication: {
    status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
    idCardPhoto: String,
    selfieWithIdPhoto: String,
    rejectionReason: String,
    appliedAt: { type: Date, default: Date.now },
    reviewedAt: Date
  },
  isVerified: { type: Boolean, default: false },
  verificationOTP: String,
  otpExpiresAt: Date,
  otpAttempts: { type: Number, default: 0 },
  isProfileComplete: { type: Boolean, default: false },
  location: {
    type: { type: String },
    coordinates: [Number]
  },
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

// Migration to remove the old 'phone' field from user collection
async function removePhoneField() {
  try {
    console.log('🔗 Connecting to MongoDB...');
    const connection = await connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Get the User model from the connection
    const UserModel = model('User', UserSchema);

    // Find all users that have the old 'phone' field
    const usersWithPhoneField = await UserModel.find({ phone: { $exists: true } });
    console.log(`📊 Found ${usersWithPhoneField.length} users with old 'phone' field`);

    let updatedCount = 0;
    let skippedCount = 0;

    for (const user of usersWithPhoneField) {
      try {
        console.log(`🔍 Processing user: ${user.email}`);
        console.log(`   Old phone field value: ${user.phone}`);
        console.log(`   Current phoneNumber field value: ${user.phoneNumber}`);

        // Remove the old 'phone' field using $unset
        await UserModel.updateOne(
          { _id: user._id },
          { $unset: { phone: 1 } }
        );

        updatedCount++;
        console.log(`✅ Removed 'phone' field from user: ${user.email}`);
      } catch (error) {
        console.error(`❌ Error removing 'phone' field from user ${user.email}:`, error);
      }
    }

    // Also check for any users that might have both fields and need data migration
    const usersWithBothFields = await UserModel.find({ 
      phone: { $exists: true }, 
      phoneNumber: { $exists: true } 
    });
    
    console.log(`📊 Found ${usersWithBothFields.length} users with both 'phone' and 'phoneNumber' fields`);

    for (const user of usersWithBothFields) {
      try {
        console.log(`🔍 Processing user with both fields: ${user.email}`);
        console.log(`   Old phone field: ${user.phone}`);
        console.log(`   Current phoneNumber field: ${user.phoneNumber}`);

        // If phoneNumber is empty but phone has data, migrate the data
        if ((!user.phoneNumber || user.phoneNumber.trim() === '') && user.phone && user.phone.trim() !== '') {
          console.log(`   Migrating data from 'phone' to 'phoneNumber' for user: ${user.email}`);
          
          await UserModel.updateOne(
            { _id: user._id },
            { 
              $set: { phoneNumber: user.phone },
              $unset: { phone: 1 }
            }
          );
          
          console.log(`✅ Migrated phone data and removed old field for user: ${user.email}`);
        } else {
          // Just remove the old field
          await UserModel.updateOne(
            { _id: user._id },
            { $unset: { phone: 1 } }
          );
          
          console.log(`✅ Removed old 'phone' field for user: ${user.email}`);
        }
      } catch (error) {
        console.error(`❌ Error processing user with both fields ${user.email}:`, error);
      }
    }

    console.log('\n📈 Migration Summary:');
    console.log(`✅ Updated: ${updatedCount} users`);
    console.log(`⏭️ Skipped: ${skippedCount} users`);
    console.log(`📊 Total processed: ${usersWithPhoneField.length + usersWithBothFields.length} users`);

    // Verify the migration
    const remainingUsersWithPhoneField = await UserModel.find({ phone: { $exists: true } });
    console.log(`🔍 Verification: ${remainingUsersWithPhoneField.length} users still have 'phone' field`);

    if (remainingUsersWithPhoneField.length === 0) {
      console.log('✅ Migration completed successfully! All old "phone" fields have been removed.');
    } else {
      console.log('⚠️ Some users still have the old "phone" field. Manual review may be needed.');
    }

  } catch (error) {
    console.error('❌ Migration failed:', error);
  } finally {
    await disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

// Run the migration
removePhoneField().then(() => {
  console.log('Migration script completed');
  process.exit(0);
}).catch((error) => {
  console.error('Migration script failed:', error);
  process.exit(1);
});
