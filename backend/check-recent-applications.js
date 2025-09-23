const mongoose = require('mongoose');
require('dotenv').config();

async function checkRecentApplications() {
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

    // Check for applications in the last 6 hours
    console.log('\n🔍 Checking applications from the last 6 hours...');
    const sixHoursAgo = new Date(Date.now() - 6 * 60 * 60 * 1000);
    const recentApplications = await CollectorApplication.find({
      createdAt: { $gte: sixHoursAgo }
    }).populate('userId', 'email name').sort({ createdAt: -1 });

    console.log(`Found ${recentApplications.length} applications in the last 6 hours:`);
    
    recentApplications.forEach((app, index) => {
      console.log(`${index + 1}. Application ID: ${app._id}`);
      console.log(`   User: ${app.userId?.email || 'Unknown'}`);
      console.log(`   Created At: ${app.createdAt}`);
      console.log(`   Applied At: ${app.appliedAt}`);
      console.log(`   Status: ${app.status}`);
      console.log(`   ID Card Type: ${app.idCardType}`);
      console.log(`   ID Card Number: ${app.idCardNumber}`);
      console.log('   ---');
    });

    // Check for applications in the last 24 hours
    console.log('\n🔍 Checking applications from the last 24 hours...');
    const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const dayApplications = await CollectorApplication.find({
      createdAt: { $gte: oneDayAgo }
    }).populate('userId', 'email name').sort({ createdAt: -1 });

    console.log(`Found ${dayApplications.length} applications in the last 24 hours:`);
    
    dayApplications.forEach((app, index) => {
      console.log(`${index + 1}. Application ID: ${app._id}`);
      console.log(`   User: ${app.userId?.email || 'Unknown'}`);
      console.log(`   Created At: ${app.createdAt}`);
      console.log(`   Status: ${app.status}`);
      console.log('   ---');
    });

    // Check for pending applications
    console.log('\n🔍 Checking all pending applications...');
    const pendingApplications = await CollectorApplication.find({
      status: 'pending'
    }).populate('userId', 'email name').sort({ createdAt: -1 });

    console.log(`Found ${pendingApplications.length} pending applications:`);
    
    pendingApplications.forEach((app, index) => {
      console.log(`${index + 1}. Application ID: ${app._id}`);
      console.log(`   User: ${app.userId?.email || 'Unknown'}`);
      console.log(`   Created At: ${app.createdAt}`);
      console.log(`   ID Card Type: ${app.idCardType}`);
      console.log(`   ID Card Number: ${app.idCardNumber}`);
      console.log('   ---');
    });

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('✅ Disconnected from MongoDB');
  }
}

checkRecentApplications();
