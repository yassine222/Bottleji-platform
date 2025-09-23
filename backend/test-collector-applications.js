const mongoose = require('mongoose');
require('dotenv').config();

async function testCollectorApplications() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Get the CollectorApplication model
    const CollectorApplication = mongoose.model('CollectorApplication', new mongoose.Schema({
      userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
      status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
      idCardPhoto: { type: String, required: true },
      selfieWithIdPhoto: { type: String, required: true },
      idCardNumber: String,
      idCardType: String,
      idCardExpiryDate: Date,
      idCardIssuingAuthority: String,
      passportIssueDate: Date,
      passportExpiryDate: Date,
      passportMainPagePhoto: String,
      idCardBackPhoto: String,
      rejectionReason: String,
      appliedAt: { type: Date, default: Date.now },
      reviewedAt: Date,
      reviewedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
      reviewNotes: String,
      createdAt: { type: Date, default: Date.now },
      updatedAt: { type: Date, default: Date.now }
    }));

    // Get the User model
    const User = mongoose.model('User', new mongoose.Schema({
      email: { type: String, required: true, unique: true },
      password: { type: String, required: true },
      name: String,
      phoneNumber: String,
      isPhoneVerified: { type: Boolean, default: false },
      phoneVerificationId: String,
      address: String,
      profilePhoto: String,
      roles: { type: [String], enum: ['household', 'collector', 'support_agent', 'moderator', 'admin', 'super_admin'], default: ['household'] },
      collectorApplicationStatus: { type: String, enum: ['pending', 'approved', 'rejected'] },
      collectorApplicationId: String,
      collectorApplicationAppliedAt: Date,
      collectorApplicationRejectionReason: String,
      collectorSubscriptionType: { type: String, enum: ['basic', 'premium'], default: 'basic' },
      isProfileComplete: { type: Boolean, default: false },
      verificationOTP: String,
      otpExpiresAt: Date,
      otpAttempts: { type: Number, default: 0 },
      isAccountLocked: { type: Boolean, default: false },
      warningCount: { type: Number, default: 0 },
      deletedAt: Date,
      deletedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
      isDeleted: { type: Boolean, default: false },
      sessionInvalidated: { type: Boolean, default: false },
      createdAt: { type: Date, default: Date.now },
      updatedAt: { type: Date, default: Date.now }
    }));

    // Check all collector applications
    console.log('\n🔍 Checking all collector applications...');
    const applications = await CollectorApplication.find().populate('userId', 'email name');
    console.log(`Found ${applications.length} collector applications:`);
    
    applications.forEach((app, index) => {
      console.log(`${index + 1}. Application ID: ${app._id}`);
      console.log(`   User: ${app.userId?.email || 'Unknown'} (${app.userId?._id || 'Unknown'})`);
      console.log(`   Status: ${app.status}`);
      console.log(`   Applied At: ${app.appliedAt}`);
      console.log(`   ID Card Type: ${app.idCardType}`);
      console.log(`   ID Card Number: ${app.idCardNumber}`);
      console.log('   ---');
    });

    // Check users with collector application fields
    console.log('\n🔍 Checking users with collector application fields...');
    const usersWithApplications = await User.find({
      $or: [
        { collectorApplicationStatus: { $exists: true } },
        { collectorApplicationId: { $exists: true } },
        { collectorApplicationAppliedAt: { $exists: true } }
      ]
    }).select('email collectorApplicationStatus collectorApplicationId collectorApplicationAppliedAt collectorApplicationRejectionReason');

    console.log(`Found ${usersWithApplications.length} users with collector application fields:`);
    
    usersWithApplications.forEach((user, index) => {
      console.log(`${index + 1}. User: ${user.email}`);
      console.log(`   collectorApplicationStatus: ${user.collectorApplicationStatus || 'Not set'}`);
      console.log(`   collectorApplicationId: ${user.collectorApplicationId || 'Not set'}`);
      console.log(`   collectorApplicationAppliedAt: ${user.collectorApplicationAppliedAt || 'Not set'}`);
      console.log(`   collectorApplicationRejectionReason: ${user.collectorApplicationRejectionReason || 'Not set'}`);
      console.log('   ---');
    });

    // Check for any recent applications (last 24 hours)
    console.log('\n🔍 Checking recent applications (last 24 hours)...');
    const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const recentApplications = await CollectorApplication.find({
      createdAt: { $gte: oneDayAgo }
    }).populate('userId', 'email name');

    console.log(`Found ${recentApplications.length} recent applications:`);
    
    recentApplications.forEach((app, index) => {
      console.log(`${index + 1}. Application ID: ${app._id}`);
      console.log(`   User: ${app.userId?.email || 'Unknown'}`);
      console.log(`   Created At: ${app.createdAt}`);
      console.log(`   Status: ${app.status}`);
      console.log('   ---');
    });

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('✅ Disconnected from MongoDB');
  }
}

testCollectorApplications();
