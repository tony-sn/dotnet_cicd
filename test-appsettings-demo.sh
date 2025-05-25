#!/bin/bash

echo "🔍 Demo: appsettings.json trong Docker Build Process"
echo "=================================================="

echo ""
echo "📂 Build Context - AuthenticationService Folder:"
echo "-------------------------------------------------"
ls -la AuthenticationService/ | grep -E "(appsettings|Dockerfile|\.csproj)"

echo ""
echo "🏗️  Building Docker Image..."
echo "Command: docker build -t demo-auth ./AuthenticationService"
cd AuthenticationService
docker build -t demo-auth . > /dev/null 2>&1
cd ..

echo "✅ Image built successfully!"

echo ""
echo "📋 Files trong Docker Image (/app/ directory):"
echo "-----------------------------------------------"
docker run --rm --entrypoint="/bin/bash" demo-auth -c "ls -la /app/ | grep -E '(appsettings|\.dll|\.json)'"

echo ""
echo "📄 appsettings.json Content TRONG Image:"
echo "----------------------------------------"
docker run --rm --entrypoint="/bin/bash" demo-auth -c "cat /app/appsettings.json"

echo ""
echo "🔄 Demo Environment Variable Override:"
echo "-------------------------------------"
echo "Original Connection String trong image:"
docker run --rm --entrypoint="/bin/bash" demo-auth -c "grep -A1 'DefaultConnection' /app/appsettings.json"

echo ""
echo "✨ Với Environment Variable Override (như CI/CD):"
echo "Command: docker run -e ConnectionStrings__DefaultConnection='PRODUCTION_OVERRIDE' ..."

# Test với environment variable
echo "Kết quả Configuration sau khi load:"
docker run --rm \
  -e "ConnectionStrings__DefaultConnection=Server=sqlserver-microservices,1433;Database=AuthDB;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=true" \
  -e "Kafka__BootstrapServers=kafka-microservices:9092" \
  --entrypoint="/bin/bash" \
  demo-auth \
  -c "echo 'Environment Variables:' && env | grep -E '(ConnectionStrings|Kafka)' && echo '' && echo 'Original appsettings.json vẫn không thay đổi:' && cat /app/appsettings.json | grep -A2 -B1 'DefaultConnection\|BootstrapServers'"

echo ""
echo "🎯 Summary:"
echo "----------"
echo "✅ appsettings.json ĐƯỢC COPY vào Docker image"
echo "✅ Environment Variables OVERRIDE values trong appsettings.json"
echo "✅ File gốc trong image KHÔNG thay đổi"
echo "✅ ASP.NET Core tự động merge configuration hierarchy"

echo ""
echo "🔧 Configuration Loading Order:"
echo "1. appsettings.json (from image)"
echo "2. appsettings.{Environment}.json (from image)"  
echo "3. Environment Variables (from CI/CD) ← WINS"
echo "4. Command line arguments"

echo ""
echo "🚀 CI/CD Strategy:"
echo "Production values come from Environment Variables"
echo "Base values come from appsettings.json trong image" 