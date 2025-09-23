const { MongoClient } = require('mongodb');

// Use the same connection string as the running server
const MONGODB_URI = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji?retryWrites=true&w=majority';

async function auditUsersCollection() {
  let client;
  
  try {
    console.log('🔗 Connecting to MongoDB...');
    client = new MongoClient(MONGODB_URI);
    await client.connect();
    console.log('✅ Connected to MongoDB');

    const db = client.db('bottleji');
    const usersCollection = db.collection('users');

    // Get all users
    const allUsers = await usersCollection.find({}).toArray();
    console.log(`📊 Total users in collection: ${allUsers.length}`);

    if (allUsers.length === 0) {
      console.log('⚠️ No users found in the collection');
      return;
    }

    // Audit results
    const auditResults = {
      totalUsers: allUsers.length,
      usersWithOldPhoneField: 0,
      usersWithPhoneNumberField: 0,
      usersWithBothFields: 0,
      usersWithNoPhoneData: 0,
      usersWithInvalidRoles: 0,
      usersWithMissingRequiredFields: 0,
      usersWithProfileIssues: 0,
      fieldMismatches: [],
      dataQualityIssues: []
    };

    console.log('\n🔍 Starting comprehensive audit...\n');

    for (let i = 0; i < allUsers.length; i++) {
      const user = allUsers[i];
      console.log(`\n--- User ${i + 1}/${allUsers.length}: ${user.email} ---`);
      
      // Check for old phone field
      if (user.phone !== undefined) {
        auditResults.usersWithOldPhoneField++;
        auditResults.fieldMismatches.push({
          userId: user._id,
          email: user.email,
          issue: 'Has old "phone" field',
          value: user.phone
        });
        console.log(`❌ Has old 'phone' field: ${user.phone}`);
      }

      // Check for phoneNumber field
      if (user.phoneNumber !== undefined && user.phoneNumber !== null && user.phoneNumber.trim() !== '') {
        auditResults.usersWithPhoneNumberField++;
        console.log(`✅ Has 'phoneNumber' field: ${user.phoneNumber}`);
      } else {
        auditResults.usersWithNoPhoneData++;
        console.log(`⚠️ No phone number data`);
      }

      // Check for both fields
      if (user.phone !== undefined && user.phoneNumber !== undefined) {
        auditResults.usersWithBothFields++;
        console.log(`⚠️ Has both 'phone' and 'phoneNumber' fields`);
      }

      // Check required fields
      if (!user.email) {
        auditResults.usersWithMissingRequiredFields++;
        auditResults.dataQualityIssues.push({
          userId: user._id,
          email: user.email,
          issue: 'Missing email'
        });
        console.log(`❌ Missing email`);
      }

      if (!user.password) {
        auditResults.usersWithMissingRequiredFields++;
        auditResults.dataQualityIssues.push({
          userId: user._id,
          email: user.email,
          issue: 'Missing password'
        });
        console.log(`❌ Missing password`);
      }

      // Check roles
      if (!user.roles || !Array.isArray(user.roles) || user.roles.length === 0) {
        auditResults.usersWithInvalidRoles++;
        auditResults.dataQualityIssues.push({
          userId: user._id,
          email: user.email,
          issue: 'Invalid or missing roles',
          value: user.roles
        });
        console.log(`❌ Invalid roles: ${JSON.stringify(user.roles)}`);
      } else {
        console.log(`✅ Roles: ${user.roles.join(', ')}`);
      }

      // Check profile completeness
      if (user.isProfileComplete === true) {
        if (!user.name || !user.phoneNumber || !user.address) {
          auditResults.usersWithProfileIssues++;
          auditResults.dataQualityIssues.push({
            userId: user._id,
            email: user.email,
            issue: 'Profile marked complete but missing required fields',
            missingFields: {
              name: !user.name,
              phoneNumber: !user.phoneNumber,
              address: !user.address
            }
          });
          console.log(`⚠️ Profile marked complete but missing: name=${!user.name}, phoneNumber=${!user.phoneNumber}, address=${!user.address}`);
        } else {
          console.log(`✅ Profile complete`);
        }
      } else {
        console.log(`ℹ️ Profile incomplete`);
      }

      // Check phone verification status
      if (user.isPhoneVerified === true) {
        if (!user.phoneNumber) {
          auditResults.dataQualityIssues.push({
            userId: user._id,
            email: user.email,
            issue: 'Phone marked verified but no phoneNumber field'
          });
          console.log(`❌ Phone verified but no phoneNumber`);
        } else {
          console.log(`✅ Phone verified: ${user.phoneNumber}`);
        }
      } else {
        console.log(`ℹ️ Phone not verified`);
      }

      // Check collector application status
      if (user.collectorApplication) {
        console.log(`📋 Collector application: ${user.collectorApplication.status || 'no status'}`);
        if (user.collectorApplication.status === 'rejected' && !user.collectorApplication.rejectionReason) {
          auditResults.dataQualityIssues.push({
            userId: user._id,
            email: user.email,
            issue: 'Rejected application without rejection reason'
          });
          console.log(`⚠️ Rejected application without reason`);
        }
      }

      // Check for unexpected field types
      if (typeof user.name !== 'string' && user.name !== null && user.name !== undefined) {
        auditResults.dataQualityIssues.push({
          userId: user._id,
          email: user.email,
          issue: 'Name field has unexpected type',
          expectedType: 'string',
          actualType: typeof user.name,
          value: user.name
        });
        console.log(`❌ Name has wrong type: ${typeof user.name} (${user.name})`);
      }

      if (typeof user.phoneNumber !== 'string' && user.phoneNumber !== null && user.phoneNumber !== undefined) {
        auditResults.dataQualityIssues.push({
          userId: user._id,
          email: user.email,
          issue: 'phoneNumber field has unexpected type',
          expectedType: 'string',
          actualType: typeof user.phoneNumber,
          value: user.phoneNumber
        });
        console.log(`❌ phoneNumber has wrong type: ${typeof user.phoneNumber} (${user.phoneNumber})`);
      }

      // Show all fields for debugging
      console.log(`📋 All fields: ${Object.keys(user).join(', ')}`);
    }

    // Print comprehensive audit summary
    console.log('\n' + '='.repeat(80));
    console.log('📊 COMPREHENSIVE AUDIT SUMMARY');
    console.log('='.repeat(80));
    
    console.log(`\n📈 General Statistics:`);
    console.log(`   Total users: ${auditResults.totalUsers}`);
    console.log(`   Users with old 'phone' field: ${auditResults.usersWithOldPhoneField}`);
    console.log(`   Users with 'phoneNumber' field: ${auditResults.usersWithPhoneNumberField}`);
    console.log(`   Users with both fields: ${auditResults.usersWithBothFields}`);
    console.log(`   Users with no phone data: ${auditResults.usersWithNoPhoneData}`);
    console.log(`   Users with invalid roles: ${auditResults.usersWithInvalidRoles}`);
    console.log(`   Users with missing required fields: ${auditResults.usersWithMissingRequiredFields}`);
    console.log(`   Users with profile issues: ${auditResults.usersWithProfileIssues}`);

    console.log(`\n🔍 Field Mismatches (${auditResults.fieldMismatches.length}):`);
    if (auditResults.fieldMismatches.length > 0) {
      auditResults.fieldMismatches.forEach((mismatch, index) => {
        console.log(`   ${index + 1}. ${mismatch.email}: ${mismatch.issue} - ${mismatch.value}`);
      });
    } else {
      console.log(`   ✅ No field mismatches found`);
    }

    console.log(`\n⚠️ Data Quality Issues (${auditResults.dataQualityIssues.length}):`);
    if (auditResults.dataQualityIssues.length > 0) {
      auditResults.dataQualityIssues.forEach((issue, index) => {
        console.log(`   ${index + 1}. ${issue.email}: ${issue.issue}`);
        if (issue.missingFields) {
          console.log(`      Missing: ${Object.entries(issue.missingFields).filter(([field, missing]) => missing).map(([field]) => field).join(', ')}`);
        }
        if (issue.value !== undefined) {
          console.log(`      Value: ${issue.value}`);
        }
      });
    } else {
      console.log(`   ✅ No data quality issues found`);
    }

    // Recommendations
    console.log(`\n💡 Recommendations:`);
    if (auditResults.usersWithOldPhoneField > 0) {
      console.log(`   • Run the phone field removal migration to clean up old 'phone' fields`);
    }
    if (auditResults.usersWithMissingRequiredFields > 0) {
      console.log(`   • Review users with missing required fields`);
    }
    if (auditResults.usersWithInvalidRoles > 0) {
      console.log(`   • Fix users with invalid role assignments`);
    }
    if (auditResults.usersWithProfileIssues > 0) {
      console.log(`   • Review profile completeness logic`);
    }
    if (auditResults.dataQualityIssues.length === 0 && auditResults.fieldMismatches.length === 0) {
      console.log(`   ✅ Database is clean and consistent!`);
    }

    console.log('\n' + '='.repeat(80));

  } catch (error) {
    console.error('❌ Audit failed:', error);
  } finally {
    if (client) {
      await client.close();
      console.log('🔌 Disconnected from MongoDB');
    }
  }
}

// Run the audit
auditUsersCollection().then(() => {
  console.log('Audit script completed');
  process.exit(0);
}).catch((error) => {
  console.error('Audit script failed:', error);
  process.exit(1);
});
