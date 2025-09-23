require('dotenv').config();
const { connect, model, Schema } = require('mongoose');

async function checkUserStatus() {
  try {
    console.log('🔗 Connecting to MongoDB...');
    const connection = await connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const UserSchema = new Schema({}, { strict: false });
    const CollectorApplicationSchema = new Schema({}, { strict: false });
    
    const User = model('User', UserSchema);
    const CollectorApplication = model('CollectorApplication', CollectorApplicationSchema);
    
    // Check specific user
    const userEmail = 'yassineromd789@gmail.com';
    const user = await User.findOne({ email: userEmail });
    
    if (!user) {
      console.log('❌ User not found');
      return;
    }
    
    const userDoc = user.toObject();
    console.log('\n👤 User Information:');
    console.log(`Email: ${userDoc.email}`);
    console.log(`Name: ${userDoc.name || 'Not set'}`);
    console.log(`Roles: ${userDoc.roles.join(', ')}`);
    console.log(`Is Collector: ${userDoc.roles.includes('collector')}`);
    console.log(`Application Status: ${userDoc.collectorApplicationStatus || 'null'}`);
    console.log(`Application ID: ${userDoc.collectorApplicationId || 'null'}`);
    console.log(`Application Applied At: ${userDoc.collectorApplicationAppliedAt || 'null'}`);
    console.log(`Application Reviewed At: ${userDoc.collectorApplicationReviewedAt || 'null'}`);
    console.log(`Rejection Reason: ${userDoc.collectorApplicationRejectionReason || 'null'}`);
    
    // Check if application exists
    if (userDoc.collectorApplicationId) {
      const application = await CollectorApplication.findById(userDoc.collectorApplicationId);
      if (application) {
        const appDoc = application.toObject();
        console.log('\n📋 Application Information:');
        console.log(`Application ID: ${appDoc._id}`);
        console.log(`Status: ${appDoc.status}`);
        console.log(`Applied At: ${appDoc.appliedAt}`);
        console.log(`Reviewed At: ${appDoc.reviewedAt}`);
        console.log(`Review Notes: ${appDoc.reviewNotes || 'null'}`);
      } else {
        console.log('\n❌ Application not found in database');
      }
    }
    
    // Determine what the drawer should show
    console.log('\n🎯 Drawer Status Analysis:');
    
    const hasCollectorRole = userDoc.roles.includes('collector');
    const applicationStatus = userDoc.collectorApplicationStatus;
    
    console.log(`Has collector role: ${hasCollectorRole}`);
    console.log(`Application status: ${applicationStatus || 'null'}`);
    
    if (hasCollectorRole && applicationStatus === 'approved') {
      console.log('✅ Should show: "Collector Mode"');
      console.log('✅ Should allow mode switch to collector');
    } else if (hasCollectorRole && !applicationStatus) {
      console.log('⚠️ Legacy collector - should show: "Collector Mode"');
      console.log('⚠️ Should allow mode switch to collector');
    } else if (applicationStatus === 'pending') {
      console.log('⏳ Should show: "Under Review"');
      console.log('❌ Should NOT allow mode switch to collector');
    } else if (applicationStatus === 'rejected') {
      console.log('❌ Should show: "Rejected"');
      console.log('❌ Should NOT allow mode switch to collector');
    } else {
      console.log('📝 Should show: "Become a Collector"');
      console.log('❌ Should NOT allow mode switch to collector');
    }

    await connection.disconnect();
    console.log('\n🔌 Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

checkUserStatus();
