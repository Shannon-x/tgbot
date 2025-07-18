# 环境变量迁移指南

本文档说明如何从旧的环境变量命名迁移到新的 `POLICR_MINI_` 前缀命名规范。

## 变量名映射表

| 旧变量名 | 新变量名 | 说明 |
|---------|----------|------|
| `TG_BOT_TOKEN` | `POLICR_MINI_BOT_TOKEN` | Bot Token |
| `TG_OWNER_ID` | `POLICR_MINI_BOT_OWNER_ID` | 管理员ID |
| `SECRET_KEY_BASE` | `POLICR_MINI_SERVER_SECRET_KEY_BASE` | 应用密钥 |
| `PHX_HOST` | `POLICR_MINI_SERVER_ROOT_URL` | 需要包含完整URL |
| `PORT` | `POLICR_MINI_SERVER_PORT` | 服务端口 |
| `DATABASE_URL` | `POLICR_MINI_DATABASE_URL` | 数据库连接 |
| `POOL_SIZE` | `POLICR_MINI_DATABASE_POOL_SIZE` | 连接池大小 |
| `TG_API_BASE_URL` | `POLICR_MINI_BOT_API_BASE_URL` | API地址 |

## 新增的重要变量

### Bot 配置
- `POLICR_MINI_BOT_NAME`: Bot 显示名称
- `POLICR_MINI_BOT_WORK_MODE`: 工作模式 (polling/webhook)
- `POLICR_MINI_BOT_ASSETS_PATH`: 资源文件路径

### Webhook 模式
- `POLICR_MINI_BOT_WEBHOOK_URL`: Webhook URL
- `POLICR_MINI_BOT_WEBHOOK_SERVER_PORT`: Webhook 端口

### 验证码配置
- `POLICR_MINI_BOT_GRID_CAPTCHA_INDI_WIDTH`: 网格宽度
- `POLICR_MINI_BOT_GRID_CAPTCHA_INDI_HEIGHT`: 网格高度
- `POLICR_MINI_BOT_GRID_CAPTCHA_WATERMARK_FONT_FAMILY`: 水印字体

### 功能选项
- `POLICR_MINI_BOT_AUTO_GEN_COMMANDS`: 自动生成命令
- `POLICR_MINI_BOT_MOSAIC_METHOD`: 马赛克方法
- `POLICR_MINI_UNBAN_METHOD`: 解封方法
- `POLICR_MINI_OPTS`: 其他选项

## 迁移步骤

1. **备份现有配置**
   ```bash
   cp .env .env.backup
   ```

2. **使用新的模板**
   ```bash
   cp .env.example .env
   ```

3. **填入原有配置值**
   根据上面的映射表，将原有的配置值填入新的变量名

4. **验证配置**
   ```bash
   docker compose config
   ```

5. **重启服务**
   ```bash
   docker compose down
   docker compose up -d
   ```

## 注意事项

1. **URL 格式变化**
   - 旧: `PHX_HOST=example.com`
   - 新: `POLICR_MINI_SERVER_ROOT_URL=https://example.com`

2. **数据库连接**
   - 确保 `POLICR_MINI_DATABASE_URL` 包含完整的连接字符串
   - 格式: `postgres://user:pass@host:port/dbname`

3. **向后兼容**
   - `.env.example` 中保留了部分旧变量名的映射
   - 但建议尽快迁移到新的命名规范

4. **Docker Compose 变量**
   - 一些 Docker 特定的变量（如 `POSTGRES_PASSWORD`）保持不变
   - 这些变量主要用于容器间通信