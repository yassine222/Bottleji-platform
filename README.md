# Bottleji - Eco-Friendly Bottle Collection App

A comprehensive mobile application for eco-friendly bottle collection, built with Flutter, featuring a modern UI, real-time map integration, and a complete backend system.

## 🚀 Project Overview

Bottleji is a full-stack application that connects households with collectors for efficient bottle and can collection. The app features a modern floating navigation design, real-time map integration with Google Maps, and a comprehensive admin dashboard.

## 📱 Features

### Mobile App (Flutter)
- **Modern UI Design**: Floating navigation bar, gradient AppBar, and Material Design 3
- **Dual User Modes**: 
  - **Household Mode**: Create drops, edit existing drops, view collection history
  - **Collector Mode**: Accept drops, set collection radius, navigate to collection points
- **Real-time Map Integration**: Google Maps with custom markers, polylines, and navigation
- **Smart Bottom Sheets**: Context-aware action buttons based on user mode and drop ownership
- **Authentication System**: Login, registration, OTP verification, password reset
- **Profile Management**: User profiles, collector applications, subscription management
- **Statistics & Analytics**: Collection stats, earnings tracking, performance metrics
- **Support System**: In-app support tickets, FAQ, contact forms

### Backend API (Node.js/NestJS)
- **RESTful API**: Complete backend with authentication, authorization, and data management
- **Real-time Features**: WebSocket support for live updates and notifications
- **Database Integration**: MongoDB with Mongoose for data persistence
- **Role-based Access Control**: Admin, collector, and household user roles
- **Email Services**: OTP verification, password reset, notifications
- **File Upload**: Image handling with Firebase Storage integration

### Admin Dashboard (Next.js)
- **User Management**: View, edit, and manage user accounts
- **Drop Management**: Monitor and manage collection drops
- **Collector Applications**: Review and approve collector applications
- **Analytics Dashboard**: System statistics and performance metrics
- **Support Management**: Handle support tickets and user inquiries

## 🛠️ Technology Stack

### Frontend (Mobile)
- **Flutter**: Cross-platform mobile development
- **Riverpod**: State management and dependency injection
- **Google Maps**: Map integration and location services
- **Firebase**: Authentication and file storage
- **Material Design 3**: Modern UI components

### Backend
- **Node.js**: Runtime environment
- **NestJS**: Progressive Node.js framework
- **MongoDB**: NoSQL database
- **Mongoose**: MongoDB object modeling
- **JWT**: Authentication tokens
- **WebSocket**: Real-time communication

### Admin Dashboard
- **Next.js**: React framework
- **TypeScript**: Type-safe JavaScript
- **Tailwind CSS**: Utility-first CSS framework
- **React Query**: Data fetching and caching

## 📁 Project Structure

```
PFE/
├── botleji/                 # Flutter mobile app
│   ├── lib/
│   │   ├── core/           # Core utilities, themes, navigation
│   │   ├── features/       # Feature-based modules
│   │   │   ├── auth/       # Authentication
│   │   │   ├── drops/      # Drop management
│   │   │   ├── home/       # Home screen and map
│   │   │   ├── navigation/ # Bottom navigation
│   │   │   └── ...
│   │   └── main.dart       # App entry point
│   ├── assets/             # Images, icons, fonts
│   └── pubspec.yaml        # Dependencies
├── backend/                # Node.js/NestJS API
│   ├── src/
│   │   ├── modules/        # Feature modules
│   │   ├── config/         # Configuration
│   │   └── main.ts         # Server entry point
│   └── package.json        # Dependencies
├── admin-dashboard/        # Next.js admin panel
│   ├── src/
│   │   ├── app/           # App router pages
│   │   ├── components/    # React components
│   │   └── lib/           # Utilities and API
│   └── package.json       # Dependencies
└── scripts/               # Utility scripts
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0+)
- Node.js (18+)
- MongoDB (local or Atlas)
- Google Maps API key
- Firebase project

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd PFE
   ```

2. **Setup Flutter App**
   ```bash
   cd botleji
   flutter pub get
   ```

3. **Setup Backend**
   ```bash
   cd backend
   npm install
   cp .env.temp .env
   # Configure environment variables
   npm run start:dev
   ```

4. **Setup Admin Dashboard**
   ```bash
   cd admin-dashboard
   npm install
   npm run dev
   ```

### Environment Configuration

#### Flutter App
- Add Google Maps API key to `android/app/src/main/AndroidManifest.xml`
- Configure Firebase in `lib/firebase_options.dart`

#### Backend
- MongoDB connection string
- JWT secret key
- Email service credentials
- Firebase admin SDK

#### Admin Dashboard
- Backend API URL
- Authentication configuration

## 🎯 Key Features Implemented

### Recent Fixes & Improvements
- ✅ **Fixed duplicate bottom sheet issue** - Removed conflicting `DraggableScrollableSheet`
- ✅ **Implemented mode-aware action buttons** - Edit Drop for households, Start Collection for collectors
- ✅ **Consistent floating button spacing** - Uniform padding across user modes
- ✅ **Modern floating navigation** - Redesigned bottom navigation with badges
- ✅ **Fixed AppBar overflow** - Responsive design with proper text handling
- ✅ **Improved drawer design** - Modern, compact drawer with proper scrolling

### User Experience
- **Smart Navigation**: Context-aware buttons based on user mode and drop ownership
- **Real-time Updates**: Live map updates and collection status changes
- **Intuitive Design**: Material Design 3 with consistent spacing and typography
- **Accessibility**: Proper contrast ratios and touch targets

## 🔧 Development Workflow

### Git Workflow
- **Main branch**: `master` - Production-ready code
- **Feature branches**: Create branches for new features
- **Commit messages**: Use descriptive commit messages
- **Pull requests**: Review code before merging

### Code Quality
- **Linting**: ESLint for TypeScript, Dart analyzer for Flutter
- **Formatting**: Prettier for consistent code style
- **Testing**: Unit and integration tests
- **Documentation**: Inline comments and README files

## 📱 Screenshots

*Add screenshots of the app here*

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support, email support@bottleji.com or create an issue in the repository.

## 🙏 Acknowledgments

- Google Maps API for location services
- Firebase for authentication and storage
- Flutter team for the amazing framework
- Material Design for UI guidelines

---

**Note**: This project is part of a PFE (Projet de Fin d'Études) and represents a complete full-stack mobile application with modern UI/UX design principles.
