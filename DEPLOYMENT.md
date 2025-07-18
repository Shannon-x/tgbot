# 详细部署教程

## 🛠️ 部署指南

### 1. 创建 Telegram Bot

1. 在 Telegram 中找到 [@BotFather](https://t.me/botfather)
2. 发送 `/newbot` 创建新机器人
3. 设置机器人名称和用户名
4. 保存获得的 Bot Token
5. 发送 `/setjoingroups` 并选择 Enable
6. 发送 `/setprivacy` 并选择 Disable（重要！）

### 2. Docker Compose 部署

创建 `docker-compose.yml` 文件：

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: policr_postgres
    environment:
      POSTGRES_DB: policr_mini
      POSTGRES_USER: policr_mini
      POSTGRES_PASSWORD: your_secure_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  app:
    image: hentioe/policr-mini:latest
    container_name: policr_mini
    depends_on:
      - postgres
    env_file:
      - prod.env
    ports:
      - "4000:4000"
    restart: unless-stopped
    command: sh -c "mix ecto.migrate && mix phx.server"

volumes:
  postgres_data:
```

### 3. 手动部署

#### 安装依赖

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y git build-essential autoconf m4 libncurses5-dev libssl-dev

# 安装 ASDF 版本管理器
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.1
echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc
source ~/.bashrc

# 安装 Erlang 和 Elixir
asdf plugin add erlang
asdf plugin add elixir
asdf install erlang 25.3.2
asdf install elixir 1.14.5-otp-25
asdf global erlang 25.3.2
asdf global elixir 1.14.5-otp-25
```

#### 安装 PostgreSQL

```bash
sudo apt install -y postgresql postgresql-contrib
sudo -u postgres createuser -P policr_mini
sudo -u postgres createdb -O policr_mini policr_mini
```

#### 构建和启动

```bash
# 克隆项目
git clone https://github.com/Hentioe/policr-mini.git
cd policr-mini

# 安装依赖
mix deps.get

# 编译项目
MIX_ENV=prod mix compile

# 创建数据库
MIX_ENV=prod mix ecto.create
MIX_ENV=prod mix ecto.migrate

# 启动服务
MIX_ENV=prod mix phx.server
```

### 4. 环境变量详解

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `TG_BOT_TOKEN` | Telegram Bot Token | `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11` |
| `TG_OWNER_ID` | 管理员 Telegram ID | `123456789` |
| `DB_HOST` | 数据库主机 | `localhost` 或 `postgres` |
| `DB_PORT` | 数据库端口 | `5432` |
| `DB_NAME` | 数据库名称 | `policr_mini` |
| `DB_USER` | 数据库用户 | `policr_mini` |
| `DB_PASS` | 数据库密码 | `your_secure_password` |
| `WEB_HOST` | Web 服务监听地址 | `0.0.0.0` |
| `WEB_PORT` | Web 服务端口 | `4000` |
| `SECRET_KEY_BASE` | 会话密钥（64字符） | 使用 `mix phx.gen.secret` 生成 |

### 5. Nginx 反向代理（可选）

如果需要使用域名访问，可以配置 Nginx：

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 6. 系统服务配置（systemd）

创建 `/etc/systemd/system/policr-mini.service`：

```ini
[Unit]
Description=Policr Mini Bot
After=network.target postgresql.service

[Service]
Type=simple
User=policr
Group=policr
WorkingDirectory=/opt/policr-mini
Environment="MIX_ENV=prod"
Environment="PORT=4000"
ExecStart=/usr/bin/mix phx.server
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

启用并启动服务：

```bash
sudo systemctl enable policr-mini
sudo systemctl start policr-mini
sudo systemctl status policr-mini
```