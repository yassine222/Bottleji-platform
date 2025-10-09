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

**Fields Sent**:
```json
{
  "title": "Drop #68de885c",
  "description": "Status: Pending\nBottles: 15\nCans: 0",
  "category": "drop_issue",
  "priority": "medium",
  "contextMetadata": {
    "dropId": "68de885caeb246e1806048f3",
    "status": "pending",
    "numberOfBottles": 15,
    "numberOfCans": 0,
    "bottleType": "plastic",
    "location": {
      "latitude": 52.270787,
      "longitude": 10.512130,
      "address": "..."
    },
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
- ✅ `contextMetadata.dropId` contains the same drop ID
- ✅ `location` contains the drop's location
- ✅ Drop details are stored in `contextMetadata` for reference

**Backend Processing**:
- Fetches drop interactions using `relatedDropId`
- Populates `relatedDropId` with full drop object (including interactions)
- Displays drop details and interaction timeline in admin dashboard

---

### 2. **COLLECTION ISSUE** (Created by Collectors)

**Category**: `collection_issue`

**Fields Sent**:
```json
{
  "title": "Collection #68de9e5c",
  "description": "Status: Accepted\nDrop: 68de885c",
  "category": "collection_issue",
  "priority": "medium",
  "contextMetadata": {
    "collectionId": "68de9e5cbe72119fb6c86959",
    "dropoffId": "68de885caeb246e1806048f3",
    "status": "accepted",
    "interactionType": "accepted",
    "interactionTime": "2025-10-02T15:46:36.321Z",
    "dropoff": {
      "id": "68de885caeb246e1806048f3",
      "numberOfBottles": 15,
      "numberOfCans": 0,
      "bottleType": "plastic",
      "location": {...},
      "status": "pending"
    }
  },
  "relatedCollectionId": "68de9e5cbe72119fb6c86959"
}
```

**Key Points**:
- ⚠️ `relatedCollectionId` is actually an **interaction ID**, NOT a collection entity ID
- ✅ `contextMetadata.collectionId` is the interaction ID
- ✅ `contextMetadata.dropoffId` contains the actual drop ID
- ✅ `contextMetadata.dropoff` contains full drop details

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

**Fields Sent**:
```json
{
  "title": "General Support Request",
  "description": "I need help with...",
  "category": "general_support",
  "priority": "medium",
  "contextMetadata": {
    "context": "general",
    "category": "general_support",
    "categoryTitle": "General Support"
  }
}
```

**Key Points**:
- ❌ No `relatedDropId`, `relatedCollectionId`, or `relatedApplicationId`
- ✅ Only basic context metadata
- ✅ Used for issues not related to specific drops/collections/applications

---

## Summary Table

| Ticket Type | Category | relatedDropId | relatedCollectionId | relatedApplicationId | Key Metadata |
|------------|----------|---------------|---------------------|---------------------|--------------|
| **Drop Issue** | `drop_issue` | ✅ Drop ObjectId | ❌ | ❌ | dropId, status, bottles, cans, location |
| **Collection Issue** | `collection_issue` | ❌ | ✅ Interaction ObjectId | ❌ | collectionId (interaction), dropoffId, dropoff details |
| **Application Issue** | `application_issue` | ❌ | ❌ | ✅ Application ObjectId | applicationId, status |
| **General Support** | `general_support` | ❌ | ❌ | ❌ | context, category |

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
