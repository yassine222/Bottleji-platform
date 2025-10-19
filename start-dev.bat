@echo off
REM Botleji Development Startup Script for Windows
REM This script starts both the backend server and admin dashboard

echo 🚀 Starting Botleji Development Environment...
echo ================================================

REM Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ❌ Node.js is not installed or not in PATH
    pause
    exit /b 1
)

REM Start backend server
echo.
echo 🔧 Starting Backend Server...
echo ==============================
cd backend
echo 📁 Changed to backend directory
echo 🚀 Running: npm run start:dev:clean
start "Backend Server" cmd /k "npm run start:dev:clean"

REM Wait a moment for backend to start
timeout /t 3 /nobreak >nul

REM Start admin dashboard
echo.
echo 🎨 Starting Admin Dashboard...
echo ===============================
cd ..\admin-dashboard
echo 📁 Changed to admin-dashboard directory
echo 🚀 Running: npm run dev
start "Admin Dashboard" cmd /k "npm run dev"

REM Wait a moment for admin dashboard to start
timeout /t 3 /nobreak >nul

echo.
echo 🎉 Development Environment Started!
echo ====================================
echo 📊 Backend Server: http://localhost:3000
echo 🎨 Admin Dashboard: http://localhost:3001
echo.
echo 💡 Close the terminal windows to stop the services
echo.
pause
