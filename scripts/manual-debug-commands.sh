#!/bin/bash

echo "=== Manual Debug Commands for Server ==="
echo "Copy and run these commands on your server (159.223.68.114)"
echo ""
echo "1. Connect to your server first:"
echo "   ssh root@159.223.68.114"
echo "   (enter password: pHuong@123dotnet)"
echo ""

cat << 'EOF'
# ========================================
# Run these commands on the server:
# ========================================

echo "=== System Information ==="
cat /etc/os-release | head -3
echo ""
free -h
echo ""
df -h /
echo ""

echo "=== Docker Status ==="
docker --version 2>/dev/null || echo "Docker not installed"
docker-compose --version 2>/dev/null || echo "Docker-compose not installed"
systemctl is-active docker
echo ""

echo "=== Container Status ==="
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
echo ""

echo "=== Networks and Volumes ==="
docker network ls
echo ""
docker volume ls
echo ""

echo "=== Deployment Directory ==="
ls -la /deployments/
echo ""

if [ -d "/deployments/microservices" ]; then
    echo "Microservices directory contents:"
    ls -la /deployments/microservices/
    echo ""
    
    if [ -f "/deployments/microservices/docker-compose.yml" ]; then
        echo "Docker-compose file content:"
        cat /deployments/microservices/docker-compose.yml
        echo ""
        
        echo "Services status:"
        cd /deployments/microservices
        docker-compose ps
    fi
fi

echo "=== Container Logs ==="
containers=("sqlserver-microservices" "kafka-microservices" "auth-service" "email-service" "gateway-api" "kafka-init")

for container in "${containers[@]}"; do
    if docker ps -a --format "{{.Names}}" | grep -q "^${container}$"; then
        echo "--- $container logs ---"
        docker logs --tail=15 $container
        echo ""
    fi
done

echo "=== Network Tests ==="
curl -f http://localhost:5000/health 2>/dev/null && echo "Gateway API: OK" || echo "Gateway API: FAILED"
curl -f http://localhost:5001/health 2>/dev/null && echo "Auth Service: OK" || echo "Auth Service: FAILED"
curl -f http://localhost:5002/health 2>/dev/null && echo "Email Service: OK" || echo "Email Service: FAILED"

echo "=== Listening Ports ==="
netstat -tlnp | grep -E ':(5000|5001|5002|1433|9092)'

echo "=== Docker Images ==="
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# ========================================
# Common Fix Commands:
# ========================================

echo ""
echo "=== If containers are not running, try these: ==="
echo "cd /deployments/microservices"
echo "docker-compose down"
echo "docker-compose pull"
echo "docker-compose up -d"
echo ""

echo "=== To restart specific services: ==="
echo "docker-compose restart auth-service"
echo "docker-compose restart email-service"
echo "docker-compose restart gateway-api"
echo ""

echo "=== To check individual service logs: ==="
echo "docker logs auth-service -f"
echo "docker logs email-service -f"
echo "docker logs gateway-api -f"
echo "docker logs kafka-microservices -f"

EOF

echo ""
echo "=========================================="
echo "QUICK CONNECT AND DEBUG:"
echo "=========================================="
echo ""
echo "To connect and debug in one go, run this:"
echo ""
echo 'ssh root@159.223.68.114 "docker ps -a && echo '\''=== LOGS ==='\'' && cd /deployments/microservices 2>/dev/null && docker-compose ps 2>/dev/null"'
echo ""
echo "Or for detailed logs:"
echo ""
echo 'ssh root@159.223.68.114 "docker logs auth-service --tail=20 2>/dev/null; docker logs email-service --tail=20 2>/dev/null; docker logs gateway-api --tail=20 2>/dev/null"' 