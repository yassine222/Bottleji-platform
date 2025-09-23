#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Starting Bottleji Backend Server...${NC}"

# Check if port 3000 is in use
PORT_PID=$(lsof -ti:3000 2>/dev/null)

if [ ! -z "$PORT_PID" ]; then
    echo -e "${YELLOW}⚠️  Port 3000 is already in use by PID: $PORT_PID${NC}"
    echo -e "${YELLOW}🔄 Killing existing process...${NC}"
    kill -9 $PORT_PID 2>/dev/null
    sleep 2
    
    # Double check if process was killed
    if lsof -ti:3000 >/dev/null 2>&1; then
        echo -e "${RED}❌ Failed to kill process on port 3000${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ Successfully killed process on port 3000${NC}"
    fi
else
    echo -e "${GREEN}✅ Port 3000 is available${NC}"
fi

echo -e "${GREEN}🚀 Starting development server...${NC}"
npm run start:dev
