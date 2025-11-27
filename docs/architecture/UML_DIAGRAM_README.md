# Bottleji Backend Schema UML Diagram

## Overview
This UML class diagram represents the complete database schema structure for the Bottleji backend application, showing all entities, their attributes, relationships, and embedded documents.

## How to View the Diagram

### Option 1: Online PlantUML Viewer (Easiest)
1. Go to http://www.plantuml.com/plantuml/uml/
2. Copy the contents of `UML_DIAGRAM.puml`
3. Paste into the editor
4. The diagram will render automatically

### Option 2: VS Code Extension
1. Install the "PlantUML" extension in VS Code
2. Open `UML_DIAGRAM.puml`
3. Press `Alt+D` (or `Cmd+D` on Mac) to preview
4. Or right-click and select "Preview PlantUML Diagram"

### Option 3: Generate PNG/SVG
```bash
# Install PlantUML (requires Java)
# macOS:
brew install plantuml

# Then generate image:
plantuml UML_DIAGRAM.puml

# This will create UML_DIAGRAM.png
```

### Option 4: IntelliJ IDEA / WebStorm
1. Install PlantUML plugin
2. Open the `.puml` file
3. Right-click → "PlantUML" → "Show Diagram"

## Diagram Structure

### Main Entities (10)
1. **User** - Central entity representing all users (household, collector, admin, etc.)
2. **Dropoff** - Recycling drops created by household users
3. **CollectionAttempt** - Tracks collector attempts to collect drops
4. **CollectorApplication** - Separate collection for collector applications
5. **DropReport** - Reports made on suspicious drops
6. **SupportTicket** - Customer support tickets
7. **RewardItem** - Items available in the reward shop
8. **RewardRedemption** - User redemptions of reward items
9. **TrainingContent** - Training materials (videos, images, stories)
10. **Notification** - User notifications

### Embedded Documents / Value Objects
- **CollectorApplicationEmbedded** - Embedded in User schema
- **Location** - Geographic coordinates
- **CancellationHistory** - Array of cancellation records
- **TimelineEvent** - Events in collection attempts
- **DropSnapshot** - Snapshot of drop at time of collection attempt
- **DeliveryAddress** - Shipping address for rewards
- **InternalNote** - Internal notes in support tickets
- **Message** - Messages in support tickets
- **TicketLocation** - Location data for tickets
- **NotificationData** - Additional data for notifications
- **NotificationAction** - Action buttons for notifications

### Key Relationships

#### User Relationships
- Creates multiple **Dropoffs**
- Makes multiple **CollectionAttempts** (as collector)
- Has one **CollectorApplication** (embedded or separate)
- Creates multiple **SupportTickets**
- Redeems multiple **RewardRedemptions**
- Receives multiple **Notifications**

#### Dropoff Relationships
- Has multiple **DropReports**
- Has multiple **CollectionAttempts**
- Can be related to **SupportTicket**

#### CollectionAttempt Relationships
- Belongs to one **Dropoff**
- Belongs to one **User** (collector)
- Contains **DropSnapshot** and **TimelineEvent** arrays
- Can be related to **SupportTicket**

#### SupportTicket Relationships
- Belongs to one **User** (creator)
- Can be assigned to one **User** (agent)
- Can be escalated to one **User** (admin)
- Can reference **Dropoff**, **CollectionAttempt**, or **CollectorApplication**
- Contains **Message** and **InternalNote** arrays

#### Reward Relationships
- **RewardItem** has many **RewardRedemptions**
- **RewardRedemption** belongs to one **User** and one **RewardItem**

## Enumerations

The diagram includes all enums used across the schemas:
- UserRole (6 values)
- CollectorApplicationStatus (3 values)
- DropoffStatus (6 values)
- BottleType (3 values)
- CancellationReason (6 values)
- ReportReason (7 values)
- ReportStatus (4 values)
- TicketStatus (5 values)
- TicketPriority (4 values)
- TicketCategory (10 values)
- RedemptionStatus (7 values)
- RewardCategory (2 values)
- NotificationType (10 values)
- NotificationPriority (4 values)

## Notes

- All relationships use ObjectId references unless specified as embedded
- String references are used in some cases (e.g., `userId` in Dropoff, `userId` in RewardRedemption)
- Timestamps (`createdAt`, `updatedAt`) are managed automatically by Mongoose
- Virtual `id` fields are added to all schemas for JSON serialization

