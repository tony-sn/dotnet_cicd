# Microservices CI/CD Project

## Tổng quan

Project này bao gồm 3 microservices chính:
- **GatewayAPI**: API Gateway sử dụng YARP Reverse Proxy
- **AuthenticationService**: Service xử lý authentication với Entity Framework Core và SQL Server
- **EmailService**: Service gửi email với Kafka consumer

## Kiến trúc

```
┌─────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│   Gateway API   │───▶│ Authentication Service │───▶│   SQL Server 2022   │
│    (Port 5000)  │    │     (Port 5001)       │    │    (Port 1433)      │
└─────────────────┘    └──────────────────────┘    └─────────────────────┘
         │                        │
         │                        │ Kafka Producer
         ▼                        ▼
┌─────────────────┐    ┌──────────────────────┐
│  Email Service  │◀───│   Kafka (KRaft)     │
│   (Port 5002)   │    │    (Port 9092)      │
└─────────────────┘    └──────────────────────┘
```

## Thiết lập GitHub Secrets

Trước khi chạy CI/CD, bạn cần thiết lập các secrets sau trong GitHub repository:

1. Vào **Settings** → **Secrets and variables** → **Actions**
2. Tạo các **Repository secrets** sau:

| Secret Name | Value | Mô tả |
|-------------|-------|-------|
| `DIGITALOCEAN_HOST` | `159.223.68.114` | IP server của bạn |
| `DIGITALOCEAN_USERNAME` | `root` | Username để SSH |
| `DIGITALOCEAN_PASSWORD` | `pHuong@123dotnet` | Password SSH |

## Thiết lập Server

### Cách 1: Sử dụng script tự động

```bash
# Chạy script setup trên server
wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/scripts/setup-server.sh
chmod +x setup-server.sh
sudo ./setup-server.sh
```

### Cách 2: Thiết lập thủ công

```bash
# Cập nhật hệ thống
sudo apt update && sudo apt upgrade -y

# Cài đặt Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Cài đặt Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Tạo thư mục deployment
sudo mkdir -p /deployments/microservices
sudo chown -R $USER:$USER /deployments
```

## CI/CD Workflows

### 1. Main Branch CI/CD (`main-cicd.yml`)

**Trigger**: Khi có push hoặc merge PR vào branch `main`

**Các bước**:
1. Build và test tất cả services
2. Build và push Docker images lên GitHub Container Registry
3. Deploy lên server production với:
   - Tạo network `microservices-network` nếu chưa có
   - Deploy SQL Server 2022
   - Deploy Kafka (KRaft mode - không cần Zookeeper)
   - Tạo Kafka topic `user-registered`
   - Deploy tất cả microservices
   - Chạy health checks

**Ports sử dụng (Production)**:
- Gateway API: `5000`
- Auth Service: `5001`  
- Email Service: `5002`
- SQL Server: `1433`
- Kafka: `9092`

### 2. Manual Deployment (`manual-deploy.yml`)

**Trigger**: Workflow dispatch (chạy thủ công)

**Tùy chọn**:
- Environment: `staging` hoặc `production`

**Đặc điểm**:
- Staging sử dụng ports khác nhau để tránh conflict
- Mỗi branch có containers riêng biệt
- Có thể deploy nhiều versions song song

**Ports sử dụng (Staging)**:
- Gateway API: `6000`
- Auth Service: `6001`
- Email Service: `6002`
- SQL Server: `1434`
- Kafka: `9093`

## Cách sử dụng

### 1. Development Local

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd dotnet_cicd

# Chạy từng service (cần .NET 9.0)
dotnet run --project AuthenticationService
dotnet run --project EmailService  
dotnet run --project GatewayAPI
```

### 2. Docker Compose Local

```bash
# Build images
docker-compose build

# Chạy tất cả services
docker-compose up -d

# Kiểm tra logs
docker-compose logs -f
```

### 3. Production Deployment

**Tự động (Recommended)**:
- Push code lên branch `main` → Tự động deploy

**Thủ công**:
- Vào GitHub Actions → Chọn "Manual Branch Deployment" → Run workflow

## Health Checks

Sau khi deploy, bạn có thể kiểm tra health của các services:

```bash
# Gateway API
curl http://159.223.68.114:5000/health

# Auth Service  
curl http://159.223.68.114:5001/health

# Email Service
curl http://159.223.68.114:5002/health
```

## API Endpoints

### Gateway API (Port 5000)
- `GET /health` - Health check
- `POST /api/auth/register` - User registration (proxy to Auth Service)
- `POST /api/email/welcome` - Send welcome email (proxy to Email Service)

### Auth Service (Port 5001)
- `GET /health` - Health check  
- `POST /api/auth/register` - User registration

### Email Service (Port 5002)
- `GET /health` - Health check
- `POST /api/email/welcome` - Send welcome email

## Database & Messaging

### SQL Server
- **Host**: `159.223.68.114:1433`
- **Database**: `AuthDB`
- **User**: `sa`
- **Password**: `YourStrong@Passw0rd`

### Kafka (KRaft Mode)
- **Bootstrap Server**: `159.223.68.114:9092`
- **Topic**: `user-registered`
- **Mode**: KRaft (không cần Zookeeper)

## Troubleshooting

### 1. Kiểm tra container status
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### 2. Xem logs
```bash
# Tất cả services
docker-compose logs -f

# Service cụ thể
docker logs auth-service
docker logs email-service
docker logs gateway-api
docker logs kafka-microservices
```

### 3. Kiểm tra network
```bash
docker network ls
docker network inspect microservices-network
```

### 4. Restart services
```bash
cd /deployments/microservices
docker-compose restart
```

### 5. Rebuild và redeploy
```bash
cd /deployments/microservices
docker-compose down
docker-compose pull
docker-compose up -d
```

### 6. Kiểm tra Kafka topics
```bash
# List topics
docker exec kafka-microservices kafka-topics --list --bootstrap-server localhost:9092

# Describe topic
docker exec kafka-microservices kafka-topics --describe --topic user-registered --bootstrap-server localhost:9092

# Test producer
docker exec kafka-microservices kafka-console-producer --topic user-registered --bootstrap-server localhost:9092

# Test consumer
docker exec kafka-microservices kafka-console-consumer --topic user-registered --bootstrap-server localhost:9092 --from-beginning
```

## Monitoring

### Container Stats
```bash
docker stats
```

### Disk Usage
```bash
docker system df
docker system prune -f  # Cleanup unused resources
```

### Network Connectivity
```bash
# Test inter-service communication
docker exec gateway-api curl http://auth-service:80/health
docker exec auth-service curl http://email-service:80/health
```

## Security Notes

- Passwords trong production nên sử dụng environment variables
- Nên enable HTTPS cho production
- Cân nhắc sử dụng Docker secrets cho sensitive data
- Firewall chỉ mở các ports cần thiết

## Technology Stack

- **.NET 9.0** - Application framework
- **Entity Framework Core** - ORM
- **SQL Server 2022** - Database
- **Apache Kafka (KRaft)** - Message broker (standalone mode)
- **YARP** - Reverse proxy
- **Docker & Docker Compose** - Containerization
- **GitHub Actions** - CI/CD pipeline
- **GitHub Container Registry** - Docker image registry

## Kafka KRaft Mode

Project này sử dụng Kafka KRaft mode (Kafka Raft), đây là architecture mới của Kafka từ phiên bản 2.8+ không cần Zookeeper:

### Ưu điểm:
- **Đơn giản hóa deployment**: Chỉ cần 1 container thay vì 2 (Kafka + Zookeeper)
- **Hiệu suất tốt hơn**: Ít overhead, khởi động nhanh hơn
- **Quản lý dễ dàng**: Ít components cần monitor và maintain

### Cấu hình KRaft:
```yaml
environment:
  KAFKA_NODE_ID: 1
  KAFKA_PROCESS_ROLES: broker,controller
  KAFKA_CONTROLLER_QUORUM_VOTERS: 1@kafka:29093
  KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
  KAFKA_LISTENERS: PLAINTEXT://kafka:9092,CONTROLLER://kafka:29093
  KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
```

## Contributing

1. Fork repository
2. Tạo feature branch: `git checkout -b feature/new-feature`
3. Commit changes: `git commit -am 'Add new feature'`
4. Push branch: `git push origin feature/new-feature`
5. Tạo Pull Request

## License

This project is licensed under the MIT License. 