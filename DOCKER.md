# Docker 配置说明

本项目的 Docker 配置已经过优化和统一，使用了清晰的分层结构。

## 文件结构

```
.
├── Dockerfile                    # 统一的多阶段构建文件
├── docker-compose.yml           # 基础服务配置
├── docker-compose.dev.yml       # 开发环境特定配置
├── docker-compose.production.yml # 生产环境特定配置
├── .env.example                 # 环境变量模板
├── .dockerignore               # Docker 构建忽略规则
├── nginx.conf                  # Nginx 反向代理配置
└── scripts/
    └── build.sh                # 镜像构建脚本
```

## 快速开始

### 1. 准备环境变量

```bash
cp .env.example .env
# 编辑 .env 文件，填写必要的配置
```

### 2. 启动服务

**开发环境：**
```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

**生产环境：**
```bash
docker compose -f docker-compose.yml -f docker-compose.production.yml up -d
```

### 3. 使用 profiles

某些可选服务使用了 Docker Compose profiles：

```bash
# 启动生产环境 + Nginx
docker compose -f docker-compose.yml -f docker-compose.production.yml --profile production up -d

# 启动生产环境 + 监控
docker compose -f docker-compose.yml -f docker-compose.production.yml --profile monitoring up -d

# 启动生产环境 + 备份
docker compose -f docker-compose.yml -f docker-compose.production.yml --profile backup up -d
```

## 镜像构建

### 使用构建脚本

```bash
# 构建本地镜像
./scripts/build.sh

# 构建并推送到 Registry
REGISTRY=your-registry.com VERSION=1.0.0 ./scripts/build.sh

# 构建多架构镜像（支持 amd64 和 arm64）
BUILD_MULTIARCH=true REGISTRY=your-registry.com ./scripts/build.sh
```

### 手动构建

```bash
# 开发环境构建
docker compose -f docker-compose.yml -f docker-compose.dev.yml build

# 生产环境构建
docker compose -f docker-compose.yml -f docker-compose.production.yml build
```

## 服务说明

### 核心服务

- **app**: Policr Mini 应用主服务
- **postgres**: PostgreSQL 数据库
- **redis**: Redis 缓存（用于会话和临时数据）

### 开发环境服务

- **influxdb**: 时序数据库（用于指标收集）
- **telegram-bot-api**: 本地 Bot API Server（可选）
- **mailhog**: 邮件测试服务（可选）

### 生产环境服务

- **nginx**: 反向代理和 SSL 终端（profile: production）
- **backup**: 自动备份服务（profile: backup）
- **prometheus**: 监控数据收集（profile: monitoring）
- **grafana**: 监控可视化（profile: monitoring）

## 启用 Redis

Redis 是可选服务，用于缓存和会话存储。要启用 Redis：

**方法 1：使用 profile**
```bash
# 在 .env 中设置
ENABLE_REDIS=true

# 启动时包含 redis profile
docker compose --profile redis up -d
```

**方法 2：使用额外的 compose 文件**
```bash
# 启动服务时包含 Redis 配置
docker compose -f docker-compose.yml -f docker-compose.redis.yml up -d
```

**方法 3：修改 docker-compose.yml**
删除 redis 服务中的 `profiles` 部分，使其默认启动。

### Redis 配置选项

```bash
# 基本配置
REDIS_HOST=redis           # Redis 主机地址
REDIS_PORT=6379           # Redis 端口
REDIS_DB=0                # 数据库编号
REDIS_PASSWORD=yourpass   # 设置密码（推荐生产环境使用）

## 启用 InfluxDB

InfluxDB 用于时序数据存储和监控。要启用 InfluxDB：

```bash
# 在 .env 中设置
ENABLE_INFLUXDB=true
INFLUXDB_HOST=influxdb
INFLUXDB_PORT=8086
INFLUXDB_PROTOCOL=http
POLICR_MINI_INFLUX_TOKEN=your_token
POLICR_MINI_INFLUX_BUCKET=policr_mini_prod
POLICR_MINI_INFLUX_ORG=policr_mini
```

## 环境变量说明

详见 `.env.example` 文件，主要包括：

- **核心配置**: Bot Token、管理员 ID、密钥等
- **数据库配置**: 分离的连接参数（主机、端口、用户名、密码）
- **Redis 配置**: 分离的连接参数
- **性能配置**: 并发数、速率限制等
- **功能开关**: 各功能模块的启用/禁用

## 常用命令

```bash
# 查看日志
docker compose logs -f app

# 进入应用容器
docker compose exec app sh

# 运行 Elixir 控制台
docker compose exec app bin/policr_mini remote

# 数据库备份
docker compose exec postgres pg_dump -U postgres policr_mini > backup.sql

# 清理所有容器和卷（危险操作）
docker compose down -v
```

## 故障排除

1. **端口冲突**: 检查 .env 中的端口配置
2. **权限问题**: 确保目录权限正确
3. **构建失败**: 清理 Docker 缓存后重试
4. **内存不足**: 调整 Docker 资源限制

更多详细信息请参考：
- [DEPLOYMENT.md](DEPLOYMENT.md) - 完整部署指南
- [ENV_MIGRATION.md](ENV_MIGRATION.md) - 环境变量迁移指南