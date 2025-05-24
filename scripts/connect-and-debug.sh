#!/bin/bash

# Server connection details
SERVER_HOST="159.223.68.114"
SERVER_USER="root"
SERVER_PASS="pHuong@123dotnet"

echo "=== Connecting to Server for Debug ==="
echo "Host: $SERVER_HOST"
echo "User: $SERVER_USER"
echo ""

# Install sshpass if not available (for password authentication)
if ! command -v sshpass &> /dev/null; then
    echo "Installing sshpass for password authentication..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install hudochenkov/sshpass/sshpass
        else
            echo "Please install sshpass manually or use SSH key authentication"
            exit 1
        fi
    else
        # Linux
        sudo apt-get update && sudo apt-get install -y sshpass
    fi
fi

# Connect to server and run debug commands
echo "Connecting to server and running debug commands..."

sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_HOST" << 'ENDSSH'

echo "=== Server Debug Script ==="
echo "Connected successfully! Running diagnostics..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== System Information ===${NC}"
echo "OS Info:"
cat /etc/os-release | head -3
echo ""
echo "Memory Usage:"
free -h
echo ""
echo "Disk Usage:"
df -h /
echo ""

echo -e "${YELLOW}=== Docker Status ===${NC}"
echo "Docker version:"
docker --version 2>/dev/null || echo "Docker not installed"
echo ""
echo "Docker-compose version:"
docker-compose --version 2>/dev/null || echo "Docker-compose not installed"
echo ""

echo "Docker service status:"
systemctl is-active docker
echo ""

echo -e "${YELLOW}=== Container Status ===${NC}"
echo "All containers:"
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}" 2>/dev/null || echo "No containers or Docker not running"
echo ""

echo "Docker networks:"
docker network ls 2>/dev/null || echo "Cannot list networks"
echo ""

echo "Docker volumes:"
docker volume ls 2>/dev/null || echo "Cannot list volumes"
echo ""

echo -e "${YELLOW}=== Deployment Directory ===${NC}"
echo "Checking deployment directories:"
ls -la /deployments/ 2>/dev/null || echo "/deployments directory not found"
echo ""

if [ -d "/deployments/microservices" ]; then
    echo "Microservices deployment directory:"
    ls -la /deployments/microservices/
    echo ""
    
    if [ -f "/deployments/microservices/docker-compose.yml" ]; then
        echo "Docker-compose file exists. Content preview:"
        head -20 /deployments/microservices/docker-compose.yml
        echo ""
        echo "Checking services status:"
        cd /deployments/microservices
        docker-compose ps 2>/dev/null || echo "Cannot get compose status"
        echo ""
    else
        echo -e "${RED}docker-compose.yml not found!${NC}"
    fi
else
    echo -e "${RED}/deployments/microservices directory not found!${NC}"
fi

echo -e "${YELLOW}=== Container Logs (Last 10 lines) ===${NC}"
containers=("sqlserver-microservices" "kafka-microservices" "auth-service" "email-service" "gateway-api" "kafka-init")

for container in "${containers[@]}"; do
    if docker ps -a --format "{{.Names}}" | grep -q "^${container}$" 2>/dev/null; then
        echo -e "${GREEN}--- $container logs ---${NC}"
        docker logs --tail=10 $container 2>/dev/null || echo "Cannot get logs for $container"
        echo ""
    else
        echo -e "${RED}$container not found${NC}"
    fi
done

echo -e "${YELLOW}=== Network Connectivity Tests ===${NC}"
echo "Testing external access:"
curl -f http://localhost:5000/health 2>/dev/null && echo "Gateway API accessible" || echo "Gateway API not accessible"
curl -f http://localhost:5001/health 2>/dev/null && echo "Auth Service accessible" || echo "Auth Service not accessible" 
curl -f http://localhost:5002/health 2>/dev/null && echo "Email Service accessible" || echo "Email Service not accessible"

echo ""
echo -e "${YELLOW}=== Process Information ===${NC}"
echo "Listening ports:"
netstat -tlnp | grep -E ':(5000|5001|5002|1433|9092)' || echo "No services listening on expected ports"

echo ""
echo -e "${YELLOW}=== Available Docker Images ===${NC}"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" 2>/dev/null | head -10

echo ""
echo -e "${YELLOW}=== Quick Fix Commands ===${NC}"
echo "If containers are not running, try these commands:"
echo "1. cd /deployments/microservices"
echo "2. docker-compose down"
echo "3. docker-compose pull"
echo "4. docker-compose up -d"
echo ""
echo "To restart individual services:"
echo "docker-compose restart auth-service"
echo "docker-compose restart email-service" 
echo "docker-compose restart gateway-api"

echo ""
echo -e "${GREEN}=== Debug Complete ===${NC}"

ENDSSH

echo ""
echo "Debug completed. Check the output above for issues."
echo ""
echo "Common solutions:"
echo "1. If Docker is not installed: Run the setup script"
echo "2. If containers are not running: Check the docker-compose.yml file"
echo "3. If images are missing: Re-run the GitHub Actions workflow"
echo "4. If network issues: Check firewall settings"
