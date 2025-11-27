# Bottleji System Architecture Diagrams

This directory contains system architecture diagrams for the entire Bottleji project, including the Flutter mobile app, NestJS backend, and Next.js admin dashboard.

## Diagrams

### 1. SYSTEM_ARCHITECTURE.puml
**High-level system architecture** showing:
- Client applications (Flutter mobile app, Admin dashboard)
- Backend services (NestJS API, WebSocket Gateway)
- Data layer (MongoDB)
- External services (Firebase, Email, Google Maps)
- Deployment architecture

**Best for**: Overview presentations, documentation, understanding system boundaries

### 2. SYSTEM_ARCHITECTURE_DETAILED.puml
**Detailed component architecture** showing:
- Internal structure of Flutter app (presentation, business logic, services)
- Internal structure of Admin dashboard (pages, components, services)
- Internal structure of Backend API (modules, services, data access)
- Detailed relationships between components

**Best for**: Technical documentation, development reference, understanding internal architecture

## How to View

### Option 1: Online PlantUML Viewer (Easiest)
1. Go to http://www.plantuml.com/plantuml/uml/
2. Copy the contents of the `.puml` file
3. Paste into the editor
4. The diagram will render automatically

### Option 2: VS Code Extension
1. Install the "PlantUML" extension in VS Code
2. Open the `.puml` file
3. Press `Alt+D` (or `Cmd+D` on Mac) to preview
4. Or right-click and select "Preview PlantUML Diagram"

### Option 3: Generate PNG/SVG
```bash
# Install PlantUML (requires Java)
# macOS:
brew install plantuml

# Then generate image:
plantuml SYSTEM_ARCHITECTURE.puml
plantuml SYSTEM_ARCHITECTURE_DETAILED.puml

# This will create PNG files
```

### Option 4: IntelliJ IDEA / WebStorm
1. Install PlantUML plugin
2. Open the `.puml` file
3. Right-click → "PlantUML" → "Show Diagram"

## System Overview

### Architecture Layers

1. **Client Layer**
   - **Flutter Mobile App**: Cross-platform mobile application for iOS and Android
   - **Admin Dashboard**: Web-based administrative interface built with Next.js

2. **Application Layer**
   - **NestJS API Server**: RESTful API providing backend services
   - **WebSocket Gateway**: Real-time communication server using Socket.IO

3. **Data Layer**
   - **MongoDB**: NoSQL database storing all application data

4. **External Services**
   - **Firebase**: Authentication and file storage
   - **Email Service**: SMTP server for notifications
   - **Google Maps API**: Location services and mapping

### Communication Flow

1. **Mobile App → Backend**
   - REST API calls over HTTPS (JWT authentication)
   - WebSocket connections for real-time updates
   - Firebase for authentication and file uploads
   - Google Maps API for location services

2. **Admin Dashboard → Backend**
   - REST API calls over HTTPS (JWT authentication)
   - WebSocket connections for real-time updates

3. **Backend → Database**
   - Mongoose ODM for data persistence
   - Direct queries for real-time operations

4. **Backend → External Services**
   - Firebase for file storage
   - SMTP for email notifications
   - Google Maps for location validation

### Technology Stack

#### Mobile App (Flutter)
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **UI**: Material Design 3
- **Maps**: Google Maps Flutter
- **Real-time**: Socket.IO Client
- **Storage**: SharedPreferences, Hive

#### Admin Dashboard (Next.js)
- **Framework**: Next.js 15 (React)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **HTTP Client**: Axios
- **Real-time**: Socket.IO Client
- **Charts**: Recharts

#### Backend (NestJS)
- **Framework**: NestJS (Node.js)
- **Language**: TypeScript
- **Database**: MongoDB with Mongoose
- **Authentication**: JWT
- **Real-time**: Socket.IO
- **File Upload**: Multer + Firebase Storage
- **Email**: Nodemailer

#### Database
- **Type**: MongoDB (NoSQL)
- **ODM**: Mongoose
- **Hosting**: MongoDB Atlas (cloud)

#### External Services
- **Authentication**: Firebase Authentication
- **File Storage**: Firebase Cloud Storage
- **Maps**: Google Maps API
- **Email**: SMTP (Gmail/other providers)

## Key Features

### Mobile App
- Cross-platform support (iOS & Android)
- Offline-first architecture
- Real-time updates via WebSocket
- Google Maps integration
- Image capture and upload
- Push notifications

### Admin Dashboard
- Responsive web interface
- Real-time data updates
- Advanced analytics and charts
- User management
- Content moderation
- Support ticket management
- Reward system management

### Backend API
- RESTful API design
- WebSocket support for real-time features
- Role-based access control (RBAC)
- File upload handling
- Email notifications
- Data validation and sanitization
- Error handling and logging

## Deployment

### Mobile App
- **iOS**: Published to Apple App Store
- **Android**: Published to Google Play Store

### Admin Dashboard
- **Web Server**: Deployed on web hosting (Vercel, Netlify, or custom server)
- **Port**: Typically 3001 (development), 80/443 (production)

### Backend API
- **API Server**: Deployed on Node.js server (AWS, Heroku, DigitalOcean, etc.)
- **Port**: Typically 3000 (development), 80/443 (production)
- **WebSocket**: Same server, different endpoint

### Database
- **MongoDB Atlas**: Cloud-hosted MongoDB
- **Connection**: Secure connection string
- **Backup**: Automated backups

## Security

- **Authentication**: JWT tokens for API authentication
- **Authorization**: Role-based access control (RBAC)
- **HTTPS**: All communications encrypted
- **CORS**: Configured for allowed origins
- **Input Validation**: Server-side validation for all inputs
- **File Upload**: Secure file upload with validation
- **Database**: Secure connection strings, no direct access

## Scalability Considerations

- **Horizontal Scaling**: Backend can be scaled horizontally
- **Load Balancing**: Can use load balancer for multiple API instances
- **Database**: MongoDB supports sharding for large datasets
- **Caching**: Can implement Redis for caching
- **CDN**: Static assets can be served via CDN
- **WebSocket**: Socket.IO supports Redis adapter for multi-server setup

