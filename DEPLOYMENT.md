# Policr Mini 部署指南

本文档提供了 Policr Mini 的详细部署说明。

## 📋 目录

- [系统要求](#系统要求)
- [Docker 部署（推荐）](#docker-部署推荐)
- [手动部署](#手动部署)
- [配置说明](#配置说明)
- [SSL/TLS 配置](#ssltls-配置)
- [监控和维护](#监控和维护)
- [故障排除](#故障排除)

## 系统要求

### 最低配置
- CPU: 1 核心
- 内存: 1GB RAM
- 存储: 10GB 可用空间
- 操作系统: Linux (Ubuntu 20.04+, Debian 10+, CentOS 8+)

### 推荐配置
- CPU: 2 核心
- 内存: 2GB RAM
- 存储: 20GB SSD
- 操作系统: Ubuntu 22.04 LTS

### 软件依赖
- Docker 20.10+ 和 Docker Compose v2+（Docker 部署）
- Elixir 1.16+ 和 Erlang/OTP 26+（手动部署）
- PostgreSQL 14+
- Redis 6+（可选）
- Nginx（反向代理，可选）

## Docker 部署（推荐）

### 1. 环境准备

```bash
# 安装 Docker
curl -fsSL https://get.docker.com | bash

# 安装 Docker Compose v2
sudo apt-get update
sudo apt-get install docker-compose-plugin

# 验证安装
docker --version
docker compose version
```

### 2. 获取代码

```bash
# 克隆仓库
git clone https://github.com/your-username/policr-mini.git
cd policr-mini

# 或者下载特定版本
wget https://github.com/your-username/policr-mini/archive/refs/tags/v1.0.0.tar.gz
tar -xzf v1.0.0.tar.gz
cd policr-mini-1.0.0
```

### 3. 配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 生成密钥
echo "SECRET_KEY_BASE=$(openssl rand -hex 64)" >> .env

# 编辑配置文件
vim .env
```

必须配置的变量：
- `POLICR_MINI_BOT_TOKEN`: 从 @BotFather 获取的 Bot Token
- `POLICR_MINI_BOT_OWNER_ID`: 您的 Telegram 用户 ID
- `POLICR_MINI_SERVER_SECRET_KEY_BASE`: 应用密钥（上面已自动生成）
- `POLICR_MINI_SERVER_ROOT_URL`: 您的域名或服务器 IP（包含协议）

### 4. 启动服务

#### 开发环境

```bash
# 启动所有服务
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# 查看日志
docker compose logs -f app

# 初始化数据库
docker compose exec app mix ecto.create
docker compose exec app mix ecto.migrate
```

#### 生产环境

```bash
# 构建生产镜像
./scripts/build.sh

# 或使用 docker compose 构建
docker compose -f docker-compose.yml -f docker-compose.production.yml build

# 启动服务
docker compose -f docker-compose.yml -f docker-compose.production.yml up -d

# 初始化数据库
docker compose exec app bin/policr_mini eval "PolicrMini.Release.migrate"
```

### 5. 配置 Nginx（可选）

如果需要使用 Nginx 作为反向代理：

```bash
# 创建 SSL 证书目录
mkdir -p ssl

# 放置 SSL 证书
cp /path/to/cert.pem ssl/
cp /path/to/key.pem ssl/

# 启动包含 Nginx 的服务
docker compose -f docker-compose.yml -f docker-compose.production.yml --profile production up -d
```

## 手动部署

### 1. 安装依赖

#### Ubuntu/Debian

```bash
# 更新系统
sudo apt-get update && sudo apt-get upgrade -y

# 安装基础依赖
sudo apt-get install -y build-essential git curl wget

# 安装 asdf 版本管理器
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.1
echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc
source ~/.bashrc

# 安装 Erlang 依赖
sudo apt-get install -y autoconf m4 libncurses5-dev libwxgtk3.0-gtk3-dev \
  libwxgtk-webview3.0-gtk3-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev \
  libssh-dev unixodbc-dev xsltproc fop libxml2-utils libncurses-dev

# 安装 Erlang 和 Elixir
asdf plugin add erlang
asdf plugin add elixir
asdf install erlang 26.2.1
asdf install elixir 1.16.0-otp-26
asdf global erlang 26.2.1
asdf global elixir 1.16.0-otp-26

# 安装 PostgreSQL
sudo apt-get install -y postgresql postgresql-contrib

# 安装 Redis（可选）
sudo apt-get install -y redis-server

# 安装 Node.js（用于前端构建）
asdf plugin add nodejs
asdf install nodejs 20.11.0
asdf global nodejs 20.11.0
```

### 2. 配置数据库

```bash
# 创建数据库用户
sudo -u postgres psql -c "CREATE USER policr_mini WITH PASSWORD 'your_password';"
sudo -u postgres psql -c "CREATE DATABASE policr_mini_prod OWNER policr_mini;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE policr_mini_prod TO policr_mini;"
```

### 3. 配置应用

```bash
# 克隆代码
git clone https://github.com/your-username/policr-mini.git
cd policr-mini

# 安装依赖
mix deps.get --only prod

# 编译项目
MIX_ENV=prod mix compile

# 安装前端依赖并构建
cd assets && npm install && npm run deploy && cd ..
cd webapps && npm install && npm run build && cd ..

# 创建静态资源
MIX_ENV=prod mix phx.digest

# 运行数据库迁移
MIX_ENV=prod mix ecto.migrate
```

### 4. 创建 systemd 服务

创建文件 `/etc/systemd/system/policr-mini.service`:

```ini
[Unit]
Description=Policr Mini Bot
After=network.target postgresql.service

[Service]
Type=simple
User=policr
Group=policr
WorkingDirectory=/home/policr/policr-mini
Environment="MIX_ENV=prod"
Environment="PORT=4000"
Environment="LANG=en_US.UTF-8"
EnvironmentFile=/home/policr/policr-mini/.env
ExecStart=/usr/local/bin/mix phx.server
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

启动服务：

```bash
# 重载 systemd 配置
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start policr-mini

# 设置开机自启
sudo systemctl enable policr-mini

# 查看状态
sudo systemctl status policr-mini
```

## 配置说明

### 环境变量详解

查看 `.env.example` 文件了解所有可用的配置选项。主要配置包括：

#### 核心配置
- `POLICR_MINI_BOT_TOKEN`: Bot Token（必需）
- `POLICR_MINI_BOT_OWNER_ID`: 管理员 ID（必需）
- `POLICR_MINI_SERVER_SECRET_KEY_BASE`: 应用密钥（必需）
- `POLICR_MINI_SERVER_ROOT_URL`: 服务根URL（必需）

#### 数据库配置
- `POLICR_MINI_DATABASE_URL`: 完整的数据库连接URL
- `POLICR_MINI_DATABASE_POOL_SIZE`: 连接池大小
- `POSTGRES_PASSWORD`: PostgreSQL密码（Docker使用）

#### 机器人配置
- `POLICR_MINI_BOT_WORK_MODE`: 工作模式（polling/webhook）
- `POLICR_MINI_BOT_WEBHOOK_URL`: Webhook URL（webhook模式需要）
- `POLICR_MINI_BOT_WEBHOOK_SERVER_PORT`: Webhook服务端口
- `POLICR_MINI_BOT_API_BASE_URL`: Telegram API地址

### 功能开关

可以通过环境变量控制功能的启用/禁用：

- `ENABLE_ANTI_SPAM`: 反垃圾功能
- `ENABLE_WELCOME_MESSAGE`: 欢迎消息功能
- `ENABLE_ADMIN_COMMANDS`: 管理命令功能

## SSL/TLS 配置

### 使用 Let's Encrypt

```bash
# 安装 Certbot
sudo apt-get install certbot

# 获取证书
sudo certbot certonly --standalone -d your-domain.com

# 复制证书到项目目录
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ssl/key.pem
sudo chown $USER:$USER ssl/*

# 设置自动续期
sudo certbot renew --dry-run
```

### 配置 Nginx SSL

更新 `nginx.conf` 中的域名和证书路径，然后重启服务。

## 监控和维护

### 健康检查

```bash
# 检查应用健康状态
curl http://localhost:4000/health

# 检查数据库连接
docker compose exec postgres pg_isready

# 检查 Redis 连接
docker compose exec redis redis-cli ping
```

### 日志管理

```bash
# 查看应用日志
docker compose logs -f app

# 查看所有服务日志
docker compose logs -f

# 导出日志
docker compose logs > logs_$(date +%Y%m%d).txt
```

### 备份和恢复

#### 自动备份

启用备份服务：

```bash
docker compose -f docker-compose.yml -f docker-compose.production.yml --profile backup up -d
```

#### 手动备份

```bash
# 备份数据库
docker compose exec postgres pg_dump -U postgres policr_mini > backup_$(date +%Y%m%d).sql

# 恢复数据库
docker compose exec -T postgres psql -U postgres policr_mini < backup_20240118.sql
```

### 监控（可选）

启用 Prometheus 和 Grafana：

```bash
# 创建监控配置
cat > prometheus.yml <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'policr-mini'
    static_configs:
      - targets: ['app:4000']
EOF

# 启动监控服务
docker compose -f docker-compose.yml -f docker-compose.production.yml --profile monitoring up -d

# 访问监控界面
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000 (admin/admin)
```

## 故障排除

### 常见问题

#### 1. Bot 无响应

检查 Bot Token 是否正确：
```bash
docker compose exec app bin/policr_mini remote
# 在 Elixir shell 中执行
Application.get_env(:policr_mini, :token)
```

#### 2. 数据库连接失败

检查数据库配置和连接：
```bash
# 测试数据库连接
docker compose exec app mix ecto.migrate

# 检查数据库日志
docker compose logs postgres
```

#### 3. 权限设置失败

确保 Bot 在群组中有管理员权限：
- 限制用户（Ban users）
- 删除消息（Delete messages）
- 邀请用户（Invite users）

#### 4. 内存使用过高

调整 Erlang VM 参数：
```bash
# 在 .env 中添加
ERL_FLAGS="+P 1000000 +Q 1000000"
```

### 调试模式

开启详细日志：
```bash
# 设置日志级别为 debug
LOG_LEVEL=debug docker compose up
```

### 性能优化建议

1. **数据库优化**
   - 定期执行 `VACUUM` 和 `ANALYZE`
   - 调整 PostgreSQL 配置参数

2. **Redis 优化**
   - 配置适当的 maxmemory 策略
   - 使用持久化避免数据丢失

3. **应用优化**
   - 调整连接池大小
   - 配置适当的并发限制

## 更新升级

### Docker 部署更新

```bash
# 拉取最新代码
git pull origin main

# 重新构建镜像
./scripts/build.sh

# 重启服务
docker compose -f docker-compose.yml -f docker-compose.production.yml up -d

# 运行数据库迁移
docker compose exec app bin/policr_mini eval "PolicrMini.Release.migrate"
```

### 手动部署更新

```bash
# 停止服务
sudo systemctl stop policr-mini

# 拉取最新代码
git pull origin main

# 更新依赖
mix deps.get --only prod

# 重新编译
MIX_ENV=prod mix compile

# 构建前端
cd assets && npm install && npm run deploy && cd ..

# 运行迁移
MIX_ENV=prod mix ecto.migrate

# 重启服务
sudo systemctl start policr-mini
```

## 安全建议

1. **定期更新**：及时安装系统和依赖的安全更新
2. **访问控制**：限制数据库和 Redis 的访问
3. **备份策略**：定期备份数据并测试恢复流程
4. **监控告警**：设置异常情况的告警通知
5. **日志审计**：定期检查日志中的异常活动

---

如需更多帮助，请查看项目 [README](README.md) 或提交 Issue。