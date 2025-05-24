#!/bin/bash

echo "=== Server Setup Script ==="

# Update system packages
echo "Updating system packages..."
apt update && apt upgrade -y

# Install curl if not present
apt install -y curl

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing Docker..."
    
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    
    # Add current user to docker group
    usermod -aG docker $USER
    
    # Start and enable Docker service
    systemctl start docker
    systemctl enable docker
    
    echo "Docker installed successfully"
else
    echo "Docker is already installed"
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose not found. Installing Docker Compose..."
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    echo "Docker Compose installed successfully"
else
    echo "Docker Compose is already installed"
fi

# Create deployment directories
mkdir -p /deployments/microservices
mkdir -p /deployments/main
mkdir -p /deployments/staging

# Install useful tools
apt install -y htop git nano vim

echo "=== Server Setup Complete ==="
echo "Docker version: $(docker --version)"
echo "Docker Compose version: $(docker-compose --version)"
echo ""
echo "Note: If you just installed Docker, please log out and log back in for group changes to take effect." 