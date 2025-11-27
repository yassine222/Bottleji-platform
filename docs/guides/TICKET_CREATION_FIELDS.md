# Support Ticket Creation - Fields Sent to Database

This document outlines what fields are sent to the database when creating support tickets for different categories.

## Backend Schema (What DB Accepts)

**File**: `backend/src/modules/support-tickets/schemas/support-ticket.schema.ts`

### Core Fields (Always Present)
- `userId`: ObjectId (ref: User) - Auto-filled from JWT token
- `title`: string (required)
- `description`: string (required)
- `category`: TicketCategory enum (required)
- `priority`: TicketPriority enum (default: MEDIUM)
- `status`: TicketStatus enum (default: OPEN)
- `createdBy`: ObjectId (ref: User) - Auto-filled from JWT token
- `lastUpdatedBy`: ObjectId (ref: User) - Auto-filled from JWT token
- `messages`: Array (auto-generated initial message)
- `createdAt`: Date (auto-generated)
- `updatedAt`: Date (auto-generated)

### Optional Context Fields
- `attachments`: string[] (default: [])
- `contextMetadata`: any (stores additional context)
- `relatedDropId`: ObjectId (ref: Dropoff)
- `relatedCollectionId`: ObjectId (stores interaction ID)
- `relatedApplicationId`: ObjectId (ref: CollectorApplication)
- `location`: { latitude: number, longitude: number, address: string }

---

## Ticket Creation by Category

### 1. **DROP ISSUE** (Created by Household Users)

**Category**: `drop_issue`

**Context**: Shows drops created by the household user in the **last 3 days**

**Fields Sent** (Improved v2):
```json
{
  "title": "Drop Issue - #68de885c",
  "description": "Issue with drop created on Sep 14\nStatus: Pending\nBottles: 15, Cans: 0",
  "category": "drop_issue",
  "priority": "medium",
  "contextMetadata": {
    "ticketType": "drop_issue",
    "dropId": "68de885caeb246e1806048f3",
    "drop": {
      "id": "68de885caeb246e1806048f3",
      "status": "pending",
      "numberOfBottles": 15,
      "numberOfCans": 0,
      "bottleType": "plastic",
      "notes": "",
      "leaveOutside": false,
      "createdAt": "2025-10-02T14:12:44.035Z"
    },
    "location": {
      "latitude": 52.270787,
      "longitude": 10.512130,
      "address": "..."
    },
    "issueContext": "household_drop_last_3_days",
    "createdAt": "2025-10-02T14:12:44.035Z"
  },
  "relatedDropId": "68de885caeb246e1806048f3",
  "location": {
    "latitude": 52.270787,
    "longitude": 10.512130,
    "address": "..."
  }
}
```

**Key Points**:
- ✅ `relatedDropId` is populated with the actual drop ObjectId
- ✅ `contextMetadata.ticketType` identifies this as a drop issue
- ✅ `contextMetadata.drop` contains complete drop details (structured)
- ✅ `contextMetadata.issueContext` indicates this is from "household_drop_last_3_days"
- ✅ `location` contains the drop's location for mapping

**Backend Processing**:
- Fetches drop interactions using `relatedDropId`
- Populates `relatedDropId` with full drop object (including interactions)
- Displays drop details and interaction timeline in admin dashboard

---

### 2. **COLLECTION ISSUE** (Created by Collectors)

**Category**: `collection_issue`

**Context**: Shows drops that were **accepted** and then **expired/cancelled/collected** in the **last 3 days**

**Fields Sent** (Improved v2):
```json
{
  "title": "Collection Issue - #68de9e5c",
  "description": "Issue with collection cancelled on Oct 2\nDrop: 68de885c",
  "category": "collection_issue",
  "priority": "medium",
  "contextMetadata": {
    "ticketType": "collection_issue",
    "collectionId": "68de9e5cbe72119fb6c86959",
    "dropoffId": "68de885caeb246e1806048f3",
    "interaction": {
      "id": "68de9e5cbe72119fb6c86959",
      "acceptedInteraction": {
        "id": "68de9e5cbe72119fb6c86959",
        "type": "accepted",
        "time": "2025-10-02T15:46:36.321Z",
        "notes": null
      },
      "finalInteraction": {
        "id": "68de9e5d...",
        "type": "cancelled",
        "time": "2025-10-02T16:03:12.456Z",
        "cancellationReason": "Too far away",
        "notes": null
      },
      "status": "cancelled"
    },
    "dropoff": {
      "id": "68de885caeb246e1806048f3",
      "numberOfBottles": 15,
      "numberOfCans": 0,
      "bottleType": "plastic",
      "location": {...},
      "status": "pending"
    },
    "issueContext": "collector_interaction_last_3_days",
    "interactionTime": "2025-10-02T16:03:12.456Z"
  },
  "relatedDropId": "68de885caeb246e1806048f3",
  "relatedCollectionId": "68de9e5cbe72119fb6c86959"
}
```

**Key Points**:
- ⚠️ `relatedCollectionId` is actually an **interaction ID**, NOT a collection entity ID
- ✅ `contextMetadata.ticketType` identifies this as a collection issue
- ✅ `contextMetadata.interaction` contains **structured interaction data**:
  - `acceptedInteraction`: The initial ACCEPTED interaction
  - `finalInteraction`: The final interaction (CANCELLED/EXPIRED/COLLECTED)
  - `status`: Final status of the collection
- ✅ `contextMetadata.dropoffId` contains the actual drop ID (properly extracted)
- ✅ `contextMetadata.dropoff` contains full drop details
- ✅ `contextMetadata.issueContext` indicates this is from "collector_interaction_last_3_days"

**Important Fixes (v2)**:
- The Flutter app now properly extracts the `dropoffId` from populated interaction objects
- Structured interaction data shows both ACCEPTED and final interaction (CANCELLED/EXPIRED/COLLECTED)
- Clear indication that this represents a pair of interactions (accept → final state)
- **Fixed**: `relatedDropId` is now properly set for collection issues (uses `dropoffId` from metadata)

**Backend Processing**:
1. Uses `relatedCollectionId` (interaction ID) to find the specific interaction
2. Extracts `dropoffId` from that interaction
3. Fetches ALL interactions for that drop
4. Returns timeline with drop details from `dropoffInfo`
5. Admin dashboard displays:
   - **Drop Details**: From `interactions[0].dropoffInfo`
   - **Interaction Timeline**: All interactions for that drop

**Why "Collection" ID is Misleading**:
- It's called `relatedCollectionId` but stores an interaction ID
- The interaction belongs to a drop, not a separate "collection" entity
- The backend resolves it to show the drop and its full interaction history

---

### 3. **APPLICATION ISSUE** (Created by Collectors)

**Category**: `application_issue`

**Fields Sent**:
```json
{
  "title": "Application Issue",
  "description": "Issue with my collector application",
  "category": "application_issue",
  "priority": "medium",
  "contextMetadata": {
    "applicationId": "68909d8ff85f26496bd23ff2",
    "status": "pending",
    "submittedAt": "2025-08-15T10:30:00.000Z"
  },
  "relatedApplicationId": "68909d8ff85f26496bd23ff2"
}
```

**Key Points**:
- ✅ `relatedApplicationId` contains the collector application ObjectId
- ✅ `contextMetadata.applicationId` contains the same application ID
- ✅ Application status and submission date stored in metadata

**Backend Processing**:
- Can populate `relatedApplicationId` with full application object
- Displays application details in admin dashboard

---

### 4. **GENERAL SUPPORT** (Any User)

**Category**: `general_support`

**Fields Sent** (Improved v2):
```json
{
  "title": "General Support",
  "description": "Get help with general support",
  "category": "general_support",
  "priority": "medium",
  "contextMetadata": {
    "ticketType": "general_support",
    "context": "general",
    "category": "general_support",
    "categoryTitle": "General Support",
    "issueContext": "general_support_request"
  }
}
```

**Key Points**:
- ❌ No `relatedDropId`, `relatedCollectionId`, or `relatedApplicationId`
- ✅ `contextMetadata.ticketType` identifies this as general support
- ✅ `contextMetadata.issueContext` indicates this is a general support request
- ✅ Used for issues not related to specific drops/collections/applications

---

## Summary Table

| Ticket Type | Category | relatedDropId | relatedCollectionId | relatedApplicationId | Key Metadata |
|------------|----------|---------------|---------------------|---------------------|--------------|
| **Drop Issue** | `drop_issue` | ✅ Drop ObjectId | ❌ | ❌ | dropId, status, bottles, cans, location |
| **Collection Issue** | `collection_issue` | ✅ Drop ObjectId | ✅ Interaction ObjectId | ❌ | collectionId (interaction), dropoffId, dropoff details, interaction pair |
| **Application Issue** | `application_issue` | ❌ | ❌ | ✅ Application ObjectId | applicationId, status |
| **General Support** | `general_support` | ❌ | ❌ | ❌ | context, category |

---

## Improvements in v2

### **Structured Metadata**
All tickets now include:
- `ticketType`: Identifies the ticket category clearly
- `issueContext`: Explains where/when the ticket was created from
- Nested objects for better data organization

### **Drop Issue Improvements**
- Complete drop details in `contextMetadata.drop` object
- Clear indication this is from "household_drop_last_3_days"
- Better title and description formatting

### **Collection Issue Improvements**
- **Structured interaction data** with both:
  - `acceptedInteraction`: The initial ACCEPTED interaction
  - `finalInteraction`: The final state (CANCELLED/EXPIRED/COLLECTED)
- Properly extracted `dropoffId` (no more empty strings!)
- Clear indication this is from "collector_interaction_last_3_days"
- Shows the complete interaction pair lifecycle

### **Time Context**
All tickets now clearly indicate their time context:
- **Drop Issues**: Drops created in last 3 days
- **Collection Issues**: Interactions completed in last 3 days (accepted → final state)

---

## Important Notes

1. **Collection Issue Confusion**:
   - `relatedCollectionId` is NOT a collection entity
   - It's an interaction ID that belongs to a drop
   - Backend resolves it to show the drop and all its interactions

2. **Data Flow**:
   ```
   Flutter App → API → Backend Service → MongoDB
   
   Collection Issue Example:
   Flutter: relatedCollectionId = "68de9e5c" (interaction ID)
   Backend: Finds interaction → Extracts dropoffId → Fetches all interactions
   Admin UI: Shows drop details + full interaction timeline
   ```

3. **Metadata vs Related IDs**:
   - `contextMetadata`: Stores additional context for display/reference
   - `relatedXxxId`: Used for database relationships and fetching related data

4. **Location Field**:
   - Only sent for drop issues (contains drop location)
   - Not used for collection/application issues

---

## Files Reference

### Backend
- Schema: `backend/src/modules/support-tickets/schemas/support-ticket.schema.ts`
- Controller: `backend/src/modules/support-tickets/support-tickets.controller.ts`
- Service: `backend/src/modules/support-tickets/support-tickets.service.ts`

### Flutter
- API Client: `botleji/lib/features/support/data/datasources/support_ticket_api_client.dart`
- Create Screen: `botleji/lib/features/support/presentation/screens/create_ticket_screen.dart`
- Item Selection: `botleji/lib/features/support/presentation/screens/support_item_selection_screen.dart`
- Model: `botleji/lib/features/support/data/models/support_ticket.dart`
