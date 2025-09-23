#!/bin/bash

# Bottleji Project Setup Script
# This script helps set up the development environment

echo "🚀 Setting up Bottleji Development Environment..."

# Check if we're in the right directory
if [ ! -f "README.md" ]; then
    echo "❌ Please run this script from the PFE root directory"
    exit 1
fi

echo "📱 Setting up Flutter app..."
cd botleji
if [ -f "pubspec.yaml" ]; then
    flutter pub get
    echo "✅ Flutter dependencies installed"
else
    echo "❌ Flutter app not found"
fi
cd ..

echo "🔧 Setting up Backend..."
cd backend
if [ -f "package.json" ]; then
    npm install
    echo "✅ Backend dependencies installed"
    if [ ! -f ".env" ]; then
        echo "⚠️  Please copy .env.temp to .env and configure your environment variables"
    fi
else
    echo "❌ Backend not found"
fi
cd ..

echo "🎛️  Setting up Admin Dashboard..."
cd admin-dashboard
if [ -f "package.json" ]; then
    npm install
    echo "✅ Admin dashboard dependencies installed"
else
    echo "❌ Admin dashboard not found"
fi
cd ..

echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Configure environment variables in backend/.env"
echo "2. Add Google Maps API key to Flutter app"
echo "3. Configure Firebase for Flutter app"
echo "4. Start the backend: cd backend && npm run start:dev"
echo "5. Start the admin dashboard: cd admin-dashboard && npm run dev"
echo "6. Run the Flutter app: cd botleji && flutter run"
echo ""
echo "Happy coding! 🚀"
