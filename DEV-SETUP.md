# 🚀 Botleji Development Setup

## Quick Start Scripts

### For macOS/Linux:
```bash
./start-dev.sh
```

### For Windows:
```cmd
start-dev.bat
```

## What the scripts do:

1. **Backend Server** (Port 3000)
   - Changes to `backend/` directory
   - Runs `npm run start:dev:clean`
   - Starts in background

2. **Admin Dashboard** (Port 3001)
   - Changes to `admin-dashboard/` directory  
   - Runs `npm run dev`
   - Starts in background

## Manual Commands (if scripts don't work):

### Backend:
```bash
cd backend
npm run start:dev:clean
```

### Admin Dashboard:
```bash
cd admin-dashboard
npm run dev
```

## Access URLs:
- **Backend API**: http://localhost:3000
- **Admin Dashboard**: http://localhost:3001

## Stopping Services:
- **macOS/Linux**: Press `Ctrl+C` in the terminal
- **Windows**: Close the terminal windows

## Troubleshooting:
- Make sure ports 3000 and 3001 are not in use
- Ensure Node.js and npm are installed
- Run `npm install` in both directories if dependencies are missing
