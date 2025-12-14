import WidgetKit
import SwiftUI
import ActivityKit
import UIKit

// MARK: - App Theme Colors
extension Color {
    // App Primary Green
    static let appPrimary = Color(red: 0.0, green: 0.412, blue: 0.361) // #00695C
    // App Orange
    static let appOrange = Color(red: 1.0, green: 0.596, blue: 0.0) // #FF9800
    // App Secondary Blue
    static let appSecondary = Color(red: 0.0, green: 0.6, blue: 1.0) // #0099FF
}

// MARK: - Helper Functions

// Helper function to load app logo from bundle
@ViewBuilder
func AppLogoView(size: CGFloat, cornerRadius: CGFloat = 4, viewType: LiveActivityViewType = .standard) -> some View {
    Group {
        let imageName: String? = {
            switch viewType {
            case .compact:
                return "live_activity_icon_compact"
            case .expanded:
                return "live_activity_icon_expanded"
            case .minimal:
                return "live_activity_icon_minimal"
            case .standard:
                return "AppLogo"
            }
        }()
        
        if let name = imageName,
           let image = UIImage(named: name, in: Bundle.main, compatibleWith: nil) ?? UIImage(named: name) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else if let fallbackImage = UIImage(named: "AppLogo", in: Bundle.main, compatibleWith: nil) ?? UIImage(named: "AppLogo") {
            Image(uiImage: fallbackImage)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(.appPrimary)
                .font(size > 20 ? .title3 : (size > 15 ? .caption : .caption2))
        }
    }
    .frame(width: size, height: size)
    .cornerRadius(cornerRadius)
}

// Enum for Live Activity view types
enum LiveActivityViewType {
    case compact
    case expanded
    case minimal
    case standard
}

// MARK: - Unified Live Activities Attributes (Required by live_activities package)

// IMPORTANT: Must be named EXACTLY "LiveActivitiesAppAttributes" for live_activities package to work
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable, Codable {
    public typealias LiveDeliveryData = ContentState  // Required for package
    
    public struct ContentState: Codable, Hashable {
        // Activity type: "collection" (collector navigation) or "dropTimeline" (household drop status)
        var activityType: String
        
        // Collection mode fields (used when activityType == "collection")
        var elapsedTime: String?
        var distance: String?
        var eta: String?
        var progressPercentage: Int?
        
        // Drop timeline mode fields (used when activityType == "dropTimeline")
        var status: String?
        var statusText: String?
        var collectorName: String?
        var timeAgo: String?
        var distanceRemaining: Double? // Distance in meters - for collector pin position
        
        // Default initializer (required for ActivityKit)
        init() {
            self.activityType = "unknown"
            self.elapsedTime = nil
            self.distance = nil
            self.eta = nil
            self.progressPercentage = nil
            self.status = nil
            self.statusText = nil
            self.collectorName = nil
            self.timeAgo = nil
        }
        
        // Required initializer for live_activities package (for push updates)
        // The package stores data in UserDefaults and ActivityKit manages the content state
        // NOTE: This is called when the package needs to read initial state from UserDefaults
        init(appGroupId: String) {
            // Initialize with defaults first
            self.activityType = "dropTimeline"
            self.elapsedTime = nil
            self.distance = nil
            self.eta = nil
            self.progressPercentage = nil
            self.status = "pending"
            self.statusText = "Created"
            self.collectorName = nil
            self.timeAgo = "Just now"
            self.distanceRemaining = nil
            
            // Try to read from UserDefaults if available
            // Use a more robust approach to avoid CFPrefs warnings
            do {
                guard let sharedDefaults = UserDefaults(suiteName: appGroupId) else {
                    print("⚠️ Could not create UserDefaults with appGroupId: \(appGroupId)")
                    return
                }
                
                // Synchronize to ensure we have the latest data
                sharedDefaults.synchronize()
                
                // Read activity type (required)
                if let activityType = sharedDefaults.string(forKey: "activityType"), !activityType.isEmpty {
                    self.activityType = activityType
                }
                
                // Read collection mode fields
                self.elapsedTime = sharedDefaults.string(forKey: "elapsedTime")
                self.distance = sharedDefaults.string(forKey: "distance")
                self.eta = sharedDefaults.string(forKey: "eta")
                if let progress = sharedDefaults.object(forKey: "progressPercentage") as? Int {
                    self.progressPercentage = progress
                }
                
                // Read drop timeline mode fields
                if let status = sharedDefaults.string(forKey: "status"), !status.isEmpty {
                    self.status = status
                }
                if let statusText = sharedDefaults.string(forKey: "statusText"), !statusText.isEmpty {
                    self.statusText = statusText
                }
                self.collectorName = sharedDefaults.string(forKey: "collectorName")
                if let timeAgo = sharedDefaults.string(forKey: "timeAgo"), !timeAgo.isEmpty {
                    self.timeAgo = timeAgo
                }
                if let distance = sharedDefaults.object(forKey: "distanceRemaining") as? Double {
                    self.distanceRemaining = distance
                }
                
                print("✅ ContentState init(appGroupId): Read from UserDefaults - activityType=\(self.activityType), status=\(self.status ?? "nil"), distanceRemaining=\(self.distanceRemaining.map { String(format: "%.2f", $0) } ?? "nil")")
            } catch {
                print("⚠️ Error reading from UserDefaults: \(error)")
                // Keep default values
            }
        }
        
        // Codable initializer for normal decoding (used when ActivityKit decodes the state from createActivity data)
        init(from decoder: Decoder) throws {
            print("🔍 [ContentState] Starting decode from push notification...")
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // Log all available keys for debugging
            let allKeys = container.allKeys
            print("🔍 [ContentState] Available keys in payload: \(allKeys.map { $0.stringValue })")
            
            // activityType is required - decode it, default to "dropTimeline" if missing
            do {
                self.activityType = try container.decode(String.self, forKey: .activityType)
                print("✅ [ContentState] Decoded activityType: \(self.activityType)")
            } catch {
                print("⚠️ [ContentState] Could not decode activityType, defaulting to 'dropTimeline': \(error)")
                self.activityType = "dropTimeline"
            }
            
            // Optional fields - decode with error handling
            self.elapsedTime = try? container.decode(String.self, forKey: .elapsedTime)
            self.distance = try? container.decode(String.self, forKey: .distance)
            self.eta = try? container.decode(String.self, forKey: .eta)
            self.progressPercentage = try? container.decode(Int.self, forKey: .progressPercentage)
            
            // Drop timeline fields
            if let status = try? container.decode(String.self, forKey: .status) {
                self.status = status
                print("✅ [ContentState] Decoded status: \(status)")
            } else {
                print("⚠️ [ContentState] Could not decode status")
            }
            
            if let statusText = try? container.decode(String.self, forKey: .statusText) {
                self.statusText = statusText
                print("✅ [ContentState] Decoded statusText: \(statusText)")
            } else {
                print("⚠️ [ContentState] Could not decode statusText")
            }
            
            if let collectorName = try? container.decode(String.self, forKey: .collectorName) {
                self.collectorName = collectorName
                print("✅ [ContentState] Decoded collectorName: \(collectorName)")
            } else {
                print("⚠️ [ContentState] Could not decode collectorName")
            }
            
            if let timeAgo = try? container.decode(String.self, forKey: .timeAgo) {
                self.timeAgo = timeAgo
                print("✅ [ContentState] Decoded timeAgo: \(timeAgo)")
            } else {
                print("⚠️ [ContentState] Could not decode timeAgo")
            }
            
            if let distanceRemaining = try? container.decode(Double.self, forKey: .distanceRemaining) {
                self.distanceRemaining = distanceRemaining
                print("✅ [ContentState] Decoded distanceRemaining: \(distanceRemaining)")
            } else {
                print("⚠️ [ContentState] Could not decode distanceRemaining")
            }
            
            print("✅ [ContentState] Decode complete - activityType=\(self.activityType), status=\(self.status ?? "nil"), statusText=\(self.statusText ?? "nil"), collectorName=\(self.collectorName ?? "nil"), timeAgo=\(self.timeAgo ?? "nil"), distanceRemaining=\(self.distanceRemaining.map { String(format: "%.2f", $0) } ?? "nil")")
        }
        
        // Encoding for Codable
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(activityType, forKey: .activityType)
            try container.encodeIfPresent(elapsedTime, forKey: .elapsedTime)
            try container.encodeIfPresent(distance, forKey: .distance)
            try container.encodeIfPresent(eta, forKey: .eta)
            try container.encodeIfPresent(progressPercentage, forKey: .progressPercentage)
            try container.encodeIfPresent(status, forKey: .status)
            try container.encodeIfPresent(statusText, forKey: .statusText)
            try container.encodeIfPresent(collectorName, forKey: .collectorName)
            try container.encodeIfPresent(timeAgo, forKey: .timeAgo)
            try container.encodeIfPresent(distanceRemaining, forKey: .distanceRemaining)
        }
        
        // Custom CodingKeys for Codable conformance
        enum CodingKeys: String, CodingKey {
            case activityType
            case elapsedTime
            case distance
            case eta
            case progressPercentage
            case status
            case statusText
            case collectorName
            case timeAgo
            case distanceRemaining
        }
    }
    
    var id: UUID
    var dropId: String
    var dropAddress: String
    var estimatedValue: String
    var transportMode: String?  // For collection mode
    var createdAt: String?       // For drop timeline mode
    
    // Default initializer
    init() {
        self.id = UUID()
        self.dropId = ""
        self.dropAddress = ""
        self.estimatedValue = ""
        self.transportMode = nil
        self.createdAt = nil
    }
    
    // Codable initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode id, with fallback to new UUID (package might not provide this)
        if let idString = try? container.decode(String.self, forKey: .id),
           let uuid = UUID(uuidString: idString) {
            self.id = uuid
        } else {
            // Generate new UUID if not provided (package generates its own activity ID)
            self.id = UUID()
        }
        
        // Decode required fields with error handling
        do {
            self.dropId = try container.decode(String.self, forKey: .dropId)
            self.dropAddress = try container.decode(String.self, forKey: .dropAddress)
            self.estimatedValue = try container.decode(String.self, forKey: .estimatedValue)
        } catch {
            print("❌ LiveActivitiesAppAttributes: Failed to decode required fields: \(error)")
            // Provide defaults to prevent crash
            self.dropId = try container.decodeIfPresent(String.self, forKey: .dropId) ?? ""
            self.dropAddress = try container.decodeIfPresent(String.self, forKey: .dropAddress) ?? ""
            self.estimatedValue = try container.decodeIfPresent(String.self, forKey: .estimatedValue) ?? "0.00 TND"
        }
        
        // Optional fields
        self.transportMode = try? container.decode(String.self, forKey: .transportMode)
        self.createdAt = try? container.decode(String.self, forKey: .createdAt)
        
        print("✅ LiveActivitiesAppAttributes decoded: dropId=\(self.dropId), dropAddress=\(self.dropAddress), estimatedValue=\(self.estimatedValue)")
    }
    
    // Encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id.uuidString, forKey: .id)
        try container.encode(dropId, forKey: .dropId)
        try container.encode(dropAddress, forKey: .dropAddress)
        try container.encode(estimatedValue, forKey: .estimatedValue)
        try container.encodeIfPresent(transportMode, forKey: .transportMode)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }
    
    // CodingKeys for attributes
    enum CodingKeys: String, CodingKey {
        case id
        case dropId
        case dropAddress
        case estimatedValue
        case transportMode
        case createdAt
    }
}

// MARK: - Legacy Collection Navigation Activity (Deprecated - keeping for migration)
// TODO: Remove after migration complete
struct CollectionActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var elapsedTime: String
        var distance: String
        var eta: String
        var progressPercentage: Int
    }
    
    var dropId: String
    var dropAddress: String
    var transportMode: String
    var estimatedValue: String
}

// MARK: - Unified Live Activity Widget (Uses LiveActivitiesAppAttributes)

@available(iOS 16.1, *)
struct UnifiedLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            // MARK: - Lock Screen View (Unified)
            // Determine activity type - default to dropTimeline if unknown
            let activityType = context.state.activityType.isEmpty || context.state.activityType == "unknown" 
                ? "dropTimeline" 
                : context.state.activityType
            
            if activityType == "collection" {
                unifiedCollectionLockScreenView(context: context)
                    .activityBackgroundTint(Color(.systemBackground))
            } else {
                unifiedDropTimelineLockScreenView(context: context)
                    .activityBackgroundTint(Color(.systemBackground))
            }
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded Presentation
                DynamicIslandExpandedRegion(.leading) {
                    expandedLeadingView(context: context)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTrailingView(context: context)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottomView(context: context)
                }
            } compactLeading: {
                // MARK: - Compact Presentation (Leading)
                compactLeadingView(context: context)
            } compactTrailing: {
                // MARK: - Compact Presentation (Trailing)
                compactTrailingView(context: context)
            } minimal: {
                // MARK: - Minimal Presentation
                minimalView(context: context)
            }
            .widgetURL(URL(string: {
                let activityType = context.state.activityType.isEmpty || context.state.activityType == "unknown" 
                    ? "dropTimeline" 
                    : context.state.activityType
                return activityType == "collection" 
                    ? "botleji://navigation?dropId=\(context.attributes.dropId)"
                    : "botleji://drop?dropId=\(context.attributes.dropId)"
            }()))
        }
    }
    
    // MARK: - Unified Collection Lock Screen View
    @ViewBuilder
    private func unifiedCollectionLockScreenView(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row
            HStack(alignment: .center, spacing: 10) {
                // App Branding
                HStack(spacing: 8) {
                    AppLogoView(size: 28, cornerRadius: 7, viewType: .standard)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bottleji")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("Active Collection")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Countdown Timer (Primary Metric)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(context.state.elapsedTime ?? "00:00")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.appOrange)
                        .monospacedDigit()
                    Text("remaining")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [Color.appPrimary, Color.appPrimary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(context.state.progressPercentage ?? 0) / 100, height: 4)
                }
            }
            .frame(height: 4)
            
            // Info Row
            HStack(spacing: 20) {
                // Distance
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.appSecondary)
                        .frame(width: 16)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Distance")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(context.state.distance ?? "0 km")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
                
                // Value
                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.caption)
                        .foregroundColor(.appPrimary)
                        .frame(width: 16)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Value")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(context.attributes.estimatedValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                // Progress
                VStack(alignment: .trailing, spacing: 1) {
                    Text("Progress")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(context.state.progressPercentage ?? 0)%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.appPrimary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    // MARK: - StandBy View (Same as Lock Screen)
    // Note: StandBy uses the same view as Lock Screen in ActivityKit
    
    // MARK: - Expanded Presentation Views (Unified)
    @ViewBuilder
    private func expandedLeadingView(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> some View {
        let activityType = context.state.activityType.isEmpty || context.state.activityType == "unknown" 
            ? "dropTimeline" 
            : context.state.activityType
        
        if activityType == "collection" {
            unifiedCollectionExpandedLeadingView(context: context)
        } else {
            unifiedDropTimelineExpandedLeadingView(context: context)
        }
    }
    
    @ViewBuilder
    private func unifiedCollectionExpandedLeadingView(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // App Logo and Name - Horizontally aligned (smaller to free space)
            HStack(alignment: .center, spacing: 4) {
                AppLogoView(size: 18, cornerRadius: 4, viewType: .expanded)
                Text("Bottleji")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            // Status - Positioned below the logo/text row with proper spacing
             // Ensure no extra leading padding
        }
        .padding(.leading, 2)
        .frame(maxWidth: .infinity, alignment: .leading) // Ensure proper alignment
    }
    
    @ViewBuilder
    private func expandedTrailingView(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> some View {
        let activityType = context.state.activityType.isEmpty || context.state.activityType == "unknown" 
            ? "dropTimeline" 
            : context.state.activityType
        
        if activityType == "collection" {
            unifiedCollectionExpandedTrailingView(context: context)
        } else {
            unifiedDropTimelineExpandedTrailingView(context: context)
        }
    }
    
    @ViewBuilder
    private func unifiedCollectionExpandedTrailingView(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> some View {
        // Countdown Timer
        Text(context.state.elapsedTime ?? "00:00")
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundColor(.appOrange)
            .monospacedDigit()
            .lineLimit(1)
    }
    
    @ViewBuilder
    private func expandedBottomView(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> some View {
        let activityType = context.state.activityType.isEmpty || context.state.activityType == "unknown" 
            ? "dropTimeline" 
            : context.state.activityType
        
        if activityType == "collection" {
            unifiedCollectionExpandedBottomView(context: context)
        } else {
            unifiedDropTimelineExpandedBottomView(context: context)
        }
    }
    
    @ViewBuilder
    private func unifiedCollectionExpandedBottomView(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> some View {
        VStack(spacing: 10) {
            // Status - Left aligned
            HStack {
                Text("Active Collection")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .padding(.leading, 8)
                Spacer()
            }
            
            // Info Row
            HStack(spacing: 16) {
                // Distance
                HStack(spacing: 5) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundColor(.appSecondary)
                    Text(context.state.distance ?? "0 km")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .padding(.leading, 8)
                
                // Value
                HStack(spacing: 5) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.appPrimary)
                    Text(context.attributes.estimatedValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Progress
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.2))
                        .frame(width: 12, height: 12)
                    Text("\(context.state.progressPercentage ?? 0)%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .padding(.trailing, 8)
            }
            
            // Progress Bar - More pronounced (thicker)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    
                    // Progress Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.appPrimary, Color.appPrimary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(context.state.progressPercentage ?? 0) / 100, height: 6)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Compact Presentation Views (Unified)
    @ViewBuilder
    private func compactLeadingView(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> some View {
        AppLogoView(size: 16, cornerRadius: 3, viewType: .compact)
    }
    
    @ViewBuilder
    private func compactTrailingView(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> some View {
        let activityType = context.state.activityType.isEmpty || context.state.activityType == "unknown" 
            ? "dropTimeline" 
            : context.state.activityType
        
        if activityType == "collection" {
            Text(context.state.elapsedTime ?? "00:00")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.appOrange)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        } else {
            Text(context.state.statusText ?? "Drop")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(statusColorForStatus(context.state.status ?? "pending"))
                .lineLimit(1)
        }
    }
    
    // MARK: - Minimal Presentation View (Unified)
    @ViewBuilder
    private func minimalView(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> some View {
        AppLogoView(size: 12, cornerRadius: 2, viewType: .minimal)
    }
    
    // MARK: - Unified Drop Timeline Views
    @ViewBuilder
    private func unifiedDropTimelineLockScreenView(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> some View {
        let currentStatus = context.state.status ?? "pending"
        let currentStatusText = context.state.statusText ?? "Created"
        let currentCollectorName = context.state.collectorName
        let currentTimeAgo = context.state.timeAgo ?? "Just now"
        
        // Debug: Log when widget re-renders with new state
        let _ = print("🔄 Widget re-rendering: status=\(currentStatus), statusText=\(currentStatusText), collectorName=\(currentCollectorName ?? "nil"), timeAgo=\(currentTimeAgo), distanceRemaining=\(context.state.distanceRemaining.map { String(format: "%.2f", $0) } ?? "nil")")
        
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .center, spacing: 10) {
                HStack(spacing: 8) {
                    AppLogoView(size: 28, cornerRadius: 7, viewType: .standard)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bottleji")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("Drop Status")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(context.attributes.estimatedValue.isEmpty ? "0.00 TND" : context.attributes.estimatedValue)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.appPrimary)
            }
            
            // Status
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColorForStatus(currentStatus))
                    .frame(width: 10, height: 10)
                Text(currentStatusText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(statusColorForStatus(currentStatus))
                
                if let collectorName = currentCollectorName, !collectorName.isEmpty {
                    Text("• \(collectorName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Timeline Progress
            timelineProgressView(status: currentStatus, distanceRemaining: context.state.distanceRemaining)
            
            // Time Ago
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(currentTimeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
    }
    
    @ViewBuilder
    private func unifiedDropTimelineExpandedLeadingView(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 6) {
                AppLogoView(size: 22, cornerRadius: 5, viewType: .expanded)
                Text("Bottleji")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            Text("Drop Status")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.leading, 4)
    }
    
    @ViewBuilder
    private func unifiedDropTimelineExpandedTrailingView(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(context.attributes.estimatedValue.isEmpty ? "0.00 TND" : context.attributes.estimatedValue)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Text(context.state.statusText ?? "Created")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(statusColorForStatus(context.state.status ?? "pending"))
                .lineLimit(1)
        }
    }
    
    @ViewBuilder
    private func unifiedDropTimelineExpandedBottomView(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> some View {
        VStack(spacing: 6) {
            timelineProgressView(status: context.state.status ?? "pending", distanceRemaining: context.state.distanceRemaining)
            
            if let collectorName = context.state.collectorName, !collectorName.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(collectorName)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Helper Functions
    private func statusColorForStatus(_ status: String) -> Color {
        switch status {
        case "pending":
            return .appSecondary
        case "accepted", "on_way":
            return .appOrange
        case "collected":
            return .appPrimary
        case "expired", "cancelled":
            return Color(.systemRed)
        default:
            return Color(.systemGray)
        }
    }
    
    @ViewBuilder
    private func timelineProgressView(status: String, distanceRemaining: Double? = nil) -> some View {
        let stages = ["Created", "Accepted", "On his way", "Outcome"]
        let statusColorValue = statusColorForStatus(status)
        
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let dotWidth: CGFloat = 5
            let numberOfDots = CGFloat(stages.count)
            let numberOfLines = numberOfDots - 1
            let totalDotWidth = dotWidth * numberOfDots
            let availableWidthForLines = totalWidth - totalDotWidth
            let lineWidth = numberOfLines > 0 ? availableWidthForLines / numberOfLines : 0
            
            ZStack(alignment: .leading) {
                // Timeline base (dots and lines)
                HStack(spacing: 0) {
                    ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                        let isActive = isStageActive(status: status, stageIndex: index)
                        let isCompleted = isStageCompleted(status: status, stageIndex: index)
                        
                        // Dot
                        Circle()
                            .fill(isCompleted ? statusColorValue : (isActive ? statusColorValue : Color(.systemGray4)))
                            .frame(width: dotWidth, height: dotWidth)
                        
                        // Connecting line with calculated equal width
                        if index < stages.count - 1 {
                            Rectangle()
                                .fill(isCompleted ? statusColorValue : Color(.systemGray4))
                                .frame(width: max(0, lineWidth), height: 2)
                        }
                    }
                }
                
                // Collector pin (only show between "Accepted" and "Outcome" when collector is on the way)
                if let distance = distanceRemaining, (status == "accepted" || status == "on_way") {
                    // Calculate pin position: 0% = at "Accepted" (index 1), 100% = at "Outcome" (index 3)
                    // We'll use a simple progress calculation: assume max distance of 10km (10000m)
                    // Progress = 1 - (distance / 10000), clamped between 0 and 1
                    let maxDistance: Double = 10000.0 // 10km
                    let progress = max(0, min(1, 1 - (distance / maxDistance)))
                    
                    // Position: between dot 1 (Accepted) and dot 3 (Outcome)
                    // Dot 1 position: dotWidth + lineWidth
                    // Dot 3 position: (dotWidth * 3) + (lineWidth * 2)
                    // Pin position: dot1 + (progress * (dot3 - dot1))
                    let dot1Position = dotWidth + lineWidth
                    let dot3Position = (dotWidth * 3) + (lineWidth * 2)
                    let pinPosition = dot1Position + (CGFloat(progress) * (dot3Position - dot1Position))
                    
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.appOrange)
                        .offset(x: pinPosition - 6) // Center the pin (12/2 = 6)
                }
            }
        }
        .frame(height: 12) // Increased height to accommodate pin
    }
    
    private func isStageActive(status: String, stageIndex: Int) -> Bool {
        switch (status, stageIndex) {
        case ("pending", 0): return true
        case ("accepted", 1): return true
        case ("on_way", 2): return true
        case ("collected", 3), ("expired", 3), ("cancelled", 3): return true
        default: return false
        }
    }
    
    private func isStageCompleted(status: String, stageIndex: Int) -> Bool {
        switch (status, stageIndex) {
        case ("accepted", 0), ("on_way", 0), ("collected", 0), ("expired", 0), ("cancelled", 0): return true
        case ("on_way", 1), ("collected", 1), ("expired", 1), ("cancelled", 1): return true
        case ("collected", 2), ("expired", 2), ("cancelled", 2): return true
        default: return false
        }
    }
}

// MARK: - Drop Timeline Activity (Household Mode)

struct DropTimelineActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: String  // "pending", "accepted", "on_way", "collected", "expired", "cancelled"
        var statusText: String  // "Created", "Accepted", "On his way", etc.
        var collectorName: String?  // Collector name if accepted
        var timeAgo: String  // "2 min ago", "Just now"
    }
    
    var dropId: String
    var dropAddress: String
    var estimatedValue: String  // "2.50 TND"
    var createdAt: String  // Timestamp
}

@available(iOS 16.1, *)
struct DropTimelineWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DropTimelineActivityAttributes.self) { context in
            // MARK: - Lock Screen View (Household)
            dropTimelineLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded Presentation (Household)
                DynamicIslandExpandedRegion(.leading) {
                    dropTimelineExpandedLeadingView(context: context)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    dropTimelineExpandedTrailingView(context: context)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    dropTimelineExpandedBottomView(context: context)
                }
            } compactLeading: {
                // MARK: - Compact Presentation (Household)
                AppLogoView(size: 16, cornerRadius: 3, viewType: .compact)
            } compactTrailing: {
                // MARK: - Compact Trailing (Household)
                Text(context.state.statusText.isEmpty ? "Drop" : context.state.statusText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(DropTimelineWidget.statusColorForStatus(context.state.status))
                    .lineLimit(1)
            } minimal: {
                // MARK: - Minimal Presentation (Household)
                AppLogoView(size: 12, cornerRadius: 2, viewType: .minimal)
            }
            .widgetURL(URL(string: "botleji://drop?dropId=\(context.attributes.dropId)"))
        }
    }
    
    // MARK: - Drop Timeline Lock Screen View
    @ViewBuilder
    private func dropTimelineLockScreenView(context: ActivityViewContext<DropTimelineActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .center, spacing: 10) {
                HStack(spacing: 8) {
                    AppLogoView(size: 28, cornerRadius: 7, viewType: .standard)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bottleji")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("Drop Status")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(context.attributes.estimatedValue.isEmpty ? "0.00 TND" : context.attributes.estimatedValue)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.appPrimary)
            }
            
            // Status
            HStack(spacing: 8) {
                Circle()
                    .fill(DropTimelineWidget.statusColorForStatus(context.state.status))
                    .frame(width: 10, height: 10)
                Text(context.state.statusText.isEmpty ? "Created" : context.state.statusText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DropTimelineWidget.statusColorForStatus(context.state.status))
                
                if let collectorName = context.state.collectorName, !collectorName.isEmpty {
                    Text("• \(collectorName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Timeline Progress
            timelineProgressView(status: context.state.status, distanceRemaining: nil) // DropTimelineWidget doesn't have distanceRemaining yet
            
            // Time Ago
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(context.state.timeAgo.isEmpty ? "Just now" : context.state.timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Drop Timeline Expanded Views
    @ViewBuilder
    private func dropTimelineExpandedLeadingView(context: ActivityViewContext<DropTimelineActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // App Logo and Name - Horizontally aligned
            HStack(alignment: .center, spacing: 6) {
                AppLogoView(size: 22, cornerRadius: 5, viewType: .expanded)
                Text("Bottleji")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            Text("Drop Status")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.leading, 4)
    }
    
    @ViewBuilder
    private func dropTimelineExpandedTrailingView(context: ActivityViewContext<DropTimelineActivityAttributes>) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(context.attributes.estimatedValue.isEmpty ? "0.00 TND" : context.attributes.estimatedValue)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Text(context.state.statusText.isEmpty ? "Created" : context.state.statusText)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(DropTimelineWidget.statusColorForStatus(context.state.status))
                .lineLimit(1)
        }
    }
    
    @ViewBuilder
    private func dropTimelineExpandedBottomView(context: ActivityViewContext<DropTimelineActivityAttributes>) -> some View {
        VStack(spacing: 6) {
            timelineProgressView(status: context.state.status, distanceRemaining: nil) // DropTimelineWidget doesn't have distanceRemaining yet
            
            if let collectorName = context.state.collectorName {
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(collectorName)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Helper Functions
    static func statusColorForStatus(_ status: String) -> Color {
        switch status {
        case "pending":
            return .appSecondary
        case "accepted", "on_way":
            return .appOrange
        case "collected":
            return .appPrimary
        case "expired", "cancelled":
            return Color(.systemRed)
        default:
            return Color(.systemGray)
        }
    }
    
    @ViewBuilder
    private func timelineProgressView(status: String, distanceRemaining: Double? = nil) -> some View {
        let stages = ["Created", "Accepted", "On his way", "Outcome"]
        let statusColorValue = DropTimelineWidget.statusColorForStatus(status)
        
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let dotWidth: CGFloat = 5
            let numberOfDots = CGFloat(stages.count)
            let numberOfLines = numberOfDots - 1
            let totalDotWidth = dotWidth * numberOfDots
            let availableWidthForLines = totalWidth - totalDotWidth
            let lineWidth = numberOfLines > 0 ? availableWidthForLines / numberOfLines : 0
            
            ZStack(alignment: .leading) {
                // Timeline base (dots and lines)
                HStack(spacing: 0) {
                    ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                        let isActive = isStageActive(status: status, stageIndex: index)
                        let isCompleted = isStageCompleted(status: status, stageIndex: index)
                        
                        // Dot
                        Circle()
                            .fill(isCompleted ? statusColorValue : (isActive ? statusColorValue : Color(.systemGray4)))
                            .frame(width: dotWidth, height: dotWidth)
                        
                        // Connecting line with calculated equal width
                        if index < stages.count - 1 {
                            Rectangle()
                                .fill(isCompleted ? statusColorValue : Color(.systemGray4))
                                .frame(width: max(0, lineWidth), height: 2)
                        }
                    }
                }
                
                // Collector pin (only show between "Accepted" and "Outcome" when collector is on the way)
                if let distance = distanceRemaining, (status == "accepted" || status == "on_way") {
                    // Calculate pin position: 0% = at "Accepted" (index 1), 100% = at "Outcome" (index 3)
                    // We'll use a simple progress calculation: assume max distance of 10km (10000m)
                    // Progress = 1 - (distance / 10000), clamped between 0 and 1
                    let maxDistance: Double = 10000.0 // 10km
                    let progress = max(0, min(1, 1 - (distance / maxDistance)))
                    
                    // Position: between dot 1 (Accepted) and dot 3 (Outcome)
                    // Dot 1 position: dotWidth + lineWidth
                    // Dot 3 position: (dotWidth * 3) + (lineWidth * 2)
                    // Pin position: dot1 + (progress * (dot3 - dot1))
                    let dot1Position = dotWidth + lineWidth
                    let dot3Position = (dotWidth * 3) + (lineWidth * 2)
                    let pinPosition = dot1Position + (CGFloat(progress) * (dot3Position - dot1Position))
                    
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.appOrange)
                        .offset(x: pinPosition - 6) // Center the pin (12/2 = 6)
                }
            }
        }
        .frame(height: 12) // Increased height to accommodate pin
    }
    
    private func isStageActive(status: String, stageIndex: Int) -> Bool {
        switch (status, stageIndex) {
        case ("pending", 0): return true
        case ("accepted", 1): return true
        case ("on_way", 2): return true
        case ("collected", 3), ("expired", 3), ("cancelled", 3): return true
        default: return false
        }
    }
    
    private func isStageCompleted(status: String, stageIndex: Int) -> Bool {
        switch (status, stageIndex) {
        case ("accepted", 0), ("on_way", 0), ("collected", 0), ("expired", 0), ("cancelled", 0): return true
        case ("on_way", 1), ("collected", 1), ("expired", 1), ("cancelled", 1): return true
        case ("collected", 2), ("expired", 2), ("cancelled", 2): return true
        default: return false
        }
    }
}

// MARK: - Widget Bundle
@main
struct LiveActivityWidgetExtension: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        if #available(iOS 16.1, *) {
            // Unified widget that handles both collection and drop timeline
            UnifiedLiveActivityWidget()
            
            // Legacy widgets (keeping for migration period - can be removed later)
            // LiveActivityWidget()
            // DropTimelineWidget()
        }
    }
}
