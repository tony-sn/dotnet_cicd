#!/bin/bash

echo "=== Server Debug Script ==="
echo "Connecting to server and checking deployment status..."

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
df -h
echo ""

echo -e "${YELLOW}=== Docker Status ===${NC}"
echo "Docker version:"
docker --version
echo ""
echo "Docker-compose version:"
docker-compose --version
echo ""

echo "Docker service status:"
systemctl status docker --no-pager
echo ""

echo -e "${YELLOW}=== Container Status ===${NC}"
echo "All containers:"
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
echo ""

echo "Docker networks:"
docker network ls
echo ""

echo "Docker volumes:"
docker volume ls
echo ""

echo -e "${YELLOW}=== Deployment Directory ===${NC}"
echo "Checking deployment directories:"
ls -la /deployments/
echo ""

if [ -d "/deployments/microservices" ]; then
    echo "Microservices deployment directory:"
    ls -la /deployments/microservices/
    echo ""
    
    if [ -f "/deployments/microservices/docker-compose.yml" ]; then
        echo "Docker-compose file exists. Checking services:"
        cd /deployments/microservices
        docker-compose ps
        echo ""
    else
        echo -e "${RED}docker-compose.yml not found!${NC}"
    fi
else
    echo -e "${RED}/deployments/microservices directory not found!${NC}"
fi

echo -e "${YELLOW}=== Container Logs (Last 20 lines) ===${NC}"
containers=("sqlserver-microservices" "kafka-microservices" "auth-service" "email-service" "gateway-api")

for container in "${containers[@]}"; do
    if docker ps -a --format "{{.Names}}" | grep -q "^${container}$"; then
        echo -e "${GREEN}--- $container logs ---${NC}"
        docker logs --tail=20 $container
        echo ""
    else
        echo -e "${RED}$container not found${NC}"
    fi
done

echo -e "${YELLOW}=== Network Connectivity Tests ===${NC}"
# Test if containers can reach each other
if docker ps --format "{{.Names}}" | grep -q "auth-service"; then
    echo "Testing auth-service health:"
    docker exec auth-service curl -f http://localhost:80/health 2>/dev/null || echo "Auth service health check failed"
fi

if docker ps --format "{{.Names}}" | grep -q "email-service"; then
    echo "Testing email-service health:"
    docker exec email-service curl -f http://localhost:80/health 2>/dev/null || echo "Email service health check failed"
fi

if docker ps --format "{{.Names}}" | grep -q "gateway-api"; then
    echo "Testing gateway-api health:"
    docker exec gateway-api curl -f http://localhost:80/health 2>/dev/null || echo "Gateway API health check failed"
fi

echo ""
echo -e "${YELLOW}=== External Access Tests ===${NC}"
echo "Testing external access:"
curl -f http://localhost:5000/health 2>/dev/null && echo "Gateway API accessible" || echo "Gateway API not accessible"
curl -f http://localhost:5001/health 2>/dev/null && echo "Auth Service accessible" || echo "Auth Service not accessible"
curl -f http://localhost:5002/health 2>/dev/null && echo "Email Service accessible" || echo "Email Service not accessible"

echo ""
echo -e "${YELLOW}=== Docker Images ===${NC}"
echo "Available images:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

echo ""
echo -e "${YELLOW}=== Resource Usage ===${NC}"
echo "Docker stats (snapshot):"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

echo ""
echo -e "${YELLOW}=== Recent Docker Events ===${NC}"
echo "Recent Docker events:"
docker events --since="1h" --until="now" | tail -10

echo ""
echo -e "${GREEN}=== Debug Complete ===${NC}" 