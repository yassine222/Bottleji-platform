# Localization Missing Strings Report
**Generated:** $(date)
**Status:** Comprehensive scan of hardcoded strings requiring localization

## Summary
This report identifies all hardcoded English strings that need to be added to the ARB files and replaced with `AppLocalizations` calls.

---

## 🔴 HIGH PRIORITY - User-Facing Core Features

### 1. App Drawer (`lib/core/widgets/app_drawer.dart`)
**Status:** ❌ NOT LOCALIZED

**Missing Strings:**
- `"Household"` - Mode label (line 439, 626)
- `"Collector"` - Mode label (line 459, 698, 717, 767, 801)
- `"Active Mode"` - Section header (line 538)
- `"My Account"` - Menu item (line 882)
- `"History"` - Menu item (line 898)
- `"Notifications"` - Menu item (line 915)
- `"Trainings"` - Menu item (line 929)
- `"Refer and Earn"` - Menu item (line 943)
- `"Settings"` - Menu item (line 957) - *Note: Already in ARB but not used*
- `"Support"` - Menu item (line 971) - *Note: Already in ARB but not used*
- `"Terms and Conditions"` - Menu item (line 985) - *Note: Already in ARB but not used*
- `"Upgrade"` - Subscription upgrade button (line 512)
- `"Review"` - Application status (line 736, 782)
- `"Rejected"` - Application status (line 751)
- `"Apply"` - Application button (line 817, 846)
- `"Loading..."` - Loading state (line 832)
- `"Become a Collector"` - Dialog title (line 249)
- `"Your application is currently under review. Would you like to view your application status?"` - Dialog message (line 218)
- `"View Status"` - Button text (line 219)
- `"Your application was rejected for the following reason:\n\n\"$rejectionReason\"\n\nWould you like to edit your application and submit it again?"` - Dialog message (line 225)
- `"Your application was approved but your collector access has been temporarily suspended. Please contact support or reapply."` - Dialog message (line 232)
- `"Reapply"` - Button text (line 233)
- `"You need to apply and be approved to access collector mode. Would you like to apply now?"` - Dialog message (line 239)
- `"Apply Now"` - Button text (line 240)
- `"Application Rejected"` - Dialog title (line 43)
- `"Your application was rejected for the following reason:"` - Dialog message (line 51)
- `"You can edit your application and submit it again."` - Dialog message (line 69)
- `"Edit Application"` - Button text (line 90)
- `"Please log in to access collector mode"` - Error message (line 190)

**Subtitle Missing:**
- Drawer header subtitle (if any exists under Bottleji logo)

---

### 2. Home Screen (`lib/features/home/presentation/screens/home_screen.dart`)
**Status:** ❌ PARTIALLY LOCALIZED

**Missing Strings:**

**App Bar:**
- `"Bottleji"` - App title (line 2518) - *Note: Already in ARB as `appTitle` but not used*
- `"Eco-friendly bottle collection"` - Subtitle under Bottleji (line 2527) ⚠️ **USER MENTIONED**

**Buttons:**
- `"Set Collection Radius"` - Button label (line 2730) - *Note: Already in ARB as `setCollectionRadius` but not used* ⚠️ **USER MENTIONED**
- `"Create Drop"` - Button label (line 2716) - *Note: Already in ARB as `createDrop` but not used* ⚠️ **USER MENTIONED**
- `"Edit Drop"` - Button label (line 2169) - *Note: Already in ARB as `editDrop` but not used*
- `"Resume Navigation"` - Button label (line 2205) - *Note: Already in ARB as `resumeNavigation` but not used*
- `"Start Collection"` - Button label (line 2248, 2360) - *Note: Already in ARB as `startCollection` but not used*
- `"Open Settings"` - Button label (line 1611) - *Note: Already in ARB as `openSettings` but not used*
- `"Try Again"` - Button label (line 1623) - *Note: Already in ARB as `tryAgain` but not used*
- `"Reload Map"` - Button label (line 1637) - *Note: Already in ARB as `reloadMap` but not used*
- `"Retry"` - Button label (line 1827) - *Note: Already in ARB as `retry` but not used*

**Create Drop Form Fields:**
- `"Bottle Type"` - Form field label (line 3487) ⚠️ **USER MENTIONED**
- `"Number of Plastic Bottles"` - Form field label (line 3586) ⚠️ **USER MENTIONED**
- `"Number of Cans"` - Form field label (line 3624) ⚠️ **USER MENTIONED**
- `"Notes (Optional)"` - Form field label (line 3661) ⚠️ **USER MENTIONED**

**Image Picker Dialog:**
- `"Take Photo"` - Dialog option (line 3345) - *Note: Already in ARB as `takePhoto` but not used*
- `"Choose from Gallery"` - Dialog option (line 3355) - *Note: Already in ARB as `chooseFromGallery` but not used*
- `"Gallery (iOS Simulator Issue)"` - Dialog option (line 3377) - *Note: Already in ARB as `galleryIOSSimulatorIssue` but not used*
- `"Use camera or real device"` - Dialog subtitle (line 3378) - *Note: Already in ARB as `useCameraOrRealDevice` but not used*
- `"Cancel"` - Dialog option (line 3398) - *Note: Already in ARB as `cancel` but not used*

**Messages:**
- `"This helps us show nearby drops and provide accurate collection services."` - Info message (line 1592) - *Note: Already in ARB as `thisHelpsUsShowNearby` but not used*
- `"Please take a photo of your bottles"` - Message (line 3676) - *Note: Already in ARB as `pleaseTakePhoto` but not used*
- `"Please wait while we load your account information"` - Loading message (line 3840) - *Note: Already in ARB as `pleaseWaitLoading` but not used*
- `"You must be logged in to create a drop"` - Error message (line 3856) - *Note: Already in ARB as `mustBeLoggedIn` but not used*
- `"Authentication issue detected. Please log out and log in again."` - Error message (line 3891) - *Note: Already in ARB as `authenticationIssue` but not used*
- `"Drop created successfully!"` - Success message (line 3934) - *Note: Already in ARB as `dropCreatedSuccessfully` but not used*
- `"Failed to create drop. Please try again."` - Error message (line 3946)
- `"Image selected successfully!"` - Success message (line 3443)
- `"Error selecting image"` - Error message (line 3457)
- `"Permission denied. Please allow photo access in Settings."` - Error message (line 3460)
- `"Gallery not available on simulator. Try camera or use a real device."` - Error message (line 3462)
- `"Leave outside the door"` - Option text (line 3676) - *Note: Already in ARB as `leaveOutsideDoor` but not used*

---

### 3. Mode Switch Splash Screen (`lib/features/auth/presentation/screens/mode_switch_splash_screen.dart`)
**Status:** ❌ NOT LOCALIZED ⚠️ **USER MENTIONED**

**Missing Strings:**
- `"Household Mode"` - Mode title (line 131)
- `"Collector Mode"` - Mode title (line 133)
- `"Create drops and track your recycling"` - Household description (line 140)
- `"Collect bottles and earn rewards"` - Collector description (line 142)

---

### 4. Splash Screen (`lib/features/splash/presentation/screens/splash_screen.dart`)
**Status:** ❌ NOT LOCALIZED

**Missing Strings:**
- `"Bottleji"` - App name (line 294) - *Note: Already in ARB as `appTitle` but not used*
- `"Sustainable Waste Management"` - Tagline (line 306)

---

### 5. Account Screen (`lib/features/account/presentation/screens/account_screen.dart`)
**Status:** ❌ NOT LOCALIZED ⚠️ **USER MENTIONED**

**Missing Strings:**
- `"My Account"` - Screen title (line 23) - *Note: Already in ARB but not used*
- `"Please login to view your profile"` - Empty state message (line 49)
- `"Login"` - Button text (line 60) - *Note: Already in ARB as `login` but not used*
- `"Profile Information"` - Section title (line 165)
- `"Full Name"` - Field label (line 177)
- `"Not set"` - Placeholder value (line 178, 198, 208)
- `"Email"` - Field label (line 187) - *Note: Already in ARB as `email` but not used*
- `"Phone"` - Field label (line 197)
- `"Address"` - Field label (line 207)
- `"Collector Status"` - Status title (line 245)
- `"You are an approved collector"` - Status message (line 253)
- `"Application Status"` - Status title (line 290)
- `"Your application is under review"` - Status message (line 298)
- `"View Details"` - Button text (line 316)
- `"Application Rejected"` - Status title (line 342)
- `"Edit Profile"` - Button text (if exists)

---

## 🟡 MEDIUM PRIORITY - Secondary Features

### 6. Register Screen (`lib/features/auth/presentation/screens/register_screen.dart`)
**Status:** ❌ NOT LOCALIZED

**Missing Strings:**
- `"Start Your Bottleji Journey"` - Welcome text (line 101)

---

### 7. Onboarding/Permissions Screens
**Status:** ❌ NOT LOCALIZED

**Missing Strings:**
- `"Bottleji requires additional permissions to work properly"` - Message (permissions_screen.dart line 327)
- Various onboarding screen strings

---

### 8. Drops List Screen (`lib/features/drops/presentation/screens/drops_list_screen.dart`)
**Status:** ❌ PARTIALLY LOCALIZED

**Missing Strings:**
- `"Filter Drops"` - Dialog title (line 340) - *Note: Already in ARB as `filterDrops` but not used*
- `"Status:"` - Filter label (line 346) - *Note: Already in ARB as `status` but not used*
- `"All"` - Filter option (line 352) - *Note: Already in ARB as `all` but not used*
- `"Date:"` - Filter label (line 375) - *Note: Already in ARB as `date` but not used*
- `"Distance:"` - Filter label (line 397) - *Note: Already in ARB as `distance` but not used*
- `"Cancel"` - Button (line 421) - *Note: Already in ARB as `cancel` but not used*
- `"Apply"` - Button (line 428) - *Note: Already in ARB as `apply` but not used*
- `"Delete Drop"` - Dialog title (line 454) - *Note: Already in ARB as `deleteDrop` but not used*
- `"Are you sure you want to delete this drop?"` - Dialog message (line 461) - *Note: Already in ARB as `areYouSureDelete` but not used*
- `"Clear Filters"` - Button (line 1174) - *Note: Already in ARB as `clearFilters` but not used*
- `"Try adjusting your filters"` - Empty state message (line 1158, 1161) - *Note: Already in ARB as `tryAdjustingFilters` but not used*
- `"Check back later for new drops"` - Empty state message (line 1159) - *Note: Already in ARB as `checkBackLater` but not used*
- `"Create your first drop to get started"` - Empty state message (line 1162) - *Note: Already in ARB as `createFirstDrop` but not used*

---

### 9. Navigation Screen (`lib/features/navigation/presentation/screens/navigation_screen.dart`)
**Status:** ❌ PARTIALLY LOCALIZED

**Missing Strings:**
- `"Cancel Collection"` - Button/Title (line 1609, 2014, 2295, 2336) - *Note: Already in ARB as `cancelCollection` but not used*
- `"Are you sure you want to cancel this collection?"` - Dialog message (line 1610) - *Note: Already in ARB as `areYouSureCancelCollection` but not used*
- `"No"` - Button (line 1610) - *Note: Already in ARB as `no` but not used*
- `"Yes, Cancel"` - Button (line 1618) - *Note: Already in ARB as `yesCancel` but not used*
- `"Leave Collection?"` - Dialog title (line 1721) - *Note: Already in ARB as `leaveCollection` but not used*
- `"Are you sure you want to leave? Your collection will remain active."` - Dialog message (line 1729) - *Note: Already in ARB as `areYouSureLeaveCollection` but not used*
- `"Stay"` - Button (line 1729) - *Note: Already in ARB as `stay` but not used*
- `"Leave"` - Button (line 1737) - *Note: Already in ARB as `leave` but not used*
- `"Report Drop"` - Button (line 2269) - *Note: Already in ARB as `reportDrop` but not used*
- `"Back"` - Button (line 2323) - *Note: Already in ARB as `back` but not used*
- `"Exit Navigation"` - Dialog title (line 2853) - *Note: Already in ARB as `exitNavigation` but not used*
- `"Are you sure you want to exit navigation? Your collection will remain active."` - Dialog message (line 2854) - *Note: Already in ARB as `areYouSureExitNavigation` but not used*

---

### 10. Active Collection Indicator (`lib/core/widgets/active_collection_indicator.dart`)
**Status:** ❌ PARTIALLY LOCALIZED

**Missing Strings:**
- `"Collection in Progress"` - Title (line 550) - *Note: Already in ARB as `collectionInProgress` but not used*
- `"Resume Collection"` - Button (line 737) - *Note: Already in ARB as `resumeCollection` but not used*
- `"Cancel"` - Button (line 717) - *Note: Already in ARB as `cancel` but not used*
- `"⚠️ Collection Timeout"` - Dialog title (line 379) - *Note: Already in ARB as `collectionTimeout` but not used*
- `"OK"` - Button (line 390) - *Note: Already in ARB as `ok` but not used*

---

## 🟢 LOW PRIORITY - Less Frequently Used

### 11. Support Screens
**Status:** ❌ NOT LOCALIZED

**Missing Strings:**
- Various support ticket creation strings
- Ticket category names
- Priority labels

### 12. Rewards Screen
**Status:** ❌ PARTIALLY LOCALIZED

**Missing Strings:**
- `"Tier System"` - Section title (line 639) - *Note: Already in ARB as `tierSystem` but not used*
- `"Retry"` - Button (line 145, 790) - *Note: Already in ARB as `retry` but not used*
- `"Close"` - Button (line 751) - *Note: Already in ARB as `close` but not used*

### 13. History Screen
**Status:** ❌ NOT LOCALIZED

**Missing Strings:**
- Various history-related labels and messages

### 14. Stats Screen
**Status:** ❌ NOT LOCALIZED

**Missing Strings:**
- Various statistics labels and chart titles

---

## 📊 Statistics

### By Priority:
- **HIGH PRIORITY:** ~80 strings
- **MEDIUM PRIORITY:** ~40 strings  
- **LOW PRIORITY:** ~30 strings
- **TOTAL:** ~150 strings

### By Status:
- **Already in ARB but not used:** ~60 strings
- **Missing from ARB:** ~90 strings

### By File:
- **app_drawer.dart:** ~30 strings
- **home_screen.dart:** ~35 strings
- **account_screen.dart:** ~15 strings
- **mode_switch_splash_screen.dart:** ~4 strings
- **Other files:** ~66 strings

---

## 🎯 Action Items

### Immediate (User-Requested):
1. ✅ App Drawer - All menu items and labels
2. ✅ Home Screen - App bar subtitle "Eco-friendly bottle collection"
3. ✅ Home Screen - "Set Collection Radius" button
4. ✅ Home Screen - "Create Drop" button (household mode)
5. ✅ Home Screen - Create drop form fields
6. ✅ Mode Switch Splash Screen - All text
7. ✅ Account Screen - All labels and messages

### Next Phase:
1. Replace all strings that are already in ARB but not being used
2. Add missing strings to ARB files
3. Update all remaining screens systematically

---

## 📝 Notes

- Many strings are already defined in ARB files but not being used in the code
- Some strings appear multiple times across different files
- Consider creating helper methods for commonly used strings
- Some strings may need pluralization support (e.g., "1 bottle" vs "5 bottles")
- Date/time formatting should use locale-aware formatting

---

**Next Steps:**
1. Add all missing strings to ARB files (English, French, German, Arabic)
2. Replace hardcoded strings with AppLocalizations calls
3. Test language switching across all screens
4. Verify RTL support for Arabic

