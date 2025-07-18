# Policr Mini - 智能 Telegram 群组验证机器人

[![status-badge](https://arm-ci.hentioe.dev/api/badges/1/status.svg)](https://arm-ci.hentioe.dev/repos/1)
[![GitHub issues](https://img.shields.io/github/issues/Hentioe/policr-mini)](https://github.com/Hentioe/policr-mini/issues)
![Languages top](https://img.shields.io/github/languages/top/Hentioe/policr-mini)
![GitHub](https://img.shields.io/github/license/Hentioe/policr-mini)

[加入群组](https://t.me/policr_community) | [更新频道](https://t.me/policr_changelog) | [官方机器人](https://t.me/policr_mini_bot) | [赞助项目](https://mini.gramlabs.org/?sponsorship)

## 🚀 简介

Policr Mini 是一个功能强大的 Telegram 群组管理机器人，专注于提供智能的新成员验证和群组管理功能。它可以有效防止垃圾用户和机器人账号的入侵，保护您的群组安全。

### 核心特性

- **🛡️ 智能验证系统**
  - 多种验证模式：图片验证、算术验证、自定义问答
  - 支持加入请求和直接加入两种方式
  - 验证失败自动重试机制
  - 权限问题自动修复

- **🚫 反垃圾消息**
  - 实时检测刷屏行为
  - 重复消息自动识别
  - 可配置的处理方式（禁言/踢出/封禁）
  - 智能时间窗口分析

- **👋 欢迎消息定制**
  - 支持富文本格式（HTML/Markdown）
  - 可添加自定义按钮
  - 支持图片和变量替换
  - 消息自动删除功能

- **⚡ 管理命令**
  - `/ban` - 封禁用户
  - `/mute` - 禁言用户
  - `/unmute` - 解除禁言
  - `/kick` - 踢出用户
  - 支持时长设置（5m/2h/1d）

- **📊 Web 控制台**
  - 实时数据统计
  - 验证历史查询
  - 群组设置管理
  - 移动端友好界面

## 🎯 适用场景

- 大型公开群组的成员管理
- 社区群组的垃圾信息防护
- 私密群组的成员审核
- 商业群组的用户验证

## 📋 系统要求

- Elixir 1.14+ 
- Erlang/OTP 25+
- PostgreSQL 13+
- Redis 6+ (可选，用于缓存)
- Docker & Docker Compose (推荐)

## 🚀 快速开始

### 方式一：使用官方机器人

1. 将 [@policr_mini_bot](https://t.me/policr_mini_bot) 添加到您的群组
2. 将机器人设置为管理员，并赋予以下权限：
   - 删除消息
   - 封禁用户
   - 邀请用户（可选，用于解封）
3. 机器人会自动开始工作

### 方式二：Docker 部署（推荐）

1. 克隆项目
```bash
git clone https://github.com/Hentioe/policr-mini.git
cd policr-mini
```

2. 复制环境配置文件
```bash
cp dev.env.example prod.env
```

3. 编辑 `prod.env` 文件，设置必要的环境变量：
```env
# Telegram Bot Token
TG_BOT_TOKEN=your_bot_token_here

# 数据库配置
DB_HOST=postgres
DB_PORT=5432
DB_NAME=policr_mini
DB_USER=policr_mini
DB_PASS=your_secure_password

# 管理员用户 ID（从 @userinfobot 获取）
TG_OWNER_ID=your_telegram_id

# Web 界面配置
WEB_HOST=0.0.0.0
WEB_PORT=4000
SECRET_KEY_BASE=your_64_char_secret_key
```

4. 启动服务
```bash
docker-compose up -d
```

5. 访问 Web 控制台
- 地址：`http://your-server-ip:4000`
- 使用 `/login` 命令在机器人私聊中获取登录链接

## 📚 使用指南

### 机器人命令

| 命令 | 说明 | 权限 |
|------|------|-------|
| `/start` | 启动机器人 | 所有用户 |
| `/ping` | 检查机器人状态 | 所有用户 |
| `/login` | 获取 Web 控制台登录链接 | 群管理员 |
| `/sync` | 同步群组信息 | 群管理员 |
| `/ban @user [time]` | 封禁用户 | 群管理员 |
| `/mute @user [time]` | 禁言用户 | 群管理员 |
| `/unmute @user` | 解除禁言 | 群管理员 |
| `/kick @user` | 踢出用户 | 群管理员 |

### 验证方式配置

1. **图片验证**（默认）
   - 用户需要从多张图片中选择正确的答案
   - 适合大多数群组

2. **算术验证**
   - 简单的加法计算
   - 适合快速验证

3. **自定义问答**
   - 管理员可以设置自定义问题和答案
   - 适合特定主题群组

### 反垃圾配置

通过 Web 控制台配置：

- **检测时间窗口**：60 秒（默认）
- **最大消息数**：10 条
- **最大重复消息**：3 条
- **处理方式**：禁言/踢出/封禁

### 欢迎消息变量

| 变量 | 说明 | 示例 |
|------|------|------|
| `{user_id}` | 用户 ID | `123456789` |
| `{username}` | 用户名 | `@example_user` |
| `{first_name}` | 名字 | `John` |
| `{last_name}` | 姓氏 | `Doe` |
| `{full_name}` | 全名 | `John Doe` |
| `{mention}` | 提及用户 | `<a href="tg://user?id=123">John Doe</a>` |

## 🔧 配置说明

### 数据库迁移

运行以下命令执行数据库迁移：

```bash
# Docker 环境
docker-compose exec app mix ecto.migrate

# 手动部署
MIX_ENV=prod mix ecto.migrate
```

### 备份与恢复

```bash
# 备份数据库
docker-compose exec postgres pg_dump -U policr_mini policr_mini > backup.sql

# 恢复数据库
docker-compose exec -T postgres psql -U policr_mini policr_mini < backup.sql
```

## 📊 监控和日志

### 查看日志

```bash
# Docker 日志
docker-compose logs -f app

# systemd 日志
journalctl -u policr-mini -f
```

### 性能监控

项目内置了 Telemetry 支持，可以通过以下方式查看：

- 访问 `http://your-server:4000/dashboard` （需要登录）
- 使用 Prometheus + Grafana 进行监控

## 🌐 API 文档

### 认证

所有 API 请求需要在 Header 中包含：

```
Authorization: Bearer YOUR_TOKEN
```

### 主要端点

- `GET /admin/api/chats` - 获取群组列表
- `GET /admin/api/chats/:id/scheme` - 获取群组方案
- `PUT /admin/api/chats/:id/scheme` - 更新群组方案
- `GET /admin/api/chats/:id/anti_spam_config` - 获取反垃圾配置
- `PUT /admin/api/chats/:id/anti_spam_config` - 更新反垃圾配置
- `GET /admin/api/chats/:id/welcome_message` - 获取欢迎消息
- `PUT /admin/api/chats/:id/welcome_message` - 更新欢迎消息

## 🤝 贡献指南

欢迎贡献代码！请遵循以下步骤：

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

### 开发环境设置

```bash
# 安装依赖
mix deps.get
cd assets && npm install

# 启动开发服务器
mix phx.server
```

## 📧 联系方式

- **Telegram 群组**: [@policr_community](https://t.me/policr_community)
- **更新频道**: [@policr_changelog](https://t.me/policr_changelog)
- **问题反馈**: [GitHub Issues](https://github.com/Hentioe/policr-mini/issues)

## 📝 许可证

本项目采用 MIT 许可证 - 详情请查看 [LICENSE](LICENSE) 文件

## 🙏 鸣谢

- 感谢所有贡献者
- 感谢 [Telegex](https://github.com/telegex/telegex) 提供的 Telegram Bot API 支持
- 感谢所有使用和支持本项目的用户

## 🎆 更新日志

### v0.8.0 (2024-01-18)
- ✅ 修复用户验证后权限设置失败的问题
- ✅ 新增反垃圾消息检测功能
- ✅ 新增管理命令 /ban /mute /unmute /kick
- ✅ 新增欢迎消息定制功能
- 🔧 优化错误处理和重试机制

### 更多历史版本

请查看 [CHANGELOG.md](CHANGELOG.md)