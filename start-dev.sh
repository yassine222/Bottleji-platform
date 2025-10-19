#!/bin/bash

# Botleji Development Startup Script
# This script starts both the backend server and admin dashboard

echo "🚀 Starting Botleji Development Environment..."
echo "================================================"

# Function to check if a port is in use
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
        echo "⚠️  Port $1 is already in use"
        return 1
    else
        return 0
    fi
}

# Check if ports are available
echo "🔍 Checking ports..."
if ! check_port 3000; then
    echo "❌ Backend port 3000 is in use. Please stop the existing process."
    exit 1
fi

if ! check_port 3001; then
    echo "❌ Admin dashboard port 3001 is in use. Please stop the existing process."
    exit 1
fi

echo "✅ Ports are available"

# Start backend server
echo ""
echo "🔧 Starting Backend Server..."
echo "=============================="
cd backend
echo "📁 Changed to backend directory"
echo "🚀 Running: npm run start:dev:clean"
npm run start:dev:clean &
BACKEND_PID=$!

# Wait a moment for backend to start
sleep 3

# Start admin dashboard
echo ""
echo "🎨 Starting Admin Dashboard..."
echo "==============================="
cd ../admin-dashboard
echo "📁 Changed to admin-dashboard directory"
echo "🚀 Running: npm run dev"
npm run dev &
ADMIN_PID=$!

# Wait a moment for admin dashboard to start
sleep 3

echo ""
echo "🎉 Development Environment Started!"
echo "===================================="
echo "📊 Backend Server: http://localhost:3000"
echo "🎨 Admin Dashboard: http://localhost:3001"
echo ""
echo "💡 Press Ctrl+C to stop both services"
echo ""

# Function to cleanup processes on exit
cleanup() {
    echo ""
    echo "🛑 Stopping services..."
    kill $BACKEND_PID 2>/dev/null
    kill $ADMIN_PID 2>/dev/null
    echo "✅ Services stopped"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Wait for both processes
wait $BACKEND_PID $ADMIN_PID
